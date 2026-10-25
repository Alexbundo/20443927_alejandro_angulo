# Inventario de datos

## Tabla resuelta

| Campo | ¿Es dato personal? | Finalidad | ¿Es necesario? | Nivel de acceso | Retención |
| --- | --- | --- | --- | --- | --- |
| id | Sí (indirecto) | Identificar de forma única al cliente y relacionar registros | Sí | Atención: Lectura · Facturación: Lectura · Analítica: Sin acceso al id real (identificador seudonimizado) · DBA: Técnico | Mientras exista la relación; se elimina o desvincula al darse de baja |
| nombre | Sí | Identificar al cliente en la atención y como receptor en la factura | Sí | Atención: Lectura · Facturación: Lectura · Analítica: Sin acceso · DBA: Técnico | Relación + 5 años (soporte fiscal y contractual) |
| correo | Sí | Contactar al cliente y, en su caso, enviarle comprobantes | Sí | Atención: Lectura · Facturación: Lectura solo si la factura se envía por correo; si no, sin acceso · Analítica: Sin acceso · DBA: Técnico | Mientras exista la relación; se elimina al baja (salvo obligación legal) |
| telefono | Sí | Contacto directo para atención y seguimiento | Condicional (solo para atención) | Atención: Lectura · Facturación: Sin acceso · Analítica: Sin acceso · DBA: Técnico | Mientras exista la relación; se elimina al baja |
| rfc | Sí (alta sensibilidad en la práctica) | Emitir facturas y cumplir obligaciones fiscales | Sí, para facturación (condicional para el resto de la base: solo clientes que requieren factura) | Atención: Enmascarado, solo si necesita verificar al cliente · Facturación: Lectura · Analítica: Sin acceso · DBA: Técnico, con campo cifrado | 5 años (plazo fiscal); después eliminación o bloqueo |
| edad | Sí | Segmentación estadística (y verificar mayoría de edad si el negocio lo exige) | No para atención ni facturación; sí para analítica, en rangos | Atención: Sin acceso · Facturación: Sin acceso · Analítica: Agregado (rangos de edad) · DBA: Técnico | Relación activa; para analítica, conservar solo rangos agregados |
| ciudad | Sí (indirecto) | Dar contexto básico en la atención y generar estadísticas por zona | Sí para analítica; condicional para atención | Atención: Lectura · Facturación: Sin acceso · Analítica: Agregado · DBA: Técnico | Relación activa; en analítica, conservar solo agregada |
| codigo_postal | Sí (indirecto) | Domicilio fiscal en la factura y estadísticas por zona | Sí para facturación (si es el domicilio fiscal); condicional para analítica | Atención: Sin acceso · Facturación: Lectura · Analítica: Agregado · DBA: Técnico | Relación + 5 años si se usa como dato fiscal; en analítica, solo agregado |
| fecha_alta | No por sí sola; se protege al estar ligada al cliente | Calcular antigüedad, plazos de retención y estadísticas de altas | Sí | Atención: Lectura · Facturación: Sin acceso · Analítica: Agregado (por mes o año) · DBA: Técnico | Mientras exista el registro; es la base para calcular plazos de retención |

## Justificación de cada decisión

### id

- **¿Dato personal?** Sí, de forma indirecta: no revela nada por sí mismo, pero apunta a un cliente identificable al combinarse con el resto de los campos.
- **Finalidad:** es el identificador interno que permite que Atención y Facturación trabajen sobre el mismo cliente y que se atiendan solicitudes ARCO.
- **¿Necesario?** Sí, es un requisito técnico de la base.
- **Acceso:** Atención y Facturación lo requieren para localizar registros. Analítica no necesita saber *quién* es cada cliente, por lo que debe recibir un identificador seudonimizado (o ninguno), no el `id` real. El DBA lo gestiona por razones técnicas (índices, integridad).
- **Retención:** acompaña la vida de la cuenta; al eliminarla se desvincula o elimina.

### nombre

- **¿Dato personal?** Sí, es el identificador más directo de una persona.
- **Finalidad:** identificar al cliente en la atención y aparecer como receptor en la factura.
- **¿Necesario?** Sí para ambos procesos.
- **Acceso:** lo consultan Atención y Facturación, porque ambos lo mencionan expresamente. Analítica no lo necesita porque trabaja sin identificar individuos, y dárselo contradiría el principio de proporcionalidad. El DBA solo tiene acceso técnico.
- **Retención:** durante la relación y 5 años después, ya que forma parte del soporte de comprobantes fiscales.

### correo

- **¿Dato personal?** Sí, identifica y permite contactar a la persona.
- **Finalidad:** comunicarse con el cliente en la atención y, si aplica, enviar la factura electrónica.
- **¿Necesario?** Sí, es parte de la información de contacto que Atención consulta.
- **Acceso:** Atención lo lee. Facturación lo necesita solo si la empresa envía facturas por correo; si el envío se hace por otro medio, no debería verlo. Analítica no, porque no identifica clientes.
- **Retención:** mientras el cliente tenga relación con la empresa; se elimina al darse de baja salvo obligación legal.
- **Uso:** el correo recolectado para atención y facturación no debe usarse para marketing sin consentimiento específico.

### telefono

- **¿Dato personal?** Sí, permite identificar y localizar a la persona.
- **Finalidad:** contacto directo en atención al cliente.
- **¿Necesario?** Condicional: solo lo requiere Atención. Facturación no lo menciona entre sus necesidades.
- **Acceso:** únicamente Atención en lectura. Facturación y Analítica no tienen razón para verlo.
- **Retención:** mientras dure la relación; se elimina al baja o si el cliente retira el consentimiento.

### rfc

- **¿Dato personal?** Sí, y de alta sensibilidad en la práctica: vincula a la persona con su situación fiscal y facilita fraude o suplantación.
- **Finalidad:** emitir facturas (CFDI) y cumplir obligaciones fiscales.
- **¿Necesario?** Sí para Facturación. Idealmente solo debería capturarse a clientes que soliciten factura.
- **Acceso:** Facturación en lectura. Atención solo lo necesitaría enmascarado, por ejemplo para confirmar la identidad del cliente sin ver el dato completo. Analítica no, porque no necesita identificar a nadie. El DBA gestiona el campo cifrado, sin descifrarlo para usos funcionales.
- **Retención:** 5 años, conforme al plazo general de conservación de comprobantes y contabilidad del Código Fiscal de la Federación. Después, eliminación o bloqueo seguro.

### edad

- **¿Dato personal?** Sí, es información sobre una persona identificada.
- **Finalidad:** estadísticas de segmentación; y, solo si el negocio lo exige, comprobar mayoría de edad.
- **¿Necesario?** No para Atención ni Facturación; sí para Analítica, pero en **rangos** (18-25, 26-35, etc.) y no como edad exacta.
- **Acceso:** Analítica solo agregado. Los demás procesos no tienen una necesidad declarada.
- **Retención:** mientras dure la relación; para estadística se conservan solo los rangos agregados.

### ciudad

- **¿Dato personal?** Sí, de forma indirecta: junto con otros campos ayuda a identificar a la persona.
- **Finalidad:** contexto básico en la atención y estadísticas por zona.
- **¿Necesario?** Sí para analítica; condicional para atención ("información básica del cliente").
- **Acceso:** Atención en lectura, Analítica solo agregada. Facturación no lo usa, porque lo fiscal se resuelve con el domicilio fiscal.
- **Retención:** mientras dure la relación; en analítica se conserva agregada o anonimizada.

### codigo_postal

- **¿Dato personal?** Sí, indirecto: es una ubicación aproximada que puede reidentificar combinada con otros datos.
- **Finalidad:** domicilio fiscal en la factura y estadísticas geográficas.
- **¿Necesario?** Sí para Facturación, siempre que sea el código postal del domicilio fiscal del cliente. Si el campo de la base es otro tipo de domicilio, el dato fiscal debe guardarse aparte.
- **Acceso:** Facturación en lectura; Analítica solo agregado. Atención no lo necesita para su función.
- **Retención:** 5 años cuando se usa como dato fiscal; en analítica, solo agregado.

### fecha_alta

- **¿Dato personal?** Por sí sola no, pero al estar ligada a un cliente identificable se protege como parte de su registro.
- **Finalidad:** conocer la antigüedad del cliente, calcular los plazos de retención y generar estadísticas de altas.
- **¿Necesario?** Sí, es clave para cumplir las políticas de conservación y demostrar responsabilidad.
- **Acceso:** Atención la consulta (antigüedad del cliente); Analítica la usa agregada por mes o año. Facturación no la necesita.
- **Retención:** mientras exista el registro; sirve de punto de partida para contar los plazos.

## Actividad 2 — Principio de minimización

### 1. ¿Todos los campos son necesarios para atención al cliente?

No. Según lo que Atención necesita consultar (nombre, correo, teléfono e información básica), la tabla tiene campos de sobra.

### 2. ¿Por qué soporte necesitaría conocer el RFC?

En principio, no lo necesita. El RFC es un dato fiscal cuya finalidad es la facturación, y esa finalidad le corresponde a otra área. Tenerlo en la tabla de soporte aumenta el riesgo sin aportar nada a la atención: si alguien con acceso lo filtra o lo usa mal, facilita fraude y suplantación de identidad.

Si en algún caso soporte debe confirmar la identidad del cliente, basta con mostrarlo enmascarado  o validar con otro dato, sin exponer el RFC completo.

### 3. ¿Necesita conocer la edad?

No. Para resolver una consulta o incidencia, la edad no influye. Su uso razonable está en Analítica y, aun ahí, en rangos (18-25, 26-35, etc.) y de forma agregada.

### 4. ¿Necesita conocer el código postal?

Tampoco. En este escenario el código postal sirve para el domicilio fiscal en la factura (Facturación) y para estadísticas por zona (Analítica). Para soporte, la ciudad ya da el contexto básico que necesita. El código postal es además una ubicación más precisa que, combinada con nombre y otros datos, ayuda a identificar a una persona.

### 5. ¿Qué principio de privacidad está relacionado con esta decisión?

El principio de proporcionalidad, también llamado minimización de datos: solo debe tratarse la información necesaria, adecuada y relevante para la finalidad que se persigue. Aquí la finalidad es atender al cliente, y los datos que no sirven para eso no deben estar en esa tabla.

## Actividad 3

### Pregunta

¿Por qué esta información puede ser más apropiada para analítica que entregar directamente la tabla completa de clientes? Respuesta corta

Porque estas consultas entregan resultados agregados (cuántos clientes hay por ciudad y por rango de edad) y no registros individuales. Analítica necesita estadísticas, no saber quién es cada cliente, así que darle la tabla completa le expondría datos que no necesita.

## Actividad 4

### Preguntas

¿Qué información puede consultar el rol? La consulta final contra information_schema.role_table_grants mostraría dos filas: SELECT sobre v_analitica_clientes y SELECT sobre clientes.
¿Puede consultar directamente clientes? Sí, tal como está el script, por GRANT SELECT ON clientes TO analista. Sin esa línea, no podría: en PostgreSQL la vista se ejecuta con los permisos de su propietario, así que analista puede leer la vista sin tener permiso sobre la tabla base.
¿Puede obtener nombre, correo y RFC? Sí, tal como está: SELECT nombre, correo, rfc FROM clientes; funcionaría. Con el permiso revocado, recibiría permission denied for table clientes.
¿Qué principio de privacidad estás aplicando? La minimización de datos (proporcionalidad): la vista expone solo lo necesario para estadística, y convierte la edad exacta en un rango. También refleja el principio de finalidad: Analítica recibe lo que su propósito requiere y nada más.
Pero ese principio queda incumplido mientras exista el acceso directo a clientes.
¿Qué principio de seguridad estás aplicando? El mínimo privilegio (least privilege): el rol recibe solo los permisos necesarios. Se complementa con need-to-know (acceso solo a lo que se necesita saber) y con aplicar el control en la propia base de datos y no confiar en que el analista no consulte lo que no debe.
