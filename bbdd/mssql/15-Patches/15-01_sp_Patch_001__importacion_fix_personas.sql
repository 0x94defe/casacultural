CREATE OR ALTER PROCEDURE internal.sp_Patch_001__importacion_fix_personas AS
 	BEGIN
 		SET XACT_ABORT ON; 

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		DECLARE @err_msg VARCHAR(128) = CONCAT('[ERROR] ', @sp_name, ' ya fue ejecutado.');
	  	IF internal.fn_Verificar__Ejecucion_Proceso(@sp_name, 1) IS NOT NULL
			THROW 50000, @err_msg, 1;

		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;

		DECLARE @TranCount INT = @@TRANCOUNT;
		BEGIN TRY
			IF @TranCount = 0 BEGIN TRAN;
				CREATE TABLE internal.Temp_Patch
				(
				    dni INT PRIMARY KEY,
				    new_fnac DATE NULL,
				    patch_fnac BIT DEFAULT 0,
				    new_ciudad VARCHAR(128) NULL,
				    patch_ciudad BIT DEFAULT 0
				);

				INSERT INTO internal.Temp_Patch(dni, new_fnac, patch_fnac) VALUES
					(11111111, '2021-09-27', 1);
				INSERT INTO internal.Temp_Patch(dni, new_ciudad, patch_ciudad) VALUES
					(22222222, NULL, 1), (33333333, NULL, 1);

				INSERT INTO internal.Patch_Queue (sp_patch_name, sp_to_patch_name, comment) VALUES
					(@sp_name, 'sp_Importar__Personas', 'Patch manual');
			IF @TranCount = 0 COMMIT;

			EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name, 1;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;

			PRINT '[INFO] Parcheadas las personas';
		END TRY
		BEGIN CATCH
			IF @TranCount = 0 ROLLBACK;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			PRINT '[ERROR] Algo anda mal con el parcheo de Personas';
			THROW;
		END CATCH
 	END;
PRINT '[INFO] sp_Patch_001__importacion_fix_personas creada';
GO
