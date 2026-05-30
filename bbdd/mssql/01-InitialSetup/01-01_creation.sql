USE master;
GO

IF DB_ID('Achiras') IS NOT NULL
BEGIN
    PRINT '[WARN] Base de datos "Achiras" ya existe. Procediendo a recrear...';

    ALTER DATABASE Achiras SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Achiras;

	IF DB_ID('Achiras') IS NOT NULL
        THROW 51000, '[ERROR] No se pudo eliminar "Achiras". Script abortado.', 1;

    PRINT '[INFO] Base de datos anterior eliminada.';
END;
GO

CREATE DATABASE Achiras
ON 
    (
        NAME = 'Achiras_Data',
        FILENAME = 'C:\Achiras\Achiras_data.mdf',
        SIZE = 512MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 128MB
    )
LOG ON
    (
        NAME = 'Achiras_Log',
        FILENAME = 'C:\Achiras\Achiras_log.ldf',
        SIZE = 128MB,
        MAXSIZE = 1024MB,
        FILEGROWTH = 64MB
    )
COLLATE Modern_Spanish_100_CI_AI;

PRINT '[INFO] Base de datos "Achiras" creada con exito!!';
GO


PRINT '[DONE] Creacion Lista';
GO
