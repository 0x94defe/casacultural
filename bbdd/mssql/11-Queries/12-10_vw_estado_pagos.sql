CREATE OR ALTER VIEW reports.vw_estado_pagos AS
	WITH
		Universo AS (
			SELECT
				s.nro_socio,
				s.fecha_alta,
				s.fecha_baja, 
				c.periodo,
				YEAR(c.periodo) AS Anio,
				MONTH(c.periodo) AS Mes
			FROM core.Socios s
			CROSS JOIN core.Cuotas c
			-- Desde el 1 de enero del año de alta
			WHERE c.periodo >= DATEFROMPARTS(YEAR(ISNULL(s.fecha_alta, '2020-01-01')), 1, 1) 
			-- Hasta el fin del año de la baja (o infinito si es NULL)
			AND (s.fecha_baja IS NULL OR c.periodo <= DATEFROMPARTS(YEAR(s.fecha_baja), 12, 31)) 
		 ),
		Evaluacion AS (
			SELECT
				u.nro_socio,
				u.Anio,
				u.Mes,
				CASE
					-- NULL XQ NO LE COMPETE, Fuera de rango de membresía (Pre-alta o Post-baja)
					WHEN u.periodo < DATEFROMPARTS(YEAR(u.fecha_alta), MONTH(u.fecha_alta), 1) 
					  OR (u.fecha_baja IS NOT NULL AND u.periodo > u.fecha_baja)
					THEN NULL
					-- SI LE COMPETE Y ESTÁ PAGO -> 1
					WHEN EXISTS (SELECT 1 FROM core.Detalles_del_Pago dp 
								 WHERE dp.nro_socio = u.nro_socio AND dp.periodo_pago = u.periodo)
					THEN 1
					-- SI LE COMPETE Y NO PAGÓ -> 0
					ELSE 0
					-- Si el periodo NO existe en Cuotas, el CROSS JOIN no lo crea -> NULL en el PIVOT
				END AS estado_pago
			FROM Universo u
		 ),
		UltimoPago AS (
			SELECT 
				s.nro_socio,
				MAX(periodo_pago) AS ultimoPago
			FROM core.Socios s
			LEFT JOIN core.Detalles_del_Pago dp ON dp.nro_socio = s.nro_socio
			GROUP BY s.nro_socio
		 )
	SELECT
		piv.Anio,
		piv.nro_socio,
		[1]  AS Enero,
		[2]  AS Febrero,
		[3]  AS Marzo,
		[4]  AS Abril,
		[5]  AS Mayo,
		[6]  AS Junio,
		[7]  AS Julio,
		[8]  AS Agosto,
		[9]  AS Septiembre,
		[10] AS Octubre,
		[11] AS Noviembre,
		[12] AS Diciembre,
		ISNULL(REPLACE(FORMAT(up.ultimoPago, 'MMM-yy', 'es-ES'), '.',''), 'Sin pagos') AS ultimo_pago_desc
	FROM Evaluacion
	PIVOT (MAX(estado_pago) FOR Mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) piv
	JOIN UltimoPago up ON up.nro_socio = piv.nro_socio;
GO
PRINT '[INFO] vw_estado_pagos Creada';
