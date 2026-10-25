# Actividad 16 – Línea base: configuración antes y después

> **Antes** = estado observado en el laboratorio.
> **Después** = estado objetivo **propuesto**. No se ha aplicado ningún cambio; actualizar esta columna con el valor real cuando se apliquen y verifiquen.

## Tabla comparativa

| Control | Antes | Después (propuesto) | Justificación |
| --- | --- | --- | --- |
| `listen_addresses` | `*` (todas las interfaces) | `localhost,<IP_privada_del_servidor>` | Reduce la exposición: solo escucha en loopback y en la red privada necesaria. Requiere reinicio del servicio |
| `pg_hba.conf` | Solo 6 reglas: `local`, `127.0.0.1` y `::1` (bases `all` y `replication`, usuarios `all`). Sin `0.0.0.0/0` ni `::/0` | Reglas específicas por base de datos + usuario + origen (`/32`); eliminar o restringir las reglas de `replication` si no se usan | Mínimo privilegio: un host, una cuenta, una base. Lo no listado queda denegado por defecto |
| Método de autenticación | `scram-sha-256` (`password_encryption` y las 6 reglas de `pg_hba.conf`) | `scram-sha-256` (se mantiene) y `hostssl` en reglas remotas | Ya es el método más robusto; no usar `trust`, `md5` ni `password` |
| Usuarios administrativos | `postgres` es el único superusuario visible (`SUPERUSER`, `CREATEROLE`, `CREATEDB`, `LOGIN`); sin acceso remoto según `pg_hba.conf` | Mantener un solo superusuario, con contraseña robusta, solo acceso local, no usado por aplicaciones. Auditar membresías de roles `pg_*` sensibles | Limita el impacto de una cuenta comprometida |
| Cuentas de aplicación | Roles `u_<matrícula>_...` con su base `db_...`. Atributos **por verificar** (no aparecieron en la captura de `pg_roles`) | Cada cuenta sin `SUPERUSER`, `CREATEROLE` ni `CREATEDB`, con acceso solo a su propia base. Depurar cuentas sin uso | Aísla a los alumnos entre sí y evita escalamiento de privilegios |
| Puerto | `5432` (por defecto) | `5432`, o cambiarlo si la política lo permite; bloqueo por firewall desde fuera de la red DBA | Cambiar el puerto solo reduce ruido automatizado. El control real es el firewall (`10.10.10.0/24` → `5432`: permitir; otros: denegar) |
| TLS | `ssl = off`; la conexión actual no usa TLS (`version` y `cipher` en `NULL`); `ssl_min_protocol_version = TLSv1.2` | `ssl = on`, certificado y clave del servidor, `ssl_min_protocol_version = TLSv1.2`, reglas remotas con `hostssl` | Cifra credenciales, consultas y resultados; evita sniffing y ataques *man-in-the-middle* |
| Permisos SO | **No evaluado** (pendiente). Rutas: datos en `C:/Program Files/PostgreSQL/17/data`, logs en `data/log` | Directorio de datos y logs accesibles solo para la cuenta de servicio de PostgreSQL y administradores. Respaldo previo de `postgresql.conf` y `pg_hba.conf` | Quien acceda al disco puede leer datos y modificar la autenticación sin pasar por PostgreSQL |
| Extensiones | Solo `plpgsql` 1.0 (en la base consultada) | Mantener solo `plpgsql`. Revisar las demás bases y no instalar extensiones sin justificación (`adminpack`, `file_fdw`, `dblink`, lenguajes *untrusted*) | Cada extensión adicional amplía la superficie de ataque |
| Conexiones | `max_connections = 100`, `superuser_reserved_connections = 3`, `statement_timeout = 0`, `idle_in_transaction_session_timeout = 0`, `log_connections = off`, `log_disconnections = off` | `statement_timeout` (p. ej. `60s`, mejor por rol), `idle_in_transaction_session_timeout` (p. ej. `5min`), `log_connections = on`, `log_disconnections = on`; `max_connections` ajustado a la carga real | Evita agotar conexiones y retener bloqueos, y deja evidencia de quién se conecta y cuándo |

## Comandos para aplicar los cambios (propuestos, no ejecutados)

```sql
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET statement_timeout = '60s';
ALTER SYSTEM SET idle_in_transaction_session_timeout = '5min';
SELECT pg_reload_conf();
```

Requieren **reinicio del servicio**: `listen_addresses`, `port` y `max_connections`.

## Pendientes antes de dar la tabla por completa

1. **Discrepancia sin resolver:** `pg_stat_activity` muestra sesiones desde `172.18.0.5`, pero `pg_hba_file_rules` solo tiene reglas locales y loopback. Revisar la columna `error`, confirmar la instancia consultada y recargar la configuración.
2. **Roles `u_...`:** ejecutar la consulta sobre `pg_roles` filtrando `NOT LIKE 'pg\_%'` y completar la fila de cuentas de aplicación.
3. **Permisos del sistema operativo:** revisar los permisos de `C:/Program Files/PostgreSQL/17/data` (clic derecho > Propiedades > Seguridad, o `icacls`).
4. **Extensiones:** repetir la consulta en las demás bases de datos.
5. **Verificación final:** tras aplicar los cambios, volver a ejecutar las consultas (`SHOW ...`, `pg_hba_file_rules`, `pg_stat_ssl`, `pg_roles`) y registrar los valores reales en la columna "Después".

La línea base muestra una configuración con fortalezas (`scram-sha-256`, `pg_hba.conf` restringido a conexiones locales, una sola extensión, `postgres` sin acceso remoto) y debilidades concretas: `listen_addresses = '*'`, `ssl = off`, sin registro de conexiones y sin tiempos de espera. Las medidas propuestas se centran en reducir la exposición de red, cifrar las comunicaciones, aplicar mínimo privilegio y dejar evidencia auditable.

## Actividad 17 – Checklist de hardening de PostgreSQL

> **Verificado:** ✅ Sí · ⚠️ Parcial · ❌ No · ⏳ Pendiente de revisar
> El estado refleja lo observado en el laboratorio hasta ahora. Actualízalo cuando se apliquen y verifiquen los cambios.

## Checklist

| # | Control | Verificado | Evidencia |
| --- | --- | --- | --- |
| 1 | Puerto documentado | ✅ | `SHOW port;` → `5432` |
| 2 | Interfaces de escucha justificadas | ❌ | `SHOW listen_addresses;` → `*`. Debe limitarse a `localhost` y la IP privada necesaria |
| 3 | `pg_hba.conf` revisado | ✅ | `SELECT ... FROM pg_hba_file_rules;` → 6 reglas (local, `127.0.0.1`, `::1`). Ruta: `C:/Program Files/PostgreSQL/17/data/pg_hba.conf` |
| 4 | Redes autorizadas restringidas | ⚠️ | Sin `0.0.0.0/0` ni `::/0`, pero hay sesiones desde `172.18.0.5` sin regla visible que las explique. Pendiente de aclarar |
| 5 | Autenticación segura | ✅ | `password_encryption = scram-sha-256` y las 6 reglas usan `scram-sha-256`. Sin `trust` ni `md5` |
| 6 | Superusuarios identificados | ✅ | `pg_roles` → solo `postgres` con `rolsuper = true` (en lo visible) |
| 7 | Cuentas de aplicación separadas | ⚠️ | Existen roles `u_<matrícula>_...` con su base `db_...` (`pg_stat_activity`), pero falta verificar sus atributos |
| 8 | Privilegios mínimos | ⏳ | Pendiente: `SELECT rolname, rolsuper, rolcreaterole, rolcreatedb FROM pg_roles WHERE rolname NOT LIKE 'pg\_%';` y revisar membresías de roles `pg_*` sensibles |
| 9 | Extensiones revisadas | ✅ | `pg_extension` → solo `plpgsql 1.0` (base consultada; repetir en las demás) |
| 10 | TLS verificado | ❌ | `ssl = off`; `pg_stat_ssl` → `ssl = false`, `version` y `cipher` en `NULL`. `ssl_min_protocol_version = TLSv1.2` |
| 11 | Configuración protegida | ⏳ | Pendiente: permisos de `postgresql.conf`, `pg_hba.conf` y `pg_ident.conf` (`icacls`) y respaldo previo |
| 12 | Directorio de datos protegido | ⏳ | Ruta: `C:/Program Files/PostgreSQL/17/data`. Pendiente verificar que solo la cuenta de servicio y administradores tengan acceso |
| 13 | Firewall documentado | ⚠️ | Política conceptual diseñada (`10.10.10.0/24` → `5432`: permitir; otros: denegar). Falta documentar las reglas reales del entorno |
| 14 | Actualizaciones documentadas | ⏳ | Pendiente: `SELECT version();` y comparar con la última versión menor de PostgreSQL 17 |
| 15 | Configuración registrada | ✅ | Línea base antes/después (Actividad 16) y rutas de `postgresql.conf`, `pg_hba.conf` y `pg_ident.conf` |
| 16 | Registro de conexiones activado | ❌ | `log_connections = off`, `log_disconnections = off` |
| 17 | Ruta de logs conocida y protegida | ⚠️ | `log_directory = log` (`C:/Program Files/PostgreSQL/17/data/log`). Falta verificar permisos y retención |
| 18 | Tiempos de espera configurados | ❌ | `statement_timeout = 0`, `idle_in_transaction_session_timeout = 0` |
| 19 | Límite de conexiones revisado | ✅ | `max_connections = 100`, `superuser_reserved_connections = 3` (valores por defecto, razonables) |
| 20 | Superusuario sin acceso remoto | ✅ | `pg_hba.conf` solo permite acceso local y loopback; no hay regla remota para `postgres` |

## Resumen del estado

| Estado | Cantidad | Controles |
| --- | --- | --- |
| ✅ Verificado | 7 | 1, 3, 5, 6, 9, 15, 19, 20 |
| ⚠️ Parcial | 5 | 4, 7, 13, 17 |
| ❌ No cumple | 4 | 2, 10, 16, 18 |
| ⏳ Pendiente | 4 | 8, 11, 12, 14 |

> Nota: el conteo por estado se lista en la columna "Controles". Revisa y ajusta los números si cambias algún estado.

## Prioridad de remediación

1. **Alta:** habilitar TLS (10), restringir `listen_addresses` (2) y activar el registro de conexiones (16).
2. **Media:** aclarar la discrepancia de `172.18.0.5` (4), configurar tiempos de espera (18) y auditar roles de alumnos (7, 8).
3. **Baja / verificación:** revisar permisos del sistema operativo (11, 12, 17), la versión instalada (14) y documentar el firewall real (13).

## Conclusión

El checklist de 20 controles muestra una base sólida en autenticación, superusuarios y extensiones, con fallos concretos en cifrado (TLS), exposición de red y trazabilidad. Los pendientes se cierran con verificaciones sencillas en el sistema operativo y en `pg_roles`. Tras aplicar las correcciones, hay que volver a marcar cada control con su evidencia real.
