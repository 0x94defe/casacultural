CREATE OR ALTER PROCEDURE core.sp_Repatronar_socio(@nro_socio INT) AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		IF NOT EXISTS (SELECT 1 FROM core.Socios WHERE nro_socio = @nro_socio)
			THROW 50000, '[ERROR] No existe ese socio', 1;
		IF EXISTS (SELECT 1 FROM core.Socios WHERE nro_socio = @nro_socio AND fecha_baja IS NULL)
			THROW 50000, '[ERROR] El socio NO ESTA DADO de baja', 1;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;


		DECLARE @TranCount INT = @@TRANCOUNT;
		BEGIN TRY
			IF @TranCount = 0 BEGIN TRAN;
				DECLARE @fecha_baja_anterior DATE, @motivo_baja_anterior VARCHAR(100);
				SELECT 
					@fecha_baja_anterior = fecha_baja,
					@motivo_baja_anterior = motivo_baja
				FROM core.Socios 
				WHERE nro_socio = @nro_socio;

				INSERT INTO logs.Bitacora(evento, entidad_afectada, id_afectada, detalle)
				SELECT 
					'SOCIO_ALTA',
					'Socio', CAST(@nro_socio AS VARCHAR(10)),
					CONCAT(
						'Repatronamos el socio. ',
						'Motivo baja anterior: ',
						COALESCE(@motivo_baja_anterior, '[NULL]'),
						'. Fecha baja anterior: ',
						CAST(@fecha_baja_anterior AS VARCHAR(10))
					)

				UPDATE s SET
					s.fecha_baja = NULL,
					s.motivo_baja = NULL
				FROM core.Socios s
				WHERE s.nro_socio = @nro_socio;
			IF @TranCount = 0 COMMIT;

			EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			PRINT '[INFO] Socio repatronado con exito';
		END TRY
		BEGIN CATCH
			IF @TranCount = 0 ROLLBACK;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			PRINT '[ERROR] Algo anda mal con la rutina repatronar socio';
			THROW;
		END CATCH
	END;
GO
PRINT '[DONE] sp_Repatronar_socio Listos';