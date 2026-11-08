# Evidencias de pg_stat_activity

## 1. ¿Qué columna permite relacionar una sesión con sus líneas de bitácora?

La columna `pid`. Es el identificador del proceso del servidor que atiende la conexión, y es el mismo número que aparece entre corchetes en el prefijo de cada línea de la bitácora (`%p` en `log_line_prefix`). Cada conexión tiene su propio proceso, de modo que todas las líneas de una sesión comparten PID: la recepción de la conexión, la autenticación, la autorización, las sentencias registradas, los errores y la desconexión.

## 2. Después de que termina el reporte, ¿qué fuente conserva evidencia de que existió?

La **bitácora**. Cuando el reporte termina, la sesión desaparece de `pg_stat_activity`, porque esa vista solo muestra lo que existe en este momento. Repetir la consulta devuelve únicamente la sesión del administrador, y no queda rastro de que `soporte_ana` ejecutó un reporte de 90 segundos.

## 3. ¿Por qué `client_addr` aparece vacío en la sesión del administrador?

Porque la sesión del administrador se conectó por **socket local**, no por red. Cuando `psql` se ejecuta en el mismo equipo con `-U postgres` y sin indicar un host, utiliza el canal local del sistema (socket Unix en Linux, o el equivalente en el despliegue) en lugar de una conexión TCP/IP. Al no haber una dirección IP de origen, `client_addr` queda en `NULL`. En la bitácora esa misma situación se muestra como `client=[local]`.
