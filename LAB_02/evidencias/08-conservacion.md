# Actividad 14

## 1. Tres formas en que la evidencia puede perderse sin que nadie la borre deliberadamente

**Reinicio del servidor.** El nivel del perfilador vuelve a `0`, de modo que desde el reinicio no se registra nada hasta que alguien lo reactive. Además se vacía la memoria de `getLog`, de modo que se pierden los eventos recientes que no estaban en un archivo.

**Sobrescritura por tamaño fijo.** `system.profile` es una colección limitada. Con el nivel 2, los documentos nuevos desplazan a los antiguos sin aviso, y la evidencia puede desaparecer en minutos. Lo mismo ocurre con la ventana de `getLog`, que guarda solo unos 1024 eventos.

**Rotación y retención de archivos, o fallos de infraestructura.** Una rotación de `mongod.log` con retención corta elimina archivos antiguos.

## 2. ¿Por qué el tamaño de 1 MB de `system.profile` es un problema de conservación y no solo de espacio?

Porque el límite no solo restringe cuánto espacio ocupa, sino **cuánto tiempo sobrevive la evidencia**. Al ser una colección limitada, cuando se llena elimina automáticamente los documentos más antiguos para hacer sitio a los nuevos.

## 3. ¿Por qué `getLog` sirve para interpretar pero no para conservar?

Sirve para **interpretar** porque devuelve los eventos recientes ya estructurados en JSON, y la función `bitacora()` permite filtrarlos y correlacionarlos desde la propia sesión, sin leer archivos.
