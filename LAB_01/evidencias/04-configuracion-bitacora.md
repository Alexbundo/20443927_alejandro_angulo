# Configuración y bitácora

## 1. ¿Por qué el proceso que registra el cambio es el principal y no tu sesión?

Porque la sesión del administrador solo escribe el archivo `postgresql.auto.conf` y envía la señal de recarga; no aplica la configuración. Quien relee los archivos de configuración y adopta los valores nuevos es el proceso principal, que recibe la señal `SIGHUP`. Es él quien detecta que un parámetro cambió y lo registra, y después reenvía la señal a los procesos hijos para que también actualicen sus valores.

## 2. ¿Qué pasaría si alguien ejecutara `ALTER SYSTEM SET log_statement = 'none'`? ¿Quedaría rastro?

Quedaría rastro, no completo.
Con `log_statement = 'ddl'` activo, el `ALTER SYSTEM` se considera una sentencia de administración y quedaría registrado en el momento de ejecutarse, con el usuario, la IP y la aplicación gracias al nuevo prefijo. Además, al recargar, el postmaster escribiría la línea `parameter "log_statement" changed to "none"`. Esas dos líneas permitirían reconstruir qué ocurrió y quién lo hizo.

## 3. ¿Por qué no se recomienda editar `postgresql.auto.conf` a mano?

- **Errores de sintaxis.** Un valor mal escrito en el archivo puede impedir que el servidor arranque o que recargue la configuración, y el fallo se descubre justo cuando se reinicia.
- **Sin validación.** `ALTER SYSTEM` comprueba que el parámetro exista y que el valor sea válido antes de escribirlo. Una edición manual no pasa por esa comprobación.
- **Sin trazabilidad.** `ALTER SYSTEM` es una sentencia SQL y puede quedar registrada con `log_statement`, con usuario y hora. Una edición directa del archivo se hace desde el sistema operativo y no deja rastro en la bitácora de PostgreSQL, por lo que sirve para saltarse la auditoría.
- **Conflictos de escritura.** PostgreSQL reescribe el archivo completo cada vez que se ejecuta `ALTER SYSTEM`, así que los comentarios o ajustes manuales pueden perderse.
- **Precedencia oculta.** Los valores de `postgresql.auto.conf` se leen después de `postgresql.conf` y lo sobrescriben. Un cambio manual puede anular silenciosamente otra configuración y confundir a quien revisa solo `postgresql.conf`.
