CREATE OR ALTER PROCEDURE internal.sp_Test_Importar__Personas AS
	BEGIN
		EXEC internal.sp_Setup__clean_database;			
		EXEC internal.sp_Load__datos_configuracion;
		--EXEC internal.sp_Patch_001__importacion_fix_personas;
		--------------------------------------------------------------------
		EXEC internal.sp_Test_Helper__Importar_Esquema_normal;
	END;
GO
PRINT '[INFO] sp_Test_Importar__Personas creada';
GO
