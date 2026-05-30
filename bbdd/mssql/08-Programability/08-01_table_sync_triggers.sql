CREATE OR ALTER TRIGGER core.tg_Cuotas__master_trigger ON core.Cuotas AFTER INSERT, UPDATE, DELETE AS
	BEGIN
	  	SET NOCOUNT ON;

	  	-- Cuotas_NoDisminuye
			/*IF EXISTS (SELECT 1 FROM INSERTED)
				BEGIN
		  			IF EXISTS (
					        SELECT 1
					        FROM INSERTED i
					        JOIN core.Cuotas c ON c.periodo < i.periodo
					        WHERE 
					        	c.periodo = (SELECT MAX(periodo) FROM core.Cuotas WHERE periodo < i.periodo) AND
					        	i.valor < c.valor
		    			)
		        		THROW 50001, '[ERROR] La cuota no puede ser menor que del periodo anterior.', 1;
		      	END*/

	    -- Sync Cuotas_Pivot
		    DECLARE @aniosAfectados TABLE (Anio INT PRIMARY KEY);
		    
		    -- años de registros insertados/actualizados
		    INSERT INTO @aniosAfectados
		    SELECT DISTINCT YEAR(periodo) FROM INSERTED;
		    
		    -- años de registros eliminados
		    INSERT INTO @aniosAfectados
		    SELECT DISTINCT YEAR(periodo) FROM DELETED;
		    
		    -- para cada año afectado, eliminar y reinsertar
		    DELETE FROM reports.Cuotas_Pivot 
		    WHERE Anio IN (SELECT Anio FROM @aniosAfectados);
		    
		    -- reinsertar desde la vista
		    INSERT INTO reports.Cuotas_Pivot
		    SELECT 
			    v.Anio,
			    v.Enero,
			    v.Febrero,
			    v.Marzo,
			    v.Abril,
			    v.Mayo,
			    v.Junio,
			    v.Julio,
			    v.Agosto,
			    v.Septiembre,
			    v.Octubre,
			    v.Noviembre,
			    v.Diciembre
				FROM reports.vw_historico_cuotas v
				JOIN @aniosAfectados a ON a.Anio = v.Anio;
	END;
GO
PRINT '[INFO] tg_Cuotas__master_trigger Creada';
GO


CREATE OR ALTER TRIGGER core.tg_Detalles_del_Pago__master_trigger ON core.Detalles_del_Pago AFTER INSERT, UPDATE, DELETE AS
	BEGIN
		SET NOCOUNT ON;

		-- Sync Pagos_Pivot (INSERT, UPDATE, DELETE)
			DECLARE @afectados TABLE (Anio INT, nro_socio INT, PRIMARY KEY (Anio, nro_socio));

			-- el UNION hace el DISTINCT y junta ambas tablas sin fallar
			INSERT INTO @afectados (Anio, nro_socio)
			SELECT YEAR(periodo_pago), nro_socio FROM INSERTED
			UNION
			SELECT YEAR(periodo_pago), nro_socio FROM DELETED;

			-- si no hay cambios (ej. un update que no toco nada), salimos
			IF NOT EXISTS (SELECT 1 FROM @afectados)
				RETURN;

			-- borramos filas pivot afectadas
			DELETE pp FROM reports.Pagos_Pivot pp
			JOIN @afectados a ON a.Anio = pp.Anio AND a.nro_socio = pp.Socio;

			-- reinsertamos desde la vista pivot
			INSERT INTO reports.Pagos_Pivot
			SELECT
				v.nro_socio,
				v.Anio,
				v.Enero,
				v.Febrero,
				v.Marzo,
				v.Abril,
				v.Mayo,
				v.Junio,
				v.Julio,
				v.Agosto,
				v.Septiembre,
				v.Octubre,
				v.Noviembre,
				v.Diciembre
			FROM reports.vw_historico_pagos v
			JOIN @afectados a 
			  ON a.Anio = v.Anio 
			 AND a.nro_socio = v.nro_socio;
	END;
GO
PRINT '[INFO] tg_Detalles_del_Pago__master_trigger Creada';
GO

PRINT '[DONE] Triggers de sincronia Listos';
GO
