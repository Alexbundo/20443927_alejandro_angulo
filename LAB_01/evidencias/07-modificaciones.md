# Modificaciones

## 1. ¿Qué nivel habría registrado la lectura del RFC? ¿Qué costo tendría en un servidor con miles de consultas por minuto?

El nivel que habría registrado la lectura es **`all`**, que registra todas las sentencias, incluidos los `SELECT`. Ni `ddl` ni `mod` lo hacen. Como alternativa más fina, la extensión `pgaudit` permite registrar solo las lecturas de ciertas tablas o de ciertos roles (por ejemplo, solo `SELECT` sobre `clientes`), sin registrar todo lo demás.

## 2. ¿Qué le falta a esta bitácora para revertir el cambio con certeza?

Le falta el **valor anterior**. La línea registrada dice que el teléfono se fijó en `6679990000`, pero no dice qué contenía antes, y sin ese dato no se puede restaurar el estado original con certeza. Es lo mismo que ocurre con el RFC: la bitácora del servidor es un registro de acciones, no un historial de datos.
