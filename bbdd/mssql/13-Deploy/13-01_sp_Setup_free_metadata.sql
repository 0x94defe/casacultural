CREATE OR ALTER PROCEDURE internal.sp_Setup__free_metadata AS
	BEGIN
		SET NOCOUNT ON;

		IF DB_NAME() = 'Achiras' -- solo valido en 'AchirasTest'
			THROW 50001, 'No permitido en Produccion', 1;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;


		DELETE FROM params.Feriados;
		DELETE FROM params.Plataforma;
		DELETE FROM params.Organizacion;

		DELETE FROM logs.Conexiones_de_Usuarios;
		DELETE FROM params.Usuarios_del_Sistema;

		DELETE FROM internal.Diccionario_Centinelas;
		DELETE FROM internal.Patch_Log;
		DELETE FROM internal.Patch_Queue;
		DELETE FROM internal.Control_de_Procesos;
		DELETE FROM internal.Migration_Log;


		DECLARE @maxId INT;

		DBCC CHECKIDENT ('logs.Conexiones_de_Usuarios', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM logs.Conexiones_de_Usuarios;
		PRINT '[INFO] Reseed a logs.Conexiones_de_Usuarios: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('params.Usuarios_del_Sistema', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM params.Usuarios_del_Sistema;
		PRINT '[INFO] Reseed a params.Usuarios_del_Sistema: ' + CAST(@maxId AS VARCHAR(10));
		------------------------------------------------------------------------
		DBCC CHECKIDENT ('internal.Diccionario_Centinelas', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM internal.Diccionario_Centinelas;
		PRINT '[INFO] Reseed a internal.Diccionario_Centinelas: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('internal.Patch_Log', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM internal.Patch_Log;
		PRINT '[INFO] Reseed a internal.Patch_Log: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('internal.Patch_Queue', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM internal.Patch_Queue;
		PRINT '[INFO] Reseed a internal.Patch_Queue: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('internal.Control_de_Procesos', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM internal.Control_de_Procesos;
		PRINT '[INFO] Reseed a internal.Control_de_Procesos: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('internal.Migration_Log', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM internal.Migration_Log;
		PRINT '[INFO] Reseed a internal.Migration_Log: ' + CAST(@maxId AS VARCHAR(10));


		EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name; 
	  	EXEC sp_set_session_context @key = N'Origen', @value = NULL;
	    
		PRINT '[DONE] Metadata limpia';
	END
PRINT '[INFO] sp_Setup__free_metadata creada';
GO
