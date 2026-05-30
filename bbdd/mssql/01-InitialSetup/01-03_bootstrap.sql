IF DB_ID('Achiras') IS NULL
		THROW 50001, 'Achiras NO existe', 1;
USE Achiras;
GO

SET XACT_ABORT ON; 

BEGIN TRY
	BEGIN TRANSACTION;
		--tablas tecnicas
			CREATE TABLE internal.Patch_Queue
			(
			    id INT IDENTITY PRIMARY KEY,
			    sp_patch_name SYSNAME NOT NULL,
			    sp_to_patch_name SYSNAME NOT NULL,
			    create_date DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
			    apply_date DATETIME2,
				state_success BIT NOT NULL DEFAULT 0,    -- 0 = no, 1 = yes
				comment VARCHAR(128) NOT NULL
			);

			CREATE TABLE internal.Patch_Log
			(
			    id BIGINT IDENTITY PRIMARY KEY,
			    id_patch_queue INT REFERENCES internal.Patch_Queue(id),
			    table_name SYSNAME NOT NULL,
			    field_name SYSNAME NOT NULL,
			    old_value VARCHAR(512),
			    new_value VARCHAR(512)
			);

			CREATE TABLE internal.Migration_Log
			(
			    id INT IDENTITY PRIMARY KEY,
			    sp_migration_name SYSNAME NOT NULL,
			    executed_by SYSNAME DEFAULT SUSER_SNAME(),
			    apply_date DATETIME2 DEFAULT SYSDATETIME(),
			    old_version INT NOT NULL,
			    new_version INT NOT NULL,
				description NVARCHAR(512) NOT NULL
			);

			CREATE TABLE internal.Diccionario_Centinelas
			(
				id SMALLINT IDENTITY PRIMARY KEY,
				tabla VARCHAR(100) NOT NULL,
			    campo VARCHAR(100) NOT NULL,
			    valor_int INT,
			    valor_varchar NVARCHAR(255),
			    valor_date DATE,
			    valor_decimal DECIMAL(19,2),
			    comentario VARCHAR(200) NOT NULL CHECK (comentario IS NULL OR LEN(TRIM(comentario)) > 2),

				CONSTRAINT CHK_Diccionario_Centinelas__un_solo_valor CHECK ((
					    CASE WHEN valor_int IS NOT NULL THEN 1 ELSE 0 END +
					    CASE WHEN valor_varchar IS NOT NULL THEN 1 ELSE 0 END +
					    CASE WHEN valor_date IS NOT NULL THEN 1 ELSE 0 END +
					    CASE WHEN valor_decimal IS NOT NULL THEN 1 ELSE 0 END) <= 1
					)
			);

			CREATE TABLE internal.Control_de_Procesos
			(
			    id INT IDENTITY PRIMARY KEY,
			    nombre_proceso SYSNAME NOT NULL,
			    numero_ejecucion INT NOT NULL CHECK (numero_ejecucion >= 0),
			   	fecha_ejecucion DATETIME2 NOT NULL DEFAULT GETDATE(),
			    usuario_ejecutor VARCHAR(50) NOT NULL DEFAULT SUSER_SNAME(),
			    es_proceso_unico BIT NOT NULL,

			    UNIQUE (nombre_proceso, numero_ejecucion)
			);
		PRINT '[INFO] Creando tablas Tecnicas';

		--funciones
			CREATE OR ALTER FUNCTION internal.fn_Verificar__Ejecucion_Proceso(@NombreProceso VARCHAR(100), @esSingular BIT = 0) RETURNS BIT AS
				/**	fn_Verificar__Ejecucion_Proceso
				    Verifica si existe al menos un registro de ejecución para un proceso dado.

				    Parámetros:
				    - @NombreProceso : Nombre lógico del proceso / stored procedure.
				    - @esSingular    :
				        0 -> consulta ejecuciones normales (no singulares).
				        1 -> consulta ejecuciones marcadas como "proceso único".

				    Uso previsto:
				    - Permitir distinguir entre:
				        a) procesos que pueden ejecutarse múltiples veces
				        b) procesos que deben ejecutarse una sola vez (deploys, seeds, migraciones)

				    IMPORTANTE:
				    - La función NO determina si un proceso "puede ejecutarse".
				    - Solo informa si existe una ejecución previa con la combinación indicada.
				    - La lógica de bloqueo / validación debe hacerse en el SP llamador.
				*/
				BEGIN
					DECLARE @ret BIT = NULL;
					
				    SELECT TOP 1 @ret = 1 
				    FROM internal.Control_de_Procesos
				    WHERE nombre_proceso = @NombreProceso AND es_proceso_unico = @esSingular
				    ORDER BY numero_ejecucion DESC; --se necesita para que el primer registro cumpla con el where

				    RETURN @ret;
				END;
			GO
			PRINT '[INFO] fn_Verificar__Ejecucion_Proceso Creada';
			GO
		PRINT '[INFO] Creando funciones Tecnicas';
		
		--SPs
			CREATE OR ALTER PROCEDURE internal.sp_Registrar__Ejecucion_Proceso(@NombreProceso SYSNAME, @activarComoSingular BIT = 0) AS
				BEGIN
				    SET NOCOUNT ON;
					
					-- si ya existe una marca de "singular", prohibido seguir.
				    IF EXISTS (SELECT 1 FROM internal.Control_de_Procesos WHERE nombre_proceso = @NombreProceso AND es_proceso_unico = 1)
				      	THROW 50001, '[ERROR] Bloqueo de Seguridad: El proceso ya fue ejecutado como singular y no permite nuevas entradas.', 1;

					DECLARE @ultimoValor INT = (SELECT MAX(numero_ejecucion) FROM internal.Control_de_Procesos WHERE nombre_proceso = @NombreProceso);
					SET @ultimoValor = ISNULL(@ultimoValor, 0);

				  	INSERT INTO internal.Control_de_Procesos (nombre_proceso, numero_ejecucion, es_proceso_unico) VALUES
				  		(@NombreProceso, @ultimoValor + 1, @activarComoSingular);     
				END;
			GO
			PRINT '[INFO] sp_Registrar__Ejecucion_Proceso Creada';
		PRINT '[DONE] Creando procedimientos  Listos';
	COMMIT TRANSACTION

	PRINT '[DONE] Sistema de meta-datos Listo';
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION;
	PRINT '[ERROR] Algo anda mal en la creacion del sistema de meta-datos';
	THROW;
END CATCH;
GO
