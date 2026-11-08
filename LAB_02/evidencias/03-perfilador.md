# Actividad 3

## 1. ¿Puedes saber cuál era el RFC antes del cambio con la información de `system.profile`?

No. El documento de `update` registra el comando (`q: { _id: 3 }` y `u: { $set: { rfc: 'GAMA780912XYZ' } }`), es decir, el valor **nuevo**, pero no el anterior.Solo indica que se modificó un documento (`nModified: 1`).

## 2. ¿Puedes saber qué datos tenía el documento eliminado?

No. El documento de `remove` solo conserva el filtro (`q: { _id: 2 }`) y el contador (`ndeleted: 1`). Prueba que se eliminó un documento con `_id: 2`, quién lo hizo, cuándo y desde dónde, pero no su contenido: nombre, correo, teléfono, RFC y demás campos desaparecieron sin dejar copia.

## 3. A diferencia de `log_statement = 'mod'` en PostgreSQL, el nivel 2 sí registró la consulta. ¿Qué ventaja y qué riesgo tiene eso?

**Ventaja.** Se obtiene evidencia de las **lecturas**, que en PostgreSQL quedaban sin rastro con `mod`. Permite saber quién consultó qué y cuándo. Además el registro viene estructurado (usuario, cliente, aplicación, documentos examinados y devueltos, duración), lo que facilita filtrarlo y analizarlo con consultas, y sirve también para diagnosticar rendimiento.

**Riesgo.**

**Datos sensibles en el registro.** El comando se guarda con sus valores literales: filtros, valores nuevos y proyecciones. Un `update` con un RFC o un `find` con un correo dejan esos datos en `system.profile`, que pasa a ser una copia parcial de la información sensible y debe protegerse igual que `clientes`. Cualquier rol con lectura sobre `system.profile` los ve.

## 4. ¿Por qué el campo `user` incluye `@comercial`?

Porque en MongoDB la identidad de un usuario es el par **nombre + base de datos de autenticación**, no solo el nombre. `app_ventas@comercial` significa que el usuario `app_ventas` está definido en la base `comercial`, que es la que lo autentica. Pueden existir dos usuarios con el mismo nombre en bases distintas, y serían cuentas totalmente diferentes, con credenciales y roles propios. Por ejemplo, `admin@admin` no es lo mismo que `admin@comercial`.
