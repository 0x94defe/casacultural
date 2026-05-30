CREATE OR ALTER PROCEDURE core.sp_Importar__Personas(@csvPath VARCHAR(MAX)) AS
		/*** ACLARACION
		 * todos los datos son extraidos en formato de string
		 * si un campo del csv era ';;', sql lo toma como ''
		 * en ese caso el '' lo considero como NULL,
		 * por lo tanto no hay valores NULL en el staging
		 * por el otro lado para valores errones uso un centinel
		*/
	BEGIN
		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));

		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;

		IF @csvPath IS NULL OR LEN(TRIM(@csvPath)) <= 3
			THROW 50000, '[ERROR] Agumento incorrecto', 1;

		SET XACT_ABORT ON;
		SET NOCOUNT ON;

		--table
			DROP TABLE IF EXISTS #CookedBulk;
			CREATE TABLE #CookedBulk(
					rn INT PRIMARY KEY,
					fecha_ultima_cuota DATE,
					nro_socio INT,
					nombre NVARCHAR(50) COLLATE DATABASE_DEFAULT,
					apellido NVARCHAR(50) COLLATE DATABASE_DEFAULT,
					dni INT,
					domicilio NVARCHAR(50) COLLATE DATABASE_DEFAULT,
					ciudad NVARCHAR(50) COLLATE DATABASE_DEFAULT,
					telefono VARCHAR(15) COLLATE DATABASE_DEFAULT,
					celular VARCHAR(15) COLLATE DATABASE_DEFAULT,
					email VARCHAR(125) COLLATE DATABASE_DEFAULT,
					fecha_nacimiento DATE,
					observaciones NVARCHAR(500) COLLATE DATABASE_DEFAULT,
					fecha_alta DATE,
					nombre_titular_cuenta NVARCHAR(50) COLLATE DATABASE_DEFAULT,
					apellido_titular_cuenta NVARCHAR(50) COLLATE DATABASE_DEFAULT,
					fecha_baja DATE,
					nacionalidad NVARCHAR(20) COLLATE DATABASE_DEFAULT,
					genero CHAR(1) COLLATE DATABASE_DEFAULT,
					----------------------------------
					BadData_comments VARCHAR(250),
					BadCast_comments VARCHAR(250),
					BadDomain_comments VARCHAR(250),
					ContainsDups_comments VARCHAR(250)
				);

		INSERT INTO #CookedBulk
		EXEC internal.sp_Helper__Importar_Esquema_normal @csvPath;

		--verif
			IF NOT EXISTS (SELECT 1 FROM #CookedBulk)
					THROW 50000, '[ERROR] no hay informacion en el csv. abortando', 1;

			IF EXISTS (SELECT 1 FROM #CookedBulk WHERE ContainsDups_comments IS NOT NULL)
					THROW 50000, '[ERROR] existen campos duplicados. abortando', 1;

			IF EXISTS (SELECT 1 FROM #CookedBulk WHERE fecha_ultima_cuota IS NOT NULL AND nro_socio IS NULL)
					THROW 50000, '[ERROR] osea existe ultima cuota registrada pero no tiene nro_socio. abortando', 1;
		
		--patch
			IF EXISTS (SELECT 1 FROM internal.Patch_Queue WHERE sp_to_patch_name = @sp_name AND apply_date IS NULL)
			BEGIN
				-- Validar que todos los DNIs del parche existan en el proceso actual
					IF EXISTS (
							SELECT 1 
							FROM internal.Temp_Patch tp
							LEFT JOIN #CookedBulk cb ON tp.dni = cb.dni
							WHERE cb.dni IS NULL
					  	)
					BEGIN
						DECLARE @dni_error INT = (SELECT TOP 1 tp.dni FROM internal.Temp_Patch tp LEFT JOIN #CookedBulk cb ON tp.dni = cb.dni WHERE cb.dni IS NULL);
						DECLARE @msg_error VARCHAR(256) = CONCAT('[ERROR] El DNI ', @dni_error, ' del parche no existe en el proceso de importación actual.');
    
						THROW 51000, @msg_error, 1;
					END

			  	DECLARE @id_patch_queue INT = (SELECT id FROM internal.Patch_Queue WHERE sp_to_patch_name = @sp_name AND apply_date IS NULL);
				SELECT TOP 0 * INTO #buffer FROM internal.Patch_Log;

				-- Update fecha_nacimiento
					UPDATE cb
				    SET cb.fecha_nacimiento = tp.new_fnac
				    OUTPUT @id_patch_queue, 'Personas', 'fecha_nacimiento', DELETED.fecha_nacimiento, INSERTED.fecha_nacimiento
				    INTO #buffer(id_patch_queue, table_name, field_name, old_value, new_value)
				    FROM #CookedBulk cb
				    JOIN internal.Temp_Patch tp ON cb.dni = tp.dni
					WHERE tp.patch_fnac = 1;

			  	-- Update ciudad
				    --	UPDATE cb
					--	SET cb.ciudad = tp.new_ciudad
					--	OUTPUT @id_patch_queue, 'Personas', 'ciudad', DELETED.ciudad, INSERTED.ciudad
					--	INTO #buffer(id_patch_queue, table_name, field_name, old_value, new_value)
					--	FROM #CookedBulk cb
					--	JOIN internal.Temp_Patch tp ON cb.dni = tp.dni
					--	WHERE tp.patch_ciudad = 1;

				INSERT INTO internal.Patch_Log(id_patch_queue, table_name, field_name, old_value, new_value)
				SELECT 
					id_patch_queue,
					table_name,
					field_name,
					old_value,
					new_value
				FROM #buffer;
				
			    UPDATE internal.Patch_Queue
			    SET state_success = 1, apply_date = SYSDATETIME()
			    WHERE sp_to_patch_name = @sp_name AND apply_date IS NULL;

			    DROP TABLE #buffer;
			    DROP TABLE internal.Temp_Patch;
				
				PRINT '[INFO] Aplicado el parche manual antes del insert final...';
			END

		DECLARE @TranCount INT = @@TRANCOUNT;
		BEGIN TRY
			IF @TranCount = 0 BEGIN TRAN;
      		SET NOCOUNT OFF;
      			-- Los que son totalmente NUEVOS (No existen en la base)
		      		DROP TABLE IF EXISTS #Nuevos;
					SELECT cb.*
					INTO #Nuevos
					FROM #CookedBulk cb
					WHERE NOT EXISTS (
							SELECT 1 FROM core.Personas p 
							WHERE p.dni = cb.dni OR (p.nombre = cb.nombre AND p.apellido = cb.apellido)
						);

						-- Los que existen pero tienen DIFERENCIAS
							DROP TABLE IF EXISTS #Diferencias;
							SELECT  
								p.dni,
								v.Campo,
								v.Valor_Actual,
								v.Valor_Nuevo
							INTO #Diferencias
							FROM #CookedBulk cb
							JOIN core.Personas p ON cb.dni = p.dni
							CROSS APPLY (VALUES
									('Nombre', p.nombre, cb.nombre),
									('Apellido', p.apellido, cb.apellido),
									('F.Nac', CONVERT(VARCHAR(10), p.fecha_nacimiento, 120), CONVERT(VARCHAR(10), cb.fecha_nacimiento, 120)),
									('Ciudad', p.ciudad, cb.ciudad),
									('Domicilio', p.domicilio, cb.domicilio),
									('Telefono', p.telefono, cb.telefono),
									('Celular', p.celular, cb.celular),
									('Email', p.email, cb.email),
									('Observaciones', p.observaciones, cb.observaciones),
									('Nacionalidad', p.nacionalidad, cb.nacionalidad),
									('Genero', p.genero, cb.genero)
								) v (Campo, Valor_Actual, Valor_Nuevo)
							WHERE ISNULL(v.Valor_Actual,'') <> ISNULL(v.Valor_Nuevo,'');

				-- inserto datos personales de los Socios
				    INSERT INTO core.Personas(
				    	dni,
				    	__nombre, 
				    	__apellido,
					    fecha_nacimiento, 
					    ciudad, --__ciudad,
					    __domicilio,
					    __telefono, 
					    __celular, 
					    __email, 
					    __observaciones,
					    nacionalidad,
					    genero)
				    SELECT
				    	cb.dni,
				    	cb.nombre, 
				    	cb.apellido,
					    cb.fecha_nacimiento, 
					    c.id, 
					    cb.domicilio,
					    cb.telefono, 
					    cb.celular, 
					    cb.email, 
					    cb.observaciones,
					    n.id,
					    cb.genero
				    FROM #CookedBulk cb
				    LEFT JOIN core.Nacionalidad n ON n.descripcion = cb.nacionalidad
				    LEFT JOIN core.Ciudad c ON c.descripcion = cb.ciudad
					WHERE NOT EXISTS (
							SELECT 1 
							FROM core.Personas p
							WHERE p.dni = cb.dni OR (p.nombre = cb.nombre AND p.apellido = cb.apellido)
						);

				-- inserto Socios
					INSERT INTO core.Socios(nro_socio, id_persona, fecha_alta, fecha_baja)
					SELECT 
						cb.nro_socio,
						p.id,
						cb.fecha_alta,
						cb.fecha_baja
					FROM #CookedBulk cb
					JOIN core.Personas p ON p.dni = cb.dni OR (p.nombre = cb.nombre AND p.apellido = cb.apellido)
					WHERE 
						nro_socio IS NOT NULL
						AND NOT EXISTS (
							    SELECT 1 FROM core.Socios s 
							    WHERE s.nro_socio = cb.nro_socio
							);

				-- reinserto en personas, los no socios, AKA titular
					WITH 
						IdsLote AS (
								SELECT
									p_titular.id AS id_titular,
									p_titular.observaciones,
									p.id AS id_benef
								FROM #CookedBulk cb
								JOIN core.Personas p ON p.dni = cb.dni
								JOIN core.Personas p_titular 
									ON p_titular.nombre = cb.nombre_titular_cuenta
								 	AND p_titular.apellido = cb.apellido_titular_cuenta
								WHERE cb.nombre_titular_cuenta IS NOT NULL AND cb.apellido_titular_cuenta IS NOT NULL
							),
						IdsAProcesar AS (
								SELECT 
									idl.id_titular,
									STRING_AGG(CAST(idl.id_benef AS VARCHAR(5)), '_') WITHIN GROUP (ORDER BY idl.id_benef) AS cadena_nueva
								FROM IdsLote idl
								WHERE
									idl.observaciones LIKE '%Titular id_persona: _%' AND 
									idl.observaciones NOT LIKE '%[_]' + CAST(idl.id_benef AS VARCHAR(5)) + '[_]%'
								GROUP BY idl.id_titular
							)
					UPDATE p
					SET	p.__observaciones = REPLACE(
												    p.observaciones, 
												    'Titular id_persona: _', 
												    'Titular id_persona: _' + n.cadena_nueva + '_'
												)
					FROM core.Personas p
					JOIN IdsAProcesar n ON p.id = n.id_titular;

					
					INSERT INTO core.Personas(__nombre, __apellido, __observaciones)
					SELECT
					    cb.nombre_titular_cuenta,
					    cb.apellido_titular_cuenta,
					    'NOTAS: |Titular id_persona: _' + STRING_AGG(CAST(p_socio.id AS VARCHAR(5)), '_') WITHIN GROUP (ORDER BY p_socio.id) + '_'
					FROM #CookedBulk cb
					JOIN core.Personas p_socio ON p_socio.dni = cb.dni
					WHERE 
						cb.nombre_titular_cuenta IS NOT NULL AND 
						cb.apellido_titular_cuenta IS NOT NULL AND
					  	NOT EXISTS (
						      	SELECT 1 FROM core.Personas p
						      	WHERE 
							      	p.nombre = cb.nombre_titular_cuenta AND
							      	p.apellido = cb.apellido_titular_cuenta
				  			)
					GROUP BY cb.nombre_titular_cuenta, cb.apellido_titular_cuenta;


				-- genero grupo de titular y beneficiario
					DROP TABLE IF EXISTS #TmpVinculo;
					CREATE TABLE #TmpVinculo(
							pila_apellidos NVARCHAR(100) COLLATE DATABASE_DEFAULT,
							id_persona_benef INT,
							id_persona_titular INT,
							id_grupo INT
						);

					-- preparo los datos
						WITH 
							NombresConocidos AS (
									SELECT DISTINCT nombre
									FROM #CookedBulk
									WHERE nombre IS NOT NULL
								),
							Limpieza AS (
									SELECT
										dni,
										nombre_titular_cuenta,
					    				apellido_titular_cuenta,

										REPLACE(CASE WHEN PATINDEX('%[A-Z]. %', apellido) > 0 
												THEN TRIM(STUFF(apellido, PATINDEX('%[A-Z]. %', apellido), 3, ''))
												ELSE apellido END,
											' De ', ' ')
										AS apellido_limpio,

										REPLACE(CASE WHEN PATINDEX('%[A-Z]. %', apellido_titular_cuenta) > 0 
												THEN TRIM(STUFF(apellido_titular_cuenta, PATINDEX('%[A-Z]. %', apellido_titular_cuenta), 3, ''))
												ELSE apellido_titular_cuenta END,
											' De ', ' ')
										AS apellido_titular_limpio
									FROM #CookedBulk
								),
							ApellidosSanitizados AS (
									SELECT 
										dni,
										nombre_titular_cuenta,
					    				apellido_titular_cuenta,

										-- Filtrar palabras que son nombres conocidos
										(SELECT STRING_AGG(value, ' ')
										 FROM STRING_SPLIT(apellido_limpio, ' ')
										 WHERE value NOT IN (SELECT nombre FROM NombresConocidos))
										AS apellido_final,

										(SELECT STRING_AGG(value, ' ')
										 FROM STRING_SPLIT(apellido_titular_limpio, ' ')
										 WHERE value NOT IN (SELECT nombre FROM NombresConocidos))
										AS apellido_titular_final
									FROM Limpieza
								),
							ApellidoFamilia AS (
									SELECT
										dni,
										nombre_titular_cuenta,
					    				apellido_titular_cuenta,

										CASE
												WHEN apellido_titular_final COLLATE Latin1_General_CI_AI = apellido_final COLLATE Latin1_General_CI_AI
													THEN apellido_final

												WHEN apellido_titular_final LIKE '%' + apellido_final + '%'
													THEN apellido_titular_final
												WHEN apellido_final LIKE '%' + apellido_titular_final + '%'
													THEN apellido_final

												ELSE apellido_final + ' + ' + apellido_titular_final
											END AS pila_apellidos
									FROM ApellidosSanitizados
								)
						INSERT INTO #TmpVinculo(pila_apellidos, id_persona_benef, id_persona_titular)
						SELECT 
							af.pila_apellidos,
							p1.id AS id_persona_benef,
							p2.id AS id_persona_titular
						FROM ApellidoFamilia af
						JOIN core.Personas p1 ON p1.dni = af.dni 
						JOIN core.Personas p2 ON p2.nombre = af.nombre_titular_cuenta AND p2.apellido = af.apellido_titular_cuenta
						WHERE af.nombre_titular_cuenta IS NOT NULL AND af.apellido_titular_cuenta IS NOT NULL;

					-- 1) Si el titular ya tiene grupo, lo uso mientras sea un grupo de familia
						UPDATE v
						SET v.id_grupo = gp.id_grupo
						FROM #TmpVinculo v
						JOIN links.Grupos_con_Personas gp ON gp.id_persona = v.id_persona_titular
						JOIN core.Grupos g ON g.id = gp.id_grupo
						WHERE g.esFamilia = 1;


						WITH 
							FamiliaFusionada AS (
								    SELECT DISTINCT
								        g.id AS id_grupo,
								        g.descripcion + ' + ' + v.pila_apellidos AS texto_sucio
								    FROM #TmpVinculo v
								    JOIN core.Grupos g ON g.id = v.id_grupo
								),
							Atomizacion AS (
								    SELECT DISTINCT
								        ff.id_grupo,
								        TRIM(s.value) AS apellido_unico
								    FROM FamiliaFusionada ff
								    CROSS APPLY STRING_SPLIT(ff.texto_sucio, '+') s
								    WHERE TRIM(s.value) <> ''
								),
							FamiliaReconstruida AS (
								    SELECT 
								        id_grupo,
								        STRING_AGG(apellido_unico, ' + ') WITHIN GROUP (ORDER BY apellido_unico) AS descripcion_final
								    FROM Atomizacion
								    GROUP BY id_grupo
								)
						UPDATE g  
						SET g.descripcion = fr.descripcion_final
						FROM core.Grupos g
						JOIN FamiliaReconstruida fr ON fr.id_grupo = g.id;

					-- 2) Crear grupos SOLO para los que no tienen
						DECLARE @GruposNuevos TABLE(rn INT IDENTITY, id_persona_titular INT, descripcion VARCHAR(128));
						DECLARE @GruposGenerados TABLE(rn INT IDENTITY, id_grupo INT);

						INSERT INTO @GruposNuevos(id_persona_titular, descripcion)
						SELECT tv.id_persona_titular, MIN(tv.pila_apellidos)
						FROM #TmpVinculo tv
						WHERE tv.id_grupo IS NULL
						GROUP BY tv.id_persona_titular;

						INSERT INTO core.Grupos(descripcion, esFamilia)
						OUTPUT INSERTED.id INTO @GruposGenerados(id_grupo)
						SELECT descripcion, 1
						FROM @GruposNuevos
						ORDER BY rn;

						UPDATE tv
						SET tv.id_grupo = gg.id_grupo
						FROM #TmpVinculo tv
						JOIN @GruposNuevos gn ON gn.id_persona_titular = tv.id_persona_titular
						JOIN @GruposGenerados gg ON gg.rn = gn.rn;

					-- 3) Insertar titular al grupo (si no está) -- 4) Insertar beneficiario al grupo (si no está)
						-- Cargas solapadas: Si por error te mandan un CSV que contiene un 20% de registros del mes pasado,
						-- 		tu lógica simplemente los ignorará y solo procesará el 80% restante.
						INSERT INTO links.Grupos_con_Personas(id_grupo, id_persona)
						SELECT tv.id_grupo, tv.id_persona_titular
						FROM #TmpVinculo tv
						WHERE NOT EXISTS (SELECT 1 FROM links.Grupos_con_Personas gp
						    							WHERE gp.id_grupo = tv.id_grupo AND gp.id_persona = tv.id_persona_titular)
						UNION ALL
						SELECT tv.id_grupo, tv.id_persona_benef
						FROM #TmpVinculo tv
						WHERE NOT EXISTS (SELECT 1 FROM links.Grupos_con_Personas gp
						    							WHERE gp.id_grupo = tv.id_grupo AND gp.id_persona = tv.id_persona_benef);


				-- generacion de cuotas
					DECLARE @periodo_inicio_sistema DATE = (SELECT DATEFROMPARTS(YEAR(inicio_sistema), MONTH(inicio_sistema), 1) FROM params.Plataforma);						
					DECLARE @Tmp_PersonasConUltimaCuota TABLE(
							nro_socio INT PRIMARY KEY,
							periodo_inicio DATE,
							periodo_ultima_cuota DATE
						);
					DECLARE @Tmp_DetallesDelPago TABLE(
							nro_socio INT,
							periodo DATE,
							monto DECIMAL(9,2),

							PRIMARY KEY (nro_socio, periodo)
						);

					INSERT INTO @Tmp_PersonasConUltimaCuota(nro_socio, periodo_inicio, periodo_ultima_cuota)
					SELECT 
						nro_socio,
						CASE WHEN fecha_alta IS NOT NULL
								THEN DATEFROMPARTS(YEAR(fecha_alta), MONTH(fecha_alta), 1)
								ELSE @periodo_inicio_sistema
							END AS periodo_inicio,
						DATEFROMPARTS(YEAR(fecha_ultima_cuota), MONTH(fecha_ultima_cuota), 1) AS periodo_ultima_cuota
					FROM #CookedBulk
					WHERE fecha_ultima_cuota IS NOT NULL;

					WITH GeneradorPeriodos AS (
					    -- Ancla: Empezamos en la fecha de inicio del sistema O su periodo_fecha_alta para cada socio
					    SELECT 
				        nro_socio,
				        periodo_inicio AS periodo,
				        periodo_ultima_cuota -- La meta
					    FROM @Tmp_PersonasConUltimaCuota

					    UNION ALL

					    -- Recursión: Sumamos un mes hasta llegar a la última cuota paga
					    SELECT 
				        nro_socio,
				        DATEADD(MONTH, 1, periodo),
				        periodo_ultima_cuota
					    FROM GeneradorPeriodos
					    WHERE DATEADD(MONTH, 1, periodo) <= periodo_ultima_cuota
						)
					INSERT INTO @Tmp_DetallesDelPago(nro_socio, periodo, monto)
					SELECT 
						gp.nro_socio,
						gp.periodo,
						c.valor
					FROM GeneradorPeriodos gp
					JOIN core.Cuotas c ON c.periodo = gp.periodo
					WHERE NOT EXISTS (SELECT 1 FROM core.Detalles_del_Pago dp
					    			  WHERE dp.nro_socio = gp.nro_socio AND dp.periodo_pago = gp.periodo)
								-- REGLA DE ORO: Si el socio ya tiene este mes registrado, no se inserta de nuevo
					OPTION (MAXRECURSION 5000);

				-- inserto pago de cuenta al dia para todas las personas este normalizadas
					DECLARE @monto_total DECIMAL(19,2) = (SELECT ISNULL(SUM(monto),0) FROM @Tmp_DetallesDelPago);
					DECLARE @IdGenerado_Pagos INT = 
						(SELECT TOP 1 id FROM core.Pagos WHERE origen_carga = 0 AND medio_pago = 0 ORDER BY fecha_hora_pago DESC);

					IF @IdGenerado_Pagos IS NULL
					BEGIN
				    	INSERT INTO core.Pagos(fecha_hora_pago, medio_pago, origen_carga, monto_pagado_real, comentario) VALUES
				    	(CAST(GETDATE() AS DATE), 0, 0, @monto_total, 'CARGA INICIAL MASIVA');

				    	SET @IdGenerado_Pagos = SCOPE_IDENTITY();
					END
					ELSE
					BEGIN
						UPDATE core.Pagos
						SET monto_pagado_real = monto_pagado_real + @monto_total
						WHERE id = @IdGenerado_Pagos
					END

				-- inserto detalle de pago
					INSERT INTO core.Detalles_del_Pago(id_pago, nro_socio, periodo_pago, monto, comentario)
					SELECT
						@IdGenerado_Pagos,
						tdp.nro_socio,
						tdp.periodo,
						tdp.monto,
						'Extraido del excel. pago generado desde la cuota en ese periodo. esto no refleja lo contable real'
					FROM @Tmp_DetallesDelPago tdp;
					
			
				-- reporte
					PRINT '';
					PRINT '              REPORTE DE IMPACTO DE IMPORTACIÓN               ';
					PRINT '--------------------------------------------------------------';
					PRINT '------------------------NUEVOS REGISTROS----------------------';
					SELECT * FROM #Nuevos;
					PRINT '';
					PRINT '';
					PRINT '------------------------CAMBIOS DETECTADOS--------------------';
					SELECT * FROM #Diferencias;
					PRINT '';
					PRINT '';
			IF @TranCount = 0 COMMIT;

			EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
    		PRINT '[INFO] ' + @sp_name + ' ejecutada con exito';
		END TRY
		BEGIN CATCH
		    IF @TranCount = 0 ROLLBACK;
		    EXEC sp_set_session_context @key = N'Origen', @value = NULL;
		    THROW;
		END CATCH;
	END; 
GO
PRINT '[INFO] sp_Importar__Personas Creada';
GO
