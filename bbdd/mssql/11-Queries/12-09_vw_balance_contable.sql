CREATE OR ALTER VIEW reports.vw_balance_contable AS
	WITH cte AS (
	    SELECT
	        YEAR(fecha_hora_pago) AS Anio,
	        MONTH(fecha_hora_pago) AS Mes,
	        monto_pagado_real
	    FROM core.pagos
	    WHERE id <> 0
	 )
	SELECT
	    Anio,
	    SUM(CASE WHEN Mes = 1 THEN monto_pagado_real ELSE 0 END) AS Enero,
	    SUM(CASE WHEN Mes = 2 THEN monto_pagado_real ELSE 0 END) AS Febrero,
	    SUM(CASE WHEN Mes = 3 THEN monto_pagado_real ELSE 0 END) AS Marzo,
	    SUM(CASE WHEN Mes = 4 THEN monto_pagado_real ELSE 0 END) AS Abril,
	    SUM(CASE WHEN Mes = 5 THEN monto_pagado_real ELSE 0 END) AS Mayo,
	    SUM(CASE WHEN Mes = 6 THEN monto_pagado_real ELSE 0 END) AS Junio,
	    SUM(CASE WHEN Mes = 7 THEN monto_pagado_real ELSE 0 END) AS Julio,
	    SUM(CASE WHEN Mes = 8 THEN monto_pagado_real ELSE 0 END) AS Agosto,
	    SUM(CASE WHEN Mes = 9 THEN monto_pagado_real ELSE 0 END) AS Septiembre,
	    SUM(CASE WHEN Mes = 10 THEN monto_pagado_real ELSE 0 END) AS Octubre,
	    SUM(CASE WHEN Mes = 11 THEN monto_pagado_real ELSE 0 END) AS Noviembre,
	    SUM(CASE WHEN Mes = 12 THEN monto_pagado_real ELSE 0 END) AS Diciembre,
	    SUM(monto_pagado_real) AS TOTAL
	FROM cte
	GROUP BY Anio;
PRINT '[INFO] vw_balance_contable Creada';
GO
