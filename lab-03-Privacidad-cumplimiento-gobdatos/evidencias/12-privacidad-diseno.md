# Preguntas

## ¿Qué problemas identificas?

Datos de alto riesgo sin necesidad: salario, estado_civil y ocupacion son información patrimonial y personal que expone mucho al titular, y los datos financieros o patrimoniales suelen requerir consentimiento expreso. Duplicidad entre campos: edad y fecha_nacimiento son redundantes, y direccion se solapa con ciudad y codigo_postal.

## ¿Qué principio de privacidad se está ignorando?

El de proporcionalidad o minimización de datos: solo debe recolectarse lo necesario, adecuado y relevante para la finalidad.

## ¿Qué preguntas realizarías antes de aprobar el diseño?

¿Para qué se usará exactamente cada campo? ¿Qué función de la app deja de funcionar si no existe? ¿Se puede lograr lo mismo con menos datos, o con un dato menos invasivo? ¿Qué pasa si este dato se filtra? ¿Qué daño causaría al titular? ¿Cuánto tiempo se conservará cada dato y qué se hará al terminar?

## ¿Qué datos eliminarías?

salario, ocupacion, edad, direccion, estado_civil.

## ¿Qué datos requerirían una justificación adicional?

rfc, direccion, telefono, ocupacion, salario. La justificación debe documentarse: finalidad, necesidad, fundamento, quién accede y por cuánto tiempo.

## ¿Cómo aplicarías privacidad por defecto?

La privacidad por defecto significa que, si nadie decide nada, el sistema ya es el más protector. Concretamente:

- Recolección mínima por defecto: el formulario de registro pide solo lo indispensable; lo demás es opcional y se solicita en el momento en que se necesita.
- Consentimientos en “no” por defecto: las finalidades secundarias (promociones, perfilamiento) se activan solo si el cliente lo acepta expresamente, sin casillas premarcadas.
- Separación de datos por finalidad: los datos fiscales en una tabla aparte, accesible solo para Facturación.
- Acceso mínimo por defecto: los roles no reciben permisos sobre la tabla base, solo sobre vistas con las columnas que necesitan.
- Protección de campos sensibles: cifrado del RFC y enmascaramiento al mostrarlo.
- Retención desde el inicio: campos de fecha de alta y baja, y un proceso automático de bloqueo y supresión al vencer el plazo.
- Perfil público o visible mínimo: si la app muestra información, mostrar solo lo básico por defecto.

## Actividad 13 — Diferenciar controles técnicos y administrativos

|Medida|Técnico|Administrativo|
|---|---|---|
|Crear roles de PostgreSQL|✔||
|Política de retención||✔|
|Cifrado de datos|✔||
|Procedimiento para solicitudes ARCO||✔|
|Vista con información limitada|✔||
|Clasificación de información||✔|
|Registro de auditoría|✔|✔|
|Política de control de acceso||✔|
