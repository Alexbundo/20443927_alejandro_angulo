# POL-03 — Retención

**Objetivo:** Reducir el riesgo de conservar datos personales más tiempo del necesario y de perder evidencia antes de lo necesario.

**Alcance:** Datos de `clientes` (PostgreSQL y MongoDB), `auditoria.cambios_clientes`, bitácoras de PostgreSQL y `mongod`, `system.profile` y respaldos.

**Regla:** Se conservan: bitácoras de accesos y de modificaciones de datos, 12 meses; bitácora de cambios de privilegios y estructura, `gobierno.solicitudes_cambio` e instantáneas de privilegios, 3 años; `system.profile`, solo mientras dure el diagnóstico. Al vencer el plazo se eliminan de forma segura y se registra la baja; en `auditoria.cambios_clientes` se anonimizan los datos personales y se conserva el hecho del cambio (usuario, fecha, tabla y campo). Los plazos de datos personales y de auditoría están sujetos a confirmación del área jurídica (obligaciones de protección de datos personales y de conservación de registros).

**Responsable:** Decide: Gerencia Comercial (datos) y Seguridad de la información (bitácoras), con validación jurídica. Ejecuta: DBA.

**Excepciones:** Conservar un registro más allá del plazo por una investigación, auditoría o requerimiento legal en curso (retención legal), autorizada por Jurídico y registrada con folio.

**Evidencia:**

- Catálogo de datos (LAB-03, Actividad 4), columna Conservación.
- Criterio de conservación de bitácoras (LAB-03, Actividad 5).
- Registro de bajas ejecutadas: hoy no existe.

**Revisión:** Cada 12 meses, y cuando cambie la normativa aplicable.
