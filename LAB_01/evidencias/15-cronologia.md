# Reconstrucción cronológica con la bitácora y la auditoría

## Línea de tiempo

| # | Fecha y hora | Usuario | Cliente | Tipo de evento | Qué ocurrió | ¿Exitoso? | Fuente |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 22:49:50.539 | (proceso principal, sin usuario) | — | Configuración | Se activan `log_connections`, `log_disconnections`, el nuevo `log_line_prefix` y `log_statement = 'ddl'` | Sí | Bitácora [1], líneas 8 a 11 |
| 2 | 22:49:51.678 | `postgres` | `[local]` | Acceso | Sesión de administrador autorizada | Sí | Bitácora [77] |
| 3 | 22:50:00.334 | `app_ventas` (nombre declarado) | `127.0.0.1` | Acceso | `password authentication failed`; aplicó la regla de `pg_hba.conf` línea 119 | No | Bitácora [91] |
| 4 | 22:50:00.462 | `usuario_inexistente` (declarado) | `127.0.0.1` | Acceso | Fallo de autenticación; el `DETAIL` indica que el rol no existe | No | Bitácora [98] |
| 5 | 22:50:00.565 | `app_ventas` | `127.0.0.1` | Acceso | Autenticada con SCRAM y autorizada con `app-ventas-web`; desconexión en 22:50:00.568 | Sí | Bitácora [105] |
| 6 | 22:50:09.341 y 22:50:09.367 | `postgres` | `[local]` | Privilegio | `REVOKE UPDATE ON clientes FROM soporte_ana` y `GRANT UPDATE ON clientes TO app_ventas` | Sí | Bitácora [119] |
| 7 | 22:50:09.372 | `postgres` | `[local]` | Estructura | `ALTER TABLE clientes ADD COLUMN segmento` | Sí | Bitácora [119] |
| 8 | 22:50:09.375 y 22:50:09.382 | `postgres` | `[local]` | Estructura / secreto | `CREATE ROLE rol_temporal ... PASSWORD` (contraseña en claro en el log) y `DROP ROLE rol_temporal` | Sí | Bitácora [119] |
| 9 | 22:50:19.459 y 22:50:19.488 | `postgres` | `[local]` | Configuración | `ALTER SYSTEM SET log_statement = 'mod'`; el proceso principal confirma el cambio | Sí | Bitácora [155] y [1] |
| 10 | 22:50:20.601 | `app_ventas` | `127.0.0.1` | Datos | `UPDATE clientes SET telefono = '6679990000' WHERE id = 3`, con `app-ventas-web` | Sí (sin error registrado) | Bitácora [162] |
| 11 | hora no visible | `soporte_ana` | `127.0.0.1` | Error | `DELETE FROM clientes WHERE id = 5` rechazado: `permission denied for table clientes` | No | Bitácora [168] |
| 12 | hora no visible | `postgres` | `[local]` | Error | `DROP ROLE soporte_ana` rechazado: el rol tiene privilegios sobre `clientes` | No | Bitácora [175] |
| 13 | 22:50:27.480 | `soporte_ana` | `127.0.0.1` | Acceso | Sesión larga `reporte-mensual` con `pg_sleep(90)` | Sí | `pg_stat_activity` (PID 189) y bitácora |
| 14 | 22:50:52.903439 | `app_ventas` | `127.0.0.1` | Datos | `UPDATE` del RFC de `id_cliente = 3`: `GAMA780912XYZ` a `GAMA780912ZZZ`, con `app-ventas-web` | Sí | Auditoría `id_evento = 1` |
| 15 | hora no visible | `postgres` | `[local]` | Datos | `INSERT` de Pedro Ruiz (`id_cliente = 6`, RFC `RUPE950101AAA`) | Sí | Auditoría `id_evento = 2` |
| 16 | hora no visible | `postgres` | `[local]` | Datos | `DELETE` de Pedro Ruiz (`id_cliente = 6`) | Sí | Auditoría `id_evento = 3` |
| 17 | hora no visible | `app_ventas` | `127.0.0.1` | Error | Intento de `ALTER TABLE clientes DISABLE TRIGGER`; rechazado por no ser propietaria | No | Bitácora [253] |
| 18 | hora no visible | `postgres` | `[local]` | Evasión | `DISABLE TRIGGER`, `UPDATE ... rfc = 'GAMA780912GHI'` sobre `id = 3` y `ENABLE TRIGGER`; **sin evento en la auditoría** | Sí | Bitácora [260] |
| 19 | hora no visible | no visible | no visible | Datos | `UPDATE clientes SET segmento = 'regular'` sin `WHERE`; 1 línea en la bitácora y 5 eventos `UPDATE` en la auditoría | Sí | Bitácora (1 línea) y auditoría (conteo) |

### 1. ¿Quién cambió el RFC?

**Primera vez (Actividad 3), valor `GAMA780912XXX`: No hay evidencia.** En ese momento `log_statement` era `none`, `log_connections` estaba en `off` y la tabla no tenía trigger. La consulta a la bitácora devolvió `(0 rows)`. El `UPDATE 1` prueba que la fila cambió, pero no deja usuario, hora ni origen.

**Actividad 7, valor `GAMA780912XYZ`: No hay evidencia directa de quién.** Se hizo con `log_statement = 'ddl'`, que no registra los `UPDATE`, y no existe evento de auditoría porque el trigger aún no estaba creado. El valor `XYZ` solo se conoce porque aparece como `valores_antes` del evento 1. Eso prueba que existió, no quién lo escribió. Si la bitácora conserva una línea `connection authorized` de `app_ventas` desde `127.0.0.1` cerca de ese momento, sería un indicio circunstancial, no una prueba del cambio.

**Actividad 12, valor `GAMA780912ZZZ`: `app_ventas`.** Lo prueban el evento 1 de la auditoría (`usuario_sesion = app_ventas`), la hora 22:50:52.903439 UTC, la IP `127.0.0.1` y la aplicación declarada `app-ventas-web`. El rol es evidencia sólida. La aplicación es solo declarativa, y `app_ventas` es una cuenta compartida, así que no se identifica a la persona.

**Actividad 14, valor `GAMA780912GHI`: `postgres`, solo por la bitácora.** La línea [260] muestra a `postgres` desde `[local]` ejecutando el `UPDATE`, entre el `DISABLE TRIGGER` y el `ENABLE TRIGGER`. La hora no es visible en la salida disponible. La tabla de auditoría no contiene este cambio, porque el trigger estaba apagado. Esa atribución depende de que la bitácora sea íntegra, y quien controla el servidor también puede editarla.

### 2. ¿Quién cambió el teléfono?

**`app_ventas`**, el 2026-10-25 a las 22:50:20.601 UTC, desde `127.0.0.1` con `app-ventas-web` (bitácora [162]). La sentencia registrada fue `UPDATE clientes SET telefono = '6679990000' WHERE id = 3`. La evidencia es completa para quién, cuándo y desde dónde. Hay una limitación: la línea muestra la sentencia, no su resultado. Solo se sabe que no se registró ningún error asociado.

### 3. ¿Hubo intentos de acceso fallidos? ¿De qué usuarios y desde dónde?

Sí, dos, ambos desde `127.0.0.1`:

- **22:50:00.334:** nombre `app_ventas` con contraseña incorrecta (PID 91). Aplicó la regla de `pg_hba.conf` línea 119.
- **22:50:00.462:** nombre `usuario_inexistente` (PID 98). El `DETAIL` de la bitácora indica que el rol no existe, dato que el cliente no recibe.

Estas líneas prueban que alguien en esa dirección presentó esos nombres y credenciales rechazadas, no quién era. El campo de aplicación aparece como `[unknown]` porque la sesión nunca llegó a establecerse.

Los errores de `soporte_ana` (evento 11) y de `app_ventas` (evento 17) **no** son fallos de autenticación. Fueron errores de autorización con credenciales válidas, rechazados por falta de privilegios.

**Fallos previos al cambio de la Actividad 3: No hay evidencia.** Con `log_connections = off` no se registraban conexiones, y sin usuario ni IP en el prefijo un fallo habría sido anónimo.

### 4. ¿Qué valor tenía el RFC antes de cada cambio?

- **Actividad 3 (a `XXX`): No hay evidencia.** No existía trigger ni registro de sentencias, y el valor original no consta en ninguna fuente.
- **Actividad 7 (a `XYZ`): No hay evidencia.** Sin trigger no se guardó el valor anterior. Es probable que fuera `XXX`, pero eso es una deducción por secuencia, no una prueba.
- **Actividad 12 (a `ZZZ`): `GAMA780912XYZ`.** Consta en `valores_antes` del evento 1, y la comparación campo por campo confirma que fue el único campo modificado.
- **Actividad 14 (a `GHI`): No hay evidencia directa.** La bitácora registra solo el valor nuevo, y no hay evento de auditoría. El último valor auditado, `GAMA780912ZZZ`, sugiere cuál era el anterior, pero es una inferencia: otros cambios sin auditar podrían haber ocurrido entre medias.
- **Teléfono (evento 10): No hay evidencia.** La sentencia no guarda el valor previo y el trigger no existía todavía.
