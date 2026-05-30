CREATE OR ALTER VIEW reports.vw_rango_etario AS
	SELECT 
		Rango_Etario,
		COUNT(*) AS Total
	FROM (
	    SELECT 
        	CASE
		        WHEN edad < 11 THEN '0-11 años'
				WHEN edad BETWEEN 11 AND 21 THEN '11-21 años'
		        WHEN edad BETWEEN 21 AND 31 THEN '21-31 años'
		        WHEN edad BETWEEN 31 AND 41 THEN '31-41 años'
				WHEN edad BETWEEN 41 AND 61 THEN '41-61 años'
				WHEN edad BETWEEN 61 AND 81 THEN '61-81 años'
		        ELSE 'Más de 81 años'
		    END AS Rango_Etario
	    FROM core.Personas
		WHERE edad IS NOT NULL
	) Subconsulta
	GROUP BY Rango_Etario;
PRINT '[INFO] vw_rango_etario Creada';
GO
