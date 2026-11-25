# Actividad 5 — Criterio de conservación de bitácoras

## Tabla de conservación

| Registro | Ubicación actual | Riesgo de pérdida observado | Sensibilidad | Periodo propuesto | Justificación | Dónde se conserva | Quién puede leerlo | Acción al vencer |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Accesos de PostgreSQL | Archivo del colector (`pg_current_logfile()`) | Rotación del archivo; reinstalación o recreación del servidor | Media (usuarios, IP, horarios) | 1 año (propuesta interna; plazo a confirmar con el área jurídica si hay obligación normativa) | Permite investigar accesos indebidos y reconstruir incidentes | Copia exportada a almacenamiento externo de solo lectura, fuera del servidor | Seguridad, DBA y auditores | Eliminación segura, con registro de la baja |
| Cambios de privilegios y estructura | Archivo del colector | Rotación; el hueco de `log_statement = none` | Alta | 3 a 5 años (plazo a confirmar con el área jurídica y la política de auditoría) | Es la evidencia de que los cambios estaban autorizados (POL-06); se concilia contra solicitudes de cambio | Almacenamiento externo de solo lectura, con control de integridad | Seguridad y auditoría; DBA solo con autorización | Revisión por auditoría antes de eliminar; eliminación segura |
| Modificaciones de datos (`log_statement = 'mod'`) | Archivo del colector | Rotación; volumen alto; las sentencias pueden contener datos personales y secretos | Alta (puede incluir datos personales) | 6 meses a 1 año | Sirve para investigar quién modificó qué; su valor baja con el tiempo y el riesgo de datos personales crece | Almacenamiento externo restringido | Seguridad y auditoría | Eliminación segura o anonimización |
| `auditoria.cambios_clientes` | Tabla en `comercial` | Se pierde con la base si se recrea; la puede alterar quien desactive el trigger | Contiene datos personales | A confirmar con el área jurídica (obligaciones de auditoría y de protección de datos personales) | Es la evidencia principal de cambios sobre clientes, pero copia datos personales | Respaldo protegido y copia de solo lectura; acceso restringido | Auditoría y seguridad; el DBA no la modifica | Eliminar o anonimizar los datos personales; conservar el hecho del cambio (quién, cuándo, qué campo) |
| Bitácora de `mongod` | `systemLog.path` o salida estándar; `getLog` solo en memoria | `getLog` se pierde al reiniciar; la salida estándar se pierde si no se recoge | Media | 1 año (propuesta interna) | Eventos del servidor, conexiones y errores para diagnóstico y seguridad | Archivo exportado a almacenamiento externo | Seguridad y DBA | Eliminación segura |
| `system.profile` | Colección limitada (capped) de 1 MB | Se sobrescribe sola | Alta (puede contener filtros con datos personales) | Corto: días o semanas, solo mientras dure el diagnóstico | Uso técnico de rendimiento; no es evidencia de auditoría | Exportar solo si se necesita para un análisis; si no, no se conserva | DBA y seguridad | Desactivar el perfilado y vaciar la colección |
| Instantáneas de privilegios (MongoDB) | `auditoria.instantaneas_privilegios` | Se pierden si se recrea la base; solo reflejan el momento de la captura | Alta | 3 a 5 años, igual que los cambios de privilegios (a confirmar con el área jurídica) | Permiten demostrar quién tenía qué permisos en una fecha | Colección protegida más copia externa de solo lectura | Seguridad y auditoría | Revisión por auditoría; eliminación segura |

## Preguntas

### 1. ¿Por qué la bitácora de cambios de privilegios merece más tiempo de conservación que la de consultas rutinarias?

Porque es evidencia de control: demuestra quién autorizó o ejecutó cambios de acceso y estructura, y sirve para investigar incidentes o auditorías que se detectan meses después. Las consultas rutinarias tienen poco valor pasado el diagnóstico y pueden contener datos personales, así que conservarlas mucho aumenta el riesgo.

### 2. ¿Qué control de integridad aplicarás a las bitácoras exportadas?

Calcular un hash SHA-256 de cada archivo al exportarlo, guardar la lista de hashes en un lugar separado, almacenar las copias en medio de solo lectura (WORM) y verificar los hashes de forma periódica. Así se detecta cualquier alteración.

### 3. ¿Qué diferencia hay entre conservar una bitácora y respaldar una base de datos?

El respaldo sirve para restaurar el servicio y se rota o sobrescribe con frecuencia. La conservación de bitácoras sirve para demostrar qué pasó y debe mantener los registros inalterables durante el plazo definido. Un respaldo puede restaurar los datos, pero no prueba quién hizo qué ni cuándo.

## Conflicto con la eliminación de datos personales (LAB-01, Actividad 13)

Conservar la auditoría puede chocar con la política de retención, que exige eliminar los datos personales. La propuesta es separar ambas cosas: al vencer el periodo de los datos personales, se anonimizan o eliminan los valores personales de la auditoría, y se conserva el hecho del cambio (usuario, fecha, tabla y campo). El plazo exacto y la base legal se confirman con el área jurídica.
