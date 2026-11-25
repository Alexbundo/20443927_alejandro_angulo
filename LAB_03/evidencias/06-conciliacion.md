# Actividad 7 — Registro de cambios y conciliación

## Tabla de conciliación

| Momento (bitácora) | Usuario | Sentencia | Folio que lo autoriza | ¿Autorizado? | Hallazgo |
| --- | --- | --- | --- | --- | --- |
| 2026-10-25 22:54:26.533 | postgres | ALTER TABLE clientes ADD COLUMN canal_alta VARCHAR(20) | CAM-2026-014 | Sí | — (dentro de la ventana y con aprobación del Comité de cambios) |
| 2026-10-25 22:50:53.549 | postgres | ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes | Ninguno | No | Hallazgo: se desactivó el control de auditoría sin folio. Si fue parte de la Actividad 14 del LAB-01, es un cambio de laboratorio que debe declararse. |
| 2026-10-25 22:50:09.367 | postgres | GRANT UPDATE ON clientes TO app_ventas | Ninguno | No | Preparación del laboratorio (LAB-01). Concede un privilegio, así que en producción necesitaría folio. |
| 2026-10-25 22:50:09.341 | postgres | REVOKE UPDATE ON clientes FROM soporte_ana | Ninguno | No | Preparación del laboratorio. Reduce privilegios; conviene documentarlo. |
| 2026-10-25 22:50:09.372 | postgres | ALTER TABLE clientes ADD COLUMN segmento VARCHAR(20) | Ninguno | No | Preparación del laboratorio. Es un cambio de estructura sin folio. |
| 2026-10-25 22:50:09.375 | postgres | CREATE ROLE rol_temporal LOGIN PASSWORD '...' | Ninguno | No | Preparación del laboratorio, pero la contraseña quedó en texto claro en la bitácora (hallazgo de seguridad). |
| 2026-10-25 22:50:53.460 | app_ventas | ALTER TABLE clientes DISABLE TRIGGER trg_auditoria_clientes | Ninguno | No | Hallazgo grave: un usuario de aplicación desactivó la auditoría. |
| 2026-10-25 22:50:53.554 | postgres | ALTER TABLE clientes ENABLE TRIGGER trg_auditoria_clientes | Ninguno | No | Reactivación sin folio. Entre el DISABLE y el ENABLE hay un periodo sin auditoría. |

## Preguntas

### 1. ¿Qué cambios de la bitácora no tienen folio? ¿Son de preparación o hallazgos?

Todos, salvo el `ALTER TABLE ... canal_alta`.

- **Preparación del laboratorio:** el `REVOKE`, el `GRANT`, el `ADD COLUMN segmento` y el `CREATE ROLE`. Se hicieron para montar el LAB-01 y se declaran como tales.
- **Hallazgos:** los `DISABLE TRIGGER` de las líneas 163 y 169, y la contraseña expuesta en la línea 37.

### 2. La desactivación del disparador del LAB-01, ¿qué tan grave es? ¿Qué distingue la línea 163 de la 169?

Es grave: el disparador es el control que registra los cambios en `auditoria.cambios_clientes`. Mientras está desactivado, los cambios a `clientes` no dejan evidencia y se pueden hacer sin rastro.

- **Línea 163:** la ejecuta `app_ventas`, un usuario de aplicación que no debería poder alterar controles. Indica un exceso de privilegios y un posible intento de evadir la auditoría.
- **Línea 169:** la ejecuta `postgres` (el DBA), que tiene esa facultad. Aun así necesita folio y aprobación, y debe reactivarse de inmediato (línea 171).

### 3. ¿Qué limitación tiene la conciliación si log_statement estuvo en none?

Solo se concilia lo que quedó registrado. Los cambios hechos en ese periodo no aparecen en la bitácora, así que no se puede probar que no hubo cambios sin autorización. Es un hueco de evidencia que debe declararse, como la creación de `dba.bitacora`.

### 4. ¿Quién debería realizar la conciliación?

Otra persona, independiente del DBA que hizo los cambios (auditoría interna, seguridad o el Comité de cambios), por separación de funciones. El DBA no debe revisar sus propios cambios, porque podría omitir u ocultar hallazgos.
