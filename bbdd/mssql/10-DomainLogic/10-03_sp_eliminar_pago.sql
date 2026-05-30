CREATE OR ALTER PROCEDURE core.sp_Eliminar__pago(@nro_socio INT, @periodo DATE) AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		IF NOT EXISTS (SELECT 1 FROM core.Socios WHERE nro_socio = @nro_socio)
			THROW 50000, '[ERROR] No existe ese socio', 1;
		IF NOT EXISTS (SELECT 1 FROM core.Detalles_del_Pago WHERE nro_socio = @nro_socio AND periodo_pago = @periodo)
			THROW 50000, '[ERROR] Existe socio pero NO existe ese periodo', 1;
		--por ahora voy a aplicar esta regla, quizas mas adelante se pueda
		IF (SELECT COUNT(*) FROM core.Detalles_del_Pago WHERE nro_socio = @nro_socio AND periodo_pago >= @periodo) <> 1
			THROW 50000, '[ERROR] Esta rutina solo puede usarse para ultimos pagos', 1;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;


		DECLARE @TranCount INT = @@TRANCOUNT;
		BEGIN TRY
			IF @TranCount = 0 BEGIN TRAN;
				DECLARE @id_detalle_pago_afectado INT, @id_pago_afectado INT, @monto_de_ese_pago DECIMAL(10,2);
				SELECT 
					@id_detalle_pago_afectado = id,
					@id_pago_afectado = id_pago,
					@monto_de_ese_pago = monto
				FROM core.Detalles_del_Pago 
				WHERE nro_socio = @nro_socio AND periodo_pago = @periodo;

				INSERT INTO logs.Bitacora(evento, entidad_afectada, id_afectada, contexto, entidad_relacionada, id_relacionado, detalle)
				SELECT 
					'PAGO_MODIFICADO',
					'Socio', CAST(@nro_socio AS VARCHAR(10)),
					'Periodo ' + CONVERT(CHAR(7), @periodo, 120),
					'DetallePago', CAST(@id_detalle_pago_afectado AS VARCHAR(10)),
					'Eliminamos registro de pago. Valor anterior $' + CAST(@monto_de_ese_pago AS VARCHAR(10))

				DECLARE @id_bitacora_ultimo_ingresado INT = SCOPE_IDENTITY();
				DECLARE @texto VARCHAR(50) = 'Pago eliminado' + '[ID_BITACORA=' + CAST(@id_bitacora_ultimo_ingresado AS VARCHAR(10)) + ']';

				DELETE FROM core.Detalles_del_Pago WHERE id = @id_detalle_pago_afectado;
				UPDATE p 
				SET	p.comentario = CONCAT_WS(' /', TRIM(p.comentario), @texto)
				FROM core.Pagos p
				WHERE p.id = @id_pago_afectado;
			IF @TranCount = 0 COMMIT;


			EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			PRINT '[INFO] Pago eliminado con exito';
		END TRY
		BEGIN CATCH
			IF @TranCount = 0 ROLLBACK;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			PRINT '[ERROR] Algo anda mal con la rutina eliminar pago';
			THROW;
		END CATCH
	END;
GO
PRINT '[DONE] sp_Eliminar__pago Listos';
GO
