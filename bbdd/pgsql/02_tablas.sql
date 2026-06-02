--tablas
BEGIN;
    --lookups
        CREATE TABLE lookups.Origenes_de_Cobro 
        (
            id SMALLSERIAL,
            descripcion VARCHAR(35) NOT NULL CHECK (length(trim(descripcion)) > 2),
            
            CONSTRAINT PK_Origenes_de_Cobro PRIMARY KEY (id)
        );
                                
        CREATE TABLE lookups.Tipos_de_Pago 
        (
            id SMALLSERIAL, 
            descripcion VARCHAR(20) NOT NULL CHECK (length(trim(descripcion)) > 2),
            
            CONSTRAINT PK_Tipos_de_Pago PRIMARY KEY (id)
        );

        CREATE TABLE core.Nacionalidad 
        (
            id SMALLSERIAL, 
            descripcion VARCHAR(20) NOT NULL CHECK (length(trim(descripcion)) > 2), -- NVARCHAR cambia a VARCHAR (en Postgres todo es UTF-8 nativo)
            
            CONSTRAINT PK_Nacionalidad PRIMARY KEY (id)
        );

        CREATE TABLE core.Ciudad 
        (
            id SMALLSERIAL, 
            descripcion VARCHAR(30) NOT NULL CHECK (length(trim(descripcion)) > 2),
            
            CONSTRAINT PK_Ciudad PRIMARY KEY (id)
        );

        DO $$BEGIN
            RAISE NOTICE '[INFO] Creando tablas de Busquedas';
        END $$;

    --core
        CREATE TABLE core.Personas 
        (
            id SERIAL, 
            dni INT NULL UNIQUE, 
            __nombre CHAR(48) CHECK (__nombre IS NULL OR length(trim(__nombre)) > 2),
            __apellido CHAR(48) CHECK (__apellido IS NULL OR length(trim(__apellido)) > 2),
            __celular CHAR(16) CHECK (__celular IS NULL OR length(trim(__celular)) > 9),
            __domicilio CHAR(48) CHECK (__domicilio IS NULL OR length(trim(__domicilio)) > 2),
            __email CHAR(64) CHECK (__email IS NULL OR length(trim(__email)) > 5),
            fecha_nacimiento DATE CHECK (fecha_nacimiento > '1900-01-01'),
            ciudad SMALLINT, 
            __telefono CHAR(16) CHECK (__telefono IS NULL OR length(trim(__telefono)) > 9),
            __observaciones CHAR(128),
            nacionalidad SMALLINT, 
            genero CHAR(1) CHECK (genero IN ('F', 'M', 'X')),

            -- Estas conversiones con ::VARCHAR son perfectamente inmutables
            nombre VARCHAR(48) GENERATED ALWAYS AS (trim(__nombre)::VARCHAR(48)) STORED,
            apellido VARCHAR(48) GENERATED ALWAYS AS (trim(__apellido)::VARCHAR(48)) STORED,
            celular VARCHAR(16) GENERATED ALWAYS AS (trim(__celular)::VARCHAR(16)) STORED,
            domicilio VARCHAR(48) GENERATED ALWAYS AS (trim(__domicilio)::VARCHAR(48)) STORED,
            email VARCHAR(64) GENERATED ALWAYS AS (trim(__email)::VARCHAR(64)) STORED,
            observaciones VARCHAR(128) GENERATED ALWAYS AS (trim(__observaciones)::VARCHAR(128)) STORED,
            

            domicilio_completo VARCHAR(104) GENERATED ALWAYS AS (trim(__domicilio):: VARCHAR(104)) STORED,
            
            nombre_completo VARCHAR(104) GENERATED ALWAYS AS (
                CAST(
                    CASE 
                        WHEN __apellido IS NULL OR trim(__apellido) = '' THEN trim(__nombre)
                        WHEN __nombre IS NULL OR trim(__nombre) = '' THEN trim(__apellido)
                        ELSE trim(__apellido) || ', ' || trim(__nombre)
                    END AS VARCHAR(104)
                )
            ) STORED,

            CONSTRAINT PK_Personas PRIMARY KEY (id),
            CONSTRAINT FK_Personas__Nacionalidad FOREIGN KEY (nacionalidad) REFERENCES core.Nacionalidad(id),
            CONSTRAINT FK_Personas__Ciudad FOREIGN KEY (ciudad) REFERENCES core.Ciudad(id)
        );

        CREATE TABLE core.Socios 
        (
            id SERIAL,
            nro_socio INT NOT NULL,
            id_persona INT NOT NULL,
            fecha_alta DATE, 
            fecha_baja DATE,
            necesita_cupon BOOLEAN,
            desea_email_pago BOOLEAN,
            pago_preferido SMALLINT,
            motivo_baja CHAR(150) CHECK (motivo_baja IS NULL OR length(trim(motivo_baja)) > 2),

            CONSTRAINT PK_Socios PRIMARY KEY (id),
            CONSTRAINT FK_Socios__Personas_id FOREIGN KEY (id_persona) REFERENCES core.Personas(id),
            CONSTRAINT FK_Socios__Tipos_de_Pago_id FOREIGN KEY (pago_preferido) REFERENCES lookups.Tipos_de_Pago(id),
            CONSTRAINT UK_Socios__nro_socio UNIQUE (nro_socio),
            CONSTRAINT UK_Socios__id_persona UNIQUE (id_persona)
        );
                                
        CREATE TABLE core.Cuotas 
        (
            periodo DATE CHECK (EXTRACT(DAY FROM periodo) = 1),
            valor DECIMAL(9,2) NOT NULL CHECK (valor >= 0),

            CONSTRAINT PK_Cuotas PRIMARY KEY (periodo)
        );

        CREATE TABLE core.Pagos 
        (
            id SERIAL,
            fecha_hora_pago TIMESTAMP NOT NULL,
            id_persona_pagadora INT,
            medio_pago SMALLINT NOT NULL,
            origen_carga SMALLINT NOT NULL,
            monto_pagado_real DECIMAL(19,2) NOT NULL CHECK (monto_pagado_real >= 0),
            comentario CHAR(128) CHECK (comentario IS NULL OR length(trim(comentario)) > 2),
            fecha_hora_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

            CONSTRAINT PK_Pagos PRIMARY KEY (id),
            CONSTRAINT FK_Pagos__Personas_id FOREIGN KEY (id_persona_pagadora) REFERENCES core.Personas(id),
            CONSTRAINT FK_Pagos__Tipos_de_Pago_id FOREIGN KEY (medio_pago) REFERENCES lookups.Tipos_de_Pago(id),
            CONSTRAINT FK_Pagos__Origenes_de_Cobro_id FOREIGN KEY (origen_carga) REFERENCES lookups.Origenes_de_Cobro(id)                
        ); 

        CREATE TABLE core.Detalles_del_Pago 
        (
            id BIGSERIAL,
            id_pago INT NOT NULL,
            nro_socio INT NOT NULL,
            periodo_pago DATE NOT NULL CHECK (EXTRACT(DAY FROM periodo_pago) = 1),
            monto DECIMAL(19,2) NOT NULL CHECK (monto >= 0),
            comentario CHAR(128) CHECK (comentario IS NULL OR length(trim(comentario)) > 2),

            CONSTRAINT PK_Detalles_del_Pago PRIMARY KEY (id),
            CONSTRAINT FK_Detalles_del_Pago__Pagos_id FOREIGN KEY (id_pago) REFERENCES core.Pagos(id),
            CONSTRAINT FK_Detalles_del_Pago__Socios_nro_socio FOREIGN KEY (nro_socio) REFERENCES core.Socios(nro_socio)
        );
                                
        CREATE TABLE core.Actividades 
        (
            id SERIAL,
            descripcion VARCHAR(70) NOT NULL CHECK (length(trim(descripcion)) > 2),
            id_persona_a_cargo INT NOT NULL, 
            fecha_inicio DATE NOT NULL,
            fecha_fin DATE,
            motivo_baja VARCHAR(150) CHECK (motivo_baja IS NULL OR length(trim(motivo_baja)) > 2),

            CONSTRAINT PK_Actividades PRIMARY KEY (id),
            CONSTRAINT FK_Actividades__Personas_id FOREIGN KEY (id_persona_a_cargo) REFERENCES core.Personas(id)
        );
                                
        CREATE TABLE core.Grupos 
        (
            id SMALLSERIAL,
            descripcion VARCHAR(255) NOT NULL CHECK (length(trim(descripcion)) > 2),
            esFamilia BOOLEAN,

            CONSTRAINT PK_Grupos PRIMARY KEY (id)
        );

        CREATE TABLE core.Comprobantes
        (
            id SERIAL,
            id_pago INT NOT NULL,
            archivo_guid UUID NOT NULL,
            archivo_nombre VARCHAR(255) NOT NULL, 
            archivo_tipo VARCHAR(100) NOT NULL,  
            archivo_tamanio INT NOT NULL,  
            fecha_subida TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

            CONSTRAINT PK_Comprobantes PRIMARY KEY (id),
            CONSTRAINT FK_Comprobantes__Pagos_id FOREIGN KEY (id_pago) REFERENCES core.Pagos(id)
        );

        DO $$BEGIN
            RAISE NOTICE '[INFO] Creando tablas del Negocio';
        END$$;

    --links
        CREATE TABLE links.Grupos_con_Personas 
        (
            id_grupo SMALLINT,
            id_persona INT,

            CONSTRAINT PK_Grupos_con_Personas PRIMARY KEY (id_grupo, id_persona),
            CONSTRAINT FK_Grupos_con_Personas__Grupos_id FOREIGN KEY (id_grupo) REFERENCES core.Grupos(id) ON DELETE CASCADE,
            CONSTRAINT FK_Grupos_con_Personas__Personas_id FOREIGN KEY (id_persona) REFERENCES core.Personas(id) ON DELETE CASCADE
        );
                                
        CREATE TABLE links.Personas_con_Actividades 
        (
            id SERIAL,
            id_persona INT NOT NULL,
            id_actividad INT NOT NULL,
            fecha_inicio DATE NOT NULL,
            fecha_fin DATE,

            CONSTRAINT PK_Personas_con_Actividades PRIMARY KEY (id),
            CONSTRAINT FK_Personas_con_Actividades__Personas_id FOREIGN KEY (id_persona) REFERENCES core.Personas(id),
            CONSTRAINT FK_Personas_con_Actividades__Actividades_id FOREIGN KEY (id_actividad) REFERENCES core.Actividades(id)
        );

        DO $$BEGIN
            RAISE NOTICE '[INFO] Creando tablas de Uniones';
        END$$;

    --reports
        CREATE TABLE reports.Cuotas_Pivot 
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
                                
        CREATE TABLE reports.Pagos_Pivot 
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

        DO $$BEGIN
            RAISE NOTICE '[INFO] Creando tablas de Estado (Pivots)';
        END$$;

    --params
        CREATE TABLE params.Usuarios_del_Sistema
        (
            id SMALLSERIAL PRIMARY KEY,
            email VARCHAR(128) NOT NULL UNIQUE CHECK (email LIKE '%_@%_.%_'),
            rol VARCHAR(16) NOT NULL CHECK (rol IN ('ADMIN', 'CONSUMER')),
            fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            activo BOOLEAN NOT NULL DEFAULT TRUE,
            nombre_completo VARCHAR(128)
        );

        CREATE TABLE params.Feriados
        (
            fecha DATE PRIMARY KEY CHECK (fecha >= '2024-01-01'),
            descripcion VARCHAR(100) NOT NULL CHECK (length(trim(descripcion)) > 2),
            es_nacional BOOLEAN NOT NULL
        );

        CREATE TABLE params.Plataforma
        (
            id SMALLINT PRIMARY KEY CHECK (id = 1),
            motor_basedatos VARCHAR(256) NOT NULL,
            inicio_sistema DATE NOT NULL,
            ubicacion_host VARCHAR(70) NOT NULL,
            fecha_ultimo_cambio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            version_actual INT DEFAULT 0 CHECK (version_actual >= 0),
            persona_a_cargo VARCHAR(62) NOT NULL CHECK (length(trim(persona_a_cargo)) > 2),
            celular VARCHAR(20) NOT NULL
        );
                                
        CREATE TABLE params.Organizacion
        (
            id SMALLINT PRIMARY KEY CHECK (id = 1),
            nombre VARCHAR(70) NOT NULL,
            direccion VARCHAR(70) NOT NULL,
            telefono VARCHAR(20) NOT NULL,
            version_actual INT DEFAULT 0 CHECK (version_actual >= 0),
            fecha_ultimo_cambio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            razon_social VARCHAR(70) NOT NULL CHECK (length(trim(razon_social)) > 2),
            cuit CHAR(13) NOT NULL, 
            cbu CHAR(22) NOT NULL,
            persona_a_cargo VARCHAR(62) NOT NULL CHECK (length(trim(persona_a_cargo)) > 2),
            celular VARCHAR(20) NOT NULL
        );

        DO $$BEGIN
            RAISE NOTICE '[INFO] Creando tablas de Referencias';
        END$$;

    --logs
        CREATE TABLE logs.Notificaciones
        (
            id SERIAL PRIMARY KEY,
            periodo DATE NOT NULL CHECK (EXTRACT(DAY FROM periodo) = 1),
            nro_socio INT NOT NULL REFERENCES core.Socios(nro_socio),
            fecha_hora_envio TIMESTAMP NOT NULL,
            confirmacion_envio BOOLEAN NOT NULL
        );
                                
        CREATE TABLE logs.Bitacora
        (
            id BIGSERIAL PRIMARY KEY,
            fecha_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            ejecutor VARCHAR(100) NOT NULL DEFAULT CURRENT_USER, -- Reemplaza SUSER_SNAME y SESSION_CONTEXT por el usuario activo en PG
            desde VARCHAR(100) NOT NULL DEFAULT 'Sistema',
            evento VARCHAR(50) NOT NULL CHECK (evento IN (
                'SOCIO_ALTA', 'SOCIO_BAJA', 
                'PERSONA_MODIFICADA', 'PERSONA_NUEVA',
                'PAGO_REGISTRADO', 'PAGO_MODIFICADO',
                'COBRO_AUTOMATICO_SALDO',
                'ACTIVIDAD_INICIADA', 'ACTIVIDAD_FINALIZADA',
                'CUOTA_ACTUALIZADA', 'GRUPO_NUEVO'
            )), 
            entidad_afectada VARCHAR(50) NOT NULL,
            id_afectada BIGINT NOT NULL,
            contexto VARCHAR(200),
            detalle VARCHAR(400),
            entidad_relacionada VARCHAR(50),
            id_relacionado BIGINT
        );

        CREATE TABLE logs.Conexiones_de_Usuarios
        (
            id BIGSERIAL PRIMARY KEY,
            id_usuario SMALLINT REFERENCES params.Usuarios_del_Sistema(id),
            sesion_iniciada TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        DO $$BEGIN
            RAISE NOTICE '[INFO] Creando tablas de Registros';    
        END$$;

    --support Antes INTERNAL
        CREATE TABLE support.Patch_Queue
        (
            id SERIAL PRIMARY KEY,
            sp_patch_name VARCHAR(255) NOT NULL, -- SYSNAME cambia a VARCHAR(255)
            sp_to_patch_name VARCHAR(255) NOT NULL,
            create_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            apply_date TIMESTAMP,
            state_success BOOLEAN NOT NULL DEFAULT FALSE,
            comment VARCHAR(128) NOT NULL
        );

        CREATE TABLE support.Patch_Log
        (
            id BIGSERIAL PRIMARY KEY,
            id_patch_queue INT REFERENCES support.Patch_Queue(id),
            table_name VARCHAR(255) NOT NULL,
            field_name VARCHAR(255) NOT NULL,
            old_value VARCHAR(512),
            new_value VARCHAR(512)
        );

        CREATE TABLE support.Migration_Log
        (
            id SERIAL PRIMARY KEY,
            sp_migration_name VARCHAR(255) NOT NULL,
            executed_by VARCHAR(255) DEFAULT CURRENT_USER,
            apply_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            old_version INT NOT NULL,
            new_version INT NOT NULL,
            description VARCHAR(512) NOT NULL
        );

        CREATE TABLE support.Diccionario_Centinelas
        (
            id SMALLSERIAL PRIMARY KEY,
            tabla VARCHAR(100) NOT NULL,
            campo VARCHAR(100) NOT NULL,
            valor_int INT,
            valor_varchar VARCHAR(255),
            valor_date DATE,
            valor_decimal DECIMAL(19,2),
            comentario VARCHAR(200) NOT NULL CHECK (comentario IS NULL OR length(trim(comentario)) > 2),

            CONSTRAINT CHK_Diccionario_Centinelas__un_solo_valor CHECK (
                (CASE WHEN valor_int IS NOT NULL THEN 1 ELSE 0 END +
                 CASE WHEN valor_varchar IS NOT NULL THEN 1 ELSE 0 END +
                 CASE WHEN valor_date IS NOT NULL THEN 1 ELSE 0 END +
                 CASE WHEN valor_decimal IS NOT NULL THEN 1 ELSE 0 END) <= 1
            )
        );

        CREATE TABLE support.Control_de_Procesos
        (
            id SERIAL PRIMARY KEY,
            nombre_proceso VARCHAR(255) NOT NULL,
            numero_ejecucion INT NOT NULL CHECK (numero_ejecucion >= 0),
            fecha_ejecucion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            usuario_ejecutor VARCHAR(50) NOT NULL DEFAULT CURRENT_USER,
            es_proceso_unico BOOLEAN NOT NULL,

            UNIQUE (nombre_proceso, numero_ejecucion)
        );

        DO $$BEGIN
        RAISE NOTICE '[INFO] Creando tablas Tecnicas (Esquema support)';

        RAISE NOTICE '[DONE] ¡Tablas creadas con éxito!';
        END$$;
COMMIT;
