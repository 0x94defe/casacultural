CREATE OR ALTER PROCEDURE core.sp_Fusionar__Grupos(@g1 INT, @g2 INT, @nuevaDescripcion VARCHAR(256)) AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;

		IF @g1 IS NULL OR @g2 IS NULL OR LEN(TRIM(@nuevaDescripcion)) < 2
			THROW 50000, '[ERROR] Argumentos invalidos', 1;

		IF @g1 = @g2
			THROW 50000, '[ERROR] No se puede fusionar el mismo grupo.', 1;

		IF NOT EXISTS (SELECT 1 FROM core.Grupos WHERE id = @g1) OR NOT EXISTS (SELECT 1 FROM core.Grupos WHERE id = @g2)
			THROW 50000, '[ERROR] Hay un grupo que no existe en la db', 1;


		DECLARE @tipo_familia_en_disputa TABLE(grupo INT PRIMARY KEY, esFamilia BIT, cantPersonas INT);
		DECLARE @desc1 VARCHAR(256) = (SELECT descripcion FROM core.Grupos WHERE id = @g1);
		DECLARE @desc2 VARCHAR(256) = (SELECT descripcion FROM core.Grupos WHERE id = @g2);
		DECLARE @esFamilia_final BIT;
		DECLARE @nuevaDescripcion_final VARCHAR(256);

		INSERT INTO @tipo_familia_en_disputa(grupo, esFamilia, cantPersonas)
		SELECT
			1,
			(SELECT esFamilia FROM core.Grupos WHERE id = @g1),
			(SELECT COUNT(*) FROM core.Grupos_con_Personas WHERE id_grupo = @g1);

		INSERT INTO @tipo_familia_en_disputa(grupo, esFamilia, cantPersonas)
		SELECT
			2,
			(SELECT esFamilia FROM core.Grupos WHERE id = @g2),
			(SELECT COUNT(*) FROM core.Grupos_con_Personas WHERE id_grupo = @g2)

		SELECT TOP 1 @esFamilia_final = esFamilia
		FROM @tipo_familia_en_disputa
		ORDER BY cantPersonas DESC;

		IF @nuevaDescripcion IS NULL
		  	BEGIN
		 		WITH Apellidos AS (
					    SELECT TRIM(value) AS apellido
					    FROM STRING_SPLIT(@desc1, '+')
					    
					    UNION
					    
					    SELECT TRIM(value)
					    FROM STRING_SPLIT(@desc2, '+')
					)
				SELECT @nuevaDescripcion_final = STRING_AGG(apellido, ' + ') WITHIN GROUP (ORDER BY apellido)
				FROM Apellidos;
		  	END
		ELSE
			BEGIN
			  	SET @nuevaDescripcion_final = @nuevaDescripcion;
			END

		-- g1 absorbe g2
		BEGIN TRY
			BEGIN TRAN;
				DELETE gp2
				FROM core.Grupos_con_Personas gp2
				JOIN core.Grupos_con_Personas gp1 
					ON gp1.id_persona = gp2.id_persona 
					AND gp1.id_grupo = @g1
				WHERE gp2.id_grupo = @g2;

				UPDATE core.Grupos_con_Personas
				SET id_grupo = @g1
				WHERE id_grupo = @g2;

				DELETE FROM core.Grupos 
				WHERE id = @g2;

				UPDATE core.Grupos SET
					esFamilia = @esFamilia_final,
					descripcion = @nuevaDescripcion_final
				WHERE id = @g1;
			COMMIT;
		END TRY
		BEGIN CATCH
			ROLLBACK;
			THROW;
		END CATCH
	END;
GO
PRINT '[INFO] sp_Fusionar__Grupos Creada';
GO
