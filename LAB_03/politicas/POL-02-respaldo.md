# POL-02 — Respaldo

**Objetivo:** Reducir el riesgo de pérdida de datos por falla, error humano o recreación del servidor.

**Alcance:** La base `comercial` en PostgreSQL y MongoDB, y la configuración de los servidores. Incluye el volumen `dba-u3_pg_data`. Aplica a producción; en pruebas y desarrollo solo si contienen datos reales.

**Regla:** Se respalda a diario `comercial` en ambos motores y las bitácoras definidas en POL-03, y las copias se guardan fuera del servidor y del volumen que respaldan. Cada mes una persona distinta del DBA que ejecuta el respaldo verifica que una copia se puede restaurar en un ambiente aislado. El respaldo se conserva por el plazo de POL-03.

**Responsable:** Decide frecuencia y plazo: propietario del dato, con Seguridad de la información. Ejecuta: DBA. Verifica: Auditoría o Seguridad de la información.

**Excepciones:** Omitir un respaldo programado por mantenimiento, con folio aprobado por el Comité de cambios y respaldo manual previo.

**Evidencia:** Hoy no existe un registro de respaldos ni de pruebas de restauración en los LAB-01 a LAB-03. Se creará un registro con fecha, alcance, resultado de la verificación y responsable. El procedimiento técnico se definirá en la Unidad V.

**Revisión:** Cada 6 meses, y cuando cambie el motor, el volumen de datos o el sitio de almacenamiento.
