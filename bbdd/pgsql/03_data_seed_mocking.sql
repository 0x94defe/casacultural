--data seed y mocking
--datos basicos
BEGIN;
    INSERT INTO lookups.Tipos_de_Pago (id, descripcion) VALUES
        (1, 'EFECTIVO'),
        (2, 'DEBITO'),
        (3, 'CREDITO'),
        (4, 'TRANSFERENCIA')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO core.Nacionalidad (id, descripcion) VALUES
        (1, 'Argentina'),
        (2, 'Uruguaya'),
        (3, 'Chilena')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO core.Ciudad (id, descripcion) VALUES
        (1, 'CABA'),
        (2, 'Rosario'),
        (3, 'Córdoba'),
        (4, 'Mendoza')
    ON CONFLICT (id) DO NOTHING;


    INSERT INTO core.Personas 
    (id, dni, __nombre, __apellido, __celular, __domicilio, __email, fecha_nacimiento, ciudad, __telefono, __observaciones, nacionalidad, genero)
    VALUES
        (1, 35123456, 'Juan Carlos', 'Gomez', '5491155551234', 'Av. Corrientes 1234', 'juan.gomez@email.com', '1990-05-15', 1, NULL, 'Socio fundador activo', 1, 'M'),
        (2, 28987654, 'María Laura', 'Rodriguez', '5493415559876', 'Calle Urquiza 789', 'maria.rod@email.com', '1982-11-22', 2, '03414445555', NULL, 1, 'F'),
        (3, 42111222, 'Lucas', 'Benitez', '5493515556677', 'Av. Colon 450', 'lucas.b@email.com', '1999-02-03', 3, NULL, 'Paga siempre adelantado', 1, 'M'),
        (4, 95888777, 'Valentina', 'Silva', '5491155550000', 'Palacio Salvo 200', 'valen.silva@email.com', '1995-08-14', 1, NULL, 'Extranjera residente', 2, 'F'),
        (5, 31444555, 'Carlos', 'Álvarez', '5492615554433', 'San Martin 900', 'carlos.alvarez@email.com', '1985-06-30', 4, NULL, 'Pidió no enviar emails los fines de semana', 1, 'M'),
        -- Socios nuevos que se van a dar de alta
        (6, 38444555, 'Mariano', 'López', '5491155552211', 'Av. Santa Fe 3400', 'mariano.lopez@email.com', '1994-03-12', 1, NULL, 'Pidió cobrar del 1 al 5', 1, 'M'),
        (7, 25333222, 'Patricia', 'Sosa', '5493415554488', 'Pellegrini 1500', 'patricia.sosa@email.com', '1976-07-25', 2, '03414218899', 'Familiar del socio 1002', 1, 'F'),
        (8, 41777888, 'Esteban', 'Quito', '5493515553322', 'Duarte Quirós 950', 'esteban.quito@email.com', '1998-10-05', 3, NULL, NULL, 1, 'M'),

        -- Socios que van a estar dados de BAJA
        (9, 22111333, 'Ricardo', 'Darin', '5491155559999', 'Libertador 4500', 'ricardito@email.com', '1972-01-16', 1, NULL, 'Ex-socio, se dio de baja por viaje', 1, 'M'),
        (10, 33444222, 'Ana', 'Koren', '5492615551144', 'Las Heras 320', 'ana.k@email.com', '1988-04-09', 4, NULL, 'Dejó de pagar en 2024', 3, 'F'),

        -- Personas que NO SON SOCIOS (pueden ser profes, staff o registrados)
        (11, 30222111, 'Marcelo', 'Gallardo', '5491155550101', 'Alcorta 7000', 'muñeco@email.com', '1980-01-18', 1, NULL, 'Profesor de la actividad Fútbol', 1, 'M'),
        (12, 36888999, 'Luciana', 'Aymar', '5493415550202', 'Av. Belgrano 200', 'lucha.aymar@email.com', '1991-08-10', 2, NULL, 'Coordinadora de eventos', 1, 'F'),
        (13, 45111000, 'Mateo', 'Messi', '5493415550303', 'Funes R9', 'mateito@email.com', '2005-09-11', 2, NULL, 'Aspirante, vino a averiguar pero no se asoció', 1, 'M')
    ON CONFLICT (id) DO NOTHING;


    INSERT INTO core.Socios 
    (nro_socio, id_persona, fecha_alta, fecha_baja, necesita_cupon, desea_email_pago, pago_preferido, motivo_baja)
    VALUES
        (1001, 1, '2024-01-10', NULL,         FALSE, TRUE,  2, NULL), -- Juan Gomez (Débito)
        (1002, 2, '2024-01-15', NULL,         TRUE,  TRUE,  1, NULL), -- María Rodriguez (Efectivo, quiere cupón)
        (1003, 3, '2024-02-01', NULL,         FALSE, FALSE, 4, NULL), -- Lucas Benitez (Transferencia, no quiere emails)
        (1004, 4, '2024-03-12', '2024-12-31', FALSE, TRUE,  3, 'Mudanza a su país de origen'), -- Valentina (Baja por mudanza)
        (1005, 5, '2024-05-20', NULL,         FALSE, TRUE,  2, NULL),  -- Carlos Álvarez (Débito)

        -- Activos
        (1006, 6, '2024-06-01', NULL,         FALSE, TRUE,  4, NULL), -- Mariano (Transferencia)
        (1007, 7, '2024-06-15', NULL,         TRUE,  TRUE,  1, NULL), -- Patricia (Efectivo)
        (1008, 8, '2024-07-01', NULL,         FALSE, FALSE, 2, NULL), -- Esteban (Débito)

        -- Inactivos (Dados de baja)
        (1009, 9, '2024-01-05', '2025-03-15', FALSE, TRUE,  3, 'Se mudó a España por trabajo de forma indefinida'),
        (1010, 10, '2024-02-10', '2024-11-30', TRUE,  FALSE, 1, 'Falta de pago crónica y falta de respuesta a intimaciones')
    ON CONFLICT (nro_socio) DO NOTHING;
COMMIT;

--mas datos
BEGIN;
    INSERT INTO core.Grupos (id, descripcion, esFamilia) VALUES
        (1, 'Familia Gomez-Silva (Juan y Valentina)', TRUE),
        (2, 'Familia Rodriguez-Sosa (María y Patricia)', TRUE),
        (3, 'Yoga - Turno Mañana Martes/Jueves', FALSE),
        (4, 'Fútbol Masculino - Torneo Interno', FALSE),
        (5, 'Comisión Directiva - Staff', FALSE)
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO links.Grupos_con_Personas (id_grupo, id_persona) VALUES
        -- Integrantes de la Familia Gomez-Silva (id_persona: 1 y 4)
        (1, 1), -- Juan Carlos Gomez (Socio Activo)
        (1, 4), -- Valentina Silva (Ex-socia de Uruguay)

        -- Integrantes de la Familia Rodriguez-Sosa (id_persona: 2 y 7)
        (2, 2), -- María Laura Rodriguez (Socio Activo)
        (2, 7), -- Patricia Sosa (Socio Activo)

        -- Alumnos del grupo de Yoga (id_persona: 2, 5, 10 - mezcla de activos, bajas y otros)
        (3, 2),  -- María Laura Rodriguez (Socio Activo)
        (3, 5),  -- Carlos Álvarez (Socio Activo)
        (3, 10), -- Ana Koren (Socio de Baja)

        -- Jugadores de Fútbol (id_persona: 1, 3, 6, 8, 13 - metemos al aspirante Mateo tmb)
        (4, 1),  -- Juan Carlos Gomez
        (4, 3),  -- Lucas Benitez
        (4, 6),  -- Mariano López
        (4, 8),  -- Esteban Quito
        (4, 13), -- Mateo Messi (No es socio pero juega el torneo)

        -- Staff / Comisión (id_persona: 11, 12 - Profesores y coordinadores)
        (5, 11), -- Marcelo Gallardo (Profesor)
        (5, 12)  -- Luciana Aymar (Coordinadora)
    ON CONFLICT (id_grupo, id_persona) DO NOTHING;

    -- El campo id_persona_a_cargo apunta al profesor/coordinador (Persona 11 y 12)
    INSERT INTO core.Actividades (id, descripcion, id_persona_a_cargo, fecha_inicio, fecha_fin, motivo_baja) VALUES
        (1, 'Clases de Yoga Kundalini', 11, '2024-03-01', NULL, NULL), -- A cargo de Marcelo Gallardo
        (2, 'Torneo de Fútbol 7 Apertura', 11, '2024-03-01', '2024-07-30', 'Finalizó el cronograma del torneo'),
        (3, 'Taller de Iniciación Deportiva Infantil', 12, '2024-05-01', NULL, NULL), -- A cargo de Luciana Aymar
        (4, 'Crossfit Avanzado (Cancelado)', 12, '2024-02-01', '2024-04-15', 'Falta de quórum y rotura de materiales')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO links.Personas_con_Actividades (id, id_persona, id_actividad, fecha_inicio, fecha_fin) VALUES
        -- Inscripciones a Yoga (Actividad 1)
        (1, 2, 1, '2024-03-01', NULL),
        (2, 5, 1, '2024-05-20', NULL),
        (3, 10, 1, '2024-03-01', '2024-11-30'), -- Se bajó de la actividad cuando se dio de baja como socia

        -- Inscripciones a Fútbol (Actividad 2)
        (4, 1, 2, '2024-03-01', '2024-07-30'),
        (5, 3, 2, '2024-03-01', '2024-07-30'),
        (6, 6, 2, '2024-06-01', '2024-07-30'),

        -- Inscripción al taller infantil (Actividad 3)
        (7, 13, 3, '2024-05-01', NULL) -- Mateo Messi asistiendo al taller
    ON CONFLICT (id) DO NOTHING;
COMMIT;

--cobros
BEGIN;
    INSERT INTO lookups.Origenes_de_Cobro (id, descripcion) VALUES
        (1, 'Cobrador a Domicilio'),
        (2, 'Profesor de Actividad'),
        (3, 'Autopago - Web/Plataforma'),
        (4, 'Administración - Sede Central')
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO core.Cuotas (periodo, valor) VALUES
        ('2025-01-01', 8000.00), ('2025-02-01', 8000.00), ('2025-03-01', 8000.00),
        ('2025-04-01', 8000.00), ('2025-05-01', 8000.00), ('2025-06-01', 8000.00),
        ('2025-07-01', 8000.00), ('2025-08-01', 8000.00), ('2025-09-01', 8000.00),
        ('2025-10-01', 8000.00), ('2025-11-01', 8000.00), ('2025-12-01', 8000.00),

        ('2026-01-01', 12000.00), ('2026-02-01', 12000.00), ('2026-03-01', 12000.00),
        ('2026-04-01', 12000.00), ('2026-05-01', 12000.00)
    ON CONFLICT (periodo) DO NOTHING;

    -- CASO 1: Juan Gomez (Yerno) paga $44.000 en Administración (Origen 4)
        -- Paga su cuota del mes y apila 4 cuotas atrasadas de su suegra (María Rodriguez)
        INSERT INTO core.Pagos 
        (id, fecha_hora_pago, id_persona_pagadora, medio_pago, origen_carga, monto_pagado_real, comentario)
        VALUES 
        (1, '2026-05-10 18:30:00', 1, 2, 4, 44000.00, 'Yerno paga lo suyo y 4 meses de su suegra María');

        INSERT INTO core.Detalles_del_Pago (id_pago, nro_socio, periodo_pago, monto, comentario) VALUES
            (1, 1001, '2026-05-01', 12000.00, 'Imputación cuota propia Mayo 2026'),
            (1, 1002, '2025-08-01', 8000.00, 'Apilado suegra - Mes 1/4 pendiente'),
            (1, 1002, '2025-09-01', 8000.00, 'Apilado suegra - Mes 2/4 pendiente'),
            (1, 1002, '2025-10-01', 8000.00, 'Apilado suegra - Mes 3/4 pendiente'),
            (1, 1002, '2025-11-01', 8000.00, 'Apilado suegra - Mes 4/4 pendiente');

    -- CASO 2: Mariano López le paga $12.000 en efectivo al Profesor (Origen 2)
        INSERT INTO core.Pagos 
        (id, fecha_hora_pago, id_persona_pagadora, medio_pago, origen_carga, monto_pagado_real, comentario)
        VALUES 
        (2, '2026-05-15 20:00:00', 6, 1, 2, 12000.00, 'Pago entregado al profesor en el entrenamiento');


        INSERT INTO core.Detalles_del_Pago (id_pago, nro_socio, periodo_pago, monto, comentario)
        VALUES (2, 1006, '2026-05-01', 12000.00, 'Cuota Mayo asignada por el profesor');

    -- CASO 3: Esteban Quito le paga $24.000 por Transferencia al Cobrador (Origen 1)
        -- Cubre dos periodos que tenía atrasados (Marzo y Abril 2026)
        INSERT INTO core.Pagos 
        (id, fecha_hora_pago, id_persona_pagadora, medio_pago, origen_carga, monto_pagado_real, comentario)
        VALUES 
        (3, '2026-05-18 11:15:00', 8, 4, 1, 24000.00, 'Cobrador rindió transferencia del socio');

        INSERT INTO core.Detalles_del_Pago (id_pago, nro_socio, periodo_pago, monto, comentario) VALUES
            (3, 1008, '2026-03-01', 12000.00, 'Marzo 2026 atrasado'),
            (3, 1008, '2026-04-01', 12000.00, 'Abril 2026 atrasado');
COMMIT;
