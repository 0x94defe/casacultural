CREATE OR ALTER VIEW lookups.vw_toda_la_info AS
	WITH 
		idsVinculadasGrupo AS (
			SELECT id_grupo, STRING_AGG(id_persona, ', ') AS id_personas_vinculadas
			FROM lookups.vw_personas_vinculados 
			GROUP BY id_grupo
		 ),
		personasVinculadas AS (
			SELECT fp.id_persona, idvg.id_personas_vinculadas
			FROM idsVinculadasGrupo idvg
			JOIN links.Grupos_con_Personas fp ON fp.id_grupo = idvg.id_grupo
		 )
	SELECT
		s.nro_socio,
		s.fecha_alta,
		s.fecha_baja,
		s.necesita_cupon,
		tp.descripcion AS pago_preferido,
		pv.id_personas_vinculadas,
		p.*
	FROM core.Socios s
	LEFT JOIN core.Personas p ON p.id = s.id_persona 
	LEFT JOIN lookups.Tipos_de_Pago tp ON tp.id = s.pago_preferido
	LEFT JOIN personasVinculadas pv ON pv.id_persona = p.id;
PRINT '[INFO] vw_toda_la_info Creada';
GO
