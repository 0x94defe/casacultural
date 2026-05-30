CREATE OR ALTER VIEW lookups.vw_campos_problematicos AS
	WITH cte AS (
		SELECT 
			id AS id_persona,
			dni,
			nro_socio,
			apellido,
			nombre,
			domicilio,
			ciudad,
			telefono,
			celular,
			email,
			fecha_nacimiento,
			fecha_alta,
			CONCAT_WS(
				', ',
				CASE WHEN dni <= 0 OR dni IS NULL 
					 THEN 'dni' END,
				CASE WHEN nro_socio <= 0 OR nro_socio IS NULL 
					 THEN 'nro_socio' END,
				CASE WHEN Apellido LIKE '%[^a-zA-Z. ]%' OR LEN(Apellido) <= 2 OR Apellido IS NULL 
					 THEN 'Apellido' END,
				CASE WHEN Nombre LIKE '%[^a-zA-Z. ]%' OR LEN(Nombre) <= 2 OR Nombre IS NULL 
					 THEN 'Nombre' END,
				CASE WHEN Domicilio LIKE '%[^a-zA-Z0-9°.- ]%' OR LEN(domicilio) < 2 OR domicilio IS NULL
					 THEN 'domicilio' END,
				CASE WHEN Ciudad LIKE '%[^a-zA-Z0-9°. ]%' OR LEN(Ciudad) <= 2 OR Ciudad IS NULL 
					 THEN 'Ciudad' END,
				CASE WHEN Telefono LIKE '%[^0-9 -]%' OR Telefono NOT LIKE '[0-9][0-9][0-9 ][0-9 ][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' OR Telefono IS NULL 
					 THEN 'Telefono' END,
				CASE WHEN Celular LIKE '%[^0-9 -]%' OR Celular NOT LIKE '[0-9][0-9] [0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' OR Celular IS NULL
					 THEN 'Celular' END,
				CASE WHEN email LIKE '%[^a-zA-Z0-9@._-]%' OR LEN(email) <= 5 OR email IS NULL 
					 THEN 'Email' END,
				CASE WHEN Fecha_Nacimiento = '1900-01-01' OR Fecha_Nacimiento IS NULL
					 THEN 'Fecha Nac.' END,
				CASE WHEN Fecha_alta = '1900-01-01' OR Fecha_alta IS NULL
					 THEN 'Fecha Alta' END
			) AS Campos_Problematicos
		FROM lookups.vw_toda_la_info
	 )
	SELECT *
	FROM cte
	WHERE Campos_Problematicos <> '';
PRINT '[INFO] vw_campos_problematicos Creada';
GO
