CREATE OR ALTER PROCEDURE reports.sp_planilla_virtuales(@periodo_actual DATE) AS
	BEGIN
		DECLARE @inicio_mes DATE = DATEFROMPARTS(YEAR(@periodo_actual), MONTH(@periodo_actual), 1);
		DECLARE @fin_mes DATE = EOMONTH(@periodo_actual);

		WITH 
			pagos_mes_en_curso AS (
				SELECT pg.id, pg.fecha_hora_pago
				FROM core.Pagos pg
				WHERE pg.fecha_hora_pago BETWEEN @inicio_mes AND @fin_mes
				AND pg.medio_pago = 2 --virtual
			 ),
			pagos_agrupados AS (
				SELECT
					dp.nro_socio,
					pg.fecha_hora_pago,
					REPLACE(UPPER(FORMAT(MIN(dp.periodo_pago), 'MMM-yy', 'es-AR')), '.', '') AS periodos_min,
					REPLACE(UPPER(FORMAT(MAX(dp.periodo_pago), 'MMM-yy', 'es-AR')), '.', '') AS periodos_max,
					COUNT(*) AS cantidad,
					SUM(dp.monto) AS monto
				FROM pagos_mes_en_curso pg
				JOIN core.Detalles_del_Pago dp ON pg.id = dp.id_pago
				GROUP BY dp.nro_socio, pg.fecha_hora_pago
			 )
		SELECT
			pa.nro_socio,
			p.dni,
			p.nombre_completo,
			pa.fecha_hora_pago,
			CASE WHEN pa.cantidad = 1
				THEN pa.periodos_max 
				ELSE CONCAT_WS(' a ', pa.periodos_min, pa.periodos_max)
			 END AS periodos,
			pa.cantidad,
			pa.monto
		FROM pagos_agrupados pa
		JOIN core.Socios s ON pa.nro_socio = s.nro_socio
		JOIN core.Personas p ON s.id_persona = p.id
		ORDER BY pa.nro_socio ASC, pa.fecha_hora_pago ASC;
	END;
PRINT '[INFO] sp_planilla_virtuales Creada';
GO
