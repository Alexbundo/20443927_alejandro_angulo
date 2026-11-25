# POL-06 — Cambios en producción

**Objetivo:** Reducir el riesgo de cambios no autorizados o sin evidencia en el ambiente de producción.

**Alcance:** Cambios de estructura, privilegios, disparadores y configuración en el ambiente de producción de `comercial` (la base con datos reales de clientes, según la definición de ambiente de la Unidad I). Desarrollo y pruebas quedan fuera, pero no pueden usar datos reales sin enmascarar.

**Regla:**

- **Antes:** el cambio tiene un folio en `gobierno.solicitudes_cambio` con aprobación del Comité de cambios, ambiente y ventana definidos.
- **Durante:** se ejecuta con un usuario identificable dentro de la ventana, sin desactivar el trigger `trg_auditoria_clientes` ni los controles de auditoría.
- **Después:** el DBA actualiza el diccionario si cambia la estructura, y una persona distinta del DBA concilia cada mes los cambios de `dba.bitacora` contra los folios.

**Responsable:** Decide: Comité de cambios. Ejecuta: DBA. Concilia: Auditoría o Seguridad de la información.

**Excepciones:** Cambio de emergencia para restablecer el servicio, autorizado por el Comité de cambios (o su delegado) y regularizado con folio en un máximo de 1 día hábil.

**Evidencia:**

- `gobierno.solicitudes_cambio` y `dba.bitacora` (LAB-03, Actividad 7).
- Tabla de conciliación (LAB-03, Actividad 7).
- Declaración del hueco de evidencia cuando `log_statement` valía `none`.

**Revisión:** Cada 12 meses, y después de un cambio no autorizado.
