-- backups
	--se necesita previamente
	IF @@VERSION LIKE '%express%'
	    THROW 50001, 'SQL Server Agent NO esta disponible en version express', 1;

	IF NOT EXISTS (SELECT 1
	    		   FROM sys.dm_server_services
	    		   WHERE servicename LIKE 'SQL Server Agent%'
	      		   AND status_desc = 'Running')
	    THROW 50001, 'SQL Server Agent NO esta en ejecucion. No se pueden crear ni ejecutar jobs de backup.', 1;

	ALTER DATABASE Achiras SET RECOVERY FULL;
----------------------------------------------------------------------------
IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

--WITH INIT: sobrescribe
--WITH NORECOVERY: en este momento no acepta transacciones

	-- uso
	-- full
	BACKUP DATABASE Achiras
	TO DISK = 'C:\Achiras\Backups\Achiras_FULL.bak'
	WITH INIT;
	-- differential
	BACKUP DATABASE Achiras
	TO DISK = 'C:\Achiras\Backups\Achiras_DIFF.bak'
	WITH DIFFERENTIAL;
	-- log tran
	BACKUP LOG Achiras
	TO DISK = 'C:\Achiras\Backups\Achiras_LOG.trn'
	WITH INIT;
	--tail log si hace falta una vez que recuperes la db de un crash
	BACKUP LOG Achiras
	TO DISK = 'C:\Achiras\Backups\Achiras_TAIL.trn'
	WITH NORECOVERY;

-- restauracion
	RESTORE DATABASE Achiras
	FROM DISK = 'FULL.bak'
	WITH NORECOVERY;

	RESTORE DATABASE Achiras
	FROM DISK = 'DIFF.bak'
	WITH NORECOVERY;

	RESTORE LOG Achiras
	FROM DISK = 'LOG1.trn'
	WITH NORECOVERY;

	RESTORE LOG Achiras
	FROM DISK = 'LOG2.trn'
	WITH NORECOVERY;

	RESTORE DATABASE Achiras
	WITH RECOVERY;

	--punto exacto
	RESTORE LOG Achiras
	FROM DISK = 'LOG.trn'
	WITH STOPAT = '2024-11-03 14:37:00', RECOVERY;
