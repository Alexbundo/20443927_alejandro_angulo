# Tabla de comparacion

| Situación | Mecanismo apropiado | ¿Qué protege? |
| --- | --- | --- |
| Contraseña de usuario | Hash con salt | La contraseña contra lectura directa y reutilización en caso de fuga |
| RFC almacenado en una tabla | Cifrado simétrico o asimétrico según el caso | La confidencialidad del documento o dato almacenado |
| Consulta enviada desde un cliente al servidor | TLS/SSL | La confidencialidad e integridad de la comunicación en tránsito |
| Respaldo de una base de datos | Cifrado de datos en reposo | Los datos almacenados del respaldo ante robo o acceso no autorizado |
| Clave criptográfica | Gestión segura de claves y almacenamiento en KMS/HSM | La confidencialidad de la propia protección criptográfica |
