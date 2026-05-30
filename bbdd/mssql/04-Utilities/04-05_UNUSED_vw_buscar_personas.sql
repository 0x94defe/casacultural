CREATE OR ALTER VIEW lookups.vw_buscar_personas WITH SCHEMABINDING AS
	SELECT 
	    id AS id_persona,
	    ISNULL(nombre_completo, '') +
			CASE WHEN id_socio IS NOT NULL THEN ' | Socio: ' +
			CAST(id_socio AS VARCHAR) ELSE '' END + 
			CASE WHEN dni <> 0 THEN ' | DNI: ' +
			CAST(dni AS VARCHAR) ELSE '' END +
			' | id_persona: ' +
			CAST(id AS VARCHAR) 
		AS resumen
	FROM core.Personas p
	JOIN core.Socios s ON p.id_persona = s.id_persona;
PRINT '[INFO] vw_buscar_personas Creada';
GO
