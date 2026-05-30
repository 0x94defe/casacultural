CREATE OR ALTER PROCEDURE internal.sp_Setup__regen_database AS
	BEGIN
		SET NOCOUNT ON;

		IF DB_NAME() = 'Achiras' -- solo valido en 'AchirasTest'
			THROW 50001, 'No permitido en Produccion', 1;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;


		EXEC internal.sp_Load__datos_personas;
		PRINT '[INFO] sp_Load__datos_personas ejecutado';
		EXEC internal.sp_Update__Vinculos
		PRINT '[INFO] sp_Update__Vinculos ejecutado';
		EXEC internal.sp_Update__Pago_preferido
		PRINT '[INFO] sp_Update__Pago_preferido ejecutado';


		EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name; 
	  	EXEC sp_set_session_context @key = N'Origen', @value = NULL;
	    
		PRINT '[DONE] Base de datos regenerada';
	END
PRINT '[INFO] sp_Setup__regen_database creada';
GO
