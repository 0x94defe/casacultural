CREATE OR ALTER VIEW reports.vw_nacionalidad AS
	SELECT
	    n.descripcion AS Nacionalidad,
	    COUNT(p.id) AS Total
	FROM core.Nacionalidad n
	LEFT JOIN core.Personas p ON n.id = p.nacionalidad
	WHERE n.id <> 0
	GROUP BY n.id, n.descripcion;
PRINT '[INFO] vw_nacionalidad Creada';
GO
