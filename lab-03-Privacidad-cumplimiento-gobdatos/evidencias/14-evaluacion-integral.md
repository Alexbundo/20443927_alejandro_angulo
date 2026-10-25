# Actividad 14 — Escenario integral

## Escenario

- La empresa tiene una base de datos con información de **50,000 clientes**.
- Todos los empleados de **Analítica** pueden consultar directamente la tabla `clientes`.
- La tabla contiene nombre, correo, teléfono, RFC, edad, ciudad y código postal.
- Analítica **únicamente genera estadísticas mensuales**.
- Los datos se conservan desde hace **12 años**.
- **No existe política documentada de retención**.
- Los **desarrolladores reciben copias completas** de la base para pruebas, y esas copias contienen **información real**.
- **Marketing** utiliza los correos electrónicos para campañas promocionales.
- **No existe documentación clara** sobre qué finalidad corresponde a cada dato.

## Problemas identificados

Los problemas 1 a 9 se desprenden directamente del escenario. Los marcados con `*` no se mencionan de forma explícita, pero son riesgos que habría que verificar.

| # | Problema | Principio afectado | Riesgo | Control propuesto |
| --- | --- | --- | --- | --- |
| 1 | Todos los empleados de Analítica consultan directamente la tabla `clientes` | Proporcionalidad (minimización) y mínimo privilegio | Acceso a registros individuales de 50,000 clientes cuando solo se necesitan estadísticas; mayor probabilidad de uso indebido, filtración o error | Revocar el acceso a la tabla base y dar solo una **vista agregada** (por ciudad y rango de edad, con mínimo de registros por grupo) mediante un rol de analítica |
| 2 | Analítica ve nombre, correo, teléfono y RFC sin necesitarlos | Proporcionalidad y finalidad | Exposición de datos identificables y fiscales sin relación con la tarea; el RFC facilita fraude y suplantación | Vista que excluya datos identificadores; generalizar la edad en rangos; no exponer `rfc`, `nombre`, `correo` ni `telefono` |
| 3 | Datos conservados desde hace 12 años | Proporcionalidad (dimensión temporal) y calidad | Se conservan datos de clientes que ya no tienen relación con la empresa; mayor superficie de ataque y mayor impacto si hay una brecha | Depuración por categoría: bloquear y suprimir lo que superó su plazo; anonimizar lo que solo se use para estadística; conservar el RFC solo durante el plazo fiscal (aprox. 5 años, a validar con legal) |
| 4 | No existe política documentada de retención | Responsabilidad | Sin plazos ni criterios, la empresa no puede justificar por qué conserva cada dato ni demostrar cumplimiento ante el titular o la autoridad | Elaborar una política de retención por dato y finalidad, aprobada por legal y privacidad, con acción al vencimiento (bloqueo, supresión o anonimización) y revisión periódica |
| 5 | Los desarrolladores reciben copias completas de la base | Proporcionalidad, finalidad y seguridad | Acceso de personal que no necesita datos reales; un entorno de desarrollo típicamente tiene menos controles que producción | Prohibir el acceso a datos reales; entregar solo datos sintéticos o enmascarados |
| 6 | Las copias de desarrollo contienen información real | Seguridad (confidencialidad) y finalidad | Fuga desde laptops, repositorios o servidores de pruebas; uso de datos de clientes para un fin distinto del que se recolectaron | **Enmascarar o anonimizar** nombre, correo, teléfono y RFC antes de copiar; generar datos de prueba; cifrar y registrar cualquier copia que sea indispensable |
| 7 | Marketing usa los correos para campañas promocionales | Finalidad, consentimiento e información | Tratamiento secundario posiblemente no informado ni consentido; sanciones, quejas y pérdida de confianza | Verificar el aviso de privacidad; registrar consentimiento u oposición por finalidad; enviar solo a quienes aceptaron, mediante una vista filtrada y con lista de exclusión |
| 8 | No hay documentación clara de la finalidad de cada dato | Finalidad y responsabilidad | No se puede decidir qué área necesita qué dato ni justificar los accesos; se tolera la recolección "por si acaso" | Inventario de datos y **matriz de gobierno** (dato, finalidad, responsable, usuarios, protección, retención, acción al finalizar) |
| 9 | Difícil atender derechos ARCO (datos sin plazos, replicados en copias de desarrollo y usados en marketing) | Derechos ARCO y responsabilidad | La cancelación u oposición no se propaga a todas las copias; incumplimiento de plazos de respuesta | Mapa de datos que incluya respaldos, réplicas, entornos de prueba y sistemas externos; procedimiento formal ARCO con responsables y plazos |
| 10* | No se indica cifrado ni protección reforzada del RFC | Seguridad | Un acceso indebido o una copia robada expone el dato en claro | Cifrado en reposo y en tránsito; enmascaramiento al mostrarlo; acceso restringido solo a Facturación |
