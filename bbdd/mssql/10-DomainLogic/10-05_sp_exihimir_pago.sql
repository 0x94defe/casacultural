CREATE OR ALTER PROCEDURE core.sp_Eximir__pago(@nro_socio INT, @periodo DATE, @motivo VARCHAR(114)) AS
 BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	IF NOT EXISTS (SELECT 1 FROM core.Socios WHERE nro_socio = @nro_socio)
		THROW 50000, '[ERROR] No existe ese socio', 1;
	--para eximir el pago nos fijamos si ya existia el pago o lo generamos
	--aca me fijo si hay continuidad
	IF NOT EXISTS (SELECT 1 FROM core.Detalles_del_Pago WHERE nro_socio = @nro_socio AND periodo_pago = DATEADD(MONTH, -1, @periodo))
		THROW 50000, '[ERROR] No se permite eximir pagos si no existe mes previo', 1;
	--en este caso particular nos fijamos ese periodo
	IF EXISTS (SELECT 1 FROM core.Detalles_del_Pago WHERE nro_socio = @nro_socio AND periodo_pago = @periodo AND monto = 0)
		THROW 50000, '[ERROR] El pago ya estaba eximido', 1;

	DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
	EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
	EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;


	DECLARE @TranCount INT = @@TRANCOUNT;
	BEGIN TRY
		DECLARE @texto VARCHAR(128) = 'Pago eximido: ' + @motivo;

		IF @TranCount = 0 BEGIN TRAN;
			IF EXISTS (SELECT 1 FROM core.Detalles_del_Pago WHERE nro_socio = @nro_socio AND periodo_pago = @periodo)
			 BEGIN
				DECLARE 
					@id_pago_raiz INT,
					@id_detalle_pago_afectado INT,
					@monto_de_ese_pago DECIMAL(10,2);

				SELECT 
					@id_detalle_pago_afectado = id,
					@id_pago_raiz = id_pago,
					@monto_de_ese_pago = monto
				FROM core.Detalles_del_Pago 
				WHERE nro_socio = @nro_socio AND periodo_pago = @periodo;

				INSERT INTO logs.Bitacora(evento, entidad_afectada, id_afectada, contexto, entidad_relacionada, id_relacionado, detalle)
				SELECT 
					'PAGO_MODIFICADO',
					'Socio', CAST(@nro_socio AS VARCHAR(10)),
					'Periodo ' + CONVERT(CHAR(7), @periodo, 120),
					'DetallePago', CAST(@id_detalle_pago_afectado AS VARCHAR(10)),
					'Modificamos el pago con valor $0. Valor anterior $' + CAST(@monto_de_ese_pago AS VARCHAR(10))

				DECLARE @id_bitacora_ultimo_ingresado INT = SCOPE_IDENTITY();

				UPDATE dp SET
					dp.comentario = @texto
				FROM core.Detalles_del_Pago dp
				WHERE dp.id = @id_detalle_pago_afectado;

				UPDATE pg SET
					pg.comentario = CONCAT_WS('|', pg.comentario, 'Existe pago Eximido' + '{ID_' + CAST(@id_detalle_pago_afectado AS VARCHAR(10)) + '}')
				FROM core.Pagos pg
				WHERE pg.id = @id_pago_raiz;
			 END
			ELSE
			 BEGIN
				INSERT INTO core.Pagos(fecha_hora_pago, id_persona_pagadora, medio_pago, origen_carga, monto_pagado_real, comentario)
					VALUES (GETDATE(), NULL, 0, 0, 0, 'Pago Eximido');

				DECLARE @id_pago_ingresado INT = SCOPE_IDENTITY();

				INSERT INTO core.Detalles_del_Pago(id_pago, nro_socio, periodo_pago, monto, comentario)
					VALUES (@id_pago_ingresado, @nro_socio, @periodo, 0, @texto);
				DECLARE @id_detalle_pago_ingresado INT = SCOPE_IDENTITY();


				INSERT INTO logs.Bitacora(evento, entidad_afectada, id_afectada, contexto, entidad_relacionada, id_relacionado, detalle)
				SELECT 
					'PAGO_REGISTRADO',
					'Socio', CAST(@nro_socio AS VARCHAR(10)),
					'Periodo ' + CONVERT(CHAR(7), @periodo, 120),
					'DetallePago', CAST(@id_detalle_pago_ingresado AS VARCHAR(10)),
					'Creamos el pago con valor $0'
			 END
		IF @TranCount = 0 COMMIT;


		EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name;
		EXEC sp_set_session_context @key = N'Origen', @value = NULL;
		PRINT '[INFO] Pago eximido con exito';
	END TRY
	BEGIN CATCH
		IF @TranCount = 0 ROLLBACK;
		EXEC sp_set_session_context @key = N'Origen', @value = NULL;
		PRINT '[ERROR] Algo anda mal con la rutina eximir pago';
		THROW;
	END CATCH
 END;
GO
PRINT '[DONE] sp_Eximir__pago Listos';
GO