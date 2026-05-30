CREATE OR ALTER PROCEDURE internal.sp_Test_Helper__Importar_Esquema_normal AS
	BEGIN
		DECLARE @csvPath NVARCHAR(MAX) = 'C:\Achiras\datos.csv';
		EXEC internal.sp_Helper__Importar_Esquema_normal @csvPath;
	END;
GO
PRINT '[INFO] sp_Test_Importar__Esquema_normal creada';
GO
