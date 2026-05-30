CREATE OR ALTER PROCEDURE internal.sp_Test_Registrar__Ejecucion_Proceso AS
	BEGIN
		EXEC internal.sp_Registrar__Ejecucion_Proceso 'sp_Inexistente', 1;
		SELECT
			'internal.fn_Verificar__Ejecucion_Proceso(''sp_Inexistente'', 0)' AS 'internal.sp_Registrar__Ejecucion_Proceso ''sp_Inexistente'', 1',
			internal.fn_Verificar__Ejecucion_Proceso('sp_Inexistente', 0) AS resultado
		UNION ALL
		SELECT
			'internal.fn_Verificar__Ejecucion_Proceso(''sp_Inexistente'', 1)',
			internal.fn_Verificar__Ejecucion_Proceso('sp_Inexistente', 1);
		
		EXEC internal.sp_Registrar__Ejecucion_Proceso 'sp_otra_Inexistente', 0;
		SELECT
			'internal.fn_Verificar__Ejecucion_Proceso(''sp_otra_Inexistente'', 0)' AS 'internal.sp_Registrar__Ejecucion_Proceso ''sp_Inexistente'', 0',
			internal.fn_Verificar__Ejecucion_Proceso('sp_otra_Inexistente', 0) AS resultado
		UNION ALL
		SELECT
			'internal.fn_Verificar__Ejecucion_Proceso(''sp_otra_Inexistente'', 1)',
			internal.fn_Verificar__Ejecucion_Proceso('sp_otra_Inexistente', 1);

		SELECT * FROM internal.Control_de_Procesos;

		-- ¿Ya se ejecutó este proceso como singular?
		IF internal.fn_Verificar__Ejecucion_Proceso('sp_Inexistente', 1) = 1
		    PRINT 'Este proceso singular ya fue ejecutado.';

		-- ¿Existe alguna ejecución previa (no singular)?
		IF internal.fn_Verificar__Ejecucion_Proceso('sp_Inexistente', 0) = 1
		    PRINT 'Proceso ejecutado anteriormente.';
	END;
GO
PRINT '[INFO] sp_Test_Registrar__Ejecucion_Proceso creada';
GO
