# Actividad 14 – Evasión de la auditoría por un administrador

## 1. ¿Qué evidencia permite detectar que hubo un cambio sin auditar?

- **La bitácora del servidor.** Las líneas `ALTER TABLE clientes DISABLE TRIGGER` y `ENABLE TRIGGER` dejan constancia de que el mecanismo estuvo apagado, con usuario (`postgres`), origen (`[local]`), PID y hora. Cualquier `UPDATE` o `DELETE` sobre `clientes` ubicado entre ambas líneas, en el mismo PID o en el intervalo, es un cambio sin auditar. Aquí el `UPDATE ... 'GAMA780912GHI'` aparece en la bitácora y no en la tabla.
- **El estado actual frente al último valor auditado.** El RFC actual (`GAMA780912GHI`) no coincide con el `valores_despues` del último evento (`GAMA780912ZZZ`). Una consulta periódica que compare el estado de `clientes` con el resultado de reproducir la auditoría detecta la deriva.
- **El estado del trigger en el catálogo.** `pg_trigger.tgenabled` pasa de `A` a `D` mientras está desactivado. Una verificación periódica puede alertar de ese cambio, aunque no sirve a posteriori si ya se reactivó.
- **Huecos en la secuencia.** Si se borraran eventos, `id_evento` mostraría saltos. Aquí no hay hueco, porque el evento simplemente nunca se creó, lo que muestra el límite de esta técnica.

## 2. ¿Qué control administrativo (no técnico) reduciría este riesgo?

El control más eficaz es la **separación de la operación y la custodia de la evidencia**, respaldada por procedimientos formales:

- **Custodia independiente de las bitácoras.** Que las bitácoras se envíen a un sistema administrado por otra área (seguridad de la información o auditoría interna), de modo que el DBA no pueda alterarlas ni borrarlas.
- **Gestión de cambios.** Todo cambio de estructura, trigger o configuración de auditoría requiere una solicitud, una justificación y una aprobación previa registradas. Un `DISABLE TRIGGER` sin ticket asociado es, por definición, un hallazgo.
- **Uso restringido de la cuenta `postgres`.** Procedimiento que limite cuándo y para qué se usa, con cuentas nominales para cada administrador, de modo que cada acción tenga responsable identificable.
- **Política de consecuencias y capacitación.** Que el personal sepa que apagar o eludir la auditoría es una falta grave y que se vigila.
- **Revisiones y auditorías internas o externas** programadas, con muestreo de cambios sobre datos críticos.
