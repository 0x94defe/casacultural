CREATE OR ALTER PROCEDURE internal.sp_Test_Registrar__Pago(@esCasoLimite BIT = 0) AS
	BEGIN
		EXEC internal.sp_Test_Importar__Vinculos;
		EXEC internal.sp_Load__datos_referenciales;
		----------------------
		DECLARE @json_good NVARCHAR(MAX) = 
			N'{
					"apellido_nombre_origen": "Suarez, Alicia",
					"fecha_hora_pago": "2025-01-20T22:22:22Z",
					"medio_pago": 1,
					"origen_carga": 1,
					"detalles_pago": [
						{
							"nro_socio": 505,
							"cant_cuotas": 1
						},
						{
							"nro_socio": 832,
							"cant_cuotas": 2
						},
						{
							"nro_socio": 435,
							"cant_cuotas": 3
						}
					]
				}';
		DECLARE @json_bad NVARCHAR(MAX) = --probar julio, cesar
			N'{
					"apellido_nombre_origen": null,
					"fecha_hora_pago": "2025-01-20",
					"medio_pago": 1,
					"origen_carga": 1,
					"detalles_pago": [
						{
							"nro_socio": 199,
							"cant_cuotas": 1
						},
						{
							"nro_socio": 199,
							"cant_cuotas": 2
						},
						{
							"nro_socio": 330,
							"cant_cuotas": 2
						},
						{
							"nro_socio": 435,
							"cant_cuotas": 3
						},
						{
							"nro_socio": 2037,
							"cant_cuotas": 0
						}
					]
			}';

		IF @esCasoLimite = 0
			EXEC core.sp_Registrar__Pago @json_good;
		ELSE
			EXEC core.sp_Registrar__Pago @json_bad;
	END;
GO
PRINT '[INFO] sp_Test_Registrar__Pago creada';
GO
