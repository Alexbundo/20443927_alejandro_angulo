# Actividad 2 — Cifrado de información sensible

## Preguntas

¿Qué diferencia existe entre crypt() y pgp_sym_encrypt()? Crypt sirve para comprobar un dato, no es reversible y tipicamente sirve para verificar contraseñas. pgp sirve para proteger y luego recuperar un dato, llega a hacer reversible con una clave, protege datos que de deben volver a leer por los administradores

¿Cuál de los dos mecanismos permite recuperar el dato original?
solo pgp con la clave pruba para volver a obtener el dato original

¿Qué ocurre si se utiliza una clave incorrecta?
Directamente postgres lanza un error, sin la clave correcta el contenido sigue siendo ilegible y la consulta falla

¿Qué problema de seguridad representa colocar la clave directamente en una consulta?
Seria un problema de gestion de claves, la clave queda expuesta logs del servidor, historial de consultas, codigo fuente y repositorios, trafico de red.
