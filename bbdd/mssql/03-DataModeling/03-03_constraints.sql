IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

SET XACT_ABORT ON; 

BEGIN TRY
	BEGIN TRANSACTION;
		-- tabla Personas
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__nombre_estricto
				CHECK (core.fn_chk_solo_letras(__nombre) = 1);
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__apellido_estricto
				CHECK (core.fn_chk_solo_letras(__apellido) = 1);
			--ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__ciudad_estricto
				--CHECK (core.fn_chk_alfanumerico(__ciudad) = 1);
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__observaciones_estricto
				CHECK (core.fn_chk_solo_espacios(__observaciones) = 1);
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__domicilio_estricto
				CHECK (core.fn_chk_especial_domicilio(__domicilio) = 1);
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__telefono_estricto
				CHECK (
						__telefono IS NULL OR (
					   		__telefono LIKE '[1-9][0-9] [0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' OR -- '11 1234-5678'
			      	   		__telefono LIKE '[1-9][0-9][0-9] [0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' OR -- '261 234-5678'
			      	   		__telefono LIKE '[1-9][0-9][0-9][0-9] [0-9][0-9]-[0-9][0-9][0-9][0-9]'
			      	   	)
					);
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__celular_estricto
				CHECK (
						__celular IS NULL OR (
			        		__celular LIKE '[1-9][0-9] [0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' -- '11 1234-5678'
			      		)
					);
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__email_estricto
				CHECK (core.fn_chk_especial_email(__email) = 1);
		PRINT '[INFO] Creando checks de Personas';

		-- tabla Pagos
			ALTER TABLE core.Pagos ADD CONSTRAINT CHK_Pagos__id_persona_pagadora_no_puede_ser_null_si_es_pago_virtual 
				CHECK (medio_pago <> 1 OR id_persona_pagadora IS NOT NULL);
		PRINT '[INFO] Creando checks de Pagos';

		-- tabla Detalles_del_Pago
			ALTER TABLE core.Detalles_del_Pago ADD CONSTRAINT CHK_Detalles_del_Pago__aclarar_porque_monto_es_cero 
				CHECK (monto <> 0 OR comentario IS NOT NULL);
		PRINT '[INFO] Creando checks de Detalles_del_Pago';

		-- tabla Personas_con_Actividades
			ALTER TABLE links.Personas_con_Actividades ADD CONSTRAINT CHK_Personas_con_Actividades__fecha_baja_posterior_fecha_alta
				CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio);
		PRINT '[INFO] Creando checks de Personas_con_Actividades';

		-- tabla Socios
			-- Fecha de baja posterior a fecha de alta (solo si fecha_alta no es NULL)
			ALTER TABLE core.Socios ADD CONSTRAINT CHK_Socios__fecha_baja_posterior_fecha_alta
	      		CHECK (fecha_baja IS NULL OR fecha_alta IS NULL OR fecha_baja >= fecha_alta);

	    	-- Motivo de baja obligatorio solo si hay fecha_baja, si no motivo de baja no tiene sentido
	    	ALTER TABLE core.Socios ADD CONSTRAINT CHK_Socios__motivo_baja_si_fecha_baja
	      		CHECK (fecha_baja IS NULL OR motivo_baja IS NULL OR (fecha_baja IS NOT NULL AND motivo_baja IS NOT NULL));
	  	PRINT '[INFO] Creando checks de Socios';

		-- tabla Actividades
		    ALTER TABLE core.Actividades ADD CONSTRAINT CHK_Actividades__fecha_baja_posterior_fecha_alta 
		    	CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio);
		    ALTER TABLE core.Actividades ADD CONSTRAINT CHK_Actividades__motivo_baja_no_puede_estar_comentado_si_no_esta_dado_de_baja 
		    	CHECK ((fecha_fin IS NULL AND motivo_baja IS NULL) OR (fecha_fin IS NOT NULL AND motivo_baja IS NOT NULL));
		PRINT '[INFO] Creando checks de Actividades';

	  	-- tablas Personas-Socios
		  	--si el socio desea ser notificado por pagos antes del vencimiento fijate que exista email
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__email_obligatorio_por_notificacion_pago
				CHECK (core.fn_chk_persona_notificacion_pago(id) = 1);

			-- si el socio elige pago por domicilio fijate que exista domicilio
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__domicilio_obligatorio_por_pago_domicilio
				CHECK (core.fn_chk_persona_pago_domicilio(id) = 1);

			-- si el socio elige pago por virtual fijate que exista celular
			ALTER TABLE core.Personas ADD CONSTRAINT CHK_Personas__celular_obligatorio_por_pago_virtual
				CHECK (core.fn_chk_persona_pago_virtual(id) = 1);
		PRINT '[INFO] Creando Cross-Checks de Personas-Socios';
	COMMIT TRANSACTION;

	PRINT '[DONE] Constraints Listos';
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;
	PRINT '[ERROR] Algo anda mal con los Constraints';
	THROW;
END CATCH;
GO
