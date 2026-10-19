# Preguntas

¿La conexión actual utiliza TLS?
No, ya que el campo que muestra si se utiliza, muestra un false y en version y cipher aparece null por que no utiliza SSL/TLS.

¿Qué versión de TLS se está utilizando?
Ninguna

¿Qué algoritmo de cifrado aparece?
Ninguno, ya que al tratarse de una conexión sin TLS/SSL, la sesión no establece ningún mecanismo de cifrado de red y los datos se transmiten en texto plano.

¿Qué diferencia existe entre una conexión protegida con TLS y una conexión sin TLS?
En la conexión con TLS los datos que viajan entre el cliente y el servidor de la base de datos viajan de manera cifrada de extremo a extremo y en la conexión sin TLS los datos viajan en texto plano a través de la red y cualquier persona puede monitorear o interceptar el tráfico de la red y puede leer las credenciales de acceso.
