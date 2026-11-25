# Actividad 4 — Catálogo mínimo de datos

## Catálogo

| ID | Conjunto de datos | Motor | Ubicación | Propietario | Custodio | Clasificación | Contiene datos personales | Finalidad | Conservación | Diccionario |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CAT-01 | Clientes | PostgreSQL 16 | u3-postgres / comercial / public.clientes | Gerencia Comercial | DBA | Confidencial | Sí | Operación comercial, facturación y contacto con el cliente | Mientras dure la relación comercial y el plazo legal posterior | diccionario-clientes.csv |
| CAT-02 | Auditoría de clientes | PostgreSQL 16 | u3-postgres / comercial / auditoria.cambios_clientes | Auditoría / Seguridad de la información | DBA | Confidencial | Sí (copia valores antiguos y nuevos de clientes) | Evidencia de cambios sobre clientes | Según política de auditoría (por ejemplo, 5 años) | Pendiente |
| CAT-03 | Registro de cambios | PostgreSQL 16 | u3-postgres / comercial / gobierno.solicitudes_cambio | Comité de cambios | DBA | Interna | No (contiene nombres de solicitantes y aprobadores) | Evidencia de autorización de cambios (POL-06) | Según política de auditoría (por ejemplo, 5 años) | Pendiente |
| CAT-04 | Clientes (tienda) | MongoDB 7 | u3-mongo / comercial / clientes | Gerencia Comercial (por confirmar) | DBA | Confidencial | Sí | Operación de la tienda y contacto con el cliente | Mientras dure la relación comercial y el plazo legal posterior | Pendiente |
| CAT-05 | Perfilado | MongoDB 7 | u3-mongo / comercial / system.profile | TI / Seguridad de la información | DBA | Confidencial | Sí (puede guardar filtros y valores de consultas) | Diagnóstico de rendimiento | Corto: se rota o se borra tras el diagnóstico | No aplica (registro técnico) |

## Preguntas

### 1. ¿Por qué CAT-02 y CAT-05 contienen datos personales aunque su propósito sea la auditoría?

Porque copian o registran datos de otros conjuntos: la auditoría guarda los valores de `clientes` que cambiaron, y el perfilado guarda las consultas con sus filtros (nombres, correos, RFC). Los datos personales se clasifican por su contenido, no por el propósito del conjunto donde están.

### 2. ¿Qué pasa si CAT-01 y CAT-04 tienen propietarios distintos y el RFC de un cliente difiere entre ambos motores?

Nadie puede decidir cuál valor es el correcto: cada propietario defiende el suyo, la corrección se retrasa y se facturan datos inconsistentes. Hace falta un propietario único del dato maestro (o un acuerdo entre propietarios) que defina la fuente de verdad y apruebe las correcciones.

### 3. ¿Qué información del catálogo cambia con más frecuencia y quién debe actualizarla?

Las filas estimadas y el tamaño, que cambian a diario, y los propietarios, custodios y diccionarios, cuando hay reorganizaciones o nuevos conjuntos. El DBA actualiza los datos técnicos. Los propietarios, la clasificación, la finalidad y la conservación los actualiza el propietario del dato, y el comité de gobierno los aprueba.
