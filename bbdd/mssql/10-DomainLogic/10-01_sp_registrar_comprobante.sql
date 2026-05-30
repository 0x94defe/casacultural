CREATE OR ALTER PROCEDURE core.sp_Registrar__Comprobante(@json NVARCHAR(MAX)) AS
	BEGIN
		SET NOCOUNT ON;

		IF @json IS NULL OR LEN(@json) <= 10
			THROW 50000, '[ERROR] Algo anda mal con json', 1;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;


		DROP TABLE IF EXISTS #Comprobante;
		CREATE TABLE #Comprobante(
				id_pago INT PRIMARY KEY,
				guid UNIQUEIDENTIFIER NOT NULL, -- El nombre físico en el disco
			    nombre NVARCHAR(255) NOT NULL CHECK (LEN(TRIM(nombre)) > 2), -- "pago_marzo_01"
			    tipo VARCHAR(100) NOT NULL CHECK (LEN(TRIM(tipo)) > 2),  -- application/pdf, image/jpeg, etc.
			    tamanio INT NOT NULL CHECK (tamanio > 0)  -- bytes
			);

		--insert
			INSERT INTO #Comprobante(id_pago, guid, nombre, tipo, tamanio)
			SELECT
				j.id_pago, 
				j.guid,
			    j.nombre,
			    j.tipo,
			    j.tamanio
			FROM OPENJSON(@json) WITH (
					id_pago INT,
					guid UNIQUEIDENTIFIER,
				    nombre NVARCHAR(255),
				    tipo VARCHAR(100),
				    tamanio INT
				) AS j;

		--validamos si todos los id_pago existan
			IF EXISTS(
					SELECT 1
				  	FROM #Comprobante c 
				  	LEFT JOIN core.Pagos p ON p.id = c.id_pago
					WHERE p.id IS NULL
				)
			BEGIN
				SELECT *
			  	FROM #Comprobante c 
			  	LEFT JOIN core.Pagos p ON p.id = c.id_pago
				WHERE p.id IS NULL;

				THROW 50001, '[ERROR] Uno o varios pagos referenciados no existen.', 1;
			END

		--validamos que Comprobante tenga algo
			IF NOT EXISTS(SELECT 1 FROM #Comprobante)
	    		THROW 50001, '[ERROR] No hay Comprobantes para procesar.', 1;

		BEGIN TRY
		  	BEGIN TRANSACTION;
			
			INSERT INTO core.Comprobantes(id_pago, archivo_guid, archivo_nombre, archivo_tipo, archivo_tamanio, fecha_subida)
			SELECT
				id_pago,
				guid,
				nombre,
				tipo,
				tamanio,
				GETDATE()
			FROM #Comprobante
			
			COMMIT TRANSACTION;
			EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;

			PRINT '[INFO] Comprobantes cargados con exito!!';
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			THROW;
		END CATCH
	END;
GO
PRINT '[INFO] sp_Registrar__Comprobante Creada';
GO