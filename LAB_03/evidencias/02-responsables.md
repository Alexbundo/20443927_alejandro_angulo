# Actividad 2 — Propietarios, custodios y usuarios

| Conjunto de datos | Propietario | Custodio | Usuarios autorizados | Quién aprueba accesos | Quién aprueba correcciones |
| --- | --- | --- | --- | --- | --- |
| comercial.public.clientes (PostgreSQL) | Área de ventas / atención a clientes | DBA | Aplicación comercial (lectura y escritura); ventas y analistas (según su rol) | Propietario del dato | Propietario del dato |
| auditoria.cambios_clientes (PostgreSQL) | Auditoría / Seguridad de la información | DBA | Auditores y seguridad (solo lectura); el trigger es el único que escribe | Propietario (Auditoría / Seguridad) | Nadie la corrige: es evidencia. Cualquier excepción la autoriza Auditoría y queda registrada |
| Bitácora de PostgreSQL | Seguridad de la información / TI | DBA (administrador del servidor) | DBA, seguridad y auditores (solo lectura) | Seguridad de la información | No se corrige; solo se archiva o rota según política |
| comercial.clientes (MongoDB) | Área de ventas / atención a clientes | DBA (administrador de MongoDB) | Aplicación comercial; analistas (según su rol) | Propietario del dato | Propietario del dato |
| comercial.system.profile (MongoDB) | TI / Seguridad de la información | DBA | DBA y seguridad; desarrollo solo con autorización para optimizar consultas | Seguridad de la información | No aplica: es un registro técnico |

## Preguntas

### 1. ¿Por qué el propietario de auditoria.cambios_clientes no debería ser el mismo que opera clientes?

Por separación de funciones: quien modifica los datos no debe controlar la evidencia de sus propios cambios, porque podría alterarla u ocultarla. Un propietario independiente mantiene la auditoría confiable.

### 2. ¿Quién debería poder leer las bitácoras y la vista dba.bitacora? Relaciónalo con lo observado en el LAB-01

Solo el DBA, seguridad y auditores, con permisos explícitos. En el LAB-01 se vio que la bitácora puede registrar secretos (por ejemplo contraseñas o datos personales dentro de las sentencias). Quien lee la bitácora puede ver esos secretos, así que su acceso se trata como el de un dato sensible, con aprobación de seguridad.

### 3. ¿Qué ocurre con la responsabilidad sobre un dato cuando nadie la tiene asignada? Relaciónalo con el problema inicial de la unidad

Nadie corrige los errores, nadie aprueba ni revoca accesos y nadie responde ante un incidente. Es el problema inicial de la unidad: los datos con errores, duplicados o expuestos persisten porque "todos los usan y nadie es responsable". Asignar propietario y custodio hace que cada problema tenga a quién decidir y a quién exigir
