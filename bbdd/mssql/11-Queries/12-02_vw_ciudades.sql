CREATE OR ALTER VIEW reports.vw_ciudades AS
	SELECT
		c.descripcion AS Ciudad,
		COUNT(p.id) AS Habitantes
	FROM core.Personas p
	JOIN core.Ciudad c ON c.id = p.ciudad
	GROUP BY c.descripcion;
PRINT '[INFO] vw_ciudades Creada';
GO
