CREATE OR ALTER TRIGGER links.tg_Grupos_con_Personas__master_trigger ON links.Grupos_con_Personas AFTER INSERT, DELETE AS
	BEGIN
	    SET NOCOUNT ON;

	    -- minimo_2_por_grupo
		IF EXISTS (
		        SELECT 1
		        FROM (SELECT id_grupo FROM INSERTED UNION SELECT id_grupo FROM DELETED) x
		        JOIN core.Grupos g ON g.id = x.id_grupo
		        WHERE g.esFamilia = 1 AND (SELECT COUNT(*) FROM links.Grupos_con_Personas gp WHERE gp.id_grupo = g.id) < 2
			)
		    THROW 50001, '[ERROR] Un Grupo debe tener minimo 2 integrantes.', 1;
	END
PRINT '[INFO] tg_Grupos_con_Personas__master_trigger Creada';
GO

CREATE OR ALTER TRIGGER links.tg_Personas_con_Actividades__master_trigger ON links.Personas_con_Actividades AFTER INSERT AS
	BEGIN
		SET NOCOUNT ON;

		-- la actividad debe estar en curso
	    IF EXISTS (	
		    	SELECT 1
		       	FROM INSERTED i
		       	JOIN core.Actividades a ON a.id = i.id_actividad
		       	WHERE a.fecha_fin IS NOT NULL
	    	)
	        THROW 50001, '[ERROR] No se puede asociar personas a una actividad finalizada', 1;
	END
PRINT '[INFO] tg_Personas_con_Actividades__master_trigger Creada';
GO


CREATE OR ALTER TRIGGER core.tg_Actividades__master_trigger ON core.Actividades AFTER UPDATE AS
	BEGIN
	    SET NOCOUNT ON;

	    -- set_fecha_fin_en_personas cuando fecha_fin pasa de NULL a NOT NULL, pero solo a personas que fecha_fin NOT NULL
	    UPDATE pa
	    SET pa.fecha_fin = i.fecha_fin
	    FROM links.Personas_con_Actividades pa
	    JOIN INSERTED i ON i.id = pa.id_actividad
	    JOIN DELETED d ON d.id = i.id
	    WHERE 
	        d.fecha_fin IS NULL AND      -- antes era NULL
	        i.fecha_fin IS NOT NULL AND -- ahora tiene valor
	        pa.fecha_fin IS NULL;   -- solo completar los que están abiertos
	END;
PRINT '[INFO] tg_Actividades__master_trigger Creada';
GO


PRINT '[DONE] Triggers de reglas Listos';
GO
