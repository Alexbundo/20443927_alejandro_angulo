# Actividad 4

## 1. ¿Qué perdiste de evidencia al aplicar el filtro? ¿Qué ganaste?

### Lo que se perdió

- **Las lecturas.** Con nivel 2 se sabía quién consultó datos y cuándo; ahora una consulta sobre datos sensibles, como la del RFC de un cliente, no deja rastro. Es el mismo hueco que existía en PostgreSQL con `log_statement = 'mod'`.
- **El contexto de la actividad.** Sin las lecturas no se puede reconstruir qué miró una cuenta antes de modificar algo, ni detectar reconocimiento previo a un ataque.
- **La evidencia anterior.** El `drop()` eliminó todo lo acumulado en `system.profile`; si no se exportó, esa evidencia no se recupera.

### Lo que se ganó

- **Menos ruido.** La evidencia relevante, que son los cambios, no queda enterrada entre consultas rutinarias.
- **Menos volumen y más retención efectiva.** `system.profile` es una colección de tamaño fijo que sobrescribe lo más antiguo. Al registrar menos, los cambios permanecen más tiempo antes de perderse.
- **Menos datos sensibles acumulados.** Las consultas con valores literales (correos, RFC) ya no se copian al perfilador, lo que reduce su sensibilidad.

## 2. ¿Qué filtro usarías si solo interesaran operaciones sobre la colección `clientes`?

Se filtra por el campo `ns`, que contiene la base y la colección:

- El perfilador ya es **por base de datos**, así que el filtro por `ns` sirve para distinguir colecciones dentro de `comercial`. Hay que activarlo en cada base que se quiera cubrir.
- Si interesara registrar solo las operaciones sobre `clientes` de ciertos usuarios, se puede añadir `user: "app_ventas@comercial"` al filtro. Conviene no excluir a los administradores: las acciones de `admin` son justamente las que más importa vigilar.
- Conviene verificar el filtro con `db.getProfilingStatus()` y probarlo con una operación de cada tipo antes de confiar en él.
