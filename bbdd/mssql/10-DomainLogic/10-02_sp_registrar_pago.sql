CREATE OR ALTER PROCEDURE core.sp_Registrar__Pago(@json NVARCHAR(MAX)) AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		IF @json IS NULL OR LEN(TRIM(@json)) <= 10
			THROW 50000, '[ERROR] Algo anda mal con json', 1;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));
		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;

		--creacion tablas
			DROP TABLE IF EXISTS #Pago;
		  	CREATE TABLE #Pago( --singleton
		  		apellido_nombre_origen NVARCHAR(80) CHECK (LEN(TRIM(apellido_nombre_origen)) > 2),
			    fecha_hora_pago DATETIME PRIMARY KEY CHECK (CAST(fecha_hora_pago AS DATE) <= CAST(GETDATE() AS DATE)),
			    medio_pago TINYINT NOT NULL,
				origen_carga TINYINT NOT NULL
			 );
			DROP TABLE IF EXISTS #Detalle_Pago;
			CREATE TABLE #Detalle_Pago(
				nro_socio INT PRIMARY KEY,
				deuda DECIMAL(19,2) NOT NULL CHECK (deuda >= 0) DEFAULT (0),
				cant_cuotas INT NOT NULL CHECK (cant_cuotas > 0)
			 );

		BEGIN TRY
			--parse de json
				INSERT INTO #Pago(apellido_nombre_origen, fecha_hora_pago, medio_pago, origen_carga)
				SELECT 
					dbo.fn_capitalize(TRIM(j1.apellido_nombre_origen)),
					j1.fecha_hora_pago, ---estoy seguro que se manda bien.. es por budibase frontend
					j1.medio_pago, ---estoy seguro que se manda bien.. es por budibase frontend
					j1.origen_carga ---estoy seguro que se manda bien.. es por budibase frontend
				FROM OPENJSON(@json) WITH (
					apellido_nombre_origen NVARCHAR(80),
					fecha_hora_pago DATETIME,
					medio_pago TINYINT,
					origen_carga TINYINT
				 ) AS j1;

				INSERT INTO #Detalle_Pago(nro_socio, cant_cuotas)
				SELECT 
					j2.nro_socio,
					j2.cant_cuotas
				FROM OPENJSON(@json, '$.detalles_pago')	WITH (
					nro_socio INT,
					cant_cuotas INT
				 ) AS j2;
			
			--validamos si existen los lookups
				IF NOT EXISTS (SELECT 1 FROM lookups.Origenes_de_Cobro oc 
							  JOIN #Pago p ON p.origen_carga = oc.id)
				   OR
				   NOT EXISTS (SELECT 1 FROM lookups.Tipos_de_Pago tp 
							  JOIN #Pago p ON p.medio_pago = tp.id)
						THROW 50001, '[ERROR] origen de cobro o medio de pago no existen en la db', 1;

			--validamos si todos los socios existan
				IF EXISTS(
					SELECT 1
					FROM #Detalle_Pago dp 
					LEFT JOIN core.Socios s ON s.nro_socio = dp.nro_socio 
					WHERE s.id IS NULL
				 )
				BEGIN
					SELECT *
				  	FROM #Detalle_Pago dp 
				  	LEFT JOIN core.Socios s ON s.nro_socio = dp.nro_socio 
					WHERE s.id IS NULL;

					THROW 50001, '[ERROR] Uno o varios socios en el detalle de pagos no existen.', 1;
				END

			--validamos que pago y detalle de pago tenga algo
				IF NOT EXISTS(SELECT 1 FROM #Pago) OR NOT EXISTS(SELECT 1 FROM #Detalle_Pago)
		    		THROW 50001, '[ERROR] No hay pago/detalles de pago para procesar.', 1;

			-- VARIABLES GLOBALES
			DECLARE @OjoIntegridadContable BIT = 0;
			DECLARE @msg_integridadContable VARCHAR(64) = 'El pago esta en los ultimos dias habiles. ojo con eso';
			DECLARE @fecha_pago DATE = GETDATE();

			--validamos integridad contable
				IF @fecha_pago > dbo.fn_ULTIMO_5TODIAHABIL_MES(@fecha_pago)
				BEGIN
					SET @OjoIntegridadContable = 1;
					PRINT '[WARN] Estamos intenando pagar mas alla de los ultimos dias habiles. No se asegura integridad contable';
				END

			-- MAS VARIABLES GLOBALES
			DECLARE @PeriodoContable DATE = DATEFROMPARTS(YEAR(@fecha_pago), MONTH(@fecha_pago), 1);
			DECLARE @ValorCuotaDeEseMomento DECIMAL(9,2) = (SELECT valor FROM core.Cuotas WHERE periodo = @PeriodoContable);

			--validamos que exista cuota cargada
				IF @ValorCuotaDeEseMomento IS NULL
					THROW 50002, '[ERROR] No hay cuotas cargadas para este periodo', 1;

			--validamos si las intenciones de pago atrasados son acorde al vencimiento actual (REGLA DE NEGOCIO)
				UPDATE #Detalle_Pago
				SET deuda = cant_cuotas * @ValorCuotaDeEseMomento;
			
			--validamos el formato del nombre
				--Gomez Luis  -->NO
				--, Luis      -->NO
				--Gomez,      -->NO
				--Gomez,,Luis -->NO
				IF EXISTS (
					SELECT 1 FROM #Pago 
				  	WHERE 
				  		apellido_nombre_origen NOT LIKE '%,%' OR
						LEFT(apellido_nombre_origen,1) = ',' OR
							RIGHT(apellido_nombre_origen,1) = ','
   				 )
						THROW 50001, '[ERROR] NO aceptamos el nombre incompleto. Debe ser algo como: "Gomez, luis"', 1;

			--validamos si la persona que ingresa el pago esta o no en la db ---------------revisar id_persona_pagadora
				DECLARE @apellido_origen NVARCHAR(40), @nombre_origen NVARCHAR(40);
				DECLARE @id_persona_pagadora INT, @count_personas INT;

				SELECT
					@apellido_origen = TRIM(SUBSTRING(apellido_nombre_origen, 1, CHARINDEX(',', apellido_nombre_origen)-1)),
					@nombre_origen   = TRIM(SUBSTRING(apellido_nombre_origen, CHARINDEX(',', apellido_nombre_origen)+1,LEN(apellido_nombre_origen)))
				FROM #Pago;

				SELECT 
					@count_personas = COUNT(*), 
				  	@id_persona_pagadora = MAX(id) -- si es uno solo perfecto. aca ya lo tengo
				FROM core.Personas 
				WHERE nombre LIKE '%' + @nombre_origen + '%' AND apellido LIKE '%' + @apellido_origen + '%';

				IF @count_personas > 1 --multiples personas
				BEGIN
					SELECT * FROM core.Personas 
					WHERE nombre LIKE '%' + @nombre_origen + '%' AND apellido LIKE '%' + @apellido_origen + '%';

				  	THROW 50000, '[ERROR] La persona que quiere pagar existe en la db pero esta duplicada!! revisar', 1;
				END

			BEGIN TRANSACTION
				-- si hay persona nueva la inserto
					DECLARE @hayNuevaPersona BIT = 0;

					IF @count_personas = 0 AND (@apellido_origen IS NOT NULL AND @nombre_origen IS NOT NULL) -- ingreso la persona al sistema
					BEGIN
						INSERT INTO core.Personas(__apellido, __nombre)
						SELECT @apellido_origen, @nombre_origen

						SET @id_persona_pagadora = SCOPE_IDENTITY();
						SET @hayNuevaPersona = 1;
						PRINT '[INFO] Se creo una nueva persona';
					END

				-- inserto a tabla Pagos
					DECLARE @monto_total DECIMAL(19,2) = (SELECT SUM(cant_cuotas) * @ValorCuotaDeEseMomento FROM #Detalle_Pago);

					INSERT INTO core.Pagos(fecha_hora_pago, id_persona_pagadora, medio_pago, origen_carga, monto_pagado_real)
					SELECT 
						fecha_hora_pago,
						@id_persona_pagadora,
						medio_pago,
						origen_carga,
						@monto_total
					FROM #Pago;

					DECLARE @id_pago_generado INT = SCOPE_IDENTITY();

				-- inserto a tabla Detalles_del_Pago
					DECLARE @periodo_inicio_sistema DATE = (SELECT DATEFROMPARTS(YEAR(inicio_sistema), MONTH(inicio_sistema), 1) FROM params.Plataforma);
					
					WITH
						UltimoPeriodo AS (
							SELECT
								jdp.nro_socio,
								jdp.cant_cuotas,
								ISNULL(
            						MAX(dp.periodo_pago), 
            						DATEADD(MONTH, -1, ISNULL(DATEFROMPARTS(YEAR(s.fecha_alta), MONTH(s.fecha_alta), 1), @periodo_inicio_sistema))
        						 ) AS ultimo_periodo_pago
							FROM #Detalle_Pago jdp
							LEFT JOIN core.Detalles_del_Pago dp ON dp.nro_socio = jdp.nro_socio
							LEFT JOIN core.Socios s ON s.nro_socio = jdp.nro_socio 
    						GROUP BY jdp.nro_socio, jdp.cant_cuotas, s.fecha_alta
						 ),
						PeriodosGenerados AS (
						    SELECT
						        nro_socio,
						        DATEADD(MONTH, 1, ultimo_periodo_pago) AS periodo_pagado,
						        cant_cuotas,
						        1 AS cuota_actual
						    FROM UltimoPeriodo

						    UNION ALL

						    SELECT
						        nro_socio,
						        DATEADD(MONTH, 1, periodo_pagado),
						        cant_cuotas,
						        cuota_actual + 1
						    FROM PeriodosGenerados
						    WHERE cuota_actual < cant_cuotas
						 )
					INSERT INTO core.Detalles_del_Pago(id_pago, nro_socio, periodo_pago, monto, comentario)
					SELECT
						@id_pago_generado, --el insert anterior
						nro_socio, --para esto tuve que corrobar que existian esos socios (esta hecho antes)
						periodo_pagado,
						@ValorCuotaDeEseMomento,
						CASE WHEN @OjoIntegridadContable = 1 THEN @msg_integridadContable ELSE NULL END
					FROM PeriodosGenerados
					OPTION (MAXRECURSION 1000);

				-- inserto nuevo grupo ;)
					DROP TABLE IF EXISTS #GrupoTentativo;
					DROP TABLE IF EXISTS #GrupoAccion;

					SELECT id_persona
					INTO #GrupoTentativo
					FROM (
					    SELECT @id_persona_pagadora AS id_persona --una sola persona
						WHERE @id_persona_pagadora IS NOT NULL

					    UNION

					    SELECT DISTINCT s.id_persona 	--varias personas
					    FROM #Detalle_Pago dp
					    JOIN core.Socios s ON s.nro_socio = dp.nro_socio
					 ) x;

					DECLARE @cant_personasJson INT = (SELECT COUNT(id_persona) FROM #GrupoTentativo);
					DECLARE @threshold NUMERIC(9,2) = (2.0/3.0);
					DECLARE @hayGrupoNuevo BIT = 0;

					WITH 
						EvaluacionGrupos AS (
							SELECT
						    g.id AS id_grupo,
						    COUNT(DISTINCT gp.id_persona) AS total_db,
						    COUNT(DISTINCT gt.id_persona) AS match_count
							FROM core.Grupos g
							JOIN links.Grupos_con_Personas gp ON gp.id_grupo = g.id
							LEFT JOIN #GrupoTentativo gt ON gt.id_persona = gp.id_persona
							WHERE g.esFamilia = 1
							GROUP BY g.id
					     ),
						AccionesCalculadas AS (
						  	SELECT
						  		id_grupo,
							  	CASE
							  		--grupo exacto
							        WHEN match_count = total_db AND match_count = @cant_personasJson 
							        THEN 'Exacta' --coincidencia exacta
							      	
							      	--subcojunto
							        WHEN match_count = @cant_personasJson AND total_db > @cant_personasJson 
							        THEN 'Exacta' --coincidencia exacta subcojunto
							      	
							      	--supercojunto
							        WHEN match_count = total_db AND @cant_personasJson > total_db 
							        THEN 'Parcial' --coincidencia parcial supercojunto
							      	
							      	--interseccion parcial
							        WHEN CAST(match_count AS NUMERIC(9,2)) / @cant_personasJson >= @threshold 
							        THEN 'Parcial' --coincidencia parcial threshold
						        	
						        	ELSE 'No match'
							  	 END AS accion
							FROM EvaluacionGrupos
						 )
					SELECT id_grupo, accion --por cada grupo hacer merge solo si es esFamilia = 1
					INTO #GrupoAccion
					FROM AccionesCalculadas
					WHERE accion <> 'No match';

					-- Insertar solo los integrantes del JSON que no estén en el grupo DB
					IF EXISTS (SELECT 1 FROM #GrupoAccion WHERE accion = 'Parcial')
					BEGIN
						--actualizamos apellidos familia
						WITH 
							MiembrosNuevos AS (
							    SELECT DISTINCT
							        ga.id_grupo,
							        p.apellido
							    FROM #GrupoAccion ga
							    CROSS JOIN #GrupoTentativo gt
							    JOIN core.Personas p ON p.id = gt.id_persona
							    WHERE 
							    	ga.accion = 'Parcial' AND
							      	NOT EXISTS (SELECT 1 FROM links.Grupos_con_Personas gp 
							          			WHERE gp.id_grupo = ga.id_grupo 
							          			AND gp.id_persona = gt.id_persona)
						 	 ),
							ApellidosParaAgregar AS (
							    SELECT 
						        	id_grupo, 
						        	STRING_AGG(apellido, ' + ') AS pila_apellidos
							    FROM MiembrosNuevos
							    GROUP BY id_grupo
							 ),
							FamiliaFusionada AS (
							    SELECT
							        g.id AS id_grupo,
							        g.descripcion + ' + ' + ca.pila_apellidos AS texto_sucio
							    FROM #GrupoAccion ga
							    JOIN core.Grupos g ON g.id = ga.id_grupo
							    JOIN ApellidosParaAgregar ca ON ca.id_grupo = ga.id_grupo
							    WHERE ga.accion = 'Parcial'
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

						--actualizamos vinculos
						INSERT INTO links.Grupos_con_Personas(id_grupo, id_persona)
						SELECT ga.id_grupo, gt.id_persona
						FROM #GrupoAccion ga
						CROSS JOIN #GrupoTentativo gt
						WHERE 
							ga.accion = 'Parcial' AND
							NOT EXISTS (SELECT 1 FROM links.Grupos_con_Personas gp
					       				WHERE gp.id_grupo = ga.id_grupo AND gp.id_persona = gt.id_persona);

						PRINT '[INFO] Se actualizaron los grupos con nuevos integrantes';
					END
					ELSE IF NOT EXISTS (SELECT 1 FROM #GrupoAccion WHERE accion = 'Exacta') -- creamos grupo nuevo
					BEGIN
						WITH ListaDeApellidos AS ( 
			                SELECT DISTINCT p.apellido
			                FROM core.Personas p
			                JOIN #GrupoTentativo gt ON gt.id_persona = p.id
			             )
			            INSERT INTO core.Grupos(descripcion)
			            SELECT STRING_AGG(apellido, ' + ') WITHIN GROUP (ORDER BY apellido)
			            FROM ListaDeApellidos 

			            DECLARE @id_grupo_generado INT = SCOPE_IDENTITY();

			            INSERT INTO links.Grupos_con_Personas(id_grupo, id_persona)
			            SELECT @id_grupo_generado, id_persona
			            FROM #GrupoTentativo

			            SET @hayGrupoNuevo = 1;
			            PRINT '[INFO] Se registro un nuevo grupo en el sistema';
			        END
			        ELSE
		        	BEGIN
		        		PRINT '[INFO] Ya existia este grupo en el sistema';
		        	END

				-- Registrar evento de nueva persona
					IF @hayNuevaPersona = 1
					BEGIN
						INSERT INTO logs.Bitacora(evento, entidad_afectada, id_afectada, entidad_relacionada, id_relacionado, detalle)
						SELECT 
							'PERSONA_NUEVA',
							'Persona', CAST(@id_persona_pagadora AS VARCHAR(10)),
							'Pago', CAST(@id_pago_generado AS VARCHAR(10)),
							'el pago vino con una persona que no exise en nuestra db'
					END
				-- Registrar evento de grupo nuevo
					IF @hayGrupoNuevo = 1
					BEGIN
						INSERT INTO logs.Bitacora(evento, entidad_afectada, id_afectada, entidad_relacionada, id_relacionado, detalle)
						SELECT 
							'GRUPO_NUEVO',
							'Grupo', CAST(@id_grupo_generado AS VARCHAR(10)),
							'Pago', CAST(@id_pago_generado AS VARCHAR(10)),
							'Asociamos la persona que pago con un nuevo atajo de grupo de pago'
					END
				-- Registrar evento de pago registrado
					INSERT INTO logs.Bitacora(evento, entidad_afectada, id_afectada, contexto, entidad_relacionada, id_relacionado, detalle)
					SELECT 
						'PAGO_REGISTRADO',
						'Socio', CAST(nro_socio AS VARCHAR(10)),
						'Abono x' + CAST(cant_cuotas AS VARCHAR(10)) + ' cuotas',
						'Pago', CAST(@id_pago_generado AS VARCHAR(10)),
						'Monto total de $' + CAST(deuda AS VARCHAR(20))
					FROM #Detalle_Pago;
			COMMIT;
			EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;

    		PRINT '[INFO] Se registro el pago en el sistema';
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0 ROLLBACK;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			THROW;
		END CATCH
	END;
GO
PRINT '[INFO] sp_Registrar__Pago Creada';
GO
