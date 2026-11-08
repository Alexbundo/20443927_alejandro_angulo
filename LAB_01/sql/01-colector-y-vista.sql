/* 6.3 */
CREATE DATABASE comercial;

SELECT version();
SHOW data_directory;
SHOW config_file;
SHOW hba_file;
SELECT pg_reload_conf();
/* 6.4 */
SELECT line_number, type, database, user_name, address, auth_method
FROM pg_hba_file_rules
WHERE database = '{all}';

/* 6.5 */
CREATE TABLE clientes (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(150) NOT NULL,
    telefono VARCHAR(20),
    rfc VARCHAR(13),
    edad INTEGER,
    ciudad VARCHAR(80),
    codigo_postal VARCHAR(10),
    fecha_alta DATE DEFAULT CURRENT_DATE
);

INSERT INTO clientes (nombre, correo, telefono, rfc, edad, ciudad, codigo_postal) VALUES
('Ana López', 'ana.lopez@example.test', '6671234567', 'LOAA850315ABC', 41, 'Culiacán', '80000'),
('Carlos Pérez', 'carlos.perez@example.test', '6672345678', 'PECA900720DEF', 35, 'Culiacán', '80100'),
('María García', 'maria.garcia@example.test', '6673456789', 'GAMA780912GHI', 47, 'Mazatlán', '82000'),
('Luis Torres', 'luis.torres@example.test', '6674567890', 'TOLU920201JKL', 34, 'Los Mochis', '81200'),
('Laura Sánchez', 'laura.sanchez@example.test', '6675678901', 'SALA880525MNO', 38, 'Culiacán', '80200');

CREATE ROLE app_ventas  LOGIN PASSWORD 'Seguridad2026';
CREATE ROLE soporte_ale LOGIN PASSWORD 'Seguridad2026';

/* PARTE A 7 ACT.1*/
SELECT name, setting, source
FROM pg_settings
WHERE name IN ('log_destination', 'logging_collector', 'log_directory', 'log_filename',
               'log_connections', 'log_disconnections', 'log_line_prefix',
               'log_statement', 'log_min_error_statement', 'log_timezone')
ORDER BY name;

/* 8. ACT2 */
SELECT pg_reload_conf();
ALTER SYSTEM SET logging_collector = on;
ALTER SYSTEM SET logging_collector = on;
SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'logging_collector';

SELECT linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n') AS linea;
SELECT name, setting, source FROM pg_settings WHERE name = 'logging_collector';
SELECT pg_current_logfile();

CREATE SCHEMA dba;
REVOKE ALL ON SCHEMA dba FROM PUBLIC;

CREATE VIEW dba.bitacora AS
SELECT t.n AS num, t.linea
FROM regexp_split_to_table(pg_read_file(pg_current_logfile()), E'\n')
     WITH ORDINALITY AS t(linea, n)
WHERE t.linea <> '';
-- últimas 10 líneas
SELECT num, linea FROM dba.bitacora ORDER BY num DESC LIMIT 10;

-- líneas que contienen un texto, sin distinguir mayúsculas
SELECT linea FROM dba.bitacora WHERE linea ILIKE '%update%';

-- líneas que cumplen una expresión regular
SELECT linea FROM dba.bitacora WHERE linea ~ '(FATAL|ERROR)';
SELECT name, context
FROM pg_settings