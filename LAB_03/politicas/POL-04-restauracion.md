# POL-04 — Restauración

**Objetivo:** Reducir el riesgo de restaurar datos de forma indebida, incompleta o que reintroduzca información eliminada.

**Alcance:** Restauración de `comercial` (PostgreSQL y MongoDB) y de bitácoras, en cualquier ambiente.

**Regla:** Toda restauración en producción requiere un folio aprobado por el propietario del dato y por el Comité de cambios, y la ejecuta el DBA dentro de la ventana autorizada. Antes de restaurar se respalda el estado actual, y después se reaplican las eliminaciones de datos personales posteriores a la fecha de la copia y se verifica la integridad de los datos con el propietario. Las restauraciones de prueba se hacen en un ambiente aislado y no usan datos de producción sin enmascarar.

**Responsable:** Decide: propietario del dato y Comité de cambios. Ejecuta: DBA. Verifica: persona distinta del DBA.

**Excepciones:** Restauración urgente por pérdida de datos en producción, autorizada verbalmente por el propietario y Seguridad de la información; el folio se regulariza en un máximo de 1 día hábil.

**Evidencia:** Folio en `gobierno.solicitudes_cambio` (LAB-03, Actividad 7) y líneas de la bitácora (`dba.bitacora`) con la actividad de la restauración. Hoy no existe un registro específico de restauraciones. El procedimiento técnico se definirá en la Unidad V.

**Revisión:** Cada 12 meses, y después de cada restauración real.
