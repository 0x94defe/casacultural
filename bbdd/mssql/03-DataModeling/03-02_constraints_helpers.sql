CREATE OR ALTER FUNCTION core.fn_chk_especial_email(@email VARCHAR(MAX)) RETURNS BIT WITH SCHEMABINDING AS
	BEGIN
	    IF @email IS NULL
	    	RETURN 1;

	    DECLARE @e VARCHAR(MAX) = TRIM(@email);
	    IF @e NOT LIKE '%_@%_.%' 
	    	RETURN 0;

	    IF @e LIKE '%[^a-zA-Z0-9@._+-]%' 
	    	RETURN 0;

	    IF @e LIKE '% %' OR @e LIKE '%@@%' OR @e LIKE '%..%' OR @e LIKE '@%' OR @e LIKE '%@.' OR @e LIKE '%.@%' 
	        RETURN 0;

	    RETURN 1;
	END;
PRINT '[INFO] fn_chk_especial_email creada';
GO

CREATE OR ALTER FUNCTION core.fn_chk_solo_letras(@texto VARCHAR(MAX)) RETURNS BIT WITH SCHEMABINDING AS
	BEGIN
	    IF @texto IS NULL
	    	RETURN 1;

	    DECLARE @t VARCHAR(MAX) = TRIM(@texto);
	    IF @t LIKE '%[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ''. -]%' OR @t LIKE '%  %' OR @t LIKE ' %' OR @t LIKE '% '
	        RETURN 0;

	    RETURN 1;
	END;
PRINT '[INFO] fn_chk_solo_letras creada';
GO

CREATE OR ALTER FUNCTION core.fn_chk_alfanumerico(@texto VARCHAR(MAX)) RETURNS BIT WITH SCHEMABINDING AS
	BEGIN
	    IF @texto IS NULL
	    	RETURN 1;

	    DECLARE @t VARCHAR(MAX) = TRIM(@texto);
	    IF @t LIKE '%[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ''. -]%' OR @t LIKE '%  %' OR @t LIKE ' %' OR @t LIKE '% '
			RETURN 0;

	    RETURN 1;
	END;
PRINT '[INFO] fn_chk_alfanumerico creada';
GO

CREATE OR ALTER FUNCTION core.fn_chk_solo_espacios(@texto VARCHAR(MAX)) RETURNS BIT WITH SCHEMABINDING AS
	BEGIN
	    IF @texto IS NULL 
	    	RETURN 1;

	    DECLARE @t VARCHAR(MAX) = TRIM(@texto);
	    IF @t LIKE '%  %' OR @t LIKE ' %' OR @t LIKE '% '
	        RETURN 0;

	    RETURN 1;
	END;
PRINT '[INFO] fn_chk_solo_espacios creada';
GO

CREATE OR ALTER FUNCTION core.fn_chk_especial_domicilio(@texto VARCHAR(MAX)) RETURNS BIT WITH SCHEMABINDING AS
	BEGIN
	    IF @texto IS NULL
	    	RETURN 1;

	    DECLARE @t VARCHAR(MAX) = TRIM(@texto);
	    IF @t LIKE '%[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ''./° -,]%' 
	    	RETURN 0;

	    IF @t LIKE '%  %' OR @t LIKE ' %' OR @t LIKE '% '
	    	RETURN 0;

	    -- 3. Estructura Calle + Altura (El corazón del Domicilio)
	    -- Debe tener "Calle [espacio] Numero" o terminar en "S/N"
	    IF NOT (@t LIKE '%_ [0-9]%' OR @t LIKE '% S/N')
	    	RETURN 0;

	    -- 4. El número de altura debe estar pegado al primer espacio 
	    -- (Evita "Calle      123")
	    DECLARE @posSpaceNum INT = PATINDEX('% [0-9]%', @t);
	    IF @posSpaceNum > 0 AND SUBSTRING(@t, @posSpaceNum + 1, 1) NOT LIKE '[0-9]' 
	        RETURN 0;

	    -- 5. Validación del Guion (Debe estar rodeado de espacios)
	    IF @t LIKE '%-%' AND @t NOT LIKE '% - %' 
	    	RETURN 0;

	    RETURN 1;
	END;
PRINT '[INFO] fn_chk_especial_domicilio creada';
GO

CREATE OR ALTER FUNCTION core.fn_chk_persona_notificacion_pago(@id_persona INT) RETURNS BIT WITH SCHEMABINDING AS
	BEGIN
	    DECLARE @result BIT = 1;
	    
	    IF EXISTS (SELECT 1 FROM core.Socios s WHERE s.id_persona = @id_persona AND s.desea_email_pago = 1)
	        IF EXISTS (SELECT 1 FROM core.Personas p WHERE p.id = @id_persona AND p.email IS NULL)
	            SET @result = 0;
	    
	    RETURN @result;
	END;
PRINT '[INFO] fn_chk_persona_notificacion_pago creada';
GO

CREATE OR ALTER FUNCTION core.fn_chk_persona_pago_domicilio(@id_persona INT) RETURNS BIT WITH SCHEMABINDING AS
	BEGIN
	    DECLARE @result BIT = 1;
	    
	    IF EXISTS (SELECT 1 FROM core.Socios s WHERE s.id_persona = @id_persona AND s.pago_preferido = 1)
	        IF EXISTS (SELECT 1 FROM core.Personas p WHERE p.id = @id_persona AND p.domicilio IS NULL)
	            SET @result = 0;
	    
	    RETURN @result;
	END;
PRINT '[INFO] fn_chk_persona_pago_domicilio creada';
GO

CREATE OR ALTER FUNCTION core.fn_chk_persona_pago_virtual(@id_persona INT) RETURNS BIT WITH SCHEMABINDING AS
	BEGIN
	    DECLARE @result BIT = 1;
	    
	    IF EXISTS (SELECT 1 FROM core.Socios s WHERE s.id_persona = @id_persona AND s.pago_preferido = 2)
	        IF EXISTS (SELECT 1 FROM core.Personas p WHERE p.id = @id_persona AND p.celular IS NULL)
	            SET @result = 0;
	    
	    RETURN @result;
	END;
PRINT '[INFO] fn_chk_persona_pago_virtual creada';
GO


PRINT '[DONE] Funciones de helper Listas';
GO
