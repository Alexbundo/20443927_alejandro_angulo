# Informe: Protección de datos personales en la tabla clientes

---

## 19.1 Clasificación

### Qué datos requieren protección

Todos los campos de la tabla son **datos personales**, porque se refieren a una persona física identificada o identificable. Se clasifican así:

| Campo | Identifica directamente | Contribuye a identificar (cuasi-identificador) | Requiere protección | Justificación |
| --- | --- | --- | --- | --- |
| `id` | No (internamente sí) | Sí | Sí, moderada | Es un seudónimo técnico; permite vincular registros entre sistemas. |
| `nombre` | Sí | Sí | Sí | Es el identificador más evidente. |
| `correo` | Sí (generalmente) | Sí | Sí | Suele contener nombre y apellido; es único y permite contacto y cruce con otras fuentes. |
| `telefono` | Sí (generalmente) | Sí | Sí | Es único, permite contacto y localización aproximada. |
| `rfc` | Sí | Sí | Sí, alta | Contiene fecha de nacimiento y letras del nombre; facilita fraude y suplantación. |
| `edad` | No | Sí | Sí, moderada | Reduce el grupo de candidatos; es redundante con el RFC. |
| `ciudad` | No | Sí | Sí, baja a moderada | Ubica geográficamente. |
| `codigo_postal` | No | Sí (aporte alto) | Sí, moderada | Cuasi-identificador clásico: acota la ubicación a una zona pequeña. |
| `fecha_alta` | No | Sí (poco) | Sí, baja | Permite correlacionar con otras bases o eventos. |

### Por qué requieren protección

- **Identificadores directos** (`nombre`, `correo`, `telefono`, `rfc`): permiten señalar a una persona concreta sin información adicional.
- **Cuasi-identificadores** (`edad`, `ciudad`, `codigo_postal`, `fecha_alta`): ninguno identifica por sí solo, pero su **combinación** puede aislar a una persona. En la muestra de 5 registros, la combinación `codigo_postal` + `edad` es única para cada cliente.
- **Sensibilidad jurídica:** en esta tabla **no hay datos personales sensibles** en sentido legal (salud, origen étnico, creencias, preferencia sexual, etc.). Sin embargo, que un dato no sea sensible no significa que no requiera protección: el RFC, por ejemplo, implica un riesgo alto en la práctica.
- **Principio rector:** la protección depende del **riesgo** y del **contexto**, no solo de la categoría jurídica del dato.

---

## 19.2 Enmascaramiento

### Qué se ocultó

En la vista `v_clientes_soporte` se muestran solo cinco columnas: `id`, `nombre`, `correo`, `telefono` y `rfc`. De ellas, tres están enmascaradas parcialmente:

| Campo | Ejemplo original | Valor mostrado |
| --- | --- | --- |
| `correo` | `ana.lopez@example.test` | `an*****@example.test` |
| `telefono` | `6671234567` | `******4567` |
| `rfc` | `LOAA850315ABC` | `*********ABC` |

Además, **no se exponen** `edad`, `ciudad`, `codigo_postal` ni `fecha_alta`.

### Para quién

Para el rol `soporte`, que atiende a clientes y necesita identificarlos y verificar datos, pero no requiere los valores completos.

### Por qué

- **Mínimo privilegio y proporcionalidad:** soporte recibe solo lo necesario para su función.
- **Reducción del riesgo** de fraude, suplantación y fuga por parte de usuarios internos.
- **Verificación sin exposición:** mostrar el final del teléfono o el inicio del correo basta para confirmar la identidad de un cliente.

### Mecanismo utilizado

- Una **vista** (`CREATE VIEW`) que aplica funciones de texto (`LEFT`, `RIGHT`, `SUBSTRING`, `POSITION`, `CONCAT`) al consultar.
- Un **rol** sin inicio de sesión (`soporte NOLOGIN`) con `USAGE` sobre el esquema `public` y `SELECT` **solo** sobre la vista.
- `REVOKE ALL ON clientes FROM soporte` para dejar explícito que no hay acceso directo a la tabla base.

### Limitaciones del enmascaramiento

- **La tabla original conserva todos los datos sin enmascarar.** El enmascaramiento ocurre al consultar, no al almacenar.
- Mostrar los últimos 4 caracteres del RFC deja visible parte de la homoclave y, según el caso, del día y mes de nacimiento.
- El `nombre` completo combinado con los fragmentos de correo y teléfono sigue siendo un perfil muy identificable.
- `CONCAT` convierte `NULL` en cadena vacía, por lo que un teléfono o RFC nulo se mostraría como `******`.
- La vista funciona porque, por defecto, se ejecuta con los permisos de su propietario.

---

## 19.3 Seudonimización

### Cómo se generaron los tokens

Se creó la tabla `pii.mapa_cliente` y se insertó un **UUID aleatorio** por cliente con `gen_random_uuid()`, a partir de `clientes`. Como el token es aleatorio, **no se puede derivar** del dato original sin consultar el mapa. (`gen_random_uuid()` es nativa desde PostgreSQL 13; `pgcrypto` solo es necesaria en versiones anteriores.)

### Dónde se encuentra el mapa de correspondencia

En `pii.mapa_cliente`, con la estructura `token` (clave primaria) y `cliente_id` (único, con llave foránea a `public.clientes(id)`). Está en un **esquema separado** (`pii`) del de análisis.

La tabla `analitica.clientes` contiene solo `cliente_token`, `edad`, `ciudad`, `codigo_postal` y `fecha_alta`: sin nombre, correo, teléfono, RFC ni `id`.

### Quién debería poder acceder al mapa

Únicamente un **rol de custodia** (por ejemplo, `custodio_pii`) o el responsable de protección de datos, con:

- acceso restringido y justificado,
- registro de auditoría de cada consulta,
- idealmente, aprobación para cada reidentificación.

El rol `analista` **no** recibe ningún permiso sobre el esquema `pii`.

### Por qué se separaron los permisos

- Quien analiza los datos **no debe poder reidentificar** a las personas.
- Se aplica **separación de funciones**, **mínimo privilegio** y **defensa en profundidad**: comprometer la cuenta del analista no expone la llave.
- Si el analista tuviera acceso al mapa, podría hacer un `JOIN` entre `analitica.clientes` y `pii.mapa_cliente`, obtener el `cliente_id` y, con él, llegar a la identidad completa. La seudonimización quedaría anulada.

### Limitaciones de la seudonimización

- Los datos seudonimizados **siguen siendo datos personales**, porque existe una forma de revertir el proceso.
- `edad`, `codigo_postal`, `ciudad` y `fecha_alta` permiten reidentificar **sin usar el mapa**.
- `analitica.clientes` es una copia puntual (`CREATE TABLE ... AS`) y no se actualiza sola; además, `cliente_token` no tiene clave primaria definida.

---

## 19.4 Anonimización

### Qué identificadores fueron eliminados

En las consultas agregadas (conteos por grupo) ya no aparecen `id`, `nombre`, `correo`, `telefono` ni `rfc`. El resultado solo muestra categorías y totales.

> Esto aplica **al resultado**. La tabla `clientes` no cambió y conserva todos los identificadores.

### Qué atributos fueron generalizados

| Atributo original | Generalización aplicada |
| --- | --- |
| `edad` | Rangos: `18-30`, `31-45`, `46+` |
| `codigo_postal` | Solo los 2 primeros dígitos (`region`) |
| `ciudad` y `fecha_alta` | No se incluyen en el resultado (supresión del atributo) |

### Resultados con los datos de ejemplo

| Consulta | Resultado |
| --- | --- |
| Solo rango de edad | `31-45`: 4, `46+`: 1 |
| Solo región | `80`: 3, `81`: 1, `82`: 1 |
| Rango de edad + región | `31-45 / 80`: 3, `31-45 / 81`: 1, `46+ / 82`: 1 |
| Rango de edad + región, con `HAVING COUNT(*) >= 5` | 0 filas |

### Qué grupos fueron suprimidos

La cláusula `HAVING COUNT(*) >= 5` aplica un umbral de **k ≥ 5** y suprime todo grupo con menos de 5 registros. Con solo 5 clientes, **todos los grupos son suprimidos** y la consulta no devuelve filas. El resultado es seguro pero inútil para el análisis: el problema es el volumen de datos, no la técnica.

### Qué riesgo de reidentificación permanece

- **Sin umbral (consulta combinada):** hay grupos de tamaño 1. `46+ / 82` corresponde a una sola persona y `31-45 / 81` también. Quien conozca a un cliente de ese perfil lo identifica de inmediato.
- **Ataque por diferencia:** comparar la consulta de edad con la de región permite inferir atributos de personas únicas.
- **Datos originales intactos:** quien tenga acceso a `clientes` puede revertir cualquier agregación.
- **Población muy pequeña:** con 5 registros no existe anonimato real; nadie "se pierde entre la multitud".
- **Conclusión:** no es correcto afirmar que el conjunto sea "100 % anónimo". Lo defendible sería hablar de un **riesgo reducido bajo ciertos supuestos** (k ≥ 5 y generalización aplicada).

### Mejoras recomendadas

- Generalizar más (rangos más amplios, primer dígito del código postal o estado, año en lugar de fecha).
- Aplicar supresión complementaria si se publican totales junto con los grupos.
- Considerar l-diversidad, t-cercanía o privacidad diferencial.
- Corregir el `CASE`: `ELSE '46+'` también captura edades menores de 18 y valores `NULL`.

---

## 19.5 Retención

### Qué criterio se utilizó

Se propuso eliminar los registros con `fecha_alta` anterior a la fecha actual menos 5 años:

```sql
SELECT *
FROM clientes
WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';
```

Con fecha de hoy (17 de octubre de 2026), el corte es el **17 de octubre de 2021**. Con los datos de ejemplo **no se afecta ningún registro**, porque todos tomaron `DEFAULT CURRENT_DATE` al insertarse.

**Justificación del periodo:**

- Principios de **finalidad y proporcionalidad** de la LFPDPPP: los datos se conservan solo mientras sean necesarios para la finalidad informada en el aviso de privacidad.
- **Obligaciones legales de conservación** (por ejemplo, la normativa fiscal suele exigir conservar comprobantes y contabilidad por 5 años); los plazos deben verificarse con el área legal.
- **Plazos de prescripción** de posibles reclamaciones y necesidades del negocio (garantías, soporte).

**Limitación del criterio:** `fecha_alta` es la fecha de alta, no de la última actividad. Un cliente dado de alta hace 6 años que compró la semana pasada seguiría activo. El criterio más adecuado sería la **última actividad o la terminación de la relación**.

### Qué información debería conservarse

- Datos sujetos a **obligaciones legales vigentes** (fiscales, mercantiles, de prevención de lavado de dinero, etc.).
- Datos de clientes con **relación activa**.
- Datos sujetos a **retención legal** por litigios, auditorías o requerimientos de autoridad.
- **Evidencia de la depuración** (no los datos personales eliminados): política vigente, aprobaciones, conteos y registros de auditoría.
- Datos agregados que ya no permiten identificar a nadie, si se demostró que la anonimización es efectiva.

### Qué información podría eliminarse

- Registros de clientes cuya relación terminó y cuyo plazo legal y de negocio ya venció.
- Todo lo que dependa de esos registros:

| Ubicación | Acción |
| --- | --- |
| `analitica.clientes` | Eliminar por `cliente_token` |
| `pii.mapa_cliente` | Eliminar (la llave foránea bloquea el `DELETE` en `clientes` si se hace antes) |
| `public.clientes` | Eliminar al final |
| Respaldos, réplicas, logs y exportaciones | Depurar según su propio plan, con fecha de caducidad |

Orden correcto: `analitica.clientes` → `pii.mapa_cliente` → `clientes` (o definir `ON DELETE CASCADE`). En México la cancelación implica un **periodo de bloqueo** antes de la supresión definitiva.

### Qué controles deberían existir antes de eliminarla

1. **Aprobación escrita** del dueño de los datos, del área legal, del responsable de protección de datos y del responsable técnico, con separación de funciones (quien propone no es el único que aprueba ni ejecuta).
2. **Verificación de retención legal** (litigios, auditorías, requerimientos).
3. **Respaldo completo, cifrado y verificado**, con prueba de restauración en un entorno aparte y fecha de caducidad propia.
4. **Copia de los registros a eliminar** en un esquema restringido, para recuperación ante error.
5. **Ejecución dentro de una transacción** (`BEGIN`), verificando conteos antes de `COMMIT`.
6. **Evidencia:** política aplicada, consulta, conteo previo y posterior, hash del respaldo, quién ejecutó y cuándo, registros de auditoría y reporte de cierre firmado. Se usan `COUNT(*)` e identificadores técnicos, no `SELECT *`.
7. **Procedimiento de recuperación ante eliminación accidental:** detener procesos, evaluar el alcance con los logs, restaurar desde la tabla de archivo, un respaldo o PITR (con WAL), respetar el orden de dependencias conservando el mismo `token`, validar integridad y documentar el incidente. No se restauran registros que sí debían eliminarse.

---

## 19.6 Conclusiones

### ¿Qué técnica utilizaría para un área de soporte?

**Enmascaramiento mediante una vista con rol restringido.** Soporte necesita identificar y atender al cliente, no ver todos sus datos. La vista muestra solo fragmentos útiles para verificar identidad, y el rol no tiene acceso a la tabla base. Convendría revisar si realmente necesita el `nombre` completo y reforzar con auditoría de accesos.

### ¿Qué técnica utilizaría para un área de analítica?

**Seudonimización con separación de esquemas y permisos.** El analista trabaja con `analitica.clientes` (token y atributos), puede seguir a un mismo cliente a lo largo del tiempo, pero no tiene acceso al mapa ni a la tabla original. Como los cuasi-identificadores siguen presentes, conviene **generalizarlos** (rangos de edad, código postal truncado, año de alta) para reducir el riesgo.

### ¿Qué técnica utilizaría para publicar estadísticas?

**Anonimización con agregación, generalización y supresión de grupos pequeños** (k-anonimato con un umbral como k ≥ 5, y supresión complementaria cuando se publiquen totales). Para mayor protección, considerar privacidad diferencial. Solo debe publicarse si el volumen de datos lo permite: con 5 registros, todo se suprime.

### ¿Por qué ninguna de estas técnicas sustituye al control de acceso?

- Los datos originales **siguen existiendo** en la tabla base, y quien acceda a ella ve todo.
- El enmascaramiento solo funciona si el usuario **no puede saltarse la vista** consultando la tabla.
- La seudonimización solo es efectiva si **nadie no autorizado** accede al mapa.
- La anonimización es difícil de garantizar y puede ser vulnerada por cruce con información externa.
- Las técnicas reducen el riesgo de **lo que se muestra**; el control de acceso determina **quién puede llegar a los datos**. Son capas complementarias (defensa en profundidad), y la seguridad no debe depender de un único control.

---

## 20. Preguntas de reflexión

### 1. ¿Cuál es la diferencia entre enmascaramiento y seudonimización?

El **enmascaramiento** oculta u ofusca parte del valor para su visualización (por ejemplo `******4567`); el dato sigue siendo reconocible en parte y el original permanece en la tabla. La **seudonimización** sustituye el identificador por un token y guarda la correspondencia en un lugar separado; el dato se desliga de la persona salvo que se use el mapa. El primero protege la **visualización**, la segunda la **vinculación** con la identidad.

### 2. ¿Por qué la seudonimización no significa anonimización?

Porque existe una forma de revertirla (el mapa `token` ↔ `cliente_id`), de modo que la persona sigue siendo identificable con información adicional. Además, los cuasi-identificadores que permanecen pueden reidentificar sin usar el mapa. Los datos seudonimizados siguen siendo datos personales; solo la anonimización irreversible los saca del ámbito de la protección de datos.

### 3. ¿Por qué eliminar `nombre` y `RFC` no garantiza que un conjunto de datos sea anónimo?

Porque quedan **correo, teléfono, id** (que también identifican) y los **cuasi-identificadores** (`edad`, `ciudad`, `codigo_postal`, `fecha_alta`). Su combinación puede aislar a una persona, sobre todo en muestras pequeñas: en este ejemplo cada combinación de `codigo_postal` y `edad` es única. Además, la tabla original sigue existiendo y permite revertir el proceso.

### 4. ¿Qué función tienen los cuasi-identificadores?

Son atributos que no identifican a una persona por sí solos, pero que **combinados entre sí o con fuentes externas** permiten reducir el grupo de candidatos hasta singularizarla. Son la base de los ataques de reidentificación y de las técnicas como el k-anonimato, que buscan controlar cuántas personas comparten la misma combinación.

### 5. ¿Por qué es importante separar el mapa de seudonimización?

Porque el mapa es la **llave** que revierte el proceso. Si está junto a los datos analíticos o accesible para quien los analiza, la seudonimización pierde todo valor. Separarlo en otro esquema, con permisos propios, rol de custodia y auditoría, evita que un solo acceso comprometido permita reidentificar a todos los clientes.

### 6. ¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?

Principalmente **mínimo privilegio** (solo recibe lo necesario para su función) y **separación de funciones** (quien analiza no es quien puede reidentificar). También **defensa en profundidad**, **minimización de datos** y **protección de datos desde el diseño**.

### 7. ¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?

Porque la vista **limita columnas y transforma valores** antes de entregarlos, y el usuario no necesita ningún permiso sobre la tabla base. Permite aplicar mínimo privilegio, centralizar la regla de enmascaramiento en la base de datos (no en la aplicación) y cambiarla sin modificar los permisos. Con acceso directo, el enmascaramiento sería decorativo: el usuario podría consultar los datos completos.

### 8. ¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra acceso no autorizado?

Proteger para **visualización** controla **cómo se ve** el dato (máscaras, generalización), pero el valor original puede seguir existiendo y ser accesible por otras vías. Proteger contra **acceso no autorizado** controla **quién puede llegar** al dato (permisos, roles, cifrado, autenticación, auditoría). Lo primero reduce la exposición accidental o innecesaria; lo segundo impide que el dato sea obtenido por quien no debe. Se necesitan ambos.

### 9. ¿Por qué la retención forma parte de la protección de datos?

Porque los principios de **finalidad, proporcionalidad y calidad** de la LFPDPPP exigen conservar los datos solo mientras sean necesarios. Un dato que ya no existe no puede filtrarse, usarse indebidamente ni ser objeto de un acceso no autorizado. Una política de retención con aprobaciones, respaldos, evidencia y recuperación ordenada reduce la superficie de riesgo y demuestra responsabilidad ante auditorías.

### 10. ¿Qué riesgo existe si una organización conserva información indefinidamente?

- **Mayor impacto de una brecha:** más datos, más antiguos y de más personas expuestos.
- **Incumplimiento legal:** se trata información sin finalidad vigente, contra los principios de proporcionalidad y finalidad.
- **Datos desactualizados o inexactos**, que pueden causar decisiones erróneas.
- **Mayor costo y complejidad** de almacenamiento, respaldo y control de acceso.
- **Más responsabilidad** ante derechos de cancelación, sanciones y daño reputacional.
- **Uso para fines distintos** a los informados originalmente.
