# Actividad 15 – Lecturas sensibles y cambios masivos

## 1. Si `clientes` tuviera un millón de registros, ¿qué ocurriría con la auditoría tras un `UPDATE` sin `WHERE`?

El disparador es de nivel fila (`FOR EACH ROW`), de modo que se ejecutaría un millón de veces y la tabla de auditoría recibiría un millón de filas nuevas, cada una con la fila completa antes y después en JSONB.

## 2. Propón quién podría autorizar la depuración de `auditoria.cambios_clientes`

La depuración no debe autorizarla ni ejecutarla el DBA por sí solo, porque estaría borrando la evidencia de sus propias acciones.

- **Responsable de seguridad de la información (o auditoría interna)**, como custodio de la evidencia y autorizador principal. Verifica que los eventos a depurar estén fuera del plazo de retención y que no haya una investigación abierta.
- **Responsable de protección de datos o cumplimiento**, que confirma que la depuración cumple con la política de retención y con las obligaciones de supresión de datos personales.
- **Dueño de los datos o dirección**, que acepta el riesgo residual.
- **El DBA como ejecutor**, nunca como autorizador, y con la ejecución registrada.

## 3. ¿Por qué `log_statement = 'all'` puede convertir la bitácora en un nuevo depósito de datos sensibles?

Porque la bitácora escribe el **texto completo de cada sentencia**, y ese texto contiene los valores literales que la aplicación o el usuario incluyen. Con `all`, cada consulta de cada tabla queda escrita, no solo las modificaciones.
