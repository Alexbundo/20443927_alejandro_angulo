# Actividad 1 — Calidad de datos desde la operación

## Registro de hallazgos

| # | Hallazgo | Registros | Regla de calidad | ¿Quién decide la corrección? | Acción propuesta |
| --- | --- | --- | --- | --- | --- |
| C1 | Posible cliente duplicado (mismo correo con distinta capitalización) | 1, 7 | Unicidad del correo | Dueño del dato (ventas o atención a clientes) | Confirmar si son la misma persona. Si lo son, fusionar en un solo registro; si no, documentar por qué comparten correo. |
| C2 | RFC incompleto: `LOAA850315AB` tiene 12 caracteres | 7 | Formato del RFC | Dueño del dato, con el cliente o su constancia fiscal | Pedir el RFC completo al cliente o validarlo con su constancia. No inventar el carácter faltante. |
| C3 | RFC ausente (`NULL`) | 8 | Completitud del RFC | Dueño del dato / responsable fiscal | Definir si el RFC es obligatorio para este cliente y recabarlo. |
| C4 | Correo con formato inválido (`sin-correo`) | 8 | Formato del correo | Dueño del dato | Pedir el correo real o dejar `NULL` si no tiene. |
| C5 | Edad fuera de rango (`-3`) | 8 | Rango de edad (18 a 120) | Dueño del dato | Corregir con la fecha de nacimiento o dejar `NULL` hasta confirmarla. |
| C6 | Teléfono incompleto (`667`), código postal de 4 dígitos (`8000`) y ciudad escrita distinto (`Culiacan` / `Culiacán`) | 8 (y 7 para la ciudad) | Formato y consistencia | Dueño del dato; negocio para el catálogo de ciudades | Corregir con el cliente y estandarizar la ciudad con un catálogo. |

## Preguntas

### 1. ¿Por qué el DBA no debe corregir por su cuenta el RFC del registro 7?

Porque el DBA custodia los datos, pero no es su dueño: solo el cliente o su constancia fiscal conocen el RFC correcto. Adivinar el carácter faltante crearía un RFC que parece válido pero puede ser falso, con posibles consecuencias fiscales. Todo cambio de datos de negocio requiere solicitud y aprobación del responsable.

### 2. ¿Qué restricción habría evitado cada hallazgo? ¿Quién debería aprobar agregarla?

El DBA las implementa, pero las aprueba el dueño del dato junto con el responsable de la aplicación, mediante control de cambios, porque son reglas de negocio y pueden afectar al sistema que inserta los datos.

### 3. Si el DBA corrige un dato, ¿qué mecanismo del LAB-01 (Parte B) deja evidencia?

La auditoría del servidor (`log_statement` y/o pgaudit): cada `UPDATE` o `DELETE` queda en el log con usuario, fecha, hora y sentencia, y se consulta con la vista `dba.bitacora`.
