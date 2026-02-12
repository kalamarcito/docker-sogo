-- Inicialización de la base de datos SOGo
-- SOGo crea sus propias tablas automáticamente, pero necesitamos asegurar permisos

-- Asegurar que el usuario sogo tiene todos los permisos
GRANT ALL PRIVILEGES ON DATABASE sogo TO sogo;
GRANT ALL PRIVILEGES ON SCHEMA public TO sogo;

-- Permitir crear tablas
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO sogo;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO sogo;
