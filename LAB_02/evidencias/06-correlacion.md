# Actividad 6

## 1. ¿Qué usuario cambió la configuración del perfilador? ¿Qué dos eventos lo demuestran?

Lo cambió el usuario **`admin`**  

Lo demuestran dos eventos que comparten la misma conexión `conn31`:

- **`Successfully authenticated`** que asocia la conexión con el usuario `admin@admin` .
- **`Profiler settings changed`** que registra el cambio de nivel 0 a nivel 1 con filtro sobre `comercial`.

El primero dice quién es la conexión, pero no qué hizo. El segundo dice qué se cambió, pero no quién. La atribución surge de unirlos por `ctx`.

## 2. ¿Qué condición debe cumplirse para que esta correlación sea válida?

Que ambos eventos pertenezcan a **la misma conexión física y a la misma vida del servidor**. El identificador `connN` es un contador que el servidor asigna en orden y que **vuelve a empezar tras cada reinicio**. Si `mongod` se reinicia, `conn31` puede designar a otra conexión, de otro usuario, en otro momento.

## 3. ¿Por qué es relevante que quede registrado un cambio de configuración del propio mecanismo de registro?

Porque quien altera el mecanismo de auditoría puede ocultar lo que haga después.  Las acciones posteriores dejan de quedar registradas. Si ese cambio no dejara huella, un administrador podría reducir la evidencia sin que nadie lo notara.
