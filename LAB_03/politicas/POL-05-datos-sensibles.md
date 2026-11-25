# POL-05 — Uso de datos sensibles

**Objetivo:** Reducir el riesgo de acceso, uso o exposición indebidos de datos personales y secretos.

**Alcance:** Columnas clasificadas como dato personal en el diccionario (`nombre`, `correo`, `rfc`, `telefono`, `ciudad`), la tabla `auditoria.cambios_clientes`, las bitácoras y `system.profile`.

**Regla:** Solo accede a datos sensibles quien tenga una finalidad documentada en el diccionario y aprobación del propietario; el soporte usa la vista enmascarada y no la tabla `clientes`. Todo acceso o modificación queda en la bitácora con usuario identificable (no cuentas compartidas), y las contraseñas y otros secretos no se escriben en sentencias SQL; cualquier extracción de bitácora se revisa y se redacta antes de compartirse.

**Responsable:** Decide: propietario del dato. Ejecuta: DBA. Supervisa: Seguridad de la información.

**Excepciones:** Acceso directo a datos sin enmascarar por incidente o requerimiento legal, autorizado por Seguridad de la información y Jurídico, con folio y fecha de fin.

**Evidencia:**

- Diccionario de datos con clasificación (`COMMENT` y `diccionario-clientes.csv`, LAB-03, Actividad 3).
- `auditoria.cambios_clientes` y `dba.bitacora` (LAB-01).
- Vista enmascarada de la Unidad II.
- Hallazgo de la contraseña de `rol_temporal` visible en la bitácora (LAB-01); hoy no existe un control que la evite.

**Revisión:** Cada 6 meses, y después de cualquier exposición de datos.
