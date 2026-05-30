-- testing tablas/vistas
--tablas
	SELECT * FROM lookups.Origenes_de_Cobro;
	SELECT * FROM lookups.Tipos_de_Pago;
	SELECT * FROM core.Nacionalidad;
	SELECT * FROM core.Ciudad;	

	SELECT * FROM core.Personas;
	SELECT * FROM core.Socios;

	SELECT * FROM core.Cuotas;
	SELECT * FROM reports.Cuotas_pivot;

	SELECT * FROM core.Pagos;
	SELECT * FROM core.Detalles_del_Pago;

	SELECT * FROM core.Comprobantes;
	SELECT * FROM reports.Pagos_pivot;

	SELECT * FROM core.Grupos;
	SELECT * FROM links.Grupos_con_Personas;

	SELECT * FROM core.Actividades;
	SELECT * FROM links.Personas_con_Actividades;

	SELECT * FROM logs.Notificaciones;
	SELECT * FROM logs.Bitacora;
	SELECT * FROM logs.Conexiones_de_Usuarios;	
--tablas sistema
	SELECT * FROM params.Feriados;
	SELECT * FROM params.Plataforma;
	SELECT * FROM params.Organizacion;
	SELECT * FROM params.Usuarios_del_Sistema;

	SELECT * FROM internal.Patch_Queue;
	SELECT * FROM internal.Patch_Log;
	SELECT * FROM internal.Migration_Log;
	SELECT * FROM internal.Diccionario_Centinelas;
	SELECT * FROM internal.Control_de_Procesos;
--vistas
	SELECT * FROM core.vw_deuda_al_dia;
	SELECT * FROM core.vw_socios_activos;
	SELECT * FROM core.vw_datos_correo;

	SELECT * FROM lookups.vw_personas_vinculados;
	SELECT * FROM lookups.vw_toda_la_info;
	SELECT * FROM lookups.vw_campos_problematicos;

	SELECT * FROM reports.vw_conteo_personas;
	SELECT * FROM reports.vw_historico_cuotas;
	SELECT * FROM reports.vw_historico_pagos ORDER BY nro_socio, Anio;
	SELECT * FROM reports.vw_balance_contable;
	SELECT * FROM reports.vw_estado_pagos ORDER BY nro_socio, Anio;

-- testing procedimientos
-- SP_utils
	--sp_Registrar__Ejecucion_Proceso
		BEGIN TRANSACTION;
			SET NOCOUNT ON;
			EXEC internal.sp_Test_Registrar__Ejecucion_Proceso;
		ROLLBACK;

-- SP_helper 
	--sp_Helper__Importar_Esquema_normal
		BEGIN TRANSACTION;
			SET NOCOUNT ON;
			EXEC internal.sp_Test_Helper__Importar_Esquema_normal;
		ROLLBACK;

-- SP_importacion
	--sp_Importar__Personas
		BEGIN TRANSACTION;
			SET NOCOUNT ON;
			EXEC internal.sp_Test_Importar__Personas;

			SELECT * FROM core.Socios;
			SELECT * FROM core.Personas;
			SELECT * FROM core.Grupos;
			SELECT * FROM links.Grupos_con_Personas;
			SELECT * FROM core.Pagos;
			SELECT * FROM core.Detalles_del_Pago;
			----------------------------------------------
			DECLARE @csvPath NVARCHAR(MAX) = 'F:\Devs\Proyecto_Phi\3 - copia.csv';
			EXEC core.sp_Importar__Personas @csvPath;
			SELECT * FROM core.Grupos;
			SELECT * FROM links.Grupos_con_Personas;
			SELECT * FROM core.Personas;
		ROLLBACK;
	--sp_Importar__Vinculos
		BEGIN TRANSACTION;
			SET NOCOUNT ON;
			EXEC internal.sp_Test_Importar__Vinculos;

			SELECT * FROM core.Socios;
			SELECT * FROM core.Personas;
			SELECT * FROM core.Grupos;
			SELECT * FROM links.Grupos_con_Personas;
		ROLLBACK;

-- SP_negocio
	-- sp_Registrar__Comprobante
		BEGIN TRANSACTION;
			SET NOCOUNT ON;
			EXEC internal.sp_Test_Registrar__Comprobante;
			
			SELECT * FROM core.Pagos;
			SELECT * FROM core.Comprobantes;
		ROLLBACK;
	-- sp_Registrar__Pago
		BEGIN TRANSACTION;
			SET NOCOUNT ON;
			EXEC internal.sp_Test_Registrar__Pago;

			--SELECT * FROM core.Personas;
			--SELECT * FROM core.Grupos;
			--SELECT * FROM links.Grupos_con_Personas;
			--SELECT * FROM core.Pagos;
			SELECT * FROM core.Detalles_del_Pago;
			--SELECT * FROM logs.Bitacora;
		ROLLBACK;

-- SP_crud
	-- sp_Crear__GrupoConSocios
		BEGIN TRAN;
			SET NOCOUNT ON;
			EXEC core.sp_Crear__GrupoConSocios 'prueba', '[1, 3 ,5]';

			SELECT * FROM core.Grupos;
			SELECT * FROM links.Grupos_con_Personas;
		ROLLBACK;
