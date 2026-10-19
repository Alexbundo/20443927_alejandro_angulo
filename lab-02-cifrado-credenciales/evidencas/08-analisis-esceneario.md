# Pregunta 1

¿Cuáles son los principales riesgos?
Contraseñas en texto claro quien lea la tabla obtiene credenciales utilizables de inmediato, con posible reutilización en otros servicios.

RFC en texto claro: Exposición de datos personales; facilita suplantación de identidad y fraude. Implica incumplimiento de la LFPDPPP.

Conexiones sin validación del servidor: Ataques donde  un atacante puede hacerse pasar por el servidor, interceptar consultas, credenciales y resultados, aunque el tráfico esté cifrado.

Claves criptográficas en archivos SQL: Compromiso de todo lo cifrado con esas claves. Quedan en repositorios, logs e historiales.

Respaldos sin protección: Un respaldo robado equivale a robar la base completa, saltándose usuarios, roles y permisos.

## Pregunta 2

¿Qué mecanismo utilizarías para cada elemento?

| Elemento | Mecanismo | Justificación |
| --- | --- | --- |
| Nombre | Control de acceso (roles y permisos); cifrado en reposo del disco | Es un dato personal poco sensible por sí solo; no suele requerir cifrado a nivel de columna. |
| Correo electrónico | Control de acceso y, si el riesgo lo justifica, cifrado de columna | Es un dato personal; si se usa como identificador de inicio de sesión, conviene protegerlo bien. |
| Contraseña | **Hash con salt**: (bcrypt), o preferiblemente Argon2 desde la aplicación | No debe recuperarse nunca; solo se verifica. |
| RFC | **Cifrado simétrico**, con clave gestionada externamente | Es un dato que debe poder recuperarse. |
| Información financiera | Cifrado de columna o a nivel de aplicación, más control de acceso estricto y auditoría | Tiene alta sensibilidad y debe poder leerse, por lo que el cifrado debe ser reversible. |
| Claves criptográficas | **Gestor de secretos o KMS** (Vault, AWS KMS, Azure Key Vault), inyección en tiempo de ejecución y rotación periódica | Nunca deben guardarse en SQL ni en el repositorio; deben mantenerse separadas de los datos que protegen. |
| Conexiones | **TLS** con, certificados válidos y TLS 1.2 como mínimo | Protege los datos en tránsito y valida la identidad del servidor. |
| Respaldos | Cifrado de los respaldos, almacenamiento separado, control de acceso, retención definida y pruebas de restauración | Evita que un respaldo robado exponga la información. |

## Pregunta 3

¿Cuál de los problemas consideras más crítico y por qué?
el más crítico es las claves criptográficas expuestas en archivos SQL, por estas razones:

Anula todo el cifrado. El algoritmo puede ser perfecto, pero si la clave es pública, cualquiera descifra los datos. El cifrado pasa a ser decorativo.
Efecto multiplicador. Una sola clave expuesta compromete todos los datos cifrados con ella, incluidos respaldos antiguos.
Es difícil de revertir. Si la clave estuvo en Git, hay que asumir que ya fue copiada; la única solución es rotarla y recifrar todo.

## Pregunta 4

¿Tener correctamente configurados los usuarios y permisos elimina estos riesgos?
Los roles y permisos controlan quién puede acceder a los datos a través de la base de datos, pero no protegen los datos cuando se accede por otra vía asi que la respuesta seria no. Por eso se requiere defensa en profundidad: control de acceso, cifrado en reposo y a nivel de columna, TLS validado en tránsito, hashing de contraseñas, gestión segura de claves, respaldos protegidos y auditoría. Los permisos son una capa necesaria, pero no suficiente: protegen la puerta de entrada, no los datos si alguien entra por otro lado.
