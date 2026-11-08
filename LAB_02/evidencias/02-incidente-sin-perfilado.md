# Actividad 2

## 1. ¿Puedes demostrar qué cambió? ¿Y quién se conectó a esa hora?

**Qué cambió: no.** No se registró la sentencia, ni el campo modificado, ni el valor nuevo, y mucho menos el valor anterior. Lo único que se sabe del cambio es el resultado que recibió el cliente (`modifiedCount: 1`), que no queda guardado en ningún lado. Que el RFC actual sea `GAMA780912XXX`

**Quién se conectó a esa hora: sí, parcialmente.** La bitácora muestra que a las 22:52:34 UTC hubo conexiones cuyos metadatos incluyen `appName = app-ventas-web`, y que una de ellas (`conn9`) se autenticó correctamente.

Por tanto, se puede afirmar que `app_ventas` se conectó a esa hora, pero no que modificó el RFC ni qué valor tenía antes.

## 2. ¿Por qué `mongosh` abre varias conexiones (`conn8`, `conn9`, …) para una sola instrucción? ¿Cuál es la que se autentica?

`mongosh` usa el controlador de MongoDB, que abre más de una conexión por cliente. Por una parte mantiene una conexión de **monitoreo**, que consulta periódicamente el estado del servidor. Por otra parte, el pool de conexiones abre las conexiones de **trabajo** por las que viajan los comandos, y puede abrir más de una.
Las conexiones de monitoreo se establecen sin credenciales, por eso en el resultado `conn8` muestra `Connection not authenticating`. La que se autentica es la de trabajo, `conn9`, con `Successfully authenticated`, y es por la que se ejecuta el `updateOne`.
