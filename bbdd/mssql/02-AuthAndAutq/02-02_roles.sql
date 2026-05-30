IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app__read_write' AND type = 'R')
	BEGIN
	    CREATE ROLE app__read_write;

	    PRINT '[INFO] Se creo el ROL: app__read_write';
	END
ELSE
	BEGIN
		PRINT '[WARN] Ya existe el ROL: app__read_write. No se volvera a crear';
	END
GO

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE 	ON SCHEMA::core     	TO app__read_write;
PRINT '[INFO] Se otorgo SELECT, INSERT, UPDATE, DELETE, EXECUTE para esquema "core"';
GO

GRANT SELECT, INSERT, DELETE					ON SCHEMA::links    	TO app__read_write;
PRINT '[INFO] Se otorgo SELECT, INSERT, DELETE para esquema "links"';
GO

GRANT SELECT, INSERT            		 		ON SCHEMA::lookups  	TO app__read_write;
PRINT '[INFO] Se otorgo SELECT, INSERT para esquema "lookups"';
GO

GRANT SELECT, INSERT	                   		ON SCHEMA::logs     	TO app__read_write;
PRINT '[INFO] Se otorgo SELECT, INSERT para esquema "logs"';
GO

GRANT SELECT, INSERT                    		ON SCHEMA::params   	TO app__read_write;
PRINT '[INFO] Se otorgo SELECT, INSERT para esquema "params"';
GO

GRANT SELECT, EXECUTE					   		ON SCHEMA::reports 		TO app__read_write;
PRINT '[INFO] Se otorgo SELECT, EXECUTE para esquema "reports"';
GO

GRANT SELECT, EXECUTE 							ON SCHEMA::internal 	TO app__read_write;
PRINT '[INFO] Se otorgo SELECT, EXECUTE para esquema "reports"';
GO


PRINT '[DONE] Roles listos';
GO
