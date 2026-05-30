IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

SET XACT_ABORT ON; 

BEGIN TRY
	BEGIN TRANSACTION;
		--busquedas
			CREATE TABLE lookups.Origenes_de_Cobro --permiso: crear
			(
			    id TINYINT IDENTITY,
			    descripcion VARCHAR(35) NOT NULL CHECK (LEN(TRIM(descripcion)) > 2),

			    CONSTRAINT PK_Origenes_de_Cobro PRIMARY KEY (id)
			);
			
			CREATE TABLE lookups.Tipos_de_Pago --permiso: crear
			(
			    id TINYINT IDENTITY,
			    descripcion VARCHAR(20) NOT NULL CHECK (LEN(TRIM(descripcion)) > 2),

			    CONSTRAINT PK_Tipos_de_Pago PRIMARY KEY (id)
			);

			CREATE TABLE core.Nacionalidad --permiso: crear
			(
			    id TINYINT IDENTITY,
			    descripcion NVARCHAR(20) NOT NULL CHECK (LEN(TRIM(descripcion)) > 2),

			    CONSTRAINT PK_Nacionalidad PRIMARY KEY (id)
			);

			CREATE TABLE core.Ciudad --permiso: crear
			(
			    id TINYINT IDENTITY,
			    descripcion NVARCHAR(30) NOT NULL CHECK (LEN(TRIM(descripcion)) > 2),

			    CONSTRAINT PK_Ciudad PRIMARY KEY (id)
			);
		PRINT '[INFO] Creando tablas de Busquedas';

		--negocio
			CREATE TABLE core.Personas --permiso: 
								  --  		 crear, 
								  -- 		   completar si corresponde(nro_socio, Documento, Fecha_Nacimiento, Ciudad, domicilio, Telefono, Celular, Correo_Electronico),
								  --       editar(observaciones)
			(
				id INT IDENTITY,
				dni INT, ------------------------------ puede ser NULL pero es campo critico. tiene que ser UNIQUE, pero los casos null en MSSQL no puedo
				__nombre CHAR(48) CHECK (__nombre IS NULL OR LEN(TRIM(__nombre)) > 2),
				nombre AS CAST(TRIM(__nombre) AS VARCHAR(48)),
				__apellido CHAR(48) CHECK (__apellido IS NULL OR LEN(TRIM(__apellido)) > 2),
				apellido AS CAST(TRIM(__apellido) AS VARCHAR(48)),
				__celular CHAR(16) CHECK (__celular IS NULL OR LEN(TRIM(__celular)) > 9),
				celular AS CAST(TRIM(__celular) AS VARCHAR(16)),
				__domicilio CHAR(48) CHECK (__domicilio IS NULL OR LEN(TRIM(__domicilio)) > 2),
				domicilio AS CAST(TRIM(__domicilio) AS VARCHAR(48)),
				__email CHAR(64) CHECK (__email IS NULL OR LEN(TRIM(__email)) > 5),
				email AS CAST(TRIM(__email) AS VARCHAR(64)),
				fecha_nacimiento DATE CHECK (fecha_nacimiento > '1900-01-01'),
				ciudad TINYINT,
				__telefono CHAR(16) CHECK (__telefono IS NULL OR LEN(TRIM(__telefono)) > 9),
				telefono AS CAST(TRIM(__telefono) AS VARCHAR(16)),
				__observaciones CHAR(128),
				observaciones AS CAST(TRIM(__observaciones) AS VARCHAR(128)),
				nacionalidad TINYINT,
				genero CHAR(1) CHECK (genero IN ('F', 'M', 'X')),

				edad AS DATEDIFF(YEAR, fecha_nacimiento, GETDATE()),
				domicilio_completo AS CAST(CONCAT_WS(', ', NULLIF(TRIM(__domicilio), ''), NULLIF(TRIM(__ciudad), '')) AS VARCHAR(104)),
				nombre_completo AS CAST(CONCAT_WS(', ', NULLIF(TRIM(__apellido), ''), NULLIF(TRIM(__nombre), '')) AS VARCHAR(104)),

				CONSTRAINT PK_Personas PRIMARY KEY (id),
				CONSTRAINT FK_Personas__Nacionalidad FOREIGN KEY (nacionalidad) REFERENCES core.Nacionalidad(id),
				CONSTRAINT FK_Personas__Ciudad FOREIGN KEY (ciudad) REFERENCES core.Ciudad(id)
			); 

			CREATE TABLE core.Socios --permiso: crear, completar(fecha_alta, fecha_baja), editar(Necesita_cupon, pago_preferido)
			(
				id INT IDENTITY,
				nro_socio INT NOT NULL,
				id_persona INT NOT NULL,
				fecha_alta DATE, ---------------- deberia ser NOT NULL. lo dejamos compatible por ETL.. no jode a procesos, excepto reportes
				fecha_baja DATE,
				necesita_cupon BIT,
				desea_email_pago BIT,
				pago_preferido TINYINT,
				motivo_baja CHAR(150) CHECK (motivo_baja IS NULL OR LEN(TRIM(motivo_baja)) > 2),

				CONSTRAINT PK_Socios PRIMARY KEY (id),
				CONSTRAINT FK_Socios__Personas_id FOREIGN KEY (id_persona) REFERENCES core.Personas(id),
				CONSTRAINT FK_Socios__Tipos_de_Pago_id FOREIGN KEY (pago_preferido) REFERENCES lookups.Tipos_de_Pago(id),
				CONSTRAINT UK_Socios__nro_socio UNIQUE (nro_socio),
				CONSTRAINT UK_Socios__id_persona UNIQUE (id_persona)
			);
			
			CREATE TABLE core.Cuotas --permiso: crear
			(
			    periodo DATE CHECK (DAY(periodo) = 1),
			    valor DECIMAL(9,2) NOT NULL CHECK (valor >= 0),
			    --OPCCION TRIGGER check, la nuevas cuotas deben ser mayor que la anterior, si es q todo aumenta xd

			    CONSTRAINT PK_Cuotas PRIMARY KEY (periodo)
			);

			CREATE TABLE core.Pagos 
			(
				-- el dia '5 de marzo, 2026' recibimos '20 mil pesitos' de 'id_persona: 98' por medio 'virtual'
				-- el pago 'id: 11'(el recien cargado) tuvo origen desde 'wasap del cobrador'
				id INT IDENTITY,
				fecha_hora_pago DATETIME NOT NULL,
				id_persona_pagadora INT,
				medio_pago TINYINT NOT NULL,
				origen_carga TINYINT NOT NULL,
				monto_pagado_real DECIMAL(19,2) NOT NULL CHECK (monto_pagado_real >= 0),
				comentario CHAR(128) CHECK (comentario IS NULL OR LEN(TRIM(comentario)) > 2),
				fecha_hora_registro DATETIME DEFAULT (GETDATE()),

				CONSTRAINT PK_Pagos PRIMARY KEY (id),
				CONSTRAINT FK_Pagos__Personas_id FOREIGN KEY (id_persona_pagadora) REFERENCES core.Personas(id),
				CONSTRAINT FK_Pagos__Tipos_de_Pago_id FOREIGN KEY (medio_pago) REFERENCES lookups.Tipos_de_Pago(id),
				CONSTRAINT FK_Pagos__Origenes_de_Cobro_id FOREIGN KEY (origen_carga) REFERENCES lookups.Origenes_de_Cobro(id)				
			); 

			CREATE TABLE core.Detalles_del_Pago 
			(
				--intencion de pago
				id BIGINT IDENTITY,
				id_pago INT NOT NULL,
				nro_socio INT NOT NULL,
				periodo_pago DATE NOT NULL CHECK (DAY(periodo_pago) = 1),
				monto DECIMAL(19,2) NOT NULL CHECK (monto >= 0),
				comentario CHAR(128) CHECK (comentario IS NULL OR LEN(TRIM(comentario)) > 2),

				CONSTRAINT PK_Detalles_del_Pago PRIMARY KEY (id),
				CONSTRAINT FK_Detalles_del_Pago__Pagos_id FOREIGN KEY (id_pago) REFERENCES core.Pagos(id),
				CONSTRAINT FK_Detalles_del_Pago__Socios_nro_socio FOREIGN KEY (nro_socio) REFERENCES core.Socios(nro_socio)
			);
			
			CREATE TABLE core.Actividades --permiso: crear, completar(fecha_fin)
			(
			    id INT IDENTITY,
			    descripcion NVARCHAR(70) NOT NULL CHECK (descripcion IS NULL OR LEN(TRIM(descripcion)) > 2),
			    id_persona_a_cargo INT NOT NULL, --(puede ser profesor no socio)
			    fecha_inicio DATE NOT NULL,
			    fecha_fin DATE,
			    motivo_baja VARCHAR(150) CHECK (motivo_baja IS NULL OR LEN(TRIM(motivo_baja)) > 2),

			    CONSTRAINT PK_Actividades PRIMARY KEY (id),
			    CONSTRAINT FK_Actividades__Personas_id FOREIGN KEY (id_persona_a_cargo) REFERENCES core.Personas(id)
			);
			
			CREATE TABLE core.Grupos --permiso: crear
			(
			    id SMALLINT IDENTITY,
			    descripcion NVARCHAR(255) NOT NULL CHECK (LEN(TRIM(descripcion)) > 2),
			    esFamilia BIT,

			    CONSTRAINT PK_Grupos PRIMARY KEY (id)
			);

			CREATE TABLE core.Comprobantes
			(
				id INT IDENTITY,
				id_pago INT NOT NULL,
				archivo_guid UNIQUEIDENTIFIER NOT NULL, -- El nombre físico en el disco
			    archivo_nombre NVARCHAR(255) NOT NULL, -- "pago_marzo_01.jpg"
			    archivo_tipo VARCHAR(100) NOT NULL,  -- application/pdf, image/jpeg, etc.
			    archivo_tamanio INT NOT NULL,  -- bytes
			    fecha_subida DATETIME NOT NULL DEFAULT GETDATE(),

			    CONSTRAINT PK_Comprobantes PRIMARY KEY (id),
			    CONSTRAINT FK_Comprobantes__Pagos_id FOREIGN KEY (id_pago) REFERENCES core.Pagos(id)
		  	);
		PRINT '[INFO] Creando tablas del Negocio';

		--union
			CREATE TABLE links.Grupos_con_Personas --permiso: crear, eliminar
			(
			    id_grupo SMALLINT,
			    id_persona INT,

			    CONSTRAINT PK_Grupos_con_Personas PRIMARY KEY (id_grupo, id_persona),
			    CONSTRAINT FK_Grupos_con_Personas__Grupos_id FOREIGN KEY (id_grupo) REFERENCES core.Grupos(id) ON DELETE CASCADE,
			    CONSTRAINT FK_Grupos_con_Personas__Personas_id FOREIGN KEY (id_persona) REFERENCES core.Personas(id) ON DELETE CASCADE
			);
			
			CREATE TABLE links.Personas_con_Actividades --permiso: crear, eliminar, completar(fecha_fin)
			(
				id INT IDENTITY,
				id_persona INT NOT NULL,
				id_actividad INT NOT NULL,
				fecha_inicio DATE NOT NULL,
				fecha_fin DATE,

				CONSTRAINT PK_Personas_con_Actividades PRIMARY KEY (id),
			    CONSTRAINT FK_Personas_con_Actividades__Personas_id FOREIGN KEY (id_persona) REFERENCES core.Personas(id),
			    CONSTRAINT FK_Personas_con_Actividades__Actividades_id FOREIGN KEY (id_actividad) REFERENCES core.Actividades(id)
			);
		PRINT '[INFO] Creando tablas de Uniones';

		--analiticas (para el maldito budibase)
			CREATE TABLE reports.Cuotas_Pivot --vista materializada
			(
			    Anio SMALLINT CHECK (Anio >= 2024),
			    Enero DECIMAL(9,2) CHECK (Enero >= 0),
			    Febrero DECIMAL(9,2) CHECK (Febrero >= 0),
			    Marzo DECIMAL(9,2) CHECK (Marzo >= 0),
			    Abril DECIMAL(9,2) CHECK (Abril >= 0),
			    Mayo DECIMAL(9,2) CHECK (Mayo >= 0),
			    Junio DECIMAL(9,2) CHECK (Junio >= 0),
			    Julio DECIMAL(9,2) CHECK (Julio >= 0),
			    Agosto DECIMAL(9,2) CHECK (Agosto >= 0),
			    Septiembre DECIMAL(9,2) CHECK (Septiembre >= 0),
			    Octubre DECIMAL(9,2) CHECK (Octubre >= 0),
			    Noviembre DECIMAL(9,2) CHECK (Noviembre >= 0),
			    Diciembre DECIMAL(9,2) CHECK (Diciembre >= 0),

			    PRIMARY KEY (Anio)
			);
			
			CREATE TABLE reports.Pagos_Pivot --vista materializada
			(
				Socio INT REFERENCES core.Socios(nro_socio),
			    Anio SMALLINT CHECK (Anio >= 2024),
			    Enero DECIMAL(19,2) CHECK (Enero >= 0),
			    Febrero DECIMAL(19,2) CHECK (Febrero >= 0),
			    Marzo DECIMAL(19,2) CHECK (Marzo >= 0),
			    Abril DECIMAL(19,2) CHECK (Abril >= 0),
			    Mayo DECIMAL(19,2) CHECK (Mayo >= 0),
			    Junio DECIMAL(19,2) CHECK (Junio >= 0),
			    Julio DECIMAL(19,2) CHECK (Julio >= 0),
			    Agosto DECIMAL(19,2) CHECK (Agosto >= 0),
			    Septiembre DECIMAL(19,2) CHECK (Septiembre >= 0),
			    Octubre DECIMAL(19,2) CHECK (Octubre >= 0),
			    Noviembre DECIMAL(19,2) CHECK (Noviembre >= 0),
			    Diciembre DECIMAL(19,2) CHECK (Diciembre >= 0),

			    PRIMARY KEY (Socio, Anio)
			);
		PRINT '[INFO] Creando tablas de Estado';

		--referencias
			CREATE TABLE params.Usuarios_del_Sistema
			(
				id SMALLINT IDENTITY PRIMARY KEY,
				email VARCHAR(128) NOT NULL UNIQUE CHECK (email LIKE '%_@%_.%_'),
				rol VARCHAR(16) NOT NULL CHECK (rol IN ('ADMIN', 'CONSUMER')),
				fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
				activo BIT NOT NULL DEFAULT 1,
				nombre_completo NVARCHAR(128)
			);

			CREATE TABLE params.Feriados
			(
				fecha DATE PRIMARY KEY CHECK (fecha >= '2024-01-01'),
				descripcion NVARCHAR(100) NOT NULL CHECK (LEN(TRIM(descripcion)) > 2),
	    		es_nacional BIT NOT NULL
			);

			CREATE TABLE params.Plataforma
			(
				id TINYINT PRIMARY KEY CHECK (id = 1),  -- singleton
				motor_basedatos NVARCHAR(256) NOT NULL,
				inicio_sistema DATE NOT NULL,
				ubicacion_host NVARCHAR(70) NOT NULL,
				fecha_ultimo_cambio DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
				version_actual INT DEFAULT 0 CHECK (version_actual >= 0),

				persona_a_cargo NVARCHAR(62) NOT NULL CHECK (LEN(TRIM(persona_a_cargo)) > 2),
				celular CHAR(12) NOT NULL CHECK (celular LIKE '[0-9][0-9] [0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
				
				version ROWVERSION
			);
			
			CREATE TABLE params.Organizacion
			(
				id TINYINT PRIMARY KEY CHECK (id = 1),  -- singleton
				nombre NVARCHAR(70) NOT NULL,
				direccion NVARCHAR(70) NOT NULL,
				telefono CHAR(12) NOT NULL CHECK (telefono LIKE '[0-9][0-9] [0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
				version_actual INT DEFAULT 0 CHECK (version_actual >= 0),
				fecha_ultimo_cambio DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

				razon_social NVARCHAR(70) NOT NULL CHECK (LEN(TRIM(razon_social)) > 2),
				cuit CHAR(13) NOT NULL CHECK (cuit LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'),
				cbu CHAR(23) NOT NULL CHECK (cbu LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),

				persona_a_cargo NVARCHAR(62) NOT NULL CHECK (LEN(TRIM(persona_a_cargo)) > 2),
				celular CHAR(12) NOT NULL CHECK (celular LIKE '[0-9][0-9] [0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),

				version ROWVERSION
			);
		PRINT '[INFO] Creando tablas de Referencias';

		--loggins
			CREATE TABLE logs.Notificaciones
			(
				id INT IDENTITY PRIMARY KEY,
				periodo DATE NOT NULL CHECK (DAY(periodo) = 1),
				nro_socio INT NOT NULL REFERENCES core.Socios(nro_socio),
				fecha_hora_envio DATETIME NOT NULL,
				confirmacion_envio BIT NOT NULL
			);
			
			CREATE TABLE logs.Bitacora
			(
				id BIGINT IDENTITY PRIMARY KEY,
			    fecha_hora DATETIME NOT NULL DEFAULT GETDATE(),

			    -- 'ejecutor' busca el usuario real, si no hay nada, usa el de la DB
			    ejecutor NVARCHAR(100) NOT NULL DEFAULT (
			        	ISNULL(CAST(SESSION_CONTEXT(N'UsuarioReal') AS NVARCHAR(100)), SUSER_SNAME())
			    	),
			    -- 'desde' busca el origen, si no hay nada, pone 'Sistema'
			    desde NVARCHAR(100) NOT NULL DEFAULT (
			        	ISNULL(CAST(SESSION_CONTEXT(N'Origen') AS NVARCHAR(100)), 'Sistema')
			    	),

			    evento VARCHAR(50) NOT NULL CHECK (evento IN (
				        'SOCIO_ALTA', 'SOCIO_BAJA', 
				        'PERSONA_MODIFICADA', 'PERSONA_NUEVA',
				        'PAGO_REGISTRADO', 'PAGO_MODIFICADO',
				        'COBRO_AUTOMATICO_SALDO',
				        'ACTIVIDAD_INICIADA', 'ACTIVIDAD_FINALIZADA',
				        'CUOTA_ACTUALIZADA', 'GRUPO_NUEVO'
			    	)), -- evento = actor + _ + accion

			    -- Entidad principal afectada
			    entidad_afectada VARCHAR(50) NOT NULL,
			    id_afectada BIGINT NOT NULL,
			    
					-- Contexto adicional (opcional)
			    contexto NVARCHAR(200),
			    detalle NVARCHAR(400),

			    -- Entidad relacionada (opcional)
			    entidad_relacionada VARCHAR(50),
			    id_relacionado BIGINT,

			    registro AS (
			    		CONVERT(VARCHAR(20), fecha_hora, 120) + ' | ' + evento + ' - ' +
						entidad_afectada + ' #' + CAST(id_afectada AS VARCHAR(10)) +
						CASE WHEN contexto IS NOT NULL THEN (' [' + contexto + '] ') ELSE ' [] ' END +
						CASE WHEN entidad_relacionada IS NOT NULL AND id_relacionado IS NOT NULL
							THEN (entidad_relacionada + ' #' + CAST(id_relacionado AS VARCHAR(10)))
							WHEN entidad_relacionada IS NOT NULL THEN entidad_relacionada
							ELSE ' y '
						END + ' | ' + COALESCE(detalle, '') + ' --> ' + ejecutor + ' @ ' + desde
			    	)
			);

			CREATE TABLE logs.Conexiones_de_Usuarios
			(
				id BIGINT IDENTITY PRIMARY KEY,
				id_usuario SMALLINT FOREIGN KEY REFERENCES params.Usuarios_del_Sistema(id),
				sesion_iniciada DATETIME NOT NULL DEFAULT GETDATE()
			);
		PRINT '[INFO] Creando tablas de Registros';	
	COMMIT TRANSACTION;

	PRINT '[DONE] Tablas Listas';
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;
	PRINT '[ERROR] Algo anda mal en las Tablas';
	THROW;
END CATCH;
GO
