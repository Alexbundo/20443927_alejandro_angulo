# Activad 5: Analizar una finalidad secundaria

1. ¿El hecho de que la organización ya tenga los datos significa automáticamente que puede utilizarlos para cualquier finalidad?
Tener los datos no equivale a tener permiso para usarlos. Los datos se recabaron para atender y facturar a los clientes, y esas son las finalidades que el aviso de privacidad les informó. Las promociones personalizadas son una finalidad secundaria: no es necesaria para la relación comercial y, por eso, requiere un análisis propio

2. ¿Qué preguntas debería realizar la organización antes de implementar este tratamiento?
¿Quién accederá a los datos, con qué permisos y con qué registro?
¿Se compartirán con terceros (agencias, plataformas de envío)? Eso exige transferencias informadas y contratos.
¿Cuánto tiempo se conservarán los perfiles y cómo se atenderán las solicitudes de baja?
¿Se incluye a menores de edad? En ese caso no debería hacerse perfilamiento comercial.
¿Qué se busca lograr exactamente? ¿Se puede lograr con menos datos o con datos agregados?
¿Los clientes dieron su consentimiento, o tuvieron la opción de negarse? ¿Cómo se registra esa decisión?

3. ¿Qué datos serían realmente necesarios?
Medio de contacto, edad, ciudad, comportamiento de compras, estatus de consentimiento

4. ¿Necesitaría el área de marketing acceso directo a clientes?
La tabla contiene datos que Marketing no necesita (RFC, código postal, etc.) y darle acceso directo contradice la minimización y el mínimo privilegio. Debe recibir únicamente una vista o extracto con los campos mínimos, solo de los clientes que no se opusieron al tratamiento. Además, el acceso de Marketing es de lectura sobre esa vista, nunca sobre la tabla base.
5. ¿Qué controles técnicos podrían limitar la información entregada?
Tablas de consentimiento, Rol propio de Marketing con mínimo privilegio, sin permisos sobre la tabla base ni sobre el RFC.
Seudonimización: que la herramienta de campañas reciba un identificador sustituto y solo reciba el correo en el momento del envío, generalización y resumen rangos de edad y categorías de compra en lugar de valores exactos o detallados, cifrado y enmascaramiento de los campos sensibles que permanecen en la base.
