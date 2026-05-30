CREATE OR ALTER PROCEDURE reports.sp_planilla_efectivos(@periodo_actual DATE) AS
	BEGIN
		DECLARE @anio_en_curso INT = YEAR(@periodo_actual);
		DECLARE @inicio_mes DATE = DATEFROMPARTS(YEAR(@periodo_actual), MONTH(@periodo_actual), 1);
		DECLARE @fin_mes DATE = EOMONTH(@periodo_actual);

		WITH 
			pagos_mes_en_curso AS (
				SELECT pg.id
				FROM core.Pagos pg
				WHERE pg.fecha_hora_pago BETWEEN @inicio_mes AND @fin_mes
				AND pg.medio_pago = 3 --efectivo
			 ),
			pagos_heat_map AS (
				SELECT
					dp.nro_socio,
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso-1, 10, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso-1, 10, 1) THEN -1 ELSE 0 END) AS [M_AnioAnt_10],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso-1, 11, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso-1, 11, 1) THEN -1 ELSE 0 END) AS [M_AnioAnt_11],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso-1, 12, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso-1, 12, 1) THEN -1 ELSE 0 END) AS [M_AnioAnt_12],

					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 1, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 1, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_01],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 2, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 2, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_02],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 3, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 3, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_03],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 4, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 4, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_04],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 5, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 5, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_05],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 6, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 6, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_06],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 7, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 7, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_07],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 8, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 8, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_08],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 9, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 9, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_09],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 10, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 10, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_10],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 11, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 11, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_11],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso, 12, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso, 12, 1) THEN -1 ELSE 0 END) AS [M_AnioCur_12],

					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso+1, 1, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso+1, 1, 1) THEN -1 ELSE 0 END) AS [M_AnioSig_01],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso+1, 2, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso+1, 2, 1) THEN -1 ELSE 0 END) AS [M_AnioSig_02],
					MAX(CASE WHEN dp.periodo_pago = DATEFROMPARTS(@anio_en_curso+1, 3, 1) THEN 1 
								WHEN dp.periodo_pago > DATEFROMPARTS(@anio_en_curso+1, 3, 1) THEN -1 ELSE 0 END) AS [M_AnioSig_03]
				FROM pagos_mes_en_curso pg
				JOIN core.Detalles_del_Pago dp ON pg.id = dp.id_pago
				WHERE dp.periodo_pago 
				BETWEEN DATEFROMPARTS(@anio_en_curso-1, 10, 1)
				AND DATEADD(DAY, -1, DATEFROMPARTS(@anio_en_curso+1, 4, 1))
				GROUP BY dp.nro_socio
			 ),
			pagos_agrupados AS (
				SELECT
					dp.nro_socio,
					REPLACE(UPPER(FORMAT(MIN(dp.periodo_pago), 'MMM-yy', 'es-AR')), '.', '') AS periodos_min,
					REPLACE(UPPER(FORMAT(MAX(dp.periodo_pago), 'MMM-yy', 'es-AR')), '.', '') AS periodos_max,
					COUNT(*) AS cantidad,
					SUM(dp.monto) AS monto
				FROM pagos_mes_en_curso pg
				JOIN core.Detalles_del_Pago dp ON pg.id = dp.id_pago
				GROUP BY dp.nro_socio
			 )
		SELECT
			p.dni,
			p.nombre_completo,
			phm.*,
			CASE WHEN pa.cantidad = 1
				THEN pa.periodos_max 
				ELSE CONCAT_WS(' a ', pa.periodos_min, pa.periodos_max)
			 END AS periodos,
			pa.cantidad,
			pa.monto
		FROM pagos_agrupados pa
		JOIN pagos_heat_map phm ON pa.nro_socio = phm.nro_socio
		JOIN core.Socios s ON pa.nro_socio = s.nro_socio
		JOIN core.Personas p ON s.id_persona = p.id
		ORDER BY phm.nro_socio ASC;
	END;
PRINT '[INFO] sp_planilla_efectivos Creada';
GO
