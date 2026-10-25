# Informe final: Privacidad y protección de datos personales en bases de datos

## 1. Introducción

En este trabajo analicé el caso de una empresa que guarda información de unos 50,000 clientes en una base de datos. El problema que encontré es que la base se administraba pensando solo en que "funcione", pero no en qué datos realmente se necesitan ni quién debería verlos.

Algunos ejemplos:

- Todo el personal de Analítica podía consultar directamente la tabla clientes, aunque solo genera estadísticas.
- Los datos se conservaban desde hacía 12 años sin una política de retención.
- Los desarrolladores recibían copias completas de la base con información real.
- Marketing usaba los correos para promociones sin que estuviera claro para qué se recolectaron.
- No había documentación de la finalidad de cada dato.

## 2. Inventario de datos

La tabla principal tiene estos campos. Los clasifiqué según qué tanto identifican a la persona y qué tan riesgosos son si se filtran.

| Dato | Tipo | Clasificación | Comentario |
| --- | --- | --- | --- |
| id | Identificador interno | Dato personal indirecto, riesgo bajo | Por sí solo no dice nada, pero apunta a una persona al unirse con otros datos |
| nombre | Identificación | Dato personal directo, riesgo medio | Identifica a la persona de forma inmediata |
| correo | Contacto | Dato personal directo, riesgo medio | Sirve para contactar y también para phishing si se filtra |
| telefono | Contacto | Dato personal directo, riesgo medio | Permite localizar a la persona |
| rfc | Fiscal | Dato personal, **riesgo alto** | Vincula a la persona con su situación fiscal; facilita fraude y suplantación |
| edad | Demográfico | Dato personal, riesgo medio | Más riesgoso si se combina con otros datos |
| ciudad | Ubicación | Dato personal indirecto, riesgo bajo | Reidentifica al combinarse con otros campos |
| codigo_postal | Ubicación | Dato personal indirecto, riesgo bajo a medio | Más preciso que la ciudad |
| fecha_alta | Técnico | Metadato, riesgo bajo | Sirve para calcular antigüedad y plazos de retención |

## 3. Finalidades

Cada dato debe tener una finalidad concreta. Lo que propongo es lo siguiente:

| Finalidad | Tipo | Datos que se justifican |
| --- | --- | --- |
| Atención al cliente | Primaria | nombre, correo, telefono, ciudad (contexto) |
| Facturación | Primaria | nombre, rfc, código postal fiscal |
| Estadísticas (Analítica) | Primaria interna | edad (en rangos), ciudad, fecha_alta, solo agregados |
| Promociones personalizadas (Marketing) | **Secundaria** | correo y segmentos, solo si el cliente lo acepta |

La idea principal es que **tener los datos no autoriza a usarlos para cualquier cosa**. Las finalidades primarias son necesarias para la relación con el cliente. Las secundarias, como las promociones, deben informarse en el aviso de privacidad y el cliente debe poder aceptarlas o rechazarlas sin perder el servicio principal.

## 4. Minimización

| Dato | Decisión | Por qué |
| --- | --- | --- |
| rfc | Limitar | Solo se necesita para facturar; no debe verlo Atención ni Analítica (como mucho, enmascarado) |
| edad | Generalizar | Analítica solo necesita rangos (18-29, 30-44...), no la edad exacta |
| codigo_postal | Limitar | Solo se justifica para el domicilio fiscal; para soporte basta la ciudad |
| ciudad | Evaluar | Es en parte redundante con el código postal, hay que decidir si conservar ambos |
| telefono | Condicional | Solo si de verdad se usa para atención |
| nombre, correo | Mantener | Son necesarios para atender y facturar, pero con acceso limitado |

## 5. Control de acceso

Para relacionar permisos con funciones, primero identifiqué qué necesita cada área para trabajar y a partir de eso asigné el acceso.

| Rol | Qué necesita | Acceso propuesto |
| --- | --- | --- |
| Atención al cliente | Contactar y atender | nombre, correo, teléfono, ciudad; RFC enmascarado |
| Facturación | Emitir facturas | nombre, RFC, código postal fiscal |
| Analítica | Estadísticas | Solo vista agregada (sin datos individuales) |
| Dirección | Tomar decisiones | Solo indicadores agregados |
| Marketing | Campañas (si hay consentimiento) | Vista con correo y segmento, solo de quienes aceptaron |
| DBA | Administrar técnicamente | Acceso técnico (respaldos, rendimiento, integridad); no usa los datos para ninguna finalidad |

## 6. Derechos ARCO

Los derechos de acceso, rectificación, cancelación y oposición tienen implicaciones técnicas que como DBA debo considerar:

1. **Localizar al titular:** se necesita un identificador único para encontrar sus datos en todas las tablas.
2. **Mapa de datos:** hay que saber en qué lugares existe la información: tablas relacionadas, respaldos, réplicas, entornos de desarrollo, reportes, exportaciones y sistemas externos.
3. **Cancelación:** no basta hacer un `DELETE`. Primero hay un bloqueo y después la supresión, y algunos datos (como los fiscales) deben conservarse por obligación legal. Un `DELETE` borra solo una copia, y las demás siguen existiendo.
4. **Oposición:** si el cliente se opone a una finalidad (por ejemplo, promociones), no se borran todos sus datos: se deja de usar para esa finalidad. Esto se resuelve con una tabla de consentimientos y vistas que filtran a quienes se opusieron.
5. **Rectificación:** debe poder corregirse el dato sin perder historial de auditoría.
6. **Acceso:** debe poder generarse un reporte con los datos del titular, tras verificar su identidad.
7. **Evidencia:** hay que registrar cuándo llegó la solicitud, quién la atendió y qué se hizo, y cuidar los plazos de respuesta.

## 7. Retención

El periodo de conservación no debería escogerse al azar ni "indefinido por si sirve". Para determinarlo, la organización debería revisar:

1. **La finalidad de cada dato:** si ya terminó la finalidad, ya no hay razón para conservarlo.
2. **Las obligaciones legales:** por ejemplo, los datos fiscales se conservan alrededor de 5 años (a validar con el área jurídica).
3. **Las obligaciones contractuales y posibles reclamaciones:** cuánto tiempo puede ser necesario tener evidencia.
4. **El tipo de dato y su riesgo:** el RFC debería tener un tratamiento más estricto que la ciudad.
5. **Alternativas:** si el dato solo sirve para estadística, se puede anonimizar o conservar agregado en lugar de identificable.
6. **Qué se hará al vencer el plazo:** bloqueo, supresión o anonimización, incluyendo respaldos y réplicas.

## 8. Gobierno de datos

Esta es la matriz de responsabilidades:

| Dato | Finalidad | Responsable | Usuarios autorizados | Protección | Retención | Acción al finalizar |
| --- | --- | --- | --- | --- | --- | --- |
| **nombre** | Identificar al cliente en la atención y en la factura | Atención al cliente | Atención (lectura), Facturación (lectura), DBA (técnico) | Control por rol, TLS, bitácora | Relación + 5 años | Bloqueo y supresión |
| **correo** | Contacto y envío de comprobantes | Atención al cliente | Atención (lectura), Facturación (si envía facturas por correo), DBA (técnico) | Control por rol, cifrado en tránsito, no usar en promociones sin consentimiento | Mientras dure la relación | Supresión y exclusión de listas |
| **telefono** | Contacto directo para atención | Atención al cliente | Atención (lectura), DBA (técnico) | Control por rol, bitácora | Mientras dure la relación | Supresión |
| **rfc** | Facturación y obligaciones fiscales | Facturación / Contabilidad | Facturación (lectura), Atención (enmascarado), DBA (técnico, cifrado) | Cifrado en reposo y tránsito, enmascaramiento, acceso restringido | 5 años | Bloqueo y luego supresión o anonimización |
| **edad** | Estadísticas | Analítica | Analítica y Dirección (agregado), DBA (técnico) | Generalización en rangos, vista de solo lectura | Relación; en estadística solo rangos | Eliminar dato individual, conservar agregado |
| **ciudad** | Contexto en atención y estadísticas por zona | Analítica | Atención (lectura), Analítica y Dirección (agregado), DBA (técnico) | Control por rol, umbral mínimo por grupo | Relación; en analítica solo agregada | Eliminar dato individual, conservar agregado |
| **codigo_postal** | Domicilio fiscal y estadísticas por zona | Facturación | Facturación (lectura), Analítica (agregado), DBA (técnico) | Igual que RFC si es dato fiscal; umbral mínimo en analítica | Relación + 5 años si es fiscal | Bloqueo, supresión o anonimización |

El **responsable** es el área dueña del dato, la que decide para qué se usa. El DBA aparece siempre como acceso **técnico**, porque administra la base pero no decide ni usa los datos para una finalidad propia.

## 9. Evaluación integral

Estos son los principales riesgos que encontré en el escenario:

| # | Problema | Principio afectado | Riesgo | Control propuesto |
| --- | --- | --- | --- | --- |
| 1 | Analítica consulta directamente `clientes` | Minimización, mínimo privilegio | Acceso a datos individuales innecesarios | Vista agregada y revocar acceso a la tabla base |
| 2 | Analítica ve nombre, correo, teléfono y RFC | Proporcionalidad, finalidad | Exposición de datos que no usa | Excluir identificadores de su vista |
| 3 | Datos conservados 12 años | Proporcionalidad (tiempo) | Mayor impacto si hay una brecha | Depuración por categoría y plazo |
| 4 | No hay política de retención | Responsabilidad | No se puede justificar la conservación | Política documentada por dato y finalidad |
| 5 | Desarrolladores reciben copias completas | Proporcionalidad, seguridad | Acceso innecesario a datos reales | Datos sintéticos o enmascarados |
| 6 | Copias de desarrollo con información real | Seguridad | Fuga desde entornos con menos controles | Enmascarar antes de copiar |
| 7 | Marketing usa correos para promociones | Finalidad, consentimiento | Tratamiento secundario sin base clara | Verificar aviso de privacidad, registrar consentimiento |
| 8 | No hay documentación de finalidades | Finalidad, responsabilidad | No se pueden justificar accesos | Inventario y matriz de gobierno |
| 9 | Difícil atender solicitudes ARCO | Derechos ARCO | Cancelaciones que no llegan a todas las copias | Mapa de datos y procedimiento formal |
| 10 | RFC sin protección especial (posible) | Seguridad | Exposición en claro | Cifrado y enmascaramiento |
| 11 | Falta de auditoría de accesos (posible) | Responsabilidad | No se detectan consultas indebidas | Bitácoras y revisión periódica |
| 12 | Datos antiguos desactualizados (posible) | Calidad | Envíos equivocados y decisiones erróneas | Actualización y depuración |

## 10. Conclusiones

Después de hacer estas actividades entendí varias cosas:

1. **Seguridad y privacidad no son lo mismo.** La seguridad protege los datos contra accesos indebidos, pero la privacidad también pregunta si esos datos debían recolectarse, usarse y conservarse.
2. **El diseño de la base de datos es una decisión de privacidad.** Qué columnas existen, cómo se separan las tablas y qué vistas se crean determinan en la práctica quién ve qué.
3. **El DBA ejecuta, pero no decide solo.** Tiene el acceso técnico, pero la finalidad y el plazo de retención son decisiones de la organización, con el área jurídica y el responsable de privacidad.
4. **Los datos existen en más lugares de los que parece.** Respaldos, réplicas, exportaciones y entornos de prueba también cuentan, y por eso borrar una fila no basta.
5. **Menos datos es menos riesgo.** Lo más efectivo para proteger un dato es no tenerlo, o tenerlo solo el tiempo y con el detalle necesarios.
6. **Las medidas técnicas y administrativas se complementan.** Un rol o un cifrado sirven poco si no hay políticas, responsables y procedimientos que los respalden.

## 11. Preguntas de reflexión

### 1. ¿Una base de datos técnicamente segura necesariamente cumple con todos los requisitos de privacidad?

No. Una base puede tener cifrado, contraseñas fuertes y firewall, y aun así incumplir la privacidad. Por ejemplo, si guarda datos que no necesita, si los usa para una finalidad que no se informó al cliente, si los conserva demasiado tiempo o si le da acceso a personas que no lo requieren. La seguridad protege los datos de terceros no autorizados, mientras que la privacidad regula también **cómo los usa la propia organización**.

### 2. ¿Por qué el principio de mínimo privilegio también contribuye a la privacidad?

Porque si cada rol solo puede ver lo que necesita, se reduce la cantidad de personas que tienen acceso a los datos personales. Eso baja el riesgo de uso indebido, filtración o error, y respeta la proporcionalidad: se accede solo a lo necesario para la función. Por ejemplo, Analítica no necesita el RFC, así que no debería poder verlo aunque técnicamente sea posible.

### 3. ¿Por qué el DBA no debería decidir por sí solo la finalidad del tratamiento de los datos?

Porque la finalidad es una decisión legal y de negocio, no técnica. El DBA tiene acceso técnico a la base, pero eso no lo autoriza a decidir para qué se usan los datos. Además, no conoce necesariamente las obligaciones legales ni las necesidades de cada área, y es sano separar funciones: quien decide no es quien ejecuta. La decisión corresponde a la organización (responsable de privacidad, jurídico y el dueño del dato), y el DBA la implementa.

### 4. ¿Por qué los desarrolladores no deberían recibir automáticamente copias completas de bases de datos productivas?

Porque normalmente no necesitan datos reales para desarrollar o probar. Darles una copia completa aumenta el número de personas con acceso a información personal sin una necesidad justificada, y viola la minimización. Además, los entornos de desarrollo suelen tener menos controles que producción. Lo adecuado es darles datos sintéticos o enmascarados.

### 5. ¿Por qué una copia utilizada para desarrollo también puede representar un riesgo de privacidad?

Porque una copia con datos reales sigue siendo información personal, aunque esté en otro entorno. Puede estar en laptops, repositorios o servidores con menos seguridad, y puede perderse, filtrarse o usarse para otra cosa. Además, complica los derechos ARCO: si un cliente pide cancelar sus datos, también habría que eliminarlos de esas copias, y a veces ni se sabe dónde están.

### 6. ¿Por qué la retención debe formar parte del ciclo de vida de los datos?

Porque los datos no deben guardarse para siempre: tienen un inicio (recolección), un uso y un fin. Si no se define cuánto tiempo se conservan y qué se hace al terminar, se acumulan datos innecesarios que aumentan el riesgo y el costo, y se incumple la proporcionalidad en su dimensión de tiempo. Incluir la retención en el ciclo de vida permite planear desde el inicio el bloqueo, la supresión o la anonimización.

### 7. ¿Qué relación existe entre privacidad por diseño y diseño de bases de datos?

Es una relación directa: privacidad por diseño significa incorporar la protección desde el inicio, y en una base de datos eso se hace al diseñarla. Decisiones como qué columnas crear, separar datos fiscales de los de contacto, definir roles y vistas, agregar campos para controlar la retención o crear una tabla de consentimientos son decisiones de diseño que aplican los principios de privacidad. Es mucho más fácil hacerlo desde el principio que corregirlo después.

### 8. ¿Qué controles técnicos implementarías para reducir el riesgo de exposición de datos personales?

- **Roles y vistas** por función, con mínimo privilegio y sin acceso directo a la tabla base.
- **Cifrado** en reposo (por ejemplo, del RFC y los respaldos) y en tránsito (TLS).
- **Enmascaramiento** de datos sensibles al mostrarlos.
- **Agregación y generalización** de datos para analítica, con un mínimo de registros por grupo.
- **Datos sintéticos o enmascarados** para desarrollo y pruebas.
- **Bitácoras de auditoría** de accesos y exportaciones, con alertas ante consultas masivas.
- **Procesos de depuración** automáticos según la política de retención.
- **Respaldos cifrados** y con retención limitada.
- **Separación de tablas por finalidad**, por ejemplo, datos fiscales aparte.

### 9. ¿Qué información debería conocer un DBA para responder técnicamente a una solicitud ARCO?

- **Dónde está el dato:** tablas, columnas, relaciones, respaldos, réplicas, entornos de prueba, reportes, exportaciones y sistemas externos.
- **Cómo identificar al titular:** el identificador único y cómo se relaciona con las demás tablas.
- **Qué debe conservarse por ley** (por ejemplo, datos fiscales) y qué puede suprimirse o bloquearse.
- **Qué finalidades tiene el dato y qué consentimientos existen**, para poder aplicar una oposición.
- **Cómo funcionan las llaves foráneas** y las eliminaciones en cascada, para no romper la integridad ni borrar de más.
- **Cómo funciona el respaldo** y su retención, para saber qué pasa con las copias.
- **La decisión del área responsable:** si la solicitud procede y con qué alcance.
- **Cómo documentar** lo realizado, para dejar evidencia.

### 10. ¿Qué responsabilidades deberían corresponder al DBA, al responsable de privacidad, al área jurídica y al propietario de los datos?

| Rol | Responsabilidades |
| --- | --- |
| **DBA** | Implementar técnicamente los controles (roles, vistas, cifrado, respaldos, bitácoras); ejecutar las depuraciones y bloqueos autorizados; mantener la integridad y la seguridad de la base; no decidir ni usar los datos para finalidades propias |
| **Responsable de privacidad** | Coordinar el cumplimiento; evaluar y decidir las solicitudes ARCO; mantener el aviso de privacidad, el inventario y la matriz de gobierno; supervisar auditorías |
| **Área jurídica** | Interpretar la normativa; definir obligaciones de conservación y plazos de respuesta; revisar el aviso de privacidad, los consentimientos y los contratos con terceros |
| **Propietario de los datos (área dueña)** | Definir la finalidad y la necesidad del dato; autorizar quién accede; proponer plazos de retención desde la operación; responder por el uso correcto de los datos de su área |

Lo importante es que las decisiones sobre el tratamiento se tomen entre estas partes y el DBA las ejecute, para que haya separación de funciones y se pueda demostrar quién decidió qué.
