# 1. ¿Puedes demostrar quién modificó el RFC?

No. Se sabe que el RFC cambió porque facturación lo reportó, pero el servidor no conserva quién lo hizo. Con `log_statement = none`, un `UPDATE` exitoso no escribe nada. Con `log_connections = off`, tampoco queda registro de quién abrió la sesión.

## 2. ¿Puedes demostrar que el cambio no lo hizo `soporte_ana`?

Hay dos ideas que no valen como prueba. El primero es decir que Ana solo tiene `SELECT` y por eso no pudo: eso describe lo que debería ocurrir según los permisos, no lo que ocurrió. Los permisos pudieron haber sido distintos en ese momento o haberse modificado después, e incluso `postgres` pudo concederle el privilegio de forma temporal. El segundo es apoyarse en la simulación: esta demuestra que `app_ventas` puede hacer el cambio, no que fuera quien lo hizo en el incidente real.

## 3. Los privilegios de la Unidad II, ¿impidieron el cambio? ¿Debían impedirlo?

No lo impidieron, y no debían impedirlo.
No lo impidieron porque `app_ventas` tiene `SELECT` y `UPDATE` sobre `clientes`, de modo que el `UPDATE` era una operación legítima según el diseño. Los privilegios funcionaron correctamente: habrían negado el cambio a `soporte_ana`, que solo tiene `SELECT`, pero permiten el de `app_ventas`. Y no debían impedirlo porque modificar el RFC es una función normal de la aplicación de ventas; bloquearlo rompería la operación del negocio.

## 4. ¿Qué tendría que haber estado configurado antes del incidente?

La evidencia no puede crearse después del hecho: tenía que existir antes.

En el registro del servidor, lo mínimo era:

```sql
ALTER SYSTEM SET log_connections    = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix    = '%m [%p] user=%u db=%d app=%a host=%h ';
ALTER SYSTEM SET log_statement      = 'mod';
SELECT pg_reload_conf();
```
