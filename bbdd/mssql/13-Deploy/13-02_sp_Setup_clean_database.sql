CREATE OR ALTER PROCEDURE internal.sp_Setup__clean_database AS
	BEGIN
		SET NOCOUNT ON;

		IF DB_NAME() = 'Achiras' -- solo valido en 'AchirasTest'
			THROW 50001, 'No permitido en Produccion', 1;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;


		DELETE FROM logs.Notificaciones;
		DELETE FROM logs.Bitacora;
		DELETE FROM reports.Cuotas_Pivot;
		DELETE FROM reports.Pagos_Pivot;

		DELETE FROM core.Comprobantes;
		DELETE FROM core.Detalles_del_Pago;
		DELETE FROM core.Pagos;

		DISABLE TRIGGER links.tg_Grupos_con_Personas__master_trigger ON links.Grupos_con_Personas;
		DELETE FROM links.Grupos_con_Personas;
		ENABLE TRIGGER links.tg_Grupos_con_Personas__master_trigger ON links.Grupos_con_Personas;
		DELETE FROM core.Grupos;
		
		DELETE FROM links.Personas_con_Actividades;
		DELETE FROM core.Actividades;

		DELETE FROM core.Cuotas;
		DELETE FROM core.Socios;
		DELETE FROM core.Personas;

		DELETE FROM core.Nacionalidad;
		DELETE FROM core.Ciudad;
		DELETE FROM lookups.Origenes_de_Cobro;
		DELETE FROM lookups.Tipos_de_Pago;

		
		DECLARE @maxId INT;

		DBCC CHECKIDENT ('logs.Notificaciones', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM logs.Notificaciones;
		PRINT '[INFO] Reseed a logs.Notificaciones: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('logs.Bitacora', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM logs.Bitacora;
		PRINT '[INFO] Reseed a logs.Bitacora: ' + CAST(@maxId AS VARCHAR(10));

		DBCC CHECKIDENT ('core.Comprobantes', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Comprobantes;
		PRINT '[INFO] Reseed a core.Comprobantes: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('core.Detalles_del_Pago', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Detalles_del_Pago;
		PRINT '[INFO] Reseed a core.Detalles_del_Pago: ' + CAST(@maxId AS VARCHAR(10));

		DBCC CHECKIDENT ('core.Pagos', RESEED, -1); --------------------------------------------------OJO!!!!
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Pagos;
		PRINT '[INFO] Reseed a core.Pagos: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('core.Grupos', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Grupos;
		PRINT '[INFO] Reseed a core.Grupos: ' + CAST(@maxId AS VARCHAR(10));

		DBCC CHECKIDENT ('core.Actividades', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Actividades;
		PRINT '[INFO] Reseed a core.Actividades: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('core.Socios', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Socios;
		PRINT '[INFO] Reseed a core.Socios: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('core.Personas', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Personas;
		PRINT '[INFO] Reseed a core.Personas: ' + CAST(@maxId AS VARCHAR(10));

		DBCC CHECKIDENT ('core.Nacionalidad', RESEED, 0); -------------------------------------------------- Nuevo
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Nacionalidad;
		PRINT '[INFO] Reseed a core.Nacionalidad: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('core.Ciudad', RESEED, 0); -------------------------------------------------- Nuevo
		SELECT @maxId = ISNULL(MAX(id), 0) FROM core.Ciudad;
		PRINT '[INFO] Reseed a core.Ciudad: ' + CAST(@maxId AS VARCHAR(10));

		DBCC CHECKIDENT ('lookups.Origenes_de_Cobro', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM lookups.Origenes_de_Cobro;
		PRINT '[INFO] Reseed a lookups.Origenes_de_Cobro: ' + CAST(@maxId AS VARCHAR(10));
		DBCC CHECKIDENT ('lookups.Tipos_de_Pago', RESEED, 0);
		SELECT @maxId = ISNULL(MAX(id), 0) FROM lookups.Tipos_de_Pago;
		PRINT '[INFO] Reseed a lookups.Tipos_de_Pago: ' + CAST(@maxId AS VARCHAR(10));


		EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name; 
	  	EXEC sp_set_session_context @key = N'Origen', @value = NULL;
	    
		PRINT '[DONE] Base de datos limpia';
	END
PRINT '[INFO] sp_Setup__clean_database creada';
GO
