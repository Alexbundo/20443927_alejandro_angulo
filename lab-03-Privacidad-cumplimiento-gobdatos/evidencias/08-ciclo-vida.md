# clientes (tabla principal)

│
├── tablas relacionadas (dentro de la misma base)
│   ├── pedidos / ventas / resumen_compras
│   ├── facturas y datos fiscales (conservación obligatoria)
│   ├── consentimientos / preferencias de contacto
│   ├── tickets y conversaciones de soporte
│   └── clientes_soporte (copia reducida para atención)
│
├── respaldos
│   ├── backups completos e incrementales
│   └── snapshots y archivos de recuperación (WAL)
│
├── réplicas
│   ├── réplicas de lectura / alta disponibilidad
│   └── ambientes de pruebas o desarrollo con copias de producción
│
├── bitácoras y auditoría
│   ├── logs de acceso y de consultas
│   └── registros de cambios (auditoría)
│
├── analítica
│   ├── vistas y tablas derivadas (v_analitica_clientes)
│   ├── data warehouse / data lake
│   └── datasets de campañas de marketing
│
├── exportaciones
│   ├── CSV / Excel descargados por usuarios
│   ├── reportes en PDF o correo electrónico
│   └── carpetas compartidas y equipos locales
│
└── sistemas externos
    ├── plataforma de envío de correos o campañas
    ├── CRM, mesa de ayuda, facturación electrónica (PAC)
    └── proveedores y encargados del tratamiento

## ¿Existen otras tablas relacionadas?

El DELETE falla por integridad, o borra en cascada datos que debían conservarse (como los fiscales), o deja datos huérfanos.

## ¿Existen respaldos?

Frecuencia, retención y ubicación de los backups. El dato sigue en el respaldo y reaparece al restaurar.

## ¿Existen réplicas?

Réplicas de lectura, ambientes de prueba, copias para desarrollo. El dato persiste en otro servidor, a veces con menos controles.

## ¿Existen registros de auditoría?

Logs que contengan nombre, correo, RFC o consultas con esos valores. Los datos personales quedan dentro de los logs.

## ¿Existen copias utilizadas para analítica?

Si no estaban anonimizados, el dato sigue identificando a la persona.

## ¿Existen archivos exportados?

CSV, reportes, adjuntos de correo, equipos locales. Es la copia más difícil de rastrear y de controlar.

## ¿Existen sistemas externos?

Plataforma de correo, CRM, proveedores. La empresa sigue siendo responsable del dato aunque lo tenga un tercero.

## ¿Por qué eliminar un registro de una tabla no necesariamente significa que toda la información relacionada con esa persona haya desaparecido de la organización?

Porque la base de datos no guarda el dato en un solo lugar. Un DELETE solo quita la fila de la tabla principal en el sistema en producción; las demás copias no se enteran. Las razones concretas:

## Actividad 9 — Derecho de oposición

Supongamos que un cliente solicita que sus datos no sean utilizados para una determinada finalidad secundaria.

Analiza:

¿Es necesario eliminar inmediatamente todos sus datos de la base?
La oposición y la cancelación son derechos distintos. El cliente no pidió que se borre todo, sino que sus datos dejen de usarse para una finalidad concreta (por ejemplo, promociones personalizadas). Eso obliga a detener ese tratamiento, no a eliminar el registro completo.
Si se borrara todo, además de exceder lo pedido, la empresa podría perder datos que necesita para atender y facturar al cliente, o que debe conservar por ley. La respuesta correcta es limitar el uso, no suprimir.

Explica:

qué información podría necesitar mantenerse?
id,nombre,correo y telefono, rfc,codigo postal, fecha_alta

qué información podría dejar de utilizarse para determinada finalidad?
Para la finalidad secundaria objetada, el cliente debe quedar excluido de:
Las listas y campañas de promociones.
La segmentación y el perfilamiento (edad, ciudad, comportamiento de compra con fines comerciales).
Los datasets y exportaciones de Marketing.
Los envíos a proveedores de correo o plataformas de campañas.
Los datos siguen existiendo, pero ya no pueden usarse para ese propósito. El correo, por ejemplo, sigue sirviendo para enviar una factura, pero no para una promoción.

qué mecanismos técnicos podrían separar finalidades
Roles y permisos separados: Marketing solo consulta la vista, nunca clientes.
Lista de exclusión (“no contactar”) que se verifica antes de cada campaña y se sincroniza con proveedores externos.
Propagación a copias: réplicas, analítica y plataformas de envío deben recibir la exclusión.
Bitácora de la solicitud y de su aplicación, para acreditar el cumplimiento.
Separación física o lógica de datos por finalidad cuando el riesgo lo justifique (por ejemplo, tablas distintas para soporte y para marketing).

por qué la decisión final no debe ser tomada únicamente por el DBA
El DBA es quien sabe cómo implementar el bloqueo, pero no quien debe decidir si procede ni qué alcance tiene. Es una decision juridica, se necesita conocer al negocio, esta separado de sus funciones
