CREATE OR ALTER VIEW lookups.vw_personas_vinculados AS
	SELECT
	    g.id AS id_grupo,
	    g.descripcion,
	    p.id AS id_persona,
	    p.nombre_completo,
	    p.dni
	FROM core.Grupos g 
	JOIN links.Grupos_con_Personas gp ON gp.id_grupo = g.id
	JOIN core.Personas p ON p.id = gp.id_persona 
PRINT '[INFO] vw_personas_vinculados Creada';
GO
