CREATE OR ALTER FUNCTION dbo.fn_ULTIMO_5TODIAHABIL_MES(@fecha DATE) RETURNS DATE AS
	BEGIN
		DECLARE @diaActual DATE = EOMONTH(@fecha);
	    DECLARE @c INT = 0;

	    -- deberia asegurarme que que 1 = domingo, 7 = sabado
	    --SET DATEFIRST 7; pero no puedo usarla en fn y es por sesion only

	    -- 1900-01-01 fue lunes → modulo 7:
			-- 5 = sabado, 6 = domingo (determinista, sin DATEFIRST)

	    WHILE @c < 5 
	    BEGIN
	    	--tecnica determinista
			IF  (DATEDIFF(DAY, '19000101', @diaActual) % 7) NOT IN (5,6) AND -- no sea fin de semana
	          	  NOT EXISTS (SELECT 1 FROM params.Feriados WHERE fecha = @diaActual) -- ni tampoco no feriado
	        	SET @c = @c + 1;

	        IF @c < 5
	            SET @diaActual  = DATEADD(DAY, -1, @diaActual);
	    END
	    
	    RETURN @diaActual;
	END;
PRINT '[INFO] fn_ULTIMO_5TODIAHABIL_MES Creada';
GO

CREATE OR ALTER FUNCTION dbo.fn_checkBadDataMark(@text NVARCHAR(255)) RETURNS BIT AS
	BEGIN
		IF @text IS NULL 
			RETURN NULL;

		SET @text = lower(@text);

		IF (@text LIKE '%x%' OR 
			 @text LIKE '%?%' OR
			  @text LIKE '%cf.%' OR
			   @text LIKE '%*%')
			RETURN 1;

		RETURN 0;
	END;
PRINT '[INFO] fn_checkBadDataMark Creada';
GO

CREATE OR ALTER FUNCTION dbo.fn_numMonth(@text NVARCHAR(10)) RETURNS INT AS
	BEGIN
		IF @text IS NULL
			RETURN NULL;

		DECLARE @ret INT = NULL;

	    SELECT TOP 1 @ret = mes_num
	    FROM (VALUES
				(1,'ene'), (1,'enero'),
			    (2,'feb'), (2,'febr'), (2,'febrero'),
			    (3,'mar'), (3,'marzo'),
			    (4,'abr'), (4,'abril'),
			    (5,'may'), (5,'mayo'),
			    (6,'jun'), (6,'junio'),
			    (7,'jul'), (7,'julio'),
			    (8,'ago'), (8,'agst'), (8,'agosto'),
			    (9,'sep'), (9,'sept'), (9,'septiembre'),
			    (10,'oct'), (10,'octubre'),
			    (11,'nov'), (11,'noviembre'),
			    (12,'dic'), (12,'diciembre')
	    	) v(mes_num, mes_corto)
	    WHERE lower(trim(@text)) LIKE '%' + mes_corto + '%';

		RETURN @ret;
	END;
PRINT '[INFO] fn_numMonth Creada';
GO

CREATE OR ALTER FUNCTION dbo.fn_capitalize(@text NVARCHAR(1000)) RETURNS NVARCHAR(1000) AS
	BEGIN
		IF @text IS NULL RETURN NULL;

	    DECLARE @reset BIT = 1;
	    DECLARE @ret NVARCHAR(1000) = '';
	    DECLARE @i INT = 1;
	    DECLARE @c CHAR(1);
			DECLARE @len INT = LEN(@text);

	    WHILE @i <= @len 
	    BEGIN
	        SELECT 
	    		@c = SUBSTRING(@text, @i, 1),
	        	@ret = @ret + CASE WHEN @reset = 1 THEN UPPER(@c) ELSE LOWER(@c) END,
	        	@reset = CASE WHEN @c LIKE '[a-zA-Z]' THEN 0 ELSE 1 END;

	        SET @i = @i + 1;
	    END

	    RETURN @ret;
	END;
PRINT '[INFO] fn_capitalize Creada';
GO

CREATE OR ALTER FUNCTION dbo.fn_getNumber(@text NVARCHAR(255)) RETURNS VARCHAR(255) AS
	BEGIN
		IF @text IS NULL
			RETURN NULL;

	    DECLARE @ret VARCHAR(255) = '';
	    DECLARE @i INT = 1;
	    DECLARE @len INT = LEN(@text);
	    DECLARE @c CHAR(1);
	    

	    WHILE @i <= @len 
	    BEGIN
	        SELECT
	        	@c = SUBSTRING(@text, @i, 1),        
	        	@ret = @ret + CASE WHEN @c LIKE '[0-9]' THEN @c ELSE '' END;
	        
	        SET @i = @i + 1;
	    END

		RETURN @ret;
	END;
PRINT '[INFO] fn_getNumber Creada';
GO


PRINT '[DONE] Funciones de utilidad Listas';
GO
