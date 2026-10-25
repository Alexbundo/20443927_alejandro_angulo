# Registro de superficie de ataque – PostgreSQL

| Elemento | Estado actual | ¿Es necesario? | Riesgo |
| --- | --- | --- | --- |
| **Puerto PostgreSQL** | 5432 (puerto por defecto) | Sí, algún puerto debe estar abierto para el servicio; el cambio de puerto es opcional | **Bajo-Medio**: al ser el puerto estándar, es el primero que escanean bots y atacantes. Cambiarlo no es seguridad real (oscuridad), pero reduce el ruido automatizado |
| **Interfaces de escucha** | `listen_addresses = *` (todas las interfaces) | No. Solo debería escuchar en las interfaces que usan los clientes legítimos (p. ej. `localhost` o la IP de la red interna) | **Alto**: el servicio queda expuesto en cualquier interfaz de red, incluidas las públicas si existen |
| **Conexiones remotas** | Activas. En `pg_stat_activity` hay sesiones desde `172.18.0.5` (puertos 42060, 42076, 40708) del usuario `u_20443927_alejandro_ang…`. Las demás sesiones muestran `client_addr = null` (socket Unix/local, p. ej. pgAdmin en el mismo host) | Parcialmente: solo para los clientes/redes identificados y justificados (la `172.18.x.x` parece una red Docker interna) | **Medio-Alto**: combinado con `listen_addresses = *`, cualquier regla permisiva en `pg_hba.conf` (p. ej. `0.0.0.0/0`) permitiría acceso externo. Hay que revisar `pg_hba.conf` |
| **Usuarios administrativos** | Existe `postgres` (superusuario, pid 31, sin cliente remoto visible). Los demás usuarios son por alumno (`u_<matrícula>_nombre`) con su propia BD (`db_...`) | Sí, un superusuario es necesario, pero limitado en uso y acceso (solo local, sin conexión remota) | **Alto** si `postgres` es accesible remotamente o tiene contraseña débil; **Medio** por verificar si los usuarios `u_...` tienen atributos como `SUPERUSER`, `CREATEROLE` o `CREATEDB` innecesarios (consultar `pg_roles`) |
| **SSL/TLS** | `ssl = off` | **Sí**, si hay cualquier conexión por red (como las de `172.18.0.5`) | **Alto**: credenciales y datos viajan en texto claro y son susceptibles a sniffing y ataques man-in-the-middle |
| **Métodos de autenticación** | `password_encryption = scram-sha-256` (almacenamiento de contraseñas). El método real de conexión se define en `pg_hba.conf`, aún sin revisar | Sí, y debe ser `scram-sha-256` en `pg_hba.conf`; no `trust` ni `md5` | **Bajo** en almacenamiento (SCRAM es el estándar actual); **desconocido** en `pg_hba.conf` hasta revisarlo. Un `trust` o `md5` ahí anularía la protección |

---

## Pregunta: ¿Por qué conocer la superficie de ataque debe preceder al hardening?

El hardening consiste en reducir o cerrar puntos de exposición; sin un inventario previo (puertos, interfaces, usuarios, protocolos) no se sabe qué cerrar, qué restringir ni qué mantener.

En este caso, el inventario muestra que `ssl = off` y `listen_addresses = *` son riesgos altos, mientras que el cifrado de contraseñas ya es correcto. Sin el diagnóstico, se podría invertir esfuerzo en cambiar el puerto y dejar abiertos los problemas graves.

**Evita romper servicios legítimos.** El inventario revela qué conexiones son necesarias (como la de `172.18.0.5`). Aplicar restricciones a ciegas puede dejar sin acceso a usuarios o aplicaciones válidas.
