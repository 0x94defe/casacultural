CREATE OR ALTER VIEW reports.vw_historico_pagos WITH SCHEMABINDING AS 
	WITH cte AS (
		SELECT
    		YEAR(periodo_pago) AS Anio,
      		MONTH(periodo_pago) AS Mes,
      		nro_socio,
      		monto
    	FROM core.Detalles_del_Pago
	 )
	SELECT
		Anio,
		nro_socio,
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
	FROM cte c
	PIVOT (SUM(monto) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) piv;
PRINT '[INFO] vw_historico_pagos Creada';
GO
