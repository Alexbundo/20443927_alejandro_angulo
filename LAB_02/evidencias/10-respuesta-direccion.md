# Actividad 10

## 1. ¿Quién cambió el RFC de María García en la Actividad 2? ¿Y en la Actividad 3?

El perfilador estaba apagado, por lo que `db.system.profile.countDocuments()` devolvió `0`. La bitácora tampoco contiene la operación: la búsqueda del texto `GAMA780912XXX` devolvió `0` líneas. MongoDB Community no escribe en su bitácora el contenido de las operaciones de escritura por defecto, solo conexiones y autenticaciones.

## 2. ¿Cuándo y desde qué aplicación?

Sin el registro de la operación no existe una hora del cambio. El evento no registrado no tiene hora y se declara como hueco, no se estima. Solo puede decirse que ocurrió después de la conexión de las 22:52:34 UTC y antes de que se buscara evidencia, lo cual no es una hora del cambio.

## 3. ¿Qué valor tenía antes?

No se guardó ni el valor anterior ni el nuevo en ninguna fuente, porque no hubo registro de la operación.
Es una limitación técnica del perfilador: registra operaciones, no versiones del dato.

## 4. ¿Cambió alguien los privilegios de `app_ventas`?

**Sí cambiaron, pero no hay evidencia de quién ni de cuándo exactamente.**

Lo que se puede afirmar con evidencia es que los privilegios cambiaron. La comparación de las dos instantáneas guardadas en `auditoria.instantaneas_privilegios` muestra que `app_ventas` pasó de tener solo `readWrite` sobre `comercial` a tener además `dbAdmin` sobre `comercial`. Esa comparación sí responde si cambiaron y qué rol se agregó.
