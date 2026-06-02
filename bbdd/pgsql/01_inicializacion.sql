--esquemas
    CREATE SCHEMA IF NOT EXISTS core;      -- entidades negocio
    CREATE SCHEMA IF NOT EXISTS links;     -- tablas de union
    CREATE SCHEMA IF NOT EXISTS lookups;   -- enums o referencias
    CREATE SCHEMA IF NOT EXISTS params;    -- db_name, version, etc.
    CREATE SCHEMA IF NOT EXISTS logs;      -- sistema de eventos
    CREATE SCHEMA IF NOT EXISTS reports;   -- vistas de reportes
    CREATE SCHEMA IF NOT EXISTS support;   -- support Antes INTERNAL(conflicto con tablas pg)

    DO $$ BEGIN
        RAISE NOTICE '[INFO] Esquemas creados o verificados con éxito.';
    END $$;

--roles y permisos
    DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app__read_write') THEN
            CREATE ROLE app__read_write NOLOGIN; -- NOLOGIN significa que actúa como grupo, no como usuario
            RAISE NOTICE '[INFO] Se creó el ROL: app__read_write';
        ELSE
            RAISE NOTICE '[WARN] Ya existe el ROL: app__read_write. No se volverá a crear';
        END IF;
    END $$;

    GRANT USAGE ON SCHEMA core, links, lookups, logs, params, reports, support TO app__read_write;

    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA core TO app__read_write;
    GRANT SELECT, INSERT, DELETE ON ALL TABLES IN SCHEMA links TO app__read_write;
    GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA lookups TO app__read_write;
    GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA logs TO app__read_write;
    GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA params TO app__read_write;
    GRANT SELECT ON ALL TABLES IN SCHEMA reports TO app__read_write;
    GRANT SELECT ON ALL TABLES IN SCHEMA support TO app__read_write;

    ALTER DEFAULT PRIVILEGES IN SCHEMA core, reports, support GRANT EXECUTE ON FUNCTIONS TO app__read_write;

    DO $$ BEGIN
        RAISE NOTICE '[INFO] Permisos de esquemas asignados al rol app__read_write.';
    END $$;

--acceso 
    DO $$ BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'db_consumer') THEN
            -- Creamos el usuario con permisos de Login
            CREATE ROLE db_consumer WITH LOGIN PASSWORD 'maconia123';
            RAISE NOTICE '[INFO] Nuevo login creado!!! el usuario "db_consumer" ya puede entrar.';
        ELSE
            RAISE NOTICE '[WARN] Ya existía el Login "db_consumer". No se modificó la contraseña.';
        END IF;
    END $$;

    GRANT app__read_write TO db_consumer;
    ALTER ROLE db_consumer SET search_path TO core, public;

    -- Hacer que los futuros objetos que crees adopten estos mismos permisos automaticamente
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA core GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app__read_write;
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA links GRANT SELECT, INSERT, DELETE ON TABLES TO app__read_write;
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lookups GRANT SELECT, INSERT ON TABLES TO app__read_write;
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA logs GRANT SELECT, INSERT ON TABLES TO app__read_write;
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA params GRANT SELECT, INSERT ON TABLES TO app__read_write;
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA reports GRANT SELECT ON TABLES TO app__read_write;
    ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA support GRANT SELECT ON TABLES TO app__read_write;

    DO $$ BEGIN
        RAISE NOTICE '[DONE] Configuración de acceso para db_consumer completada.';
    END $$;
