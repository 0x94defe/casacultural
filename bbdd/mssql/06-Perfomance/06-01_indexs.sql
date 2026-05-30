IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

SET XACT_ABORT ON; 

BEGIN TRY
	BEGIN TRANSACTION;
		-- configurativos
			CREATE UNIQUE INDEX UX_Personas__DNI_Unico ON core.Personas(dni) WHERE dni IS NOT NULL;
		PRINT '[INFO] Indices configurativos creados';

		-- fillfactor
			--ALTER INDEX PK_Socios ON core.Socios REBUILD WITH (FILLFACTOR = 80);
		--PRINT '[INFO] Indices con FillFactor creadas';

		-- indices
		  	CREATE INDEX IX_Bitacora__fecha ON logs.Bitacora(fecha_hora DESC);
		  	CREATE INDEX IX_Bitacora__entidad ON logs.Bitacora(entidad_afectada, id_afectada);
		  	CREATE INDEX IX_Socios__id_persona ON core.Socios(id_persona) INCLUDE(nro_socio);
			CREATE INDEX IX_Personas__dni ON core.Personas(dni) INCLUDE(nombre, apellido);
			CREATE INDEX IX_Pagos__fecha_hora_pago ON core.Pagos(fecha_hora_pago) INCLUDE(id_persona_pagadora);
			CREATE INDEX IX_Detalles_del_Pago__periodo ON core.Detalles_del_Pago(periodo_pago, nro_socio);
		PRINT '[INFO] Indices NONCLUSTERED creadas';
		
		-- de vistas
			-- indice Clustered sobre la vista. A partir de ahora, esta vista OCUPA ESPACIO.
			--CREATE UNIQUE INDEX UX_vw_buscar_personas ON lookups.vw_buscar_personas(id_persona);
			-- indice para que el buscador de Budibase vuele
			--CREATE INDEX IX_vw_buscar_personas ON lookups.vw_buscar_personas(resumen);
		--PRINT '[INFO] Indices de vistas creadas (materializacion)';
	COMMIT TRANSACTION;

	PRINT '[DONE] Indices Listos';
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;
	PRINT '[ERROR] Algo anda mal en los Indices';
	THROW;
END CATCH;
GO
