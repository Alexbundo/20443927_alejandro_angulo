SHOW ssl;
-- MOSTRAR EL PROTOCOLO DE SSL
SHOW ssl_min_protocol_version;
-- CONSULTAR EL PUERTO
SHOW port;
-- CONSULTAR QUE DIRECCIONES ESCUCHA
SHOW listen_addresses;
-- VERIFICAR LA CONEXIÓN ACTUAL
SELECT
    inet_client_addr(),
    inet_client_port();
-- VERIFICAR SI LA SESIÓN ACTUAL USA TLS
SELECT
    ssl,
    version,
    cipher
FROM pg_stat_ssl
WHERE pid = pg_backend_pid();