# Evidencias de configuración de logging

## 1. ¿Por qué `logging_collector` requiere reinicio y `log_statement` solo recarga?

La diferencia está en el contexto de cada parámetro `logging_collector` tiene contexto `postmaster`, lo que significa que solo se lee al arrancar el servidor. Este parámetro decide si el proceso principal lanza un proceso auxiliar y redirige hacia una tubería la salida de error de todos los demás procesos.

`log_statement`, en cambio, tiene contexto `superuser` y puede modificarse en breve. Es únicamente una variable que cada sesión consulta cada vez que ejecuta una sentencia. Con `pg_reload_conf()` el servidor vuelve a leer la configuración y las sesiones adoptan el valor nuevo sin necesidad de crear ni reconfigurar procesos. Incluso un superusuario puede cambiarlo solo para su sesión con `SET log_statement = 'all';`.

En términos prácticos, lo que cambia la estructura del servidor (procesos, memoria, puertos) exige un reinicio, mientras que lo que cambia un criterio de decisión, como qué sentencias registrar, solo requiere una recarga.

## 2. ¿Qué ventaja tiene leer la bitácora con SQL y qué riesgo introduce?

La principal ventaja es la capacidad de análisis. Con SQL es posible filtrar por usuario, hora, dirección IP o aplicación, agrupar los intentos fallidos por origen y cruzar la información con la tabla `auditoria_clientes` mediante un `JOIN`.

Existe además una dependencia del servicio: si PostgreSQL está caído, saturado o comprometido, la bitácora no puede consultarse, mientras que un archivo en disco sí seguiría disponible.

## 3. ¿Quién debería poder consultar `dba.bitacora`?

Solo el personal de administración y auditoría, con permiso de lectura y nunca de escritura. El propietario del objeto sería `postgres`, que administra la tabla pero no debería usarse para el trabajo diario. La consulta debería hacerse mediante un rol de auditoría (por ejemplo `auditor`) con `SELECT`, de modo que pueda revisar la evidencia sin poder modificarla.

El principio que sustenta esto es la separación de funciones: quien administra el sistema no debería ser el único que revisa su bitácora. Si existe un auditor independiente, el DBA no puede ocultar sus propias acciones sin que se note.
