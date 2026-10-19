/* 6. Preparación */
SELECT * FROM clientes;
/*comprobacion de la extension*/
SELECT extname FROM pg_extension
WHERE extname = 'pgcrypto';
/*7. Actividad 1 — Protección de credenciales*/
/*Una implementación incorrecta sería:*/
CREATE TABLE usuarios_insegura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL
);
/*usuario de prueba*/
INSERT INTO usuarios_insegura (usuario, password)
VALUES ('juan', 'Password123');
SELECT * FROM usuarios_insegura;
/*7.3 Generar una representación no reversible*/
SELECT crypt(
    'Password123',
    gen_salt('bf')
);
SELECT crypt(
    'Password123',
    gen_salt('bf')
);
/*7.4 Crear una tabla para credenciales protegidas*/
CREATE TABLE usuarios_segura (
    id BIGSERIAL PRIMARY KEY,
    usuario VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL
);
/*Insertar usuario*/
INSERT INTO usuarios_segura (usuario, password_hash)
VALUES (
    'juan',
    crypt('Password123', gen_salt('bf'))
);
SELECT * FROM usuarios_segura;
/*7.5 Verificar una contraseña*/
SELECT
    usuario,
    password_hash = crypt('Password123', password_hash)
        AS contraseña_correcta
FROM usuarios_segura
WHERE usuario = 'juan';
/*PROBAR CON CONTRASEÑA INCORRECTA*/
SELECT
    usuario,
    password_hash = crypt('OtraPassword', password_hash)
        AS contraseña_correcta
FROM usuarios_segura
WHERE usuario = 'juan';