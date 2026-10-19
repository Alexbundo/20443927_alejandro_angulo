# Informe final: Protección de credenciales, datos sensibles, TLS y gestión de claves en PostgreSQL

## Práctica de seguridad en bases de datos con PostgreSQL y la extensión pgcrypto

## 1. Introducción

Una base de datos con usuarios, roles y permisos bien configurados no está, por ese solo hecho,no esta bien protegida. Los permisos controlan quién puede consultar los datos a través del motor, pero no protegen la información si alguien accede por otra vía: un respaldo robado, el disco del servidor, el tráfico de red interceptado, un administrador con acceso legítimo o un archivo SQL publicado con claves dentro.

## 2. Protección de credenciales

Se compararon tres formas de tratar una contraseña:

| | Texto claro | Hash (bcrypt con `crypt()`) | Cifrado (`pgp_sym_encrypt()`) |
| --- | --- | --- | --- |
| **Qué se guarda** | La contraseña tal cual | Una huella de una sola vía con salt | Un dato binario que oculta el original |
| **¿Reversible?** | No hay nada que revertir; ya es legible | No | Sí, con la clave correcta |
| **¿Requiere clave?** | No | No | Sí |
| **Si se filtra la tabla** | Compromiso inmediato y total | El atacante debe romper cada hash por fuerza bruta | Depende de que la clave siga secreta |
| **Uso adecuado** | Ninguno | Contraseñas | Datos que deben leerse de nuevo |

**Implementación insegura.** La tabla usuarios_insegura guarda la contraseña en un campo VARCHAR. Con solo SELECT * FROM usuarios_insegura; se ve Password123 sin ningún esfuerzo.

**Implementación segura.** La tabla usuarios_segura almacena password_hash, generado con crypt('Password123', gen_salt('bf')). Aquí gen_salt('bf') crea un salt aleatorio con el algoritmo Blowfish (bcrypt) y crypt() combina la contraseña con ese salt para producir el hash. Al ejecutar dos veces la misma consulta se obtuvieron hashes distintos, porque cada llamada genera un salt nuevo.

## 3. Protección de datos sensibles

Se protegió el **RFC** de los clientes, almacenado en la tabla clientes_protegidos en la columna rfc_cifrado de tipo BYTEA. El RFC es un dato personal que permite identificar a una persona y facilita fraudes y suplantación de identidad; además, su tratamiento está sujeto a la LFPDPPP en México.

A diferencia de la contraseña, el RFC sí debe poder recuperarse (por ejemplo, para facturar), por lo que no sirve un hash: se usó cifrado simétrico con pgp_sym_encrypt('LOPA900101ABC, 'CLAVE-DE-PRUEBA') y se recuperó con pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA'). Con una clave incorrecta, PostgreSQL no devuelve un dato falso, sino un error.

## 4. TLS

**Qué problema resuelve.** Sin TLS, las consultas, los resultados y las contraseñas viajan en texto claro por la red, de modo que un atacante puede espiarlos o modificarlos en tránsito. TLS aporta confidencialidad (cifra el tráfico), integridad (detecta alteraciones) y autenticación del servidor.

**Qué se verificó en PostgreSQL.** Se ejecutaron estas consultas:

- `SHOW ssl;`: indica si el servidor tiene TLS habilitado.
- `SHOW port;` y `SHOW listen_addresses;`: puerto y direcciones en las que escucha el servidor.
- `SELECT inet_client_addr(), inet_client_port();`: dirección y puerto del cliente de la sesión actual.
- `SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid();`: indica si **la sesión actual** usa TLS, con qué versión y con qué algoritmo de cifrado.

Si `ssl` es `f`, `version` y `cipher` aparecen vacíos y la sesión viaja sin cifrar. Esto es habitual en conexiones locales por socket Unix, donde además `inet_client_addr()` devuelve `NULL`.

## 5. Gestión de claves

El cifrado es tan fuerte como el secreto de su clave. En la práctica, la consulta `pgp_sym_decrypt(rfc_cifrado, 'CLAVE-DE-PRUEBA')` tiene la clave escrita en el propio script, y eso crea varios problemas:

- **Quien tenga el script tiene la llave.** Si el script y los datos cifrados caen en las mismas manos, el cifrado no aporta protección.
- **Persistencia en el historial.** Si el archivo se sube a un repositorio, la clave queda en el historial de Git, en *forks*, clones y cachés, aunque se borre después.
- **Rastros en otros sistemas.** La clave puede aparecer en logs del servidor (`log_statement`), en `pg_stat_statements`, en el historial de la consola y en el tráfico de red si no hay TLS.
- **Efecto multiplicador.** Una sola clave expuesta compromete todos los datos y respaldos cifrados con ella.
- **Los scripts se comparten con mucha gente.** Circulan entre desarrolladores, herramientas de integración continua y servicios externos, muchos más de los que deberían tener acceso a la clave.

Por eso las claves deben vivir en un gestor de secretos o KMS (Vault, AWS KMS, Azure Key Vault), separadas de los datos y del código, e inyectarse en tiempo de ejecución. Como parte de la práctica se redactó una política de nueve reglas que cubre generación, almacenamiento, acceso, rotación, respaldo, revocación, exposición accidental y eliminación. Su principio central es que una clave expuesta, aunque sea por accidente, se trata como comprometida y se rota de inmediato.

## 6. Resultados

- La tabla `usuarios_insegura` dejó ver la contraseña en texto plano con una simple consulta de lectura.
- Dos ejecuciones de `crypt('Password123', gen_salt('bf'))` produjeron hashes diferentes, confirmando el uso de un salt aleatorio.
- La verificación con `crypt()` devolvió `true` con la contraseña correcta y `false` con la incorrecta, sin necesidad de recuperar la contraseña original.
- El RFC se almacenó cifrado en `BYTEA` y se recuperó correctamente con la clave adecuada; con una clave errónea se produce un error.
- Se comprobó que la clave en texto dentro del script es un riesgo grave de gestión de claves.
- Se consultó el estado de TLS de la sesión con `pg_stat_ssl` (valores en la sección 4).
- En el caso de la empresa, el problema más crítico se identificó en las **claves criptográficas expuestas en archivos SQL**, porque anulan todo el cifrado y afectan a todos los datos y respaldos; se concluyó que los permisos correctos **no** eliminan los riesgos.
- Se elaboró una política de gestión de claves de nueve reglas.

## 7. Problemas encontrados

- **Tablas ya existentes.** Al repetir los scripts, `CREATE TABLE` falla si la tabla ya existe; también `usuarios_segura.usuario` es `UNIQUE`, por lo que reinsertar a `juan` produce un error de duplicado. Se resuelve con `DROP TABLE IF EXISTS`, o bien con `CREATE TABLE IF NOT EXISTS` y `ON CONFLICT`.
- **Hashes distintos en cada ejecución.** Puede parecer un error, pero es el comportamiento esperado del salt aleatorio.
- **Error con clave incorrecta.** `pgp_sym_decrypt` lanza *Wrong key or corrupt data* en lugar de devolver un valor.
- **Interpretación de TLS.** `SHOW ssl` puede devolver `on` mientras la sesión no usa TLS; hay que consultar `pg_stat_ssl`. En conexiones locales por socket, `ssl` es `f` y `inet_client_addr()` es `NULL`.
- **Validación del servidor.** Habilitar TLS en el servidor no basta: si el cliente usa `sslmode=require` o `prefer`, el tráfico se cifra pero no se valida al servidor.
- **Duplicidad de consultas.** Algunos scripts repetían consultas idénticas (por ejemplo, las dos ejecuciones de `crypt()` y de `pgp_sym_decrypt`), lo cual es intencional en el caso de `crypt()` para comparar salts, pero redundante en otros.

## 8. Conclusiones

**Lo aprendido.**

1. Texto claro, hash y cifrado resuelven problemas distintos: las contraseñas se verifican (hash con salt), los datos que deben leerse de nuevo se cifran.
2. El algoritmo rara vez es el eslabón débil; lo es la gestión de la clave.
3. Los permisos son necesarios pero insuficientes: protegen la entrada por el motor, no por otras vías.
4. TLS protege los datos en tránsito y el cifrado de columna protege los datos en reposo; son capas complementarias.

**Medidas en un entorno productivo.**

- Hash de contraseñas con bcrypt o Argon2 (preferentemente en la aplicación, con factor de costo ajustado) y flujo de restablecimiento en lugar de recuperación.
- Cifrado de columnas sensibles (RFC, información financiera), con control de acceso y auditoría.
- TLS con certificados válidos y `sslmode=verify-full` en los clientes.
- Claves en un KMS/HSM o gestor de secretos, inyectadas en tiempo de ejecución, con rotación, revocación y política documentada.
- Escaneo de secretos (`gitleaks`, hooks `pre-commit`) para evitar fugas en repositorios.
- Respaldos cifrados, almacenados por separado, con acceso restringido, retención definida y pruebas periódicas de restauración.
- Cifrado en reposo del disco o del almacenamiento y mínimo privilegio en roles.
- Evitar que las claves aparezcan en logs (`log_statement`) y en `pg_stat_statements`.

## Preguntas de reflexión

**1. ¿Por qué una contraseña no debe almacenarse como texto claro?**
Porque cualquiera que pueda leer la tabla obtiene credenciales inmediatamente utilizables. Como muchas personas reutilizan contraseñas, el daño se extiende a otros servicios. Además, incumple buenas prácticas  y la normativa de protección de datos.

**2. ¿Por qué un hash no es equivalente a un cifrado?**
Un hash es una función de una sola vía: no tiene clave ni función inversa, y solo permite comprobar si un dato coincide. El cifrado es reversible: con la clave correcta se recupera el dato original. Por eso el hash sirve para contraseñas y el cifrado para datos que hay que volver a leer. Si se cifraran las contraseñas, quien obtuviera la clave podría recuperarlas todas.

**3. ¿Por qué el cifrado de una columna no sustituye al control de acceso?**
Porque responden a preguntas distintas. El control de acceso decide quién puede consultar o modificar datos. El cifrado de columna protege el contenido si alguien accede por otra vía. Sin control de acceso, cualquier usuario podría intentar usar la función de descifrado, o podría borrar, alterar o reemplazar los datos cifrados; además, el cifrado no impide que un usuario autorizado con la clave descifre más de lo que le corresponde. Se necesitan ambos controles.

**4. ¿Por qué TLS no sustituye a los mecanismos de autorización de PostgreSQL?**
TLS solo protege el canal de comunicación entre cliente y servidor: impide que terceros lean o alteren el tráfico. No decide qué puede hacer un usuario una vez conectado. Una conexión perfectamente cifrada puede pertenecer a un usuario con permisos excesivos o a un atacante con credenciales robadas; la autorización es lo que limita sus acciones.

**5. ¿Qué ocurriría si una organización pierde una clave utilizada para cifrar información?**
Los datos cifrados con ella serían irrecuperables, incluidos los de los respaldos que dependan de esa clave. Es una pérdida de disponibilidad permanente, con posibles consecuencias operativas y legales.

**6. ¿Qué ocurriría si una clave criptográfica se publica accidentalmente en GitLab?**
Debe considerarse comprometida. Aunque se borre el archivo, la clave permanece en el historial de Git. Cualquiera que tenga datos cifrados con esa clave  podría descifrarlos. Se debe revocar y rotar la clave, recifrar los datos, limpiar el historial.

**7. ¿Por qué un repositorio privado no debe considerarse un almacén de secretos?**
Porque su privacidad depende de configuraciones, permisos y personas que cambian con el tiempo: desarrolladores que se van, cuentas comprometidas, cambios de visibilidad por error, clones locales, integraciones y herramientas de integración continua con acceso al código. El historial conserva los secretos para siempre, y no hay rotación, auditoría de uso ni separación de funciones propias de un gestor de secretos. Si el repositorio se filtra, también se filtra la clave.

**8. ¿Qué diferencia existe entre proteger información almacenada y proteger información durante su transmisión?**
La información almacenada se protege frente a quien acceda a discos, respaldos o tablas, con cifrado de columna, cifrado de disco y control de acceso. La información en tránsito se protege mientras viaja por la red frente a espionaje y alteración, con TLS validado. Un dato cifrado en la tabla puede viajar sin protección en el resultado de una consulta o en la clave enviada por una conexión sin TLS; por eso se requieren ambas protecciones.

**9. ¿Por qué la gestión de claves es tan importante como el algoritmo criptográfico?**
Los incidentes suelen deberse a claves mal almacenadas, expuestas, compartidas, nunca rotadas o perdidas. Si la clave es accesible para el atacante, la fortaleza del algoritmo es irrelevante. La seguridad de todo el sistema se reduce a la protección de la clave durante todo su ciclo de vida: generación, almacenamiento, acceso, rotación, respaldo, revocación y eliminación.

**10. ¿Qué mecanismo adicional implementarías en una organización para proteger los respaldos de las bases de datos?**
Cifraría cada respaldo con una clave gestionada en un KMS, distinta de la que protege los datos en producción, y la custodiaría por separado de los respaldos. Complementaría esto con almacenamiento aislado, acceso restringido con autenticación multifactor, bitácoras de auditoría, política de retención y eliminación segura, y pruebas periódicas de restauración para comprobar tanto la integridad de los respaldos como la disponibilidad de las claves.
