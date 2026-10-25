# Informe final – Hardening de PostgreSQL

> Basado en lo observado en el laboratorio (PostgreSQL 17 en Windows). Los cambios de la sección 3 son **propuestos**: si no se aplicaron, indícalo en el informe y actualiza la respuesta con los valores reales tras verificar.

## Resumen del estado encontrado

|Control|Estado observado|
|---|---|
|`listen_addresses`|`*` (todas las interfaces)|
|Puerto|`5432`|
|`ssl`|`off` (sin TLS en la conexión actual)|
|Autenticación|`scram-sha-256` (almacenamiento y las 6 reglas de `pg_hba.conf`)|
|`pg_hba.conf`|Solo local, `127.0.0.1` y `::1`; sin `0.0.0.0/0` ni `::/0`|
|Superusuarios|Solo `postgres` (en lo visible)|
|Extensiones|Solo `plpgsql`|
|Registro|`log_connections = off`, `log_disconnections = off`|
|Tiempos de espera|`statement_timeout = 0`, `idle_in_transaction_session_timeout = 0`|
|Pendiente|Discrepancia con sesiones desde `172.18.0.5`, atributos de roles `u_...` y permisos del SO|

---

## 1. ¿Cuál era la principal superficie de ataque?

El **servicio de red de PostgreSQL**: el puerto `5432` con `listen_addresses = '*'`, que lo deja escuchando en todas las interfaces del equipo. Es el único punto por el que un atacante remoto puede llegar a la base de datos.

Se ve agravada por la falta de TLS y por la existencia de conexiones remotas (sesiones desde `172.18.0.5`). Quedaba mitigada en parte porque `pg_hba.conf` solo aceptaba conexiones locales y de loopback.

## 2. ¿Qué configuración representaba el mayor riesgo?

Dos configuraciones de riesgo **alto**, que se combinan:

1. **`ssl = off`:** credenciales, consultas y resultados viajan sin cifrar, expuestos a sniffing y ataques *man-in-the-middle*.
2. **`listen_addresses = '*'`:** el servicio queda expuesto en cualquier interfaz.

Si hubiera que elegir una, el mayor riesgo es la **escucha en todas las interfaces**, porque determina *quién puede llegar* al servicio. La ausencia de TLS determina *qué puede ver quien llegue*. Con registro de conexiones apagado, además, no habría evidencia de un acceso indebido.

## 3. ¿Qué cambio produjo la mayor reducción de exposición?

**Restringir `listen_addresses`** a `localhost` y a la IP privada necesaria (propuesto, requiere reinicio), junto con el **firewall en *default deny*** hacia el puerto 5432. Es el cambio que más reduce la exposición porque elimina el acceso desde interfaces y redes que no lo necesitan, en lugar de filtrarlo más adelante.

Cambios complementarios, por orden de impacto:

|Orden|Cambio|Efecto|
|---|---|---|
|1|`listen_addresses` restringido + firewall *default deny*|Reduce quién puede llegar al servicio|
|2|`ssl = on` + `hostssl`|Protege lo que viaja por la red|
|3|`pg_hba.conf` por base + usuario + origen `/32`|Reduce quién puede autenticarse|
|4|`log_connections` / `log_disconnections` en `on`|Permite detectar y auditar|
|5|Tiempos de espera|Mejora la disponibilidad|

## 4. ¿Qué diferencia existe entre firewall y `pg_hba.conf`?

|Aspecto|Firewall|`pg_hba.conf`|
|---|---|---|
|Capa|Red / transporte (IP, puerto)|Aplicación (PostgreSQL)|
|Cuándo actúa|**Antes** de que el tráfico llegue a PostgreSQL|**Después** de aceptar la conexión TCP|
|Qué evalúa|IP origen/destino, puerto, protocolo|Tipo de conexión, base de datos, usuario, origen y método de autenticación|
|Qué protege|El servicio (el puerto)|El acceso lógico (qué cuenta entra a qué base)|

El firewall decide **quién puede llegar**; `pg_hba.conf` decide **quién puede entrar**. Son complementarios: si uno falla o es permisivo, el otro contiene el daño (defensa en profundidad).

## 5. ¿Qué diferencia existe entre autenticación y autorización?

- **Autenticación:** verifica **quién eres** (usuario y contraseña con `scram-sha-256`, certificado). Se configura principalmente en `pg_hba.conf`.
- **Autorización:** define **qué puedes hacer** una vez autenticado (permisos sobre bases, esquemas y tablas; atributos del rol como `SUPERUSER`, `CREATEDB`; membresías de roles). Se gestiona con `GRANT`, `REVOKE` y atributos de roles.

Una autenticación correcta no implica que el acceso deba ser amplio. Una contraseña fuerte (autenticación) no limita el daño de una cuenta con privilegios excesivos (autorización).

## 6. ¿Por qué una cuenta de aplicación no debe ser `SUPERUSER`?

Porque `SUPERUSER` **omite todas las comprobaciones de permisos**. Si la cuenta de la aplicación se compromete (por inyección SQL, filtración de credenciales o un fallo de la aplicación), el atacante obtiene:

- Acceso a **todas las bases de datos** y datos de otros usuarios.
- Capacidad de crear, modificar o eliminar roles y de cambiar la configuración.
- Posibilidad de llegar al **sistema operativo** (lectura y escritura de archivos del servidor, ejecución de programas con `COPY ... PROGRAM`).
- Control sobre la auditoría y los registros.

Una cuenta de aplicación debe tener solo los privilegios sobre las tablas y esquemas que usa (**mínimo privilegio**), para que un compromiso quede acotado a esa aplicación.

## 7. ¿Por qué cambiar el puerto de PostgreSQL no constituye hardening suficiente?

Cambiar el puerto es **seguridad por oscuridad**. Solo reduce el ruido de escaneos automatizados que buscan el puerto 5432, pero:

- Un escaneo completo de puertos (por ejemplo, con `nmap`) detecta el servicio igualmente, y la identificación del protocolo lo confirma.
- No limita quién puede conectarse, no cifra el tráfico, no restringe usuarios ni privilegios y no mejora el registro.
- No corrige ninguna de las debilidades reales: `listen_addresses = '*'`, falta de TLS, reglas amplias o cuentas privilegiadas.

Puede usarse como una capa menor, siempre que existan los controles reales: firewall, `pg_hba.conf` restrictivo, TLS y mínimo privilegio.

## 8. ¿Por qué `listen_addresses='*'` puede ser innecesario?

Porque el servidor casi nunca necesita aceptar conexiones en **todas** las interfaces. Los clientes legítimos suelen estar en `localhost` o en una red privada concreta.

Con `*`:

- El servicio queda expuesto en interfaces que no se usan (públicas, VPN, adaptadores virtuales).
- La única barrera pasa a ser el firewall y `pg_hba.conf`; si alguno falla, el servicio está alcanzable.
- Se amplía la superficie de ataque sin aportar beneficio.

Lo adecuado es listar solo las interfaces necesarias (por ejemplo `localhost,<IP_privada>`), de modo que PostgreSQL ni siquiera abra el puerto en las demás. Este parámetro requiere **reiniciar** el servicio.

## 9. ¿Qué papel tiene el sistema operativo en la seguridad de PostgreSQL?

PostgreSQL se ejecuta sobre el sistema operativo y **confía en él**. Si el sistema operativo se compromete, las protecciones internas de la base de datos pueden omitirse:

- **Archivos:** quien lea el directorio de datos puede copiar toda la información; quien modifique `pg_hba.conf` o `postgresql.conf` puede cambiar la autenticación sin pasar por PostgreSQL.
- **Cuenta de servicio:** debe ser dedicada y sin privilegios innecesarios; si se ejecuta como `SYSTEM` o `root`, un compromiso de la base de datos se extiende al sistema.
- **Permisos y respaldos:** los logs y las copias de seguridad pueden contener datos sensibles y deben protegerse.
- **Parches y servicios:** un sistema sin actualizaciones o con servicios innecesarios ofrece rutas alternativas de ataque.
- **Red:** el firewall del sistema controla el acceso al puerto.
- **Trazabilidad:** los logs se deben proteger (o enviar a un servidor central) para que no puedan borrarse localmente.

En el laboratorio la revisión de permisos del sistema operativo quedó **pendiente**, por lo que debe completarse (por ejemplo con `icacls` sobre `C:/Program Files/PostgreSQL/17/data`).

## 10. ¿Qué controles deberían revisarse periódicamente?

|Frecuencia|Control|
|---|---|
|Continua / diaria|Logs y alertas: fallos de autenticación repetidos, accesos desde orígenes inusuales, sesiones `idle in transaction` prolongadas|
|Mensual|Versión instalada y parches de seguridad; sesiones remotas en `pg_stat_activity`|
|Trimestral|Reglas de `pg_hba.conf`; roles, atributos y membresías (`pg_roles`, roles `pg_*` sensibles); cuentas inactivas; extensiones; reglas del firewall; parámetros de la línea base (`listen_addresses`, `ssl`, tiempos de espera, límites de conexión)|
|Semestral / anual|Permisos del sistema operativo y del directorio de datos; vigencia de certificados TLS; rotación de credenciales; prueba de restauración de respaldos; revisión completa de la línea base y de la documentación|

Cada revisión debe registrarse: qué se revisó, quién, cuándo y qué cambios se aplicaron.

---

## Conclusión

La principal debilidad del laboratorio era la **exposición de red** (`listen_addresses = '*'`, puerto 5432) combinada con la **falta de cifrado** (`ssl = off`) y de **trazabilidad** (registro de conexiones apagado). Las fortalezas eran la autenticación `scram-sha-256`, un `pg_hba.conf` restringido a conexiones locales, un único superusuario y una sola extensión.

El hardening consiste en reducir la superficie de ataque antes de aplicar controles, y en combinar capas independientes: **red (firewall y escucha), autenticación (`pg_hba.conf` y `scram-sha-256`), autorización (mínimo privilegio), cifrado (TLS), sistema operativo (permisos) y monitoreo (logs y revisiones)**. Ningún control basta por sí solo, y el estado debe revisarse y documentarse de forma periódica.
