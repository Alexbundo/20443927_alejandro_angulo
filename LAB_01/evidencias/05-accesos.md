# Accesos y autenticación

## 1. La bitácora registra `app_ventas` en el intento fallido. ¿Eso prueba que la aplicación de ventas intentó entrar? ¿Qué prueba realmente?

No lo prueba. El campo `user=` contiene el nombre de rol que quien se conectó escribió en la cadena de conexión, y cualquiera que conozca ese nombre puede teclearlo. Esa persona pudo ser la aplicación con una contraseña mal configurada, un empleado probando credenciales, un atacante que adivinó el nombre del rol o alguien que ejecutó justamente el comando de esta práctica.

## 2. ¿Qué información adicional registra PostgreSQL cuando el rol no existe? ¿Por qué aparece en la bitácora y no en el mensaje que recibe el cliente?

Cuando el rol no existe, la línea `DETAIL` registra `Role "usuario_inexistente" does not exist.` En cambio, cuando el rol existe pero la contraseña es incorrecta, el detalle indica la regla de `pg_hba.conf` que coincidió. El administrador puede así distinguir las dos situaciones, y el cliente no.

## 3. ¿Por qué `app=[unknown]` en el intento fallido, pero `app=app-ventas-web` en la desconexión?

Porque `application_name` se transmite en el paquete de arranque de la conexión, pero el servidor lo incorpora a la sesión una vez que la autenticación se completó y se procesan los parámetros de inicio. Antes de ese punto, el campo `%a` del prefijo no tiene valor y se imprime como `[unknown]`.

La consecuencia práctica es que el campo `app=` no es fiable para atribuir intentos **fallidos**. En ellos no se puede saber qué aplicación se declaraba. Para esos casos los datos útiles son el usuario, la IP y la hora. Y aun en sesiones exitosas, `application_name` lo escribe el cliente, así que sirve para organizar y filtrar, no como prueba.

## 4. ¿Qué patrón de varias líneas te haría sospechar de un ataque de fuerza bruta? Escribe la consulta que contaría los intentos fallidos por usuario

Un ataque de fuerza bruta deja un patrón que se distingue de un error aislado de contraseña:

- Muchas líneas `FATAL: password authentication failed` en un intervalo corto, con una cadencia regular de decenas o cientos por minuto, imposible para una persona tecleando.
- Una misma IP de origen probando muchos usuarios distintos (*password spraying*), o muchas IP probando un mismo usuario (ataque distribuido).
- Líneas `Role "..." does not exist` con nombres típicos (`admin`, `root`, `test`, `postgres`), señal de enumeración de usuarios.
- Puertos de origen distintos y consecutivos, con cada intento abriendo una conexión nueva y cerrándola enseguida.
- Un éxito (`connection authorized`) inmediatamente después de una larga secuencia de fallos desde la misma IP, que indica que el atacante probablemente acertó.
- Actividad fuera del horario habitual o desde IP que nunca se habían visto.
