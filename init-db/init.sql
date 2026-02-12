-- Inicialización de la base de datos SOGo
-- Este script crea la vista de usuarios necesaria para autenticación SQL

-- Tabla de usuarios para autenticación
CREATE TABLE IF NOT EXISTS sogo_users (
    c_uid VARCHAR(255) PRIMARY KEY,
    c_name VARCHAR(255) NOT NULL,
    c_password VARCHAR(255) NOT NULL,
    c_cn VARCHAR(255),
    mail VARCHAR(255)
);

-- Vista que SOGo usa para autenticación (requerida por SOGoUserSources type: sql)
CREATE OR REPLACE VIEW sogo_view AS
    SELECT
        c_uid,
        c_name,
        c_password,
        c_cn,
        mail
    FROM sogo_users;

-- Usuario de prueba (password: test123 en MD5)
-- MD5 de 'test123' = cc03e747a6afbbcbf8be7668acfebee5
INSERT INTO sogo_users (c_uid, c_name, c_password, c_cn, mail)
VALUES ('testuser', 'testuser', '{md5}cc03e747a6afbbcbf8be7668acfebee5', 'Test User', 'testuser@example.com')
ON CONFLICT (c_uid) DO NOTHING;
