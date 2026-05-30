IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

CREATE SCHEMA core AUTHORIZATION dbo; -- entidades negocio
PRINT '[INFO] Se creo el esquema "core"';
GO

CREATE SCHEMA links AUTHORIZATION dbo; -- tablas de union //no tocar, se generan solas al hacer data entry
PRINT '[INFO] Se creo el esquema "links"';
GO

CREATE SCHEMA lookups AUTHORIZATION dbo; -- enums o referencias(monedas, impuestos) //solo se agregan mediante sp
PRINT '[INFO] Se creo el esquema "lookups"';
GO

CREATE SCHEMA params AUTHORIZATION dbo; --  db_name, version, nombre, domicilio, cuit //no tocar
PRINT '[INFO] Se creo el esquema "params"';
GO

CREATE SCHEMA logs AUTHORIZATION dbo; -- sistema de eventos del negocio //no tocar
PRINT '[INFO] Se creo el esquema "logs"';
GO

CREATE SCHEMA reports AUTHORIZATION dbo; -- vistas de reportes //se refresscan solas no tocar
PRINT '[INFO] Se creo el esquema "reports"';
GO

CREATE SCHEMA internal AUTHORIZATION dbo; -- tablas tecnicas o acciones especificas como etl //No tocar en absluto xd
PRINT '[INFO] Se creo el esquema "internal"';
GO


PRINT '[DONE] Schemas listos';
GO
