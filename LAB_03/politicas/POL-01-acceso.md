# Políticas de gobierno de datos — Comercializadora Norte

## POL-01 — Acceso

**Objetivo:** Reducir el riesgo de accesos indebidos o excesivos a los datos de `comercial`.

**Alcance:** Roles y usuarios de PostgreSQL y MongoDB (`comercial`), incluidas las bitácoras y la vista `dba.bitacora`. Aplica a producción, pruebas y desarrollo.

**Regla:** Todo acceso o cambio de privilegios requiere una solicitud escrita del jefe del solicitante, aprobada por el propietario del dato. El DBA revisa cada mes las sentencias GRANT y REVOKE de la bitácora y las concilia con las solicitudes aprobadas; cada trimestre se revisan los privilegios vigentes y se revocan los no justificados.

**Responsable:** Decide: propietario del dato. Ejecuta: DBA. Revisa: Seguridad de la información.

**Excepciones:** Acceso de emergencia por un máximo de 24 horas, autorizado por Seguridad de la información; se regulariza con solicitud en un máximo de 2 días hábiles y el acceso se revoca al terminar.

**Evidencia:**

- Líneas `statement: GRANT/REVOKE` de `dba.bitacora`.
- Registro de solicitudes aprobadas: hoy `gobierno.solicitudes_cambio`  cubre cambios en producción. No existe aún un registro específico de solicitudes de acceso.
- Acta de la revisión trimestral: hoy no existe.
