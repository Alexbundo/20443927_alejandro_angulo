# 1. Con esta configuración, ¿se registra quién se conecta?

**No.** `log_connections = off` y `log_disconnections = off`: las conexiones exitosas y sus desconexiones no dejan línea en la bitácora. Solo quedarían errores graves, como un `FATAL: password authentication failed`, y aun así sin usuario ni IP de forma sistemática, porque el prefijo no los incluye.

## 2. ¿Se registran las sentencias `UPDATE`?

**No.** `log_statement = none` (valor por defecto) implica que ninguna sentencia se registra por sí misma. Un `UPDATE` solo aparecería si fallara, porque `log_min_error_statement = error` incluye el texto de la sentencia que produjo un error. Un `UPDATE` exitoso, como el que cambió el RFC de María García, **no deja rastro**.

## 3. ¿La línea de bitácora incluye el usuario o la dirección IP del cliente?

**No.** `log_line_prefix = '%t'` solo escribe la **fecha y hora** (sin milisegundos). Faltan:

| Marcador | Dato | Estado |
| --- | --- | --- |
| `%u` | Usuario | No incluido |
| `%d` | Base de datos | No incluido |
| `%a` | `application_name` | No incluido |
| `%h` | IP del cliente | No incluido |
| `%p` | PID del proceso | No incluido |

## 4. ¿En qué zona horaria se registran los eventos? ¿Por qué importa al reconstruir una cronología?

**`America/Chihuahua`**, fijada explícitamente en el archivo de configuración.

Importa porque:

1. **Correlación entre fuentes.** El log, `auditoria_clientes.fecha` (`timestamptz`), el firewall, los logs de la aplicación y el sistema operativo pueden usar zonas distintas. Sin conocer cada una, un evento puede parecer ocurrir horas antes o después de otro, e invertir causa y efecto (por ejemplo, un intento fallido que aparenta ser posterior al cambio).
2. **Validez como evidencia.** Un informe forense debe indicar la zona de cada fuente y convertirlas a una referencia común, preferiblemente UTC.

## 5. Con `logging_collector = off`, ¿quién decide dónde termina la bitácora: PostgreSQL o el mecanismo con que se desplegó el servidor?

**El mecanismo con que se desplegó el servidor**, no PostgreSQL.

Con el colector apagado, PostgreSQL no gestiona archivos de log: solo escribe en la salida de error estándar . Lo que ocurre con ese flujo depende de quien lanzó el proceso:
**En este laboratorio** el colector está `on`, así que PostgreSQL decide: escribe en `C:/Program Files/PostgreSQL/17/data/log/`
