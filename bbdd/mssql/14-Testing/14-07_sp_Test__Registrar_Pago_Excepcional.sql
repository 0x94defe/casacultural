BEGIN TRANSACTION;
    DECLARE @json NVARCHAR(MAX) = N'{
        "apellido_nombre_origen": "Miguel, Luis",
        "fecha_hora_pago": "2026-06-11T10:00:00",
        "medio_pago": 1,
        "origen_carga": 1,
        "comentario": "Pago excepcional de cuotas pendientes",
        "detalles_pago": [
            {
                "nro_socio": 255,
                "periodo": "2026-06-01",
                "monto": 5000.00,
                "comentario": "Cuota Mayo ATRASADA"
            },
            {
                "nro_socio": 256,
                "periodo": "2026-06-01",
                "monto": 5500.00,
                "comentario": "Cuota Junio ATRASADA"
            }
        ]
    }';

    EXEC core.sp_Registrar__Pago_Excepcional @json = @json;
    PRINT '[PASS] El procedimiento termino su ejecucion sin lanzar excepciones';

    SELECT TOP 1 id, fecha_hora_pago, id_persona_pagadora, monto_pagado_real, comentario 
    FROM core.Pagos ORDER BY id DESC;

    SELECT TOP 3 id_pago, nro_socio, periodo_pago, monto, comentario 
    FROM core.Detalles_del_Pago ORDER BY id_pago DESC;

    SELECT TOP 5 id, evento, entidad_afectada, id_afectada, detalle 
    FROM logs.Bitacora ORDER BY id DESC;
ROLLBACK TRANSACTION;
