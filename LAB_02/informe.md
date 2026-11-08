# Informe

## 1. Despliegue, edición y limitación

El servidor es una instalación nativa de MongoDB en Windows, con el binario en `C:\Program Files\MongoDB\Server\9.0\bin` y el cliente `mongosh` 2.14.1. La guía pide MongoDB 7 y el servidor instalado es la versión 9.0.4, por lo que debe indicarse como diferencia de versión. Se trabajó con dos sesiones: la del DBA (`admin`, autenticado contra `admin`) y la de la aplicación (`app_ventas`, con `appName=app-ventas-web`), ambas por red a `127.0.0.1`.

## 2. Perfilador

El perfilador es por base de datos y guarda en `system.profile`. Se probaron tres configuraciones. Con el nivel 0 (estado inicial, `was: 0`) no se registró nada: la modificación del RFC de la Actividad 2 no dejó rastro. Con el nivel 2 se registraron la consulta, la actualización y la eliminación. Con el nivel 1 y un filtro por `op` (`insert`, `update`, `remove`) se conservaron solo las modificaciones, y el filtro sustituye a `slowms` y `sampleRate`.

el perfilador dice quién, cuándo, desde dónde y qué comando, pero no el estado del dato. En el `update` consta el valor nuevo, no el anterior, y en el `remove` consta el filtro, no el contenido del documento eliminado.

## 3. Bitácora de `mongod`

La bitácora se escribe en `C:\Program Files\MongoDB\Server\9.
Se lee también en memoria con`getLog: "global"` mediante la función `bitacora()`, que solo conserva unos 1024 eventos recientes.

Los accesos quedan bien registrados. El acceso exitoso aparece como `Successfully authenticated` (`result: 0`) con usuario, base y cliente, por ejemplo `app_ventas` desde `127.0.0.1:37234` a las 22:52:57.394. Los fallos aparecen como `Failed to authenticate`, con código `18` para contraseña incorrecta (`storedKey mismatch`) y `11` para usuario inexistente (`UserNotFound`). Un intento puede producir varias líneas, por lo que se cuentan intentos y no líneas. El nombre de aplicación de los fallos fue `mongosh 2.10.0` porque la cadena no incluía `appName`, lo que recuerda que ese campo lo declara el cliente.

Los cambios de configuración también se registran, pero sin usuario. `Profiler settings changed` muestra el paso del nivel 0 al nivel 1 con filtro. El autor se obtiene correlacionando `ctx` con la autenticación de la misma conexión: `admin` desde `127.0.0.1:37200`. La correlación solo es válida si no hubo un reinicio entre ambos eventos, porque los números `connN` se reinician.

## 4. Privilegios

La evidencia disponible es limitada. Al conceder `dbAdmin` a `app_ventas` con el perfilador en nivel 2, ni `system.profile` ni la bitácora registraron `grantRolesToUser`: ambas búsquedas devolvieron `0`. La revocación y el restablecimiento del perfilador tampoco dejaron rastro.

Su límite es que describe estados, no eventos: no se sabe quién concedió el rol ni cuándo exactamente, solo que ocurrió entre ambas fotografías. El campo `tomada_por` indica quién tomó la instantánea, no quién hizo el cambio. Además, quien escribe y quien administra son la misma cuenta, y un administrador podría borrar una instantánea incómoda.

## 5. Conservación

Se observaron cuatro riesgos de pérdida sin borrado deliberado: el reinicio, que devuelve el perfilador al nivel 0 y vacía la memoria de `getLog`; la sobrescritura de `system.profile` por su tamaño fijo; la ventana de unos 1024 eventos de `getLog`; y el `drop()` de `system.profile` al cambiar la configuración, que eliminó lo acumulado y exige exportar antes.

## 6. Comparación

La Actividad 9 comparó PostgreSQL (bitácora más disparador), MongoDB Community y la auditoría nativa. En PostgreSQL se observaron accesos, fallos, cambios de privilegios y de estructura, modificaciones y valor anterior (este último solo con el disparador). En MongoDB Community se observaron accesos, fallos y modificaciones con perfilador activo.

## 7. Recomendación

Para una organización que necesite auditar cambios de privilegios en MongoDB, recomendaría **usar la auditoría nativa de MongoDB Enterprise o de Atlas**, configurada para registrar administración de usuarios y roles, con envío de los eventos a un sistema externo custodiado por otra área, con hash y retención definida. La razón es que es el único mecanismo que registra el comando con autor y hora, algo que en este laboratorio Community no pudo dar.

Si el costo o la decisión de plataforma lo impiden, recomendaría como alternativa transitoria instantáneas automáticas de privilegios, escritas por una cuenta de servicio de solo anexar y copiadas fuera del servidor, junto con gestión de cambios que obligue a registrar cada concesión de roles, y una alerta ante cualquier diferencia sin solicitud asociada. Esa alternativa detecta pero no atribuye, y debe comunicarse así.

Hechos verificados en este laboratorio: la edición es Community (`modules: []`), el cambio de privilegios no apareció en el perfilador ni en la bitácora, las instantáneas detectaron el cambio sin autor ni hora precisa, y la correlación por `ctx` permitió atribuir un cambio de configuración del perfilador.

**1. ¿Por qué el perfilador no debe presentarse como un mecanismo de auditoría de seguridad?**

Porque se diseñó para diagnosticar rendimiento, no para dar garantías de seguridad. No registra los comandos de administración de usuarios y roles (el `grantRolesToUser` no apareció), es una colección de tamaño fijo que se sobrescribe, vuelve a nivel 0 tras un reinicio y cualquier administrador puede apagarlo o borrarlo.

**2. ¿Por qué el perfilador sí aporta trazabilidad aunque no sea auditoría?**

Porque, cuando está activo, registra de forma estructurada usuario con su base, cliente, aplicación, momento, tipo de operación y documentos afectados.

**3. ¿Qué riesgo introduce el nivel 2 al registrar filtros de consultas que pueden contener datos personales?**

Convierte `system.profile` en un depósito de datos personales. Los filtros y los valores nuevos se guardan en claro, de modo que cualquier rol con lectura sobre esa colección o sobre la exportación los ve. Además esas copias sobreviven a la depuración de la colección principal, lo que choca con la política de retención y de minimización.

**4. ¿Qué diferencia hay entre detectar un cambio y atribuirlo a alguien?**

Detectar es comprobar que el estado cambió, como hicieron las instantáneas con el rol `dbAdmin`. Atribuir es identificar quién lo hizo y cuándo, y exige un registro del evento con identidad y hora. En la Actividad 7 se pudo detectar pero no atribuir. Y aun la atribución llega a una cuenta y a una dirección, no a una persona, porque `app_ventas` es compartida.

**5. ¿Por qué reconocer una limitación técnica es parte del trabajo profesional del DBA?**

Porque Dirección toma decisiones basándose en lo que el DBA afirma, y una afirmación que excede la evidencia expone a la organización a riesgos que cree controlados. Declarar que no hay evidencia, y explicar el motivo técnico, permite decidir con información correcta.
