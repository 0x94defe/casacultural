IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

SET XACT_ABORT ON; 

BEGIN TRY
	BEGIN TRANSACTION;
		-- Solo crear
			REVOKE UPDATE, DELETE ON lookups.Origenes_de_Cobro FROM app__read_write;
			REVOKE UPDATE, DELETE ON lookups.Tipos_de_Pago FROM app__read_write;
			REVOKE UPDATE, DELETE ON core.Grupos FROM app__read_write; 
			REVOKE UPDATE, DELETE ON core.Cuotas FROM app__read_write;
			REVOKE UPDATE, DELETE ON core.Actividades FROM app__read_write; --crear boton de baja en fecha_fin
		PRINT '[INFO] Permiso solo creacion para: Origenes_de_Cobro, Tipos_de_Pago, Grupos, Cuotas, Actividades';

		-- crear y eliminar
			REVOKE UPDATE ON links.Grupos_con_Personas FROM app__read_write;
			REVOKE UPDATE ON links.Personas_con_Actividades FROM app__read_write; --crear boton de baja en fecha_fin
		PRINT '[INFO] Permiso solo crear y eliminar para: Grupos_con_Personas, Personas_con_Actividades';

		-- SOLO a través de SP 
			REVOKE INSERT, UPDATE, DELETE ON core.Comprobantes FROM app__read_write;
			REVOKE INSERT, UPDATE, DELETE ON core.Detalles_del_Pago FROM app__read_write;
			REVOKE INSERT, UPDATE, DELETE ON core.Pagos FROM app__read_write;
		PRINT '[INFO] Permiso denegados para: Comprobantes, Detalles_del_Pago, Pagos';

		-- solo crear (puede ser creado desde persona)
			-- update: necesita_cupon, pago_preferido
			REVOKE DELETE ON core.Socios FROM app__read_write; -- crear boton de baja en budibase
		PRINT '[INFO] Permiso solo actualizar y crear para: Socios';

		-- crear manualmente!!
		-- update: observaciones
		-- update solo si esta vacio:
			-- nro_socio, Documento, Fecha_Nacimiento, Ciudad, domicilio, Telefono, Celular, Correo_Electronico
			REVOKE DELETE ON core.Personas FROM app__read_write;
		PRINT '[INFO] Permiso solo actualizar y crear para: Personas';
	COMMIT TRANSACTION;

	PRINT '[DONE] Permisos Listos';
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;
	PRINT '[ERROR] Algo anda mal con los Permisos';
	THROW;
END CATCH;
GO
