CREATE OR ALTER PROCEDURE internal.sp_Setup__init_database AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		DECLARE @err_msg VARCHAR(128) = CONCAT('[ERROR] ', @sp_name, ' ya fue ejecutado.');
	  	IF internal.fn_Verificar__Ejecucion_Proceso(@sp_name, 1) IS NOT NULL
			THROW 50000, @err_msg, 1;

		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;

		BEGIN TRY
		  	BEGIN TRAN;
			  	EXEC internal.sp_Setup__free_metadata;
			  	PRINT '[INFO] sp_Setup__free_metadata ejecutado';

			  	EXEC internal.sp_Setup__clean_database;
			  	PRINT '[INFO] sp_Setup__clean_database ejecutado';

					EXEC internal.sp_Load__datos_configuracion;
					PRINT '[INFO] sp_Load__datos_configuracion ejecutado';

					EXEC internal.sp_Load__datos_referenciales;
					PRINT '[INFO] sp_Load__datos_referenciales ejecutado';

					EXEC internal.sp_Setup__regen_database;
					PRINT '[INFO] sp_Setup__regen_database ejecutado';
			COMMIT;
			  
			EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name, 1; 
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			    
			PRINT '[DONE] Base de datos totalmente operativa!!';
		END TRY
		BEGIN CATCH
		  IF XACT_STATE() <> 0 ROLLBACK;
		  EXEC sp_set_session_context @key = N'Origen', @value = NULL;
		  PRINT '[ERROR] Algo anda mal orquestando los sp del setup';
		  THROW; 
		END CATCH
	END;
PRINT '[INFO] sp_Setup__init_database creada';
GO
