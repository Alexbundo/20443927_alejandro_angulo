# Actividad 10 — Crear una política mínima de protección de claves

Regla 1. Generación con fuentes seguras.

Las claves deben generarse con un generador de números aleatorios criptográficamente seguro (KMS, gen_random_bytes()), con longitud y algoritmo acordes a estándares vigentes (AES-256 para cifrado simétrico). Nunca se derivarán de palabras, nombres o contraseñas humanas. Cada clave tendrá un solo propósito (cifrar RFC, cifrar respaldos, firmar tokens) y un identificador de versión, para que la compromisión de una no afecte a las demás.

Regla 2. Acceso por mínimo privilegio, con identidad propia y trazabilidad.

Solo las aplicaciones y personas con necesidad demostrada podrán usar una clave, mediante identidades individuales (nunca cuentas compartidas). Se separarán los permisos de usar la clave (cifrar/descifrar) de los de administrarla (crear, rotar, eliminar), de modo que ninguna persona tenga ambos. Todo acceso quedará registrado en bitácoras de auditoría que se revisen periódicamente.

Regla 3. Almacenamiento exclusivo en un sistema de custodia, separado de los datos.

Las claves solo residirán en un gestor de secretos, KMS o HSM . No se guardarán en scripts SQL, código fuente, archivos de configuración versionados, tablas de la base de datos ni en el mismo servidor o respaldo que los datos que protegen. Si alguien obtiene la base de datos, no debe obtener automáticamente la llave.

Regla 4. Rotación periódica y por evento.

Cada clave tendrá una vigencia máxima definida (por ejemplo, 12 meses para claves de datos) y se rotará además de inmediato ante: salida de personal con acceso, sospecha de compromiso o cambio de proveedor. La rotación incluirá recifrar los datos con la nueva versión y conservar la anterior, de forma restringida y solo de descifrado, hasta completar la migración.

Regla 5. Respaldo cifrado, fragmentado y probado.
Las claves tendrán una copia de recuperación independiente de los respaldos de datos, cifrada con una clave maestra, en ubicación distinta y con acceso que requiera la autorización de al menos dos personas. Se probará periódicamente la restauración, porque una clave perdida equivale a datos perdidos para siempre.

Regla 6. Revocación inmediata y con plan de contingencia.
Cuando una clave se declare comprometida, se desactivará de inmediato para nuevas operaciones, se emitirá una clave sustituta y se recifrarán los datos afectados. Se evaluará el alcance, es decir, qué datos, respaldos y réplicas dependían de ella, y se documentará el incidente. Toda clave tendrá un responsable asignado, con autoridad para ordenar la revocación.
