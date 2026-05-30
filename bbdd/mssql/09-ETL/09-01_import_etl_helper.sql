CREATE OR ALTER PROCEDURE internal.sp_Helper__Importar_Esquema_normal(@csvPath VARCHAR(MAX)) AS
	BEGIN
		SET NOCOUNT ON;
		-- tablas
			DROP TABLE IF EXISTS #RawBulk;
			CREATE TABLE #RawBulk(
					fecha_ultima_cuota VARCHAR(20),
					numero_socio VARCHAR(15),
					apellido_nombre NVARCHAR(100),
					documento VARCHAR(15),
					direccion NVARCHAR(100),
					telefono VARCHAR(15),
					celular VARCHAR(15),
					correo_electronico VARCHAR(125),
					fecha_nacimiento NVARCHAR(40),
					observaciones NVARCHAR(500),
					socio_desde NVARCHAR(40),
					titular_cuenta NVARCHAR(100),
					fecha_baja VARCHAR(20),
					nacionalidad NVARCHAR(20),
					genero VARCHAR(5)
				);
			DROP TABLE IF EXISTS #CleanedBulk;
			CREATE TABLE #CleanedBulk(
					fecha_ultima_cuota VARCHAR(20),
					numero_socio VARCHAR(15),
					apellido_nombre NVARCHAR(100),
					documento VARCHAR(15),
					direccion NVARCHAR(100),
					telefono VARCHAR(15),
					celular VARCHAR(15),
					correo_electronico VARCHAR(125),
					fecha_nacimiento NVARCHAR(40),
					observaciones NVARCHAR(500),
					socio_desde NVARCHAR(40),
					titular_cuenta NVARCHAR(100),
					fecha_baja VARCHAR(20),
					nacionalidad NVARCHAR(20),
					genero VARCHAR(5),
					----------------------------------
					rn INT IDENTITY PRIMARY KEY
				);
			DROP TABLE IF EXISTS #ParsedBulk;
			CREATE TABLE #ParsedBulk(
					fecha_ultima_cuota VARCHAR(20),
					numero_socio VARCHAR(15),
					apellido_nombre NVARCHAR(100),
					documento VARCHAR(15),
					direccion NVARCHAR(100),
					telefono VARCHAR(15),
					celular VARCHAR(15),
					correo_electronico VARCHAR(125),
					fecha_nacimiento NVARCHAR(40),
					observaciones NVARCHAR(500),
					socio_desde NVARCHAR(40),
					titular_cuenta NVARCHAR(100),
					fecha_baja VARCHAR(20),
					nacionalidad NVARCHAR(20),
					genero VARCHAR(5),
					----------------------------------
					rn INT PRIMARY KEY
				);
			DROP TABLE IF EXISTS #CastedBulk;
			CREATE TABLE #CastedBulk(
					fecha_ultima_cuota DATE,
					numero_socio INT,
					apellido_nombre NVARCHAR(100),
					documento INT,
					direccion NVARCHAR(100),
					telefono VARCHAR(15),
					celular VARCHAR(15),
					correo_electronico VARCHAR(125),
					fecha_nacimiento DATE,
					observaciones NVARCHAR(500),
					socio_desde DATE,
					titular_cuenta NVARCHAR(100),
					fecha_baja DATE,
					nacionalidad NVARCHAR(20),
					genero CHAR(1),
					----------------------------------
					rn INT PRIMARY KEY
				);
			DROP TABLE IF EXISTS #RefinedBulk;
			CREATE TABLE #RefinedBulk(
					fecha_ultima_cuota DATE,
					numero_socio INT,
					apellido_nombre NVARCHAR(100),
					documento INT,
					direccion NVARCHAR(100),
					telefono VARCHAR(15),
					celular VARCHAR(15),
					correo_electronico VARCHAR(125),
					fecha_nacimiento DATE,
					observaciones NVARCHAR(500),
					socio_desde DATE,
					titular_cuenta NVARCHAR(100),
					fecha_baja DATE,
					nacionalidad NVARCHAR(20),
					genero CHAR(1),
					----------------------------------
					rn INT PRIMARY KEY
				);
			
			DROP TABLE IF EXISTS #FinalBulk;
			CREATE TABLE #FinalBulk(
					fecha_ultima_cuota DATE,
					nro_socio INT,
					nombre NVARCHAR(50),
					apellido NVARCHAR(50),
					dni INT,
					domicilio NVARCHAR(50),
					ciudad NVARCHAR(50),
					telefono VARCHAR(15),
					celular VARCHAR(15),
					email VARCHAR(125),
					fecha_nacimiento DATE,
					observaciones NVARCHAR(500),
					fecha_alta DATE,
					nombre_titular_cuenta NVARCHAR(50),
					apellido_titular_cuenta NVARCHAR(50),
					fecha_baja DATE,
					nacionalidad NVARCHAR(20),
					genero CHAR(1),
					----------------------------------
					rn INT PRIMARY KEY
				);
			

			DROP TABLE IF EXISTS #BadDataBulk;
			CREATE TABLE #BadDataBulk(
					esUltimaCuotaErronea NVARCHAR(20),
					esNumeroSocioErroneo VARCHAR(15),
					esApellidoNombreErroneo NVARCHAR(100),
					esDocumentoErroneo VARCHAR(15),
					esDireccionErronea NVARCHAR(100),
					esTelefonoErroneo VARCHAR(15),
					esCelularErroneo VARCHAR(15),
					esCorreoErroneo VARCHAR(125),
					esFNacimientoErronea NVARCHAR(40),
					esObservacionErronea NVARCHAR(500),
					esSocioDesdeErroneo NVARCHAR(40),
					esTitularErroneo NVARCHAR(100),
					esFechaBajaErronea NVARCHAR(20),
					esNacionalidadErronea NVARCHAR(20),
					esGeneroErroneo CHAR(1),
					-----------------------------
					rn INT PRIMARY KEY
				);
			DROP TABLE IF EXISTS #BadCastBulk;
			CREATE TABLE #BadCastBulk(
					esUltimaCuotaErronea NVARCHAR(20),
					esNumeroSocioErroneo VARCHAR(15),
					esApellidoNombreErroneo NVARCHAR(100),
					esDocumentoErroneo VARCHAR(15),
					esDireccionErronea NVARCHAR(100),
					esTelefonoErroneo VARCHAR(15),
					esCelularErroneo VARCHAR(15),
					esCorreoErroneo VARCHAR(125),
					esFNacimientoErronea NVARCHAR(40),
					esObservacionErronea NVARCHAR(500),
					esSocioDesdeErroneo NVARCHAR(40),
					esTitularErroneo NVARCHAR(100),
					esFechaBajaErronea NVARCHAR(20),
					esNacionalidadErronea NVARCHAR(20),
					esGeneroErroneo CHAR(1),
					-----------------------------
					rn INT PRIMARY KEY
				);
			DROP TABLE IF EXISTS #BadDomainBulk;
			CREATE TABLE #BadDomainBulk(
					esUltimaCuotaErronea NVARCHAR(20),
					esNumeroSocioErroneo VARCHAR(15),
					esApellidoNombreErroneo NVARCHAR(100),
					esDocumentoErroneo VARCHAR(15),
					esDireccionErronea NVARCHAR(100),
					esTelefonoErroneo VARCHAR(15),
					esCelularErroneo VARCHAR(15),
					esCorreoErroneo VARCHAR(125),
					esFNacimientoErronea NVARCHAR(40),
					esObservacionErronea NVARCHAR(500),
					esSocioDesdeErroneo NVARCHAR(40),
					esTitularErroneo NVARCHAR(100),
					esFechaBajaErronea NVARCHAR(20),
					esNacionalidadErronea NVARCHAR(20),
					esGeneroErroneo CHAR(1),
					-----------------------------
					rn INT PRIMARY KEY
				);

		-- extract stage
			DECLARE @sql NVARCHAR(MAX) = N'
				BULK INSERT #RawBulk 
			    FROM ''' + @csvPath + N'''
				WITH (FIRSTROW = 2,
					  FIELDTERMINATOR = ''|'',
					  ROWTERMINATOR = ''\n'',
					  CODEPAGE = ''65001'');';
			EXEC sp_executesql @sql;

			UPDATE #RawBulk SET
				documento = TRIM(documento), 
				direccion = TRIM(direccion),
				telefono = TRIM(telefono),
				celular = TRIM(celular),
				socio_desde = TRIM(socio_desde),
				correo_electronico = TRIM(correo_electronico),
				------------- datos informativos que no me interesa presicion
				numero_socio = TRIM(numero_socio),
				apellido_nombre = TRIM(apellido_nombre),
				fecha_nacimiento = TRIM(fecha_nacimiento),
				observaciones = TRIM(observaciones),
				fecha_ultima_cuota = TRIM(fecha_ultima_cuota),
				titular_cuenta = TRIM(titular_cuenta),
				fecha_baja = TRIM(fecha_baja),
				nacionalidad = TRIM(nacionalidad),
				genero = TRIM(genero);

			UPDATE #RawBulk SET
				documento = CASE WHEN documento = '' THEN NULL ELSE documento END,
				direccion = CASE WHEN direccion = '' THEN NULL ELSE direccion END,
				telefono = CASE WHEN telefono = '' THEN NULL ELSE telefono END,
				celular = CASE WHEN celular = '' THEN NULL ELSE celular END,
				socio_desde = CASE WHEN socio_desde = '' THEN NULL ELSE socio_desde END, 
				correo_electronico = CASE WHEN correo_electronico = '' THEN NULL ELSE correo_electronico END,
				------------- ------------- ------------- ------------- -------------
				numero_socio = CASE WHEN numero_socio = '' THEN NULL ELSE numero_socio END,
				apellido_nombre = CASE WHEN apellido_nombre = '' THEN NULL ELSE apellido_nombre END,
				fecha_nacimiento = CASE WHEN fecha_nacimiento = '' THEN NULL ELSE fecha_nacimiento END,
				observaciones = CASE WHEN observaciones = '' THEN NULL ELSE observaciones END,
				fecha_ultima_cuota = CASE WHEN fecha_ultima_cuota = '' THEN NULL ELSE fecha_ultima_cuota END,
				titular_cuenta = CASE WHEN titular_cuenta = '' THEN NULL ELSE titular_cuenta END,
				fecha_baja = CASE WHEN fecha_baja = '' THEN NULL ELSE fecha_baja END,
				nacionalidad = CASE WHEN nacionalidad = '' THEN NULL ELSE nacionalidad END,
				genero = CASE WHEN genero = '' THEN NULL ELSE genero END;

			INSERT INTO #CleanedBulk --rn identity se agrega solo
			SELECT *
			FROM #RawBulk;

		-- transform stage/normalize
			INSERT INTO #BadDataBulk
	    	SELECT
				CASE WHEN dbo.fn_checkBadDataMark(fecha_ultima_cuota) = 1 OR (fecha_ultima_cuota IS NOT NULL AND dbo.fn_numMonth(fecha_ultima_cuota) IS NULL) 
						 THEN fecha_ultima_cuota END AS esUltimaCuotaErronea,
				CASE WHEN dbo.fn_checkBadDataMark(numero_socio) = 1 
						 THEN numero_socio END AS esNumeroSocioErroneo,			
				CASE WHEN dbo.fn_checkBadDataMark(apellido_nombre) = 1 AND LEN(apellido_nombre) < 3
						 THEN apellido_nombre END AS esApellidoNombreErroneo,				  
				CASE WHEN dbo.fn_checkBadDataMark(documento) = 1 
						 THEN documento END AS esDocumentoErroneo,
				CASE WHEN dbo.fn_checkBadDataMark(direccion) = 1 
						 THEN direccion END AS esDireccionErronea,
				CASE WHEN dbo.fn_checkBadDataMark(telefono) = 1 
						 THEN telefono END AS esTelefonoErroneo,
				CASE WHEN dbo.fn_checkBadDataMark(celular) = 1 
						 THEN celular END AS esCelularErroneo,
				CASE WHEN dbo.fn_checkBadDataMark(correo_electronico) = 1 
						 THEN correo_electronico END AS esCorreoErroneo,
				CASE WHEN dbo.fn_checkBadDataMark(fecha_nacimiento) = 1 
						 THEN fecha_nacimiento END AS esFNacimientoErronea,
				NULL AS esObservacionErronea, -- no aplica
				CASE WHEN dbo.fn_checkBadDataMark(socio_desde) = 1
						 THEN socio_desde END AS esSocioDesdeErroneo,
				CASE WHEN dbo.fn_checkBadDataMark(titular_cuenta) = 1
						 THEN titular_cuenta END AS esTitularErroneo,
				CASE WHEN dbo.fn_checkBadDataMark(fecha_baja) = 1 OR (fecha_baja IS NOT NULL AND dbo.fn_numMonth(fecha_baja) IS NULL)
						 THEN fecha_baja END AS esFechaBajaErronea,
				CASE WHEN dbo.fn_checkBadDataMark(nacionalidad) = 1
						 THEN nacionalidad END AS esNacionalidadErronea,
				CASE WHEN dbo.fn_checkBadDataMark(genero) = 1
						 THEN genero END AS esGeneroErroneo, 		 			
				rn
			FROM #CleanedBulk;

			UPDATE p SET
				documento = CASE WHEN esDocumentoErroneo IS NOT NULL THEN NULL ELSE documento END,
				direccion = CASE WHEN esDireccionErronea IS NOT NULL THEN NULL ELSE direccion END,
				celular = CASE WHEN esCelularErroneo IS NOT NULL THEN NULL ELSE celular END,
				socio_desde = CASE WHEN esSocioDesdeErroneo IS NOT NULL THEN NULL ELSE socio_desde END,
				numero_socio = CASE WHEN esNumeroSocioErroneo IS NOT NULL THEN NULL ELSE numero_socio END,
				fecha_ultima_cuota = CASE WHEN esUltimaCuotaErronea IS NOT NULL THEN NULL ELSE fecha_ultima_cuota END,
				fecha_baja = CASE WHEN esFechaBajaErronea IS NOT NULL THEN NULL ELSE fecha_baja END,
				correo_electronico = CASE WHEN esCorreoErroneo IS NOT NULL THEN NULL ELSE correo_electronico END,
				------------- -------------------- -------------- -----------------
				telefono = CASE WHEN esTelefonoErroneo IS NOT NULL THEN NULL ELSE telefono END, 
				apellido_nombre = CASE WHEN esApellidoNombreErroneo IS NOT NULL THEN NULL ELSE apellido_nombre END,
				fecha_nacimiento = CASE WHEN esFNacimientoErronea IS NOT NULL THEN NULL ELSE fecha_nacimiento END,
				observaciones = CASE WHEN esObservacionErronea IS NOT NULL THEN NULL ELSE observaciones END,
				titular_cuenta = CASE WHEN esTitularErroneo IS NOT NULL THEN NULL ELSE titular_cuenta END,
				nacionalidad = CASE WHEN esNacionalidadErronea IS NOT NULL THEN NULL ELSE nacionalidad END,
				genero = CASE WHEN esGeneroErroneo IS NOT NULL THEN NULL ELSE genero END
			FROM #CleanedBulk p
			JOIN #BadDataBulk b ON b.rn = p.rn;


			INSERT INTO #ParsedBulk
			SELECT *
			FROM #CleanedBulk;

		-- transform stage/validation check
			UPDATE #ParsedBulk SET
				documento = dbo.fn_getNumber(documento), 
				direccion = dbo.fn_capitalize(direccion),
				telefono = dbo.fn_getNumber(telefono),
				celular = dbo.fn_getNumber(celular),
				socio_desde = REPLACE(socio_desde, '.', '/'),
				fecha_ultima_cuota = LOWER(fecha_ultima_cuota),
				fecha_baja = LOWER(fecha_baja),
				correo_electronico = LOWER(correo_electronico),
				------------- datos informativos que no me interesa presicion
				numero_socio = dbo.fn_getNumber(numero_socio),
				apellido_nombre = REPLACE(REPLACE(dbo.fn_capitalize(apellido_nombre), '/', ''), '  ', ' '),
				fecha_nacimiento = REPLACE(fecha_nacimiento, '.', '/'),
				observaciones = LOWER(observaciones),
				titular_cuenta = dbo.fn_capitalize(titular_cuenta),
				nacionalidad = dbo.fn_capitalize(nacionalidad),
				genero = UPPER(genero);

			INSERT INTO #BadCastBulk
			SELECT
				CASE WHEN TRY_CONVERT(
						DATE,
						CONCAT(LEFT(fecha_ultima_cuota, 4), '-', RIGHT('0' + CAST(dbo.fn_numMonth(fecha_ultima_cuota) AS VARCHAR(2)), 2), '-01')
				 	) IS NULL THEN fecha_ultima_cuota END AS esUltimaCuotaErronea,
				CASE WHEN TRY_CAST(numero_socio AS INT) IS NULL THEN numero_socio END AS esNumeroSocioErroneo,			
				NULL AS esApellidoNombreErroneo,				  
				CASE WHEN TRY_CAST(documento AS INT) IS NULL THEN documento END AS esDocumentoErroneo,
				NULL AS esDireccionErronea,
				NULL AS esTelefonoErroneo,
				NULL AS esCelularErroneo,
				NULL AS esCorreoErroneo,
				CASE WHEN COALESCE(TRY_CONVERT(DATE, fecha_nacimiento, 105), TRY_CONVERT(DATE, fecha_nacimiento, 5), NULL) IS NULL
					   THEN fecha_nacimiento END 
					AS esFNacimientoErronea,
				NULL AS esObservacionErronea, -- no aplica
				CASE WHEN COALESCE(
					TRY_CONVERT(DATE, socio_desde, 105),
					TRY_CONVERT(DATE, socio_desde, 101),
					TRY_CONVERT(DATE, socio_desde, 5),
					TRY_CONVERT(DATE, CONCAT(LEFT(socio_desde, 4), '-', RIGHT('0' + CAST(dbo.fn_numMonth(socio_desde) AS VARCHAR(2)), 2), '-01')),
					TRY_CONVERT(DATE, CONCAT('20', RIGHT(socio_desde, 2), '-', RIGHT('0' + CAST(dbo.fn_numMonth(socio_desde) AS VARCHAR(2)), 2), '-01')),
					NULL) IS NULL 
						 THEN socio_desde END 
					AS esSocioDesdeErroneo,
				NULL AS esTitularErroneo,
				CASE WHEN TRY_CONVERT(
						DATE,
						CONCAT(LEFT(fecha_baja, 4), '-', RIGHT('0' + CAST(dbo.fn_numMonth(fecha_baja) AS VARCHAR(2)), 2), '-01')
				 	) IS NULL THEN fecha_baja END AS esFechaBajaErronea,
				NULL AS esNacionalidadErronea,
				NULL AS esGeneroErroneo,
				rn
			FROM #ParsedBulk;

			INSERT INTO #CastedBulk
			SELECT
				TRY_CONVERT(
						DATE,
						CONCAT(LEFT(fecha_ultima_cuota, 4), '-', RIGHT('0' + CAST(dbo.fn_numMonth(fecha_ultima_cuota) AS VARCHAR(2)), 2), '-01')
				 	),
				TRY_CAST(numero_socio AS INT),
				apellido_nombre,
				TRY_CAST(documento AS INT),
				direccion,
				telefono,
				celular,
				correo_electronico,
				COALESCE(TRY_CONVERT(DATE, fecha_nacimiento, 105), TRY_CONVERT(DATE, fecha_nacimiento, 5), NULL) AS fecha_nacimiento,
				observaciones,
				COALESCE(
					TRY_CONVERT(DATE, socio_desde, 105),
					TRY_CONVERT(DATE, socio_desde, 101),
					TRY_CONVERT(DATE, socio_desde, 5),
					TRY_CONVERT(DATE, CONCAT(LEFT(socio_desde, 4), '-', RIGHT('0' + CAST(dbo.fn_numMonth(socio_desde) AS VARCHAR(2)), 2), '-01')),
					TRY_CONVERT(DATE, CONCAT('20', RIGHT(socio_desde, 2), '-', RIGHT('0' + CAST(dbo.fn_numMonth(socio_desde) AS VARCHAR(2)), 2), '-01')),
					NULL) AS socio_desde,
				titular_cuenta,
				TRY_CONVERT(
						DATE,
						CONCAT(LEFT(fecha_baja, 4), '-', RIGHT('0' + CAST(dbo.fn_numMonth(fecha_baja) AS VARCHAR(2)), 2), '-01')
				 	),
				nacionalidad,
				LEFT(genero, 1),
				rn
			FROM #ParsedBulk

		-- transform stage/type check
			INSERT INTO #BadDomainBulk
			SELECT
				NULL AS esUltimaCuotaErronea, --no aplica
				CASE WHEN numero_socio < 1 THEN numero_socio END AS esNumeroSocioErroneo,
				CASE WHEN LEN(apellido_nombre) < 3 THEN apellido_nombre END AS esApellidoNombreErroneo,
				CASE WHEN documento < 1 THEN documento END AS esDocumentoErroneo,
				CASE WHEN LEN(direccion) < 3 THEN direccion END AS esDireccionErronea,
				CASE WHEN LEN(telefono) < 8 THEN telefono END AS esTelefonoErroneo,
				CASE WHEN LEN(celular) < 8 THEN celular END AS esCelularErroneo,
				CASE WHEN LEN(correo_electronico) < 2 THEN correo_electronico END AS esCorreoErroneo,
				CASE WHEN fecha_nacimiento < '1900-01-01' THEN fecha_nacimiento END AS esFNacimientoErronea,
				NULL AS esObservacionErronea, --no aplica
				CASE WHEN socio_desde < '1957-01-01' THEN socio_desde END AS esSocioDesdeErroneo,
				CASE WHEN LEN(titular_cuenta) < 3 THEN titular_cuenta END AS esTitularErroneo,
				NULL AS esFechaBajaErronea, --no aplica
				CASE WHEN LEN(nacionalidad) < 3 THEN nacionalidad END AS esNacionalidadErronea,
				CASE WHEN genero NOT IN ('F', 'M', 'X') THEN genero END AS esGeneroErroneo,
				rn
			FROM #CastedBulk;

			UPDATE #CastedBulk SET
				documento = CASE WHEN documento < 1 THEN NULL ELSE documento END,
				direccion = CASE WHEN LEN(direccion) < 3 THEN NULL ELSE direccion END,
				celular = CASE WHEN LEN(celular) < 8 THEN NULL ELSE celular END,
				socio_desde = CASE WHEN socio_desde < '1957-01-01' THEN NULL ELSE socio_desde END,
				numero_socio = CASE WHEN numero_socio < 1 THEN NULL ELSE numero_socio END,
				fecha_ultima_cuota = fecha_ultima_cuota, --no aplica
				fecha_baja = fecha_baja, --no aplica
				correo_electronico = CASE WHEN LEN(correo_electronico) < 2 THEN NULL ELSE correo_electronico END,
				------------- datos informativos. no me importa si estan mal, los dejo en null
				telefono = CASE WHEN LEN(telefono) < 8 THEN NULL ELSE telefono END, 
				apellido_nombre = CASE WHEN LEN(apellido_nombre) < 3 THEN NULL ELSE apellido_nombre END,
				fecha_nacimiento = CASE WHEN fecha_nacimiento < '1900-01-01' THEN NULL ELSE fecha_nacimiento END,
				observaciones = observaciones, --no aplica
				titular_cuenta = CASE WHEN LEN(titular_cuenta) < 3 THEN NULL ELSE titular_cuenta END,
				nacionalidad = CASE WHEN LEN(nacionalidad) < 3 THEN NULL ELSE nacionalidad END,
				genero = CASE WHEN genero NOT IN ('F', 'M', 'X') THEN NULL ELSE genero END;

			INSERT INTO #RefinedBulk
			SELECT *
			FROM #CastedBulk

		-- transform stage/domain check
			INSERT INTO #FinalBulk
			SELECT
				fecha_ultima_cuota,

				numero_socio AS nro_socio,

				CASE WHEN apellido_nombre IS NOT NULL THEN
	     		  		TRIM(SUBSTRING(apellido_nombre, CHARINDEX(',', apellido_nombre)+1, LEN(apellido_nombre)))
	     	  		END as nombre,

	     		CASE WHEN apellido_nombre IS NOT NULL THEN
	     		  		TRIM(SUBSTRING(apellido_nombre, 1, CHARINDEX(',', apellido_nombre)-1)) 
	     	  		END AS apellido,

				documento AS dni,

				CASE WHEN CHARINDEX('-', direccion) <> 0 THEN
						TRIM(LEFT(direccion, LEN(direccion) - CHARINDEX('-', REVERSE(direccion))))
					END AS domicilio,

				CASE WHEN CHARINDEX('-', direccion) <> 0 THEN
					 	TRIM(RIGHT(direccion, CHARINDEX('-', REVERSE(direccion)) - 1))
				  END AS ciudad,

				CASE WHEN telefono IS NOT NULL THEN
	      				'11 ' + STUFF(RIGHT(telefono, 8), 5, 0, '-')
			    	END AS telefono,

	      		CASE WHEN celular IS NOT NULL THEN
	     				'11 ' + STUFF(RIGHT(celular, 8), 5, 0, '-')
			    	END AS celular,

		    	correo_electronico AS email,

				fecha_nacimiento,

	    		observaciones,

	    		socio_desde AS fecha_alta,

	    		CASE WHEN CHARINDEX(',', titular_cuenta) <> 0 THEN
							TRIM(SUBSTRING(titular_cuenta, CHARINDEX(',', titular_cuenta)+1, LEN(titular_cuenta)))
						WHEN CHARINDEX(' ', titular_cuenta) <> 0 THEN
							TRIM(SUBSTRING(titular_cuenta, 1, LEN(titular_cuenta) - CHARINDEX(' ', REVERSE(titular_cuenta))))
						ELSE
							NULL
					END AS nombre_titular_cuenta,

				CASE WHEN CHARINDEX(',', titular_cuenta) <> 0 THEN
							TRIM(SUBSTRING(titular_cuenta, 1, CHARINDEX(',', titular_cuenta)-1))
						WHEN CHARINDEX(' ', titular_cuenta) <> 0 THEN
							TRIM(SUBSTRING(titular_cuenta, LEN(titular_cuenta) - CHARINDEX(' ', REVERSE(titular_cuenta))+1, LEN(titular_cuenta)))
						ELSE
							titular_cuenta
					END AS apellido_titular_cuenta,

				fecha_baja,

				nacionalidad,

				genero,

				rn
			FROM #RefinedBulk;
	
		-- dup verification
			DROP TABLE IF EXISTS #AllTypeDuplicates;

			WITH 
				src AS (
					    SELECT rn, 'DNI' AS tipo, CAST(dni AS varchar(50)) AS valor
					    FROM #FinalBulk
					    WHERE dni IS NOT NULL

					    UNION ALL

					    SELECT rn, 'SOCIO', CAST(nro_socio AS varchar(50))
					    FROM #FinalBulk
					    WHERE nro_socio IS NOT NULL
					),
				base AS (
					    SELECT
					        rn,
					        tipo,
					        valor,
					        MIN(rn) OVER (PARTITION BY tipo, valor) AS rn_original,
					        COUNT(*) OVER (PARTITION BY tipo, valor) AS cnt
					    FROM src
					)
			SELECT
		    tipo,
		    valor,
		    rn_original,
		    STRING_AGG(CAST(rn AS varchar(10)), ',') WITHIN GROUP (ORDER BY rn) AS rn_duplicados
			INTO #AllTypeDuplicates
			FROM base
			WHERE cnt > 1
			GROUP BY tipo, valor, rn_original;

		-- load stage
			DROP TABLE IF EXISTS #InsertBulk;

			WITH
				BadData AS (
						SELECT 
							rn,
							NULLIF(CONCAT_WS(
								' | ',
								CASE WHEN esDocumentoErroneo IS NOT NULL THEN esDocumentoErroneo END,
								CASE WHEN esDireccionErronea IS NOT NULL THEN esDireccionErronea END,
								CASE WHEN esCelularErroneo IS NOT NULL THEN esCelularErroneo END,
								CASE WHEN esSocioDesdeErroneo IS NOT NULL THEN esSocioDesdeErroneo END,
								CASE WHEN esNumeroSocioErroneo IS NOT NULL THEN esNumeroSocioErroneo END,
								CASE WHEN esUltimaCuotaErronea IS NOT NULL THEN esUltimaCuotaErronea END,
								CASE WHEN esFechaBajaErronea IS NOT NULL THEN esFechaBajaErronea END,
								CASE WHEN esCorreoErroneo IS NOT NULL THEN esCorreoErroneo END,
								------------- -------------------- -------------- -----------------
								CASE WHEN esTelefonoErroneo IS NOT NULL THEN esTelefonoErroneo END, 
								CASE WHEN esApellidoNombreErroneo IS NOT NULL THEN esApellidoNombreErroneo END,
								CASE WHEN esFNacimientoErronea IS NOT NULL THEN esFNacimientoErronea END,
								CASE WHEN esObservacionErronea IS NOT NULL THEN esObservacionErronea END,
								CASE WHEN esTitularErroneo IS NOT NULL THEN esTitularErroneo END,
								CASE WHEN esNacionalidadErronea IS NOT NULL THEN esNacionalidadErronea END,
								CASE WHEN esGeneroErroneo IS NOT NULL THEN esGeneroErroneo END
							), '') AS BadData_comments
						FROM #BadDataBulk
					),
				BadCast AS (
						SELECT 
							rn,
							NULLIF(CONCAT_WS(
								' | ',
								CASE WHEN esDocumentoErroneo IS NOT NULL THEN esDocumentoErroneo END,
								CASE WHEN esDireccionErronea IS NOT NULL THEN esDireccionErronea END,
								CASE WHEN esCelularErroneo IS NOT NULL THEN esCelularErroneo END,
								CASE WHEN esSocioDesdeErroneo IS NOT NULL THEN esSocioDesdeErroneo END,
								CASE WHEN esNumeroSocioErroneo IS NOT NULL THEN esNumeroSocioErroneo END,
								CASE WHEN esUltimaCuotaErronea IS NOT NULL THEN esUltimaCuotaErronea END,
								CASE WHEN esFechaBajaErronea IS NOT NULL THEN esFechaBajaErronea END,
								CASE WHEN esCorreoErroneo IS NOT NULL THEN esCorreoErroneo END,
								------------- -------------------- -------------- -----------------
								CASE WHEN esTelefonoErroneo IS NOT NULL THEN esTelefonoErroneo END, 
								CASE WHEN esApellidoNombreErroneo IS NOT NULL THEN esApellidoNombreErroneo END,
								CASE WHEN esFNacimientoErronea IS NOT NULL THEN esFNacimientoErronea END,
								CASE WHEN esObservacionErronea IS NOT NULL THEN esObservacionErronea END,
								CASE WHEN esTitularErroneo IS NOT NULL THEN esTitularErroneo END,
								CASE WHEN esNacionalidadErronea IS NOT NULL THEN esNacionalidadErronea END,
								CASE WHEN esGeneroErroneo IS NOT NULL THEN esGeneroErroneo END
							), '') AS BadCast_comments
						FROM #BadCastBulk
					),
				BadDomain AS (
						SELECT 
							rn,
							NULLIF(CONCAT_WS(
								' | ',
								CASE WHEN esDocumentoErroneo IS NOT NULL THEN esDocumentoErroneo END,
								CASE WHEN esDireccionErronea IS NOT NULL THEN esDireccionErronea END,
								CASE WHEN esCelularErroneo IS NOT NULL THEN esCelularErroneo END,
								CASE WHEN esSocioDesdeErroneo IS NOT NULL THEN esSocioDesdeErroneo END,
								CASE WHEN esNumeroSocioErroneo IS NOT NULL THEN esNumeroSocioErroneo END,
								CASE WHEN esUltimaCuotaErronea IS NOT NULL THEN esUltimaCuotaErronea END,
								CASE WHEN esFechaBajaErronea IS NOT NULL THEN esFechaBajaErronea END,
								CASE WHEN esCorreoErroneo IS NOT NULL THEN esCorreoErroneo END,
								------------- -------------------- -------------- -----------------
								CASE WHEN esTelefonoErroneo IS NOT NULL THEN esTelefonoErroneo END, 
								CASE WHEN esApellidoNombreErroneo IS NOT NULL THEN esApellidoNombreErroneo END,
								CASE WHEN esFNacimientoErronea IS NOT NULL THEN esFNacimientoErronea END,
								CASE WHEN esObservacionErronea IS NOT NULL THEN esObservacionErronea END,
								CASE WHEN esTitularErroneo IS NOT NULL THEN esTitularErroneo END,
								CASE WHEN esNacionalidadErronea IS NOT NULL THEN esNacionalidadErronea END,
								CASE WHEN esGeneroErroneo IS NOT NULL THEN esGeneroErroneo END
							), '') AS BadDomain_comments
						FROM #BadDomainBulk
					),
				src AS (
					    SELECT rn, 'DNI' AS tipo, CAST(dni AS VARCHAR(50)) AS valor
					    FROM #FinalBulk
					    WHERE dni IS NOT NULL

					    UNION ALL

					    SELECT rn, 'SOCIO' AS tipo, CAST(nro_socio AS VARCHAR(50)) AS valor
					    FROM #FinalBulk
					    WHERE nro_socio IS NOT NULL
					),
				dups AS (
					    SELECT
					        s1.rn,
					        s1.tipo,
					        STRING_AGG(CAST(s2.rn AS VARCHAR(10)), ',') WITHIN GROUP (ORDER BY s2.rn) AS other_rns
					    FROM src s1
					    JOIN src s2 ON s1.tipo = s2.tipo AND s1.valor = s2.valor AND s1.rn <> s2.rn
					    GROUP BY s1.rn, s1.tipo
					),
				AllTypesDup AS (
					    SELECT
					        rn,
					        STRING_AGG(tipo + ' duped from rn: ' + other_rns, ' | ') WITHIN GROUP (ORDER BY tipo) AS ContainsDups_comments
					    FROM dups
					    GROUP BY rn
					)
			SELECT
				f.rn,
				fecha_ultima_cuota,
				nro_socio,
				nombre,
				apellido,
				dni,
				domicilio,
				ciudad,
				telefono,
				celular,
				email,
				fecha_nacimiento,
				observaciones,
				fecha_alta,
				nombre_titular_cuenta,
				apellido_titular_cuenta,
				fecha_baja,
				nacionalidad,
				genero,
				BadData_comments,
				BadCast_comments,
				BadDomain_comments,
				ContainsDups_comments
			INTO #InsertBulk
			FROM #FinalBulk f
			LEFT JOIN BadData bd ON bd.rn = f.rn
			LEFT JOIN BadCast bc ON bc.rn = f.rn
			LEFT JOIN BadDomain bdom ON bdom.rn = f.rn
			LEFT JOIN AllTypesDup dup ON dup.rn = f.rn;

			SELECT * FROM #InsertBulk;

			--debug
					--SELECT * FROM #RawBulk;
					--SELECT * FROM #CleanedBulk;
					--SELECT * FROM #ParsedBulk;
					--SELECT * FROM #CastedBulk;
					--SELECT * FROM #RefinedBulk;
					--SELECT * FROM #FinalBulk;
					----
					--SELECT * FROM #BadDataBulk;
					--SELECT * FROM #BadCastBulk;
					--SELECT * FROM #BadDomainBulk;
	END;
GO
PRINT '[INFO] sp_Helper__Importar_Esquema_normal Creada';
GO


PRINT '[DONE] SP_importacion Listos';
GO
