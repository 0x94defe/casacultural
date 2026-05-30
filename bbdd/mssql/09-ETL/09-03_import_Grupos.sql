CREATE OR ALTER PROCEDURE core.sp_Importar__Vinculos(@json NVARCHAR(MAX)) AS
		--NOTA: este sp debe ser idempotente
	BEGIN
   		IF @json IS NULL OR LEN(@json) < 2
				THROW 50000, '[ERROR] Agumento incorrecto', 1;

		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		DECLARE @sp_name SYSNAME = (SELECT OBJECT_NAME(@@PROCID));

		EXEC sp_set_session_context @key = N'UsuarioReal', @value = NULL;
		EXEC sp_set_session_context @key = N'Origen', @value = @sp_name;


		--tablas
			DROP TABLE IF EXISTS #EntidadesVinculadas;
			CREATE TABLE #EntidadesVinculadas(
			    rn INT IDENTITY PRIMARY KEY,
			    grupo_interno INT NOT NULL,
			    nro_socio INT,
			    id_persona INT
			  );
			DROP TABLE IF EXISTS #Grupos;
			CREATE TABLE #Grupos(
					rn INT IDENTITY PRIMARY KEY,
			    grupo_interno INT NOT NULL,
			    id_grupo INT,
			    esFamilia BIT NOT NULL
			  );
		
		--carga
			INSERT INTO #EntidadesVinculadas(grupo_interno, nro_socio, id_persona)
			SELECT
			    g.grupo_interno,
			    CASE WHEN i.tipo = 'socio' THEN i.id ELSE NULL END,
			    CASE WHEN i.tipo = 'persona' THEN i.id ELSE NULL END
			FROM OPENJSON(@json) WITH (
			    grupo_interno INT,
			    esFamilia BIT,
			    integrantes NVARCHAR(MAX) AS JSON
				) g
			CROSS APPLY OPENJSON(g.integrantes) WITH (
			    tipo VARCHAR(20),
			    id INT
				) i;

			INSERT INTO #Grupos(grupo_interno, esFamilia)
			SELECT DISTINCT
			    g.grupo_interno,
			    g.esFamilia
			FROM OPENJSON(@json) WITH (
			    grupo_interno INT,
			    esFamilia BIT,
			    integrantes NVARCHAR(MAX) AS JSON
				) g

		--verif
			IF NOT EXISTS (SELECT 1 FROM #Grupos)
	    	BEGIN
	    		PRINT '[WARN] No se recibieron datos.. nada que hacer.';
	    		RETURN;
	    	END

	   		IF EXISTS (SELECT 1 FROM #EntidadesVinculadas GROUP BY grupo_interno HAVING COUNT(*) < 2)
	    	BEGIN
	    		--para debug
	    		SELECT grupo_interno FROM #EntidadesVinculadas GROUP BY grupo_interno HAVING COUNT(*) < 2;

	    		THROW 50000, '[ERROR] Que sentido tiene agregar 1 grupo si no tengo por lo menos 2 personas?? revisar.', 1;
	    	END

			IF EXISTS (
					SELECT 1 
					FROM core.Personas p 
					LEFT JOIN #EntidadesVinculadas v ON v.id_persona = p.id
					WHERE p.id IS NULL
				)
			BEGIN
				--debug
				SELECT * 
				FROM core.Personas p 
				LEFT JOIN #EntidadesVinculadas v ON v.id_persona = p.id
				WHERE p.id IS NULL;

				THROW 50000, '[ERROR] Hay una persona que no existe. favor revisar.', 1;
			END


		DECLARE @TranCount INT = @@TRANCOUNT;
		BEGIN TRY
			IF @TranCount = 0 BEGIN TRAN;
				SET NOCOUNT OFF;

				-- un socio NO puede existir sin una entidad persona, entonces agregamos peronas faltantes
					DROP TABLE IF EXISTS #Personas_Insertadas;
					CREATE TABLE #Personas_Insertadas(
							rn INT IDENTITY PRIMARY KEY,
							id_persona INT
					  );
					DROP TABLE IF EXISTS #Socios_Insertados;
					CREATE TABLE #Socios_Insertados(
							rn INT IDENTITY PRIMARY KEY,
							nro_socio INT
					  );

					INSERT #Socios_Insertados(nro_socio)
					SELECT DISTINCT v.nro_socio
					FROM #EntidadesVinculadas v
					WHERE NOT EXISTS(SELECT 1 FROM core.Socios s WHERE s.nro_socio = v.nro_socio);

					IF EXISTS (SELECT 1 FROM #Socios_Insertados)
					BEGIN
						-- Primero insertamos las personas.
						INSERT INTO core.Personas(dni)
						OUTPUT INSERTED.id INTO #Personas_Insertadas(id_persona)
						SELECT NULL
						FROM #Socios_Insertados
						ORDER BY rn;

						-- luego los socios
						INSERT INTO core.Socios(nro_socio, id_persona)
						SELECT s.nro_socio, p.id_persona
						FROM #Socios_Insertados s
						JOIN #Personas_Insertadas p ON p.rn = s.rn;

						-- completamos la tabla de socios vinculados, para los coicidenntes
						UPDATE v 
						SET v.id_persona = p.id_persona
						FROM #EntidadesVinculadas v
						JOIN #Socios_Insertados s ON s.nro_socio = v.nro_socio
						JOIN #Personas_Insertadas p ON p.rn = s.rn;
					END

				-- completamos la tabla de socios vinculados
					--tengo el socio, cual es su id_persona?
					UPDATE v 
					SET	v.id_persona = s.id_persona
					FROM #EntidadesVinculadas v
					JOIN core.Socios s ON s.nro_socio = v.nro_socio;

					-- tengo id_persona, sera su nro_socio?
					UPDATE v 
					SET	v.nro_socio = s.nro_socio
					FROM #EntidadesVinculadas v
					JOIN core.Socios s ON s.id = v.id_persona;

				-- "Resolución de Entidades" (Entity Resolution)
					DECLARE @threshold DECIMAL(9,2) = (2.0/3.0);
					DROP TABLE IF EXISTS #ResultadosEvaluacion;
					DROP TABLE IF EXISTS #AccionPorGrupo;

					--resultados
						WITH 
							personasJson AS (
									SELECT v.grupo_interno, COUNT(DISTINCT v.id_persona) AS total_json
									FROM #EntidadesVinculadas v
									GROUP BY v.grupo_interno
								),
							personasDb AS (
									SELECT gp.id_grupo, COUNT(DISTINCT gp.id_persona) AS total_db
									FROM core.Grupos g
									JOIN links.Grupos_con_Personas gp ON gp.id_grupo = g.id
									WHERE g.esFamilia = 1
									GROUP BY gp.id_grupo
								),
							EvaluacionMatriz AS (
								    SELECT
							        v.grupo_interno,
							        g.id AS id_grupo_db,
							        pjson.total_json,
							        pdb.total_db,
							        COUNT(DISTINCT v.id_persona) AS match_count
								    FROM #EntidadesVinculadas v
								    JOIN links.Grupos_con_Personas gp ON v.id_persona = gp.id_persona
								    JOIN core.Grupos g ON g.id = gp.id_grupo
								    JOIN personasJson pjson ON pjson.grupo_interno = v.grupo_interno
								    JOIN personasDb pdb ON pdb.id_grupo = g.id
									WHERE g.esFamilia = 1
								    GROUP BY v.grupo_interno, g.id, pjson.total_json, pdb.total_db
								),
							GrupoAcciones AS (
								    SELECT 
								        grupo_interno,
								        id_grupo_db,
								        match_count,
										total_json,
										total_db,
								        CASE 
								            -- Exacto o la DB ya lo contiene: No hacer nada
								            WHEN match_count = total_json AND total_db >= total_json THEN 'Exacta'
								            -- El JSON es más grande que la DB pero la contiene: Completar grupo DB
								            WHEN match_count = total_db AND total_json > total_db THEN 'Parcial'
								            -- Intersección fuerte (>= 2/3): Completar grupo DB
								            WHEN CAST(match_count AS DECIMAL(9,2)) / total_json >= @threshold THEN 'Parcial'
								            ELSE 'No match'
								        	END AS accion_tentativa
								    FROM EvaluacionMatriz
								)
						SELECT * 
						INTO #ResultadosEvaluacion 
						FROM GrupoAcciones;
						
					--resumen
						WITH 
							ResumenPorGrupo AS (
								    SELECT 
							        pj.grupo_interno,
									re.id_grupo_db,
							        MAX(CASE WHEN re.accion_tentativa = 'Parcial' THEN 1 ELSE 0 END) AS tiene_parcial,
							        MAX(CASE WHEN re.accion_tentativa = 'Exacta' THEN 1 ELSE 0 END) AS tiene_exacta
								    FROM (SELECT DISTINCT grupo_interno FROM #EntidadesVinculadas) pj
									LEFT JOIN #ResultadosEvaluacion re ON re.grupo_interno = pj.grupo_interno
									GROUP BY pj.grupo_interno, re.id_grupo_db
								),
							ClasificacionInicial AS (
								    SELECT 
							        grupo_interno,
									id_grupo_db,
							        CASE 
							            WHEN tiene_parcial = 1 THEN 'PROCESAR_MERGE'
							            WHEN tiene_exacta = 1 THEN 'DESCARTAR_YA_EXISTE'
							            ELSE 'PROCESAR_NUEVO'
								        END AS decision
								    FROM ResumenPorGrupo
								),
							SalvaguardaTransitividad AS (
									SELECT 
										ci.grupo_interno,
										MIN(gp.id_grupo) AS id_grupo_candidato
									FROM ClasificacionInicial ci
									JOIN #EntidadesVinculadas v ON v.grupo_interno = ci.grupo_interno
									JOIN links.Grupos_con_Personas gp ON gp.id_persona = v.id_persona
									JOIN core.Grupos g ON g.id = gp.id_grupo
									WHERE ci.decision = 'PROCESAR_NUEVO' AND g.esFamilia = 1
									GROUP BY ci.grupo_interno
									HAVING COUNT(DISTINCT gp.id_grupo) = 1 
								)
						SELECT 
							ci.grupo_interno,
							ISNULL(ci.id_grupo_db, st.id_grupo_candidato) AS id_grupo_db,
							CASE WHEN ci.decision = 'PROCESAR_NUEVO' AND st.id_grupo_candidato IS NOT NULL 
									THEN 'PROCESAR_MERGE' 
									ELSE ci.decision 
								END AS decision
						INTO #AccionPorGrupo
						FROM ClasificacionInicial ci
						LEFT JOIN SalvaguardaTransitividad st ON st.grupo_interno = ci.grupo_interno;
						
					--actualizamos
						--CASO MERGE: Actualizar descripciones y agregar miembros faltantes
						IF EXISTS (SELECT 1 FROM #AccionPorGrupo WHERE decision = 'PROCESAR_MERGE')
						BEGIN
							--actualizamos familia
						    WITH 
						    	ApellidosNuevos AS (
								        SELECT DISTINCT 
								        	a.id_grupo_db,
								        	p.apellido
								        FROM #AccionPorGrupo a
								        JOIN #EntidadesVinculadas v ON v.grupo_interno = a.grupo_interno
								        JOIN core.Personas p ON p.id = v.id_persona
								        WHERE 
								        	a.decision = 'PROCESAR_MERGE' AND
								          	NOT EXISTS (SELECT 1 FROM links.Grupos_con_Personas gp 
								                        WHERE gp.id_grupo = a.id_grupo_db AND gp.id_persona = v.id_persona)
							    	),
							    ConcatApellidos AS (
								        SELECT 
								        	id_grupo_db,
								        	STRING_AGG(apellido, ' + ') AS pila_apellidos
								        FROM ApellidosNuevos
								        GROUP BY id_grupo_db
							    	),
							    FamiliaFusionada AS (
									    SELECT
									        g.id AS id_grupo,
									        g.descripcion + ' + ' + ca.pila_apellidos AS texto_sucio
									    FROM #AccionPorGrupo a
									    JOIN core.Grupos g ON g.id = a.id_grupo_db
									    JOIN ConcatApellidos ca ON ca.id_grupo_db = a.id_grupo_db
									    WHERE a.decision = 'PROCESAR_MERGE'
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
						    JOIN FamiliaReconstruida fr ON g.id = fr.id_grupo;

						    -- Insertar nuevos miembros en la intermedia
						    INSERT INTO links.Grupos_con_Personas (id_grupo, id_persona)
						    SELECT DISTINCT 
						    	a.id_grupo_db,
						    	v.id_persona
						    FROM #AccionPorGrupo a
						    JOIN #EntidadesVinculadas v ON v.grupo_interno = a.grupo_interno
						    WHERE 
						    	a.decision = 'PROCESAR_MERGE' AND
						      	NOT EXISTS (SELECT 1 FROM links.Grupos_con_Personas gp 
						                    WHERE gp.id_grupo = a.id_grupo_db AND gp.id_persona = v.id_persona);
						END

					--creamos
						-- les doy apellidos para buscar a esa familia visualmente porque por tablas ya estan enlazados.
						-- es una ayuda visual al operador tener una pila de apellidos
						IF EXISTS (SELECT 1 FROM #AccionPorGrupo WHERE decision = 'PROCESAR_NUEVO')
						BEGIN
							DECLARE @GruposNuevos TABLE(
									rn INT IDENTITY PRIMARY KEY,
									grupo_interno INT,
				          			descripcion NVARCHAR(128),
				          			esFamilia BIT
				          		);
							DECLARE @GruposGenerados TABLE (
									rn INT IDENTITY PRIMARY KEY,
									id_grupo INT
							  	);

							--preparamos datos: apellidos y esFamilia
						    WITH 
				          		ApellidosPorGrupo AS (
						              SELECT
						                v.grupo_interno,
						                CASE WHEN PATINDEX('%[A-Z]. %', p.apellido) <> 0 
															  THEN TRIM(STUFF(p.apellido, PATINDEX('%[A-Z]. %', p.apellido), 3, ''))
																ELSE p.apellido	
															END AS apellido_normalizado
						              FROM #AccionPorGrupo a
						              JOIN #EntidadesVinculadas v ON v.grupo_interno = a.grupo_interno
						              JOIN core.Personas p ON p.id = v.id_persona
						              WHERE a.decision = 'PROCESAR_NUEVO'
				        			),
				          		ApellidosUnicosPorGrupo AS (
							            SELECT DISTINCT
							                grupo_interno,
							            	REPLACE(apellido_normalizado, ' De ', ' ') AS apellido_normalizado
							            FROM ApellidosPorGrupo
				        			),
								Filtrados AS (
									-- Buscamos si existe OTRO apellido en el mismo grupo que contenga a este
									-- Si "Alcalde" está contenido en "Alcalde Bessia", el NOT EXISTS lo vuela
										SELECT 
										  a1.grupo_interno, 
										  a1.apellido_normalizado
										FROM ApellidosUnicosPorGrupo a1
										WHERE NOT EXISTS (
											  	SELECT 1 
											  	FROM ApellidosUnicosPorGrupo a2
											  	WHERE 
											  		a1.grupo_interno = a2.grupo_interno AND
											    	a1.apellido_normalizado <> a2.apellido_normalizado AND
												  	' ' + a2.apellido_normalizado + ' ' LIKE '% ' + a1.apellido_normalizado + ' %'
										  	)
									),
								SinPermutaciones AS (
								  	-- MIN asegura que si hay dos espejados, nos quedamos con uno solo
								  	-- Creamos una huella con las palabras ordenadas alfabéticamente
										SELECT 
											grupo_interno,
											MIN(apellido_normalizado) AS apellido_final
										FROM (
											SELECT 
												grupo_interno, 
												apellido_normalizado,
												(SELECT STRING_AGG(TRIM(value), ' ') WITHIN GROUP (ORDER BY value)
											     FROM STRING_SPLIT(apellido_normalizado, ' ')) AS huella
											FROM Filtrados
										 ) t
										GROUP BY grupo_interno, huella COLLATE Latin1_General_CI_AI
									),
				          		NuevosGrupos AS (
							            SELECT
							                grupo_interno,
							                STRING_AGG(apellido_final, ' + ') WITHIN GROUP (ORDER BY apellido_final) AS muchos_apellidos
							            FROM SinPermutaciones
							            GROUP BY grupo_interno
									),
				          		AgregarEsFamilia AS (
						          		SELECT 
						          			ng.grupo_interno,
						          			COALESCE(ng.muchos_apellidos, 'error_apellidos') AS descripcion,
						          			g.esFamilia
						          		FROM NuevosGrupos ng 
						          		JOIN #Grupos g ON g.grupo_interno = ng.grupo_interno
					          		)
					        INSERT INTO @GruposNuevos
					        SELECT *
					        FROM AgregarEsFamilia;

							-- insert nuevo grupo
						    INSERT INTO core.Grupos(descripcion, esFamilia)
						    OUTPUT INSERTED.id INTO @GruposGenerados(id_grupo)
						    SELECT descripcion, esFamilia 
						    FROM @GruposNuevos
						    ORDER BY grupo_interno;

							-- insert relaciones del grupo
							INSERT INTO links.Grupos_con_Personas(id_grupo, id_persona)
							SELECT gg.id_grupo, v.id_persona
							FROM @GruposNuevos gn
							JOIN @GruposGenerados gg ON gg.rn = gn.rn 
							JOIN #EntidadesVinculadas v ON v.grupo_interno = gn.grupo_interno;

						    PRINT '[INFO] Procesando creación de grupos nuevos...';
						END
			IF @TranCount = 0 COMMIT;

			EXEC internal.sp_Registrar__Ejecucion_Proceso @sp_name;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			PRINT '[INFO] ' + @sp_name + ' ejecutada con exito';
		END TRY
		BEGIN CATCH
			IF @TranCount = 0 ROLLBACK;
			EXEC sp_set_session_context @key = N'Origen', @value = NULL;
			THROW;
		END CATCH
	END;
GO
PRINT '[INFO] sp_Importar__Vinculos Creada';
