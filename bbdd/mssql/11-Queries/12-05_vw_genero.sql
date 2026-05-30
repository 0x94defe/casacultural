CREATE OR ALTER VIEW reports.vw_genero AS
	SELECT 
	    v.Tipo,
	    COUNT(p.genero) AS Cantidad
	FROM (
	    SELECT 'M' AS cod, 'Masculino' AS Tipo

	    UNION ALL

	    SELECT 'F', 'Femenino'

	    UNION ALL

	    SELECT 'X', 'No Binario / Otros'

	    UNION ALL

	    SELECT NULL, 'Sin Especificar'
	) v
	LEFT JOIN core.Personas p 
	ON v.cod = p.genero 
	OR (v.cod IS NULL AND p.genero IS NULL)
	GROUP BY v.Tipo, v.cod
	ORDER BY v.cod ASC;
PRINT '[INFO] vw_genero Creada';
GO
