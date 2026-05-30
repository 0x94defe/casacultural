CREATE OR ALTER VIEW reports.vw_historico_cuotas WITH SCHEMABINDING AS 
	WITH cte AS (
		SELECT
    		YEAR(periodo) AS Anio,
        	MONTH(periodo) AS Mes,
        	valor
		FROM core.Cuotas
	 )
	SELECT
		Anio,
	  	[1] AS Enero,
		[2] AS Febrero,
		[3] AS Marzo,
		[4] AS Abril,
		[5] AS Mayo,
		[6] AS Junio,
		[7] AS Julio,
		[8] AS Agosto,
		[9] AS Septiembre,
		[10] AS Octubre,
		[11] AS Noviembre,
		[12] AS Diciembre		
	FROM cte
	PIVOT (SUM(valor) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) piv;
PRINT '[INFO] vw_historico_cuotas Creada';
GO
