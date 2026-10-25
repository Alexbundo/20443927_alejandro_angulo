# Actividad 18 – Caso integral

## Escenario

- PostgreSQL acepta conexiones desde cualquier dirección IPv4.
- Una aplicación web se conecta con un usuario con privilegios administrativos.
- El servidor escucha en todas las interfaces (`listen_addresses = '*'`).
- El firewall permite el puerto 5432 desde cualquier origen.
- `pg_hba.conf` contiene `host all all 0.0.0.0/0`.
- El administrador afirma: *"no hay problema porque todas las contraseñas son fuertes"*.

## Problemas, riesgos y controles

| # | Problema | Riesgo | Control propuesto |
| --- | --- | --- | --- |
| 1 | `pg_hba.conf` permite `all/all` desde `0.0.0.0/0` | Cualquier host de Internet puede intentar autenticarse con cualquier usuario en cualquier base | Regla específica: base + usuario + origen `/32` + `scram-sha-256` (mínimo privilegio) |
| 2 | El firewall permite el puerto 5432 desde cualquier origen | El servicio es alcanzable, escaneable y atacable desde Internet; el firewall no cumple su función | Permitir 5432 solo desde la red o IP autorizada y denegar el resto (*default deny*) |
| 3 | `listen_addresses = '*'` | El servicio queda expuesto en todas las interfaces, incluidas las públicas | Limitar a `localhost` y la IP privada necesaria (requiere reinicio) |
| 4 | La aplicación web usa un usuario con privilegios administrativos | Una inyección SQL o una credencial filtrada otorga control total del servidor | Cuenta de aplicación dedicada, sin `SUPERUSER`, `CREATEROLE` ni `CREATEDB`, con permisos solo sobre sus tablas |
| 5 | Falta de segmentación: la base de datos es accesible directamente desde Internet | Exposición directa; sin barrera de red si falla otro control | Colocar la BD en red privada; solo el servidor de aplicación puede llegar a ella |
| 6 | Sin TLS (se asume `ssl = off` si no se indica lo contrario) | Consultas, resultados y sesiones viajan en texto claro; riesgo de sniffing y *man-in-the-middle* | `ssl = on`, `ssl_min_protocol_version = TLSv1.2` y reglas `hostssl` |
| 7 | Superusuario accesible desde cualquier IP | Objetivo principal de fuerza bruta; su compromiso implica control total | `postgres` solo por `local`/loopback; sin regla remota para superusuarios |
| 8 | Aplicación expuesta a inyección SQL con privilegios elevados | La inyección permite leer o modificar todo, y con roles como `pg_read_server_files` o `pg_execute_server_program` llegar al sistema operativo | Consultas parametrizadas, validación de entradas y privilegios mínimos en el rol de la aplicación |
| 9 | Sin límite de intentos de autenticación visibles | Fuerza bruta, *password spraying* y *credential stuffing* sin freno | Restringir el origen, usar herramientas de bloqueo de IP (p. ej. fail2ban) y alertar sobre fallos repetidos |
| 10 | Sin monitoreo ni registro de conexiones (`log_connections` y `log_disconnections` en `off` por defecto) | Un acceso indebido no deja evidencia y no se detecta | Activar ambos parámetros, centralizar logs (SIEM) y alertar por accesos desde IP inusuales |
| 11 | Sin `statement_timeout` ni `idle_in_transaction_session_timeout` | Consultas descontroladas, conexiones agotadas y bloqueos prolongados (denegación de servicio) | Definir tiempos de espera por rol o base; ajustar `max_connections` y usar un *pooler* |
| 12 | Sin protección demostrada del sistema operativo y del directorio de datos | Quien acceda al disco puede leer datos o modificar `pg_hba.conf` sin pasar por PostgreSQL | Permisos restringidos a la cuenta de servicio y administradores; respaldo de configuración |
| 13 | Confianza exclusiva en las contraseñas (un solo control) | Un único punto de falla: filtración, reutilización o robo de la contraseña compromete todo | Defensa en profundidad: red + firewall + `pg_hba.conf` + TLS + mínimo privilegio + monitoreo |
| 14 | Credenciales de administrador almacenadas en la aplicación web | Si se compromete la aplicación (archivo de configuración, repositorio, variables), se obtiene la credencial más poderosa | Gestor de secretos, rotación periódica de credenciales y cuenta con privilegios mínimos |
| 15 | Sin segregación de funciones (la aplicación y la administración usan el mismo nivel de acceso) | Un error o abuso de la aplicación afecta toda la instancia | Roles separados: administración, aplicación (lectura/escritura) y solo lectura |

## ¿Es suficiente tener contraseñas fuertes?

**No.** Una contraseña fuerte protege contra adivinar la credencial, pero no contra los demás vectores de ataque. Es **un solo control** y sirve como última barrera, no como estrategia completa.

### Autenticación

- Una contraseña fuerte dificulta la fuerza bruta, pero no evita que se filtre, se reutilice, se robe del código de la aplicación o se capture si la conexión no está cifrada.
- `scram-sha-256` evita enviar la contraseña en claro, pero no cifra el resto de la sesión.
- Sin límite de origen, el atacante puede intentar indefinidamente, y una sola credencial válida basta.
- **Mejora:** `scram-sha-256`, rotación de credenciales, gestor de secretos y, donde sea posible, autenticación por certificado.

### Autorización

- Autenticarse correctamente no debería significar poder hacerlo todo. Con una cuenta administrativa en la aplicación, cualquier fallo (por ejemplo, una inyección SQL) se ejecuta con privilegios totales, sin importar la fortaleza de la contraseña.
- **Mejora:** mínimo privilegio, roles separados y sin `SUPERUSER` para aplicaciones.

### Red

- Con el puerto 5432 abierto a Internet, el servicio es alcanzable y recibe escaneos, intentos de fuerza bruta y exploits contra vulnerabilidades del propio PostgreSQL, incluidos los que ocurren antes de autenticarse, donde la contraseña no interviene.
- `0.0.0.0/0` en `pg_hba.conf`, `*` en `listen_addresses` y el firewall abierto eliminan tres capas de defensa a la vez.
- **Mejora:** red privada, firewall con *default deny*, `listen_addresses` restringido y `pg_hba.conf` por `/32`.

### Configuración

- Sin TLS, el contenido de las sesiones viaja sin cifrar. Sin tiempos de espera ni límites, un usuario legítimo o un atacante puede agotar recursos.
- Los valores por defecto no están pensados para exposición pública.
- **Mejora:** `ssl = on` con `hostssl`, tiempos de espera, límites de conexión y extensiones mínimas.

### Sistema operativo

- Si el atacante llega al sistema (por una vulnerabilidad o por un rol con `pg_read_server_files`, `pg_write_server_files` o `pg_execute_server_program`), la contraseña de la base de datos deja de importar: puede leer archivos de datos, modificar `pg_hba.conf` o ejecutar programas.
- **Mejora:** permisos restrictivos en el directorio de datos y configuración, cuenta de servicio sin privilegios innecesarios, parches de seguridad y membresías de roles sensibles auditadas.

### Monitoreo

- Sin registro de conexiones ni alertas, ni siquiera se sabría que alguien está probando contraseñas, ni que una cuenta válida se usa desde un origen extraño.
- La seguridad no consiste solo en prevenir; también debe permitir **detectar y responder**.
- **Mejora:** `log_connections` y `log_disconnections` activados, logs centralizados, alertas por autenticaciones fallidas y revisión periódica de `pg_stat_activity`.

## Actividad 19 – Baseline de seguridad para PostgreSQL 16

## 1. Red

| Elemento | Valor de la línea base | Justificación |
| --- | --- | --- |
| Interfaces autorizadas | `listen_addresses = 'localhost,<IP_privada_del_servidor>'` (nunca `*`) | Solo se escucha donde hay clientes legítimos. Requiere reinicio |
| Puerto | `5432` documentado; cambiarlo es opcional | Cambiar el puerto solo reduce ruido automatizado; no es un control real |
| Firewall | *Default deny*. Permitir `5432/TCP` solo desde las redes autorizadas; registrar (log) los intentos denegados | El firewall filtra antes de llegar a PostgreSQL |
| Redes permitidas | Red DBA (p. ej. `10.10.10.0/24`) y el/los servidores de aplicación por `/32` | Mínimo privilegio de red |
| Exposición | Sin acceso desde Internet; acceso externo solo por VPN o bastión | Elimina la exposición directa |

Política de firewall conceptual:

| Origen | Destino | Puerto | Acción |
| --- | --- | --- | --- |
| Red DBA / servidor de aplicación | PostgreSQL | 5432 | Permitir |
| Cualquier otro origen | PostgreSQL | 5432 | Denegar |

## 2. Autenticación

| Elemento | Valor de la línea base |
| --- | --- |
| Método | `scram-sha-256` en `password_encryption` y en todas las reglas de `pg_hba.conf`. Prohibido `trust`, `md5` y `password` |
| `pg_hba.conf` | Reglas por **base + usuario + origen `/32` + método**. Sin `0.0.0.0/0` ni `::/0`. Reglas remotas con `hostssl`. Sin reglas de `replication` si no se usa |
| Políticas de credenciales | Contraseñas largas y únicas (mínimo 14 caracteres o frase de contraseña); sin reutilización; rotación periódica y ante sospecha de filtración; almacenamiento en un gestor de secretos, nunca en código ni repositorios |
| Fecha de expiración | `VALID UNTIL` en roles de uso temporal (p. ej. cuentas de alumnos o de proveedores) |
| Cuentas administrativas | Un único superusuario (`postgres`), solo por `local` o loopback, sin acceso remoto y sin uso por aplicaciones. Administradores con cuentas nominales, no compartidas |
| Cuentas inactivas | Deshabilitar (`NOLOGIN`) o eliminar las que no se usen |

## 3. Autorización

| Elemento | Valor de la línea base |
| --- | --- |
| Roles | Separar por función: administración, aplicación (lectura/escritura), solo lectura y mantenimiento. Usar roles de grupo (`NOLOGIN`) y asignar usuarios a ellos |
| Privilegios | Mínimo privilegio con `GRANT` explícitos. `REVOKE ALL ON DATABASE ... FROM PUBLIC` y `REVOKE CREATE ON SCHEMA public FROM PUBLIC` |
| Atributos | Ningún rol de aplicación con `SUPERUSER`, `CREATEROLE`, `CREATEDB` ni `REPLICATION` |
| Roles predefinidos sensibles | Auditar la membresía de `pg_execute_server_program`, `pg_read_server_files`, `pg_write_server_files`, `pg_read_all_data` y `pg_write_all_data`; no concederlos a cuentas de aplicación |
| Cuentas de aplicación | Una por aplicación, con acceso solo a su base y esquema, sin ser dueña de objetos críticos si no es necesario |
| Revisión | Auditoría trimestral de roles y membresías |

## 4. Configuración

| Parámetro | Valor recomendado | Nota |
| --- | --- | --- |
| `listen_addresses` | `localhost,<IP_privada>` | Reinicio |
| `max_connections` | Ajustado a la carga real (por defecto 100) | Reinicio; usar un *pooler* si se necesitan muchas |
| `superuser_reserved_connections` | `3` | Garantiza acceso administrativo en saturación |
| `statement_timeout` | `60s` (mejor por rol o base de datos) | Evita consultas descontroladas |
| `idle_in_transaction_session_timeout` | `5min` | Libera transacciones abandonadas |
| `idle_session_timeout` | Valor definido por política | Cierra sesiones ociosas |
| `log_connections` | `on` | Trazabilidad de accesos |
| `log_disconnections` | `on` | Trazabilidad de sesiones |
| `log_line_prefix` | Incluir hora, PID, usuario, base de datos y origen | Facilita la investigación |
| `log_statement` | `ddl` como mínimo; evaluar `pgaudit` si se requiere auditoría fina | Evidencia de cambios de estructura |
| `log_min_duration_statement` | Según política | Detecta consultas lentas |
| `log_directory` | Ruta conocida, con retención y rotación definidas | Evita llenar el disco |
| `password_encryption` | `scram-sha-256` | Almacenamiento seguro |
| Extensiones | Solo las necesarias (p. ej. `plpgsql`). Prohibido instalar `adminpack`, `file_fdw`, `dblink`, `postgres_fdw` ni lenguajes *untrusted* sin justificación aprobada | Menor superficie de ataque |

## 5. Sistema operativo

| Elemento | Valor de la línea base |
| --- | --- |
| Propietario de archivos | Cuenta de servicio dedicada de PostgreSQL (sin privilegios administrativos ni inicio de sesión interactivo), propietaria del directorio de datos |
| Permisos | **Linux:** directorio de datos `0700` (o `0750` con acceso de grupo), `postgresql.conf` y `pg_hba.conf` solo escritura del propietario. **Windows:** ACL con acceso solo para la cuenta de servicio y administradores (`icacls`) |
| Directorio de datos | Protegido contra lectura por otros usuarios; en partición separada si es posible, para que los logs no la llenen |
| Configuración | Respaldo previo a cada cambio de `postgresql.conf`, `pg_hba.conf` y `pg_ident.conf` |
| Servicio | Servicio ejecutado con la cuenta dedicada, no con `SYSTEM`/`root` |
| Sistema | Servidor dedicado o mínimo: sin servicios innecesarios, con parches del SO y antivirus/EDR cuando aplique |
| Logs | Protegidos con permisos restringidos y, si es posible, enviados a un servidor central para que no puedan borrarse localmente |
| Respaldos | Cifrados y con acceso restringido |

## 6. Cifrado

| Elemento | Valor de la línea base |
| --- | --- |
| TLS | `ssl = on`, `ssl_cert_file` y `ssl_key_file` con certificado válido (de preferencia emitido por una CA de la organización), `ssl_min_protocol_version = 'TLSv1.2'` (preferible TLS 1.3 donde sea compatible) |
| Obligatoriedad | Reglas remotas con `hostssl`; clientes con `sslmode=verify-full` |
| Clave privada | Permisos restringidos al propietario (en Linux `0600`) y rotación según la vigencia del certificado |
| Protección de credenciales | `scram-sha-256`; secretos fuera del código; sin contraseñas en texto claro en scripts, variables visibles ni logs |
| Información sensible | Minimizar datos sensibles almacenados; cifrar columnas críticas (p. ej. con `pgcrypto`, aprobado y documentado) o cifrar a nivel de aplicación; cifrado de disco y de respaldos |
| Registros | Evitar que los logs incluyan datos sensibles (cuidado con `log_statement = all`) |

## 7. Mantenimiento

| Elemento | Valor de la línea base |
| --- | --- |
| Actualización | Aplicar las versiones menores de PostgreSQL 16 en cuanto se publiquen (contienen correcciones de seguridad); plan de actualización mayor antes del fin de soporte de la versión. Verificar con `SELECT version();` |
| Pruebas | Probar los cambios en un entorno de pruebas antes de producción; plan de reversión |
| Revisión periódica | Trimestral: roles y membresías, reglas de `pg_hba.conf`, extensiones, conexiones remotas y parámetros de la línea base. Anual: revisión completa y prueba de restauración |
| Monitoreo | Revisión de logs y alertas ante fallos de autenticación repetidos, accesos desde orígenes inusuales y sesiones `idle in transaction` prolongadas |
| Respaldos | Copias periódicas con prueba de restauración documentada |
| Documentación | Inventario de la superficie de ataque, tabla antes/después, checklist de hardening, rutas de configuración, responsables y fecha de cada revisión |
| Gestión de cambios | Todo cambio de configuración registrado (qué, quién, cuándo, por qué) |

## Resumen de la línea base

| Dominio | Control clave |
| --- | --- |
| Red | Escucha restringida + firewall *default deny* + redes por `/32` |
| Autenticación | `scram-sha-256` + `pg_hba.conf` específico + un solo superusuario local |
| Autorización | Mínimo privilegio + roles separados + cuentas de aplicación sin atributos elevados |
| Configuración | Tiempos de espera + registro de conexiones + extensiones mínimas |
| Sistema operativo | Cuenta de servicio dedicada + permisos restringidos + respaldo de configuración |
| Cifrado | TLS obligatorio (`hostssl`) + secretos protegidos + datos sensibles minimizados |
| Mantenimiento | Parches menores + revisión periódica + documentación y gestión de cambios |

## Conclusión

La línea base busca aplicar **defensa en profundidad**: reducir la exposición de red, exigir autenticación fuerte, limitar lo que cada cuenta puede hacer, cifrar las comunicaciones, proteger el sistema operativo y mantener evidencia y mantenimiento continuos. Ningún control sustituye a los demás: si uno falla, los otros deben contener el daño. Debe revisarse y actualizarse periódicamente, y cualquier desviación respecto a ella debe documentarse y justificarse.
