# Informe

## 1. Despliegue y situación inicial

El servidor se desplegó como instalación nativa de PostgreSQL 17 en Windows, con datos en `C:/Program Files/PostgreSQL/17/data` y logs en `data/log`. Se crearon la base `comercial` y los roles `app_ventas` (`SELECT`, `UPDATE`), `soporte_ana` (`SELECT`) y `postgres` (administrador). Las conexiones de la aplicación se hicieron por red a `127.0.0.1`, para que quedaran IP y `application_name`.

La consulta a `pg_settings` mostró lo que el servidor registraba por defecto: `log_connections = off`, `log_disconnections = off`, `log_statement = none`, `log_line_prefix = '%t'`, `log_min_error_statement = error`, `log_timezone = America/Chihuahua` y `logging_collector = on`.

Con esos valores el servidor no podía responder a Dirección:

- **¿Quién?** Sin registro de conexiones ni sentencias, y con un prefijo sin `%u`, un `UPDATE` exitoso no dejaba usuario.
- **¿Cuándo?** Un `UPDATE` exitoso no se escribía, así que no tenía hora. El prefijo `%t` ni siquiera daba milisegundos.
- **¿Desde dónde?** El prefijo no incluía `%h` ni `%a`. `pg_stat_activity` solo muestra sesiones abiertas.

## 2. Configuración aplicada

Se activaron `log_connections` y `log_disconnections` para registrar quién se conecta, desde dónde y cuánto dura cada sesión. Se cambió `log_line_prefix` a `'%m [%p] user=%u db=%d app=%a client=%h '`, que añade hora con milisegundos, el PID para agrupar las líneas de una sesión, el usuario, la base, la aplicación y la IP. Se fijó `log_statement` primero en `ddl`, que cubre cambios de estructura y de privilegios, y después en `mod`, que añade `INSERT`, `UPDATE` y `DELETE`, porque con `ddl` los cambios de datos no quedaban registrados. Se descartó `all` por el volumen y por el riesgo de convertir el log en un depósito de datos sensibles. Se mantuvo `log_min_error_statement = error`, que escribe el texto de toda sentencia que falle.

Todos esos parámetros se aplicaron con `ALTER SYSTEM` y `pg_reload_conf()`, de modo que solo requirieron recarga y no reinicio.

## 3. Eventos observados

Un evento de configuración es la línea del proceso principal `[1] ... parameter "log_statement" changed to "ddl"`. Dice qué parámetro cambió y cuándo, pero no quién lo cambió, porque el proceso principal no atiende a ningún cliente y deja usuario y base vacíos.

Un acceso exitoso es la línea `[105] ... connection authorized: user=app_ventas ... application_name=app-ventas-web`. Prueba que hubo una sesión de ese rol desde `127.0.0.1`; el nombre de aplicación es solo declarativo.

Un acceso fallido es `[91] ... FATAL: password authentication failed for user "app_ventas"`, acompañado de la regla de `pg_hba.conf` línea 119 que se aplicó. Prueba que alguien, desde esa IP, presentó ese nombre con una credencial rechazada, pero no la identidad de quien lo hizo. En el intento con `usuario_inexistente` el detalle del log indica que el rol no existe, información que el cliente no recibe para que no pueda enumerar usuarios.

Un evento de privilegio es `[119] ... statement: REVOKE UPDATE ON clientes FROM soporte_ana`, que deja constancia de la revocación aunque no cambiara nada efectivo. Un evento de estructura es `[119] ... statement: ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20)`.

Un evento de datos es `[162] ... user=app_ventas ... statement: UPDATE clientes SET telefono = '6679990000' WHERE id = 3`. Responde quién, cuándo y desde dónde, pero no el valor anterior del teléfono.

Un error de autorización es `[168] ... user=soporte_ana ... ERROR: permission denied for table clientes`, con su `STATEMENT` correspondiente. Indica que la credencial fue válida y que el privilegio no existía, lo que lo hace más significativo para una investigación que un simple fallo de contraseña.

## 4. Auditoría del dato

La tabla `auditoria.cambios_clientes` se creó en un esquema separado, sin acceso para `PUBLIC`, `app_ventas` ni `soporte_ana`. Guarda un identificador de evento, el momento como `TIMESTAMPTZ`. Los valores por defecto toman el contexto de la sesión desde el servidor, de modo que quien modifica los datos no puede elegirlos. `TIMESTAMPTZ` da un instante que se puede correlacionar con otras fuentes, y `JSONB` conserva la fila completa y resiste cambios en la estructura de `clientes`.

La función del trigger se declaró `SECURITY DEFINER` para que `app_ventas` pueda generar evidencia sin tener permisos sobre ella. El efecto secundario es que dentro de la función `current_user` pasa a ser el propietario, `postgres`, como mostró el campo `usuario_efectivo`. Por eso se guarda también `session_user`, que conserva el rol real de la conexión; sin él, todos los cambios parecerían hechos por el administrador. La función fija su `search_path` y el trigger se dejó con `ENABLE ALWAYS`.

El incidente quedó documentado en el evento 1: `app_ventas`, desde `127.0.0.1` y con la aplicación `app-ventas-web`, cambió el RFC del cliente 3 el 2026-10-25 a las 22:50:52.903439 UTC. El valor anterior era `GAMA780912XYZ` y el nuevo `GAMA780912ZZZ`, y la comparación campo por campo con `jsonb_each` confirmó que fue el único campo modificado. La restauración se haría con un `UPDATE` que lea `valores_antes` y que a su vez quedaría auditado.

## 5. Limitaciones

Las lecturas no quedan registradas: ni el trigger ni `log_statement = 'mod'` cubren los `SELECT`, y la consulta de `soporte_ana` al RFC no dejó rastro. Registrarlas exigiría `log_statement = 'all'`, con sus costos y riesgos, o `pgaudit` con auditoría de objeto.

El volumen es otro límite. El trigger actúa por fila, de modo que el `UPDATE` masivo de `segmento` produjo una línea en la bitácora y cinco eventos en la auditoría.

El límite más importante es el administrador con control total. `postgres` desactivó el trigger, cambió el RFC a `GAMA780912GHI` y lo volvió a activar, y el conteo de la auditoría no cambió. Solo la bitácora lo registra, y quien controla el servidor también puede alterarla. Por último, nada de lo ocurrido antes de la configuración existe como evidencia.

## 6. Riesgos de la bitácora

El primer riesgo es la exposición de secretos. La sentencia `CREATE ROLE rol_temporal ... PASSWORD 'Temporal_Practica_2026'` quedó en texto claro en el log, y eliminar el rol no borra esa línea. La contraseña debe considerarse comprometida.

La bitácora contiene además datos personales: con `mod`, los `UPDATE` escriben RFC y teléfonos en el archivo. Es por tanto tan sensible como `clientes`

Existe riesgo de pérdida si la bitácora vive solo en el servidor, porque una reinstalación, una rotación o un fallo de disco la destruyen. Por eso se exportó una copia a `evidencias/bitacora-lab01.log` con la contraseña sustituida por `<REDACTED>`

También hay riesgo por el acceso de terceros. Leer la bitácora desde SQL exige un mecanismo privilegiado como `pg_read_server_files`, por lo que solo debe poder consultarla un rol de auditoría, nunca la aplicación ni soporte, y el archivo en disco debe restringirse a la cuenta de servicio y a los administradores.

## 7. Cronología y conclusión

Con esta configuración sí puede demostrarse quién cambió un dato sensible y qué valor tenía antes, pero solo para los cambios posteriores a la activación y mientras el trigger y la bitácora no hayan sido manipulados. Para el cambio de RFC de la Actividad 12 se prueba el rol, la hora, la IP y el valor anterior. Para los cambios de las Actividades 3 y 7 no hay evidencia, y se declaran como huecos porque un evento que no se registró no tiene hora. Para el cambio de la Actividad 14 la evidencia es parcial: la bitácora identifica a `postgres`, pero no registra el valor anterior. La auditoría atribuye a roles y direcciones, no a personas. La garantía completa exige además una copia externa de la bitácora con hash, custodia por un área distinta al DBA y gestión de cambios sobre el mecanismo de auditoría.

## 29. Preguntas de reflexión

**1. ¿Por qué la auditoría no puede configurarse después de un incidente para investigarlo?**

Porque registra los hechos a medida que ocurren y no puede reconstruir lo pasado. Solo quedarían los respaldos, que sirven para conocer un valor pero no para atribuir la acción. Activar la auditoría después sirve para el futuro, no para el incidente que ya ocurrió.

**2. ¿Por qué conviene que la bitácora la administre el propio servidor y no el mecanismo de despliegue?**

Con `logging_collector = on`, PostgreSQL controla el destino, el nombre, la rotación y el formato de los archivos, y todo se configura con parámetros que pueden consultarse y auditarse, como `log_directory` o `log_filename`. Con el colector apagado, el destino depende de quien lanzó el proceso (un contenedor, `systemd` o un servicio de Windows) y puede variar o perderse sin que la base de datos lo sepa. Aun así, la copia definitiva debe enviarse a un sistema externo.

**3. ¿Por qué el prefijo de línea es tan importante como el nivel de `log_statement`?**

Porque el nivel decide qué se registra y el prefijo decide si lo registrado sirve para atribuir. Con `%t`, un `UPDATE` registrado no diría quién lo hizo, desde dónde ni con qué aplicación. Con `%m [%p] user=%u db=%d app=%a client=%h`, cada línea responde a las preguntas de Dirección y el PID permite reconstruir la historia completa de una sesión.

**4. ¿Qué diferencia práctica hay entre registrar la sentencia y registrar el cambio en el dato?**

La sentencia dice qué se ordenó, quién y cuándo, pero no qué filas ni qué valores cambiaron, ni cuántas. El registro del dato guarda la fila antes y después, y por eso permite revertir.

**5. ¿Qué evidencia ofrece `pg_stat_activity` que no ofrece la bitácora, y viceversa?**

`pg_stat_activity` muestra en vivo qué hace cada sesión, con su estado, la consulta en curso y su duración, y permite intervenir con `pg_cancel_backend` o `pg_terminate_backend`. La bitácora conserva lo que ocurrió cuando la sesión ya terminó: conexiones, fallos, sentencias y desconexiones con su duración.

**6. Si el administrador puede cambiar `log_statement` a `none` y desactivar el disparador, ¿quién audita al administrador?**

Nadie dentro del propio servidor. Lo audita lo que queda fuera de su control: una copia externa de la bitácora custodiada por otra área, con hash y permisos de solo anexar, alertas ante cualquier `DISABLE TRIGGER` o cambio de parámetros `log_*`.
