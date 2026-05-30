CREATE OR ALTER VIEW reports.vw_conteo_personas AS
	SELECT
		COUNT(p.id) AS personas_en_el_sistema,

		(COUNT(p.id) - COUNT(s.id)) AS no_socios,

		COUNT(s.id) AS socios,

		COUNT(CASE WHEN s.id IS NOT NULL AND Fecha_baja IS NULL THEN 1 END) AS socios_activos,

		COUNT(CASE WHEN s.id IS NOT NULL AND Fecha_baja IS NOT NULL THEN 1 END) AS socios_inactivos
	FROM core.Personas p
	LEFT JOIN core.Socios s ON s.id_persona = p.id;
PRINT '[INFO] vw_conteo_personas Creada';
GO
