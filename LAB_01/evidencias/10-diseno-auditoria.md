# Diseño de auditoría

## Tabla de campos

| Campo propuesto | Tipo | ¿Qué pregunta responde? | ¿Puede ser nulo? ¿Por qué? |
| --- | --- | --- | --- |
| `id_evento` | `BIGSERIAL` | Ninguna directamente; da soporte a todas. Identifica de forma única cada evento y permite detectar huecos en la secuencia (evidencia de borrado) y ordenar eventos que ocurren en el mismo instante. | **No.** Es la llave primaria y la genera la base de datos. Un evento sin identificador no se puede citar como evidencia. |
| `momento` | `TIMESTAMPTZ` | **2. ¿Cuándo?** Fecha y hora exactas del cambio, con zona horaria, lo que evita la ambigüedad al correlacionar con el log del servidor, el firewall o la aplicación. | **No.** Un evento sin hora no se puede ubicar en la cronología. Se llena con `DEFAULT now()` para que no dependa del cliente. |
| `usuario_sesion` | `TEXT` | **1. ¿Quién hizo el cambio?** Es el rol con el que se abrió la conexión (`session_user`), la identidad autenticada, por ejemplo `app_ventas`. | **No.** Toda sesión autenticada tiene un rol. Se llena con `DEFAULT session_user`, que el cliente no puede falsificar. |
| `usuario_efectivo` | `TEXT` | **1. ¿Quién hizo el cambio?** Es el rol bajo cuyos privilegios se ejecutó la operación (`current_user`). Difiere de `usuario_sesion` cuando hay `SET ROLE` o funciones `SECURITY DEFINER`, y revela si alguien actuó con privilegios prestados. | **No.** Siempre existe un rol efectivo (normalmente igual al de sesión). Si ambos difieren, esa diferencia es en sí una señal que investigar. |
| `aplicacion` | `TEXT` | **3. ¿Desde qué aplicación o equipo?** Registra el `application_name` declarado por el cliente (por ejemplo `app-ventas-web`). | **Sí.** El cliente puede no declararlo y entonces llega vacío. Además lo declara el propio cliente, así que sirve para orientar, no como prueba. |
| `ip_cliente` | `INET` | **3. ¿Desde qué aplicación o equipo?** Dirección de origen de la conexión (`inet_client_addr()`). Es más confiable que `application_name`, porque la fija la red y no el cliente. | **Sí.** En conexiones por socket local no hay IP y el valor es `NULL`. Ese `NULL` es información útil: indica acceso desde el propio servidor. |
| `operacion` | `TEXT` | **1 y 5.** Indica qué ocurrió (`UPDATE` o `DELETE`) y por tanto cómo interpretar `valores_antes` y `valores_despues`. Conviene limitarlo con `CHECK (operacion IN ('INSERT','UPDATE','DELETE'))`. | **No.** Un registro sin tipo de operación es ininterpretable. |
| `id_cliente` | `BIGINT` | **5. ¿Qué valor tenía antes?** Permite localizar la historia de un cliente concreto (por ejemplo `id = 3`, María García) y reconstruir sus cambios en orden. | **No** para operaciones sobre filas. Solo sería nulo en operaciones sin fila (como `TRUNCATE`), que requieren un tratamiento aparte. |
| `valores_antes` | `JSONB` | **5. ¿Qué valor tenía antes?** Es el campo central: la fila completa antes del cambio (`to_jsonb(OLD)`). Permite restaurar el RFC original y ver qué más cambió. | **Sí.** En un `INSERT` no existe estado anterior. En `UPDATE` y `DELETE` nunca debe ser nulo. |
| `valores_despues` | `JSONB` | **5. ¿Qué valor tenía antes?** (por contraste) y **1** en conjunto. La fila tras el cambio (`to_jsonb(NEW)`); comparada con `valores_antes` muestra exactamente qué campos cambiaron. | **Sí.** En un `DELETE` no existe estado posterior. En `INSERT` y `UPDATE` nunca debe ser nulo. |

## Actividad 10 – Esquema y tabla de auditoría

## 1. ¿Por qué `momento` usa `TIMESTAMPTZ` y no `TIMESTAMP`?

Porque `TIMESTAMPTZ` representa un instante absoluto, y `TIMESTAMP` solo una fecha y hora "de reloj" sin zona. Internamente, `TIMESTAMPTZ` se almacena normalizado a UTC y se muestra convirtiéndolo a la zona horaria de la sesión. Un `TIMESTAMP` guarda los números tal cual, sin decir a qué zona pertenecen.

## 2. ¿Por qué se guarda el registro completo en `JSONB` y no solo la columna que cambió?

- **Contexto completo.** El incidente reportó el RFC, pero un `UPDATE` puede modificar varias columnas a la vez, o la persona que investigue puede necesitar ver otras (nombre, teléfono). Guardar la fila completa permite ver todo el estado antes y después, no solo lo que se sospechaba.
- **Resistencia a cambios de estructura.** Si `clientes` gana o pierde columnas (como cuando se agregó `segmento` o `telefono`), una tabla de auditoría con columnas fijas dejaría de coincidir y habría que migrarla. El JSON conserva cada fila tal como era, con las columnas que tenía en ese momento.
- **Detección de qué cambió.** Comparando `valores_antes` con `valores_despues` se identifica exactamente qué campos difieren, sin tener que anticipar esos campos.

## 3. La tabla de auditoría también contendrá RFC. ¿Qué implica eso para su clasificación y su control de acceso?

Implica que la tabla de auditoría es **tan sensible como `clientes`**, y en cierto sentido más: contiene los valores actuales y los **históricos**, incluidos los que ya fueron corregidos o borrados. Aunque se elimine un cliente, su RFC sigue existiendo en la auditoría.

Debe clasificarse con el mismo nivel que los datos personales de clientes (datos personales y fiscales, confidenciales). Hereda las obligaciones que apliquen a esa clasificación: protección de datos personales, plazos de conservación y deber de poder responder solicitudes de acceso o supresión. Esto crea una tensión que debe resolverse por política: la auditoría exige conservar el historial, y la protección de datos puede exigir no conservar datos más tiempo del necesario. Hace falta definir un periodo de retención y un procedimiento de depuración documentado.
