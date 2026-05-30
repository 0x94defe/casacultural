CREATE OR ALTER VIEW reports.vw_antiguedad AS
	WITH cte AS ( 
		SELECT 
			CASE 
				WHEN DATEDIFF(day, fecha_alta, GETDATE()) <= 365 THEN '0-1 Año (Nuevo)'
				WHEN DATEDIFF(day, fecha_alta, GETDATE()) <= (5 * 365) THEN '1-5 Años (Socio)'
				WHEN DATEDIFF(day, fecha_alta, GETDATE()) <= (10 * 365) THEN '5-10 Años (Veterano)'
				ELSE '+10 Años (Histórico)'
			END AS Rango_Antiguedad,
			CASE 
				WHEN DATEDIFF(day, fecha_alta, GETDATE()) <= 365 THEN 1
				WHEN DATEDIFF(day, fecha_alta, GETDATE()) <= (5 * 365) THEN 2
				WHEN DATEDIFF(day, fecha_alta, GETDATE()) <= (10 * 365) THEN 3
				ELSE 4
			END AS Orden
		FROM core.Socios)
	SELECT
		MAX(Rango_Antiguedad) AS Rango_Antiguedad,
		COUNT(*) AS Total
	FROM cte
	GROUP BY Rango_Antiguedad;
PRINT '[INFO] vw_antiguedad Creada';
GO
