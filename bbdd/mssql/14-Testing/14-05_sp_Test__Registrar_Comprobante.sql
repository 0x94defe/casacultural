CREATE OR ALTER PROCEDURE internal.sp_Test_Registrar__Comprobante AS
	BEGIN			
		EXEC internal.sp_Load__datos_configuracion;
		------------------------------------
		SET IDENTITY_INSERT core.Pagos ON;
		INSERT INTO core.Pagos(id, fecha_hora_pago, medio_pago, origen_carga) VALUES
			(1,'2024-11-11 22:52:01', 2, 2), (2,'2024-07-11', 2, 3), (3,'2024-01-23', 3, 1);
		SET IDENTITY_INSERT core.Pagos OFF;

		DECLARE @json NVARCHAR(MAX) = 
			N'[
						{
							"id_pago": 1,
							"guid": "3F8A6D1C-4C2E-4F5A-9B1E-7A2D6F4B91C8",
							"nombre": "el_pago",
							"tipo": ".jpg",
							"tamanio": 12424
						},
						{
							"id_pago": 2,
							"guid": "12345678-1234-1234-1234-323456789012",
							"nombre": "el_otro_pago",
							"tipo": ".pdf",
							"tamanio": 213
						},
						{
							"id_pago": 3,
							"guid": "A7D4E2B9-91F3-4C6E-8A5D-0E2F6B9C3A74",
							"nombre": "el_otro_pago",
							"tipo": ".pdf",
							"tamanio": 213
						}
				]';

		EXEC core.sp_Registrar__Comprobante @json;
	END;
GO
PRINT '[INFO] sp_Test_Registrar__Comprobante creada';
GO
