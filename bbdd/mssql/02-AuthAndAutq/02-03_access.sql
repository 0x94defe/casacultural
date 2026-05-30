IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'budibase')
	BEGIN
    	PRINT '[WARN] Ya existia Login "budibase". No se creo nada';
  	END
ELSE
	BEGIN
		CREATE LOGIN budibase WITH PASSWORD = 'XXXXXXX';

		PRINT '[INFO] Nuevo login creado!!! el usuario "budibase" ya puede entrar a la base de datos.';
	END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Achiras_user__budibase')
	BEGIN
    	CREATE USER Achiras_user__budibase FOR LOGIN budibase WITH DEFAULT_SCHEMA = core;

    	PRINT '[INFO] Usuario "budibase" ya puede entrar a "Achiras"';
	END
ELSE
	BEGIN
		PRINT '[WARN] Ya existia un Usuario "budibase". No se creo nada';
	END

ALTER ROLE app__read_write ADD MEMBER PhiDatabase_user__budibase;
PRINT '[INFO] Login "budibase" fue otorgado con el rol: app__read_write';
GO

GRANT VIEW DEFINITION TO PhiDatabase_user__budibase;
PRINT '[INFO] Se otorgo VIEW DEFINITION para que budibase pueda listar todos los esquemas';
GO


PRINT '[DONE] Acceso listo';
GO
