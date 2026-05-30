CREATE OR ALTER PROCEDURE internal.sp_Test_Importar__Vinculos AS
	BEGIN
		EXEC internal.sp_Test_Importar__Personas;
		--------------------------------------------------------------------
		DECLARE @json NVARCHAR(MAX) = 
			'[
			  {
			    "grupo_interno": 1,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 255 },
			      { "tipo": "socio", "id": 256 },
			      { "tipo": "socio", "id": 1921 },
			      { "tipo": "socio", "id": 1922 }
			    ]
			  },
			  {
			    "grupo_interno": 2,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 435 },
			      { "tipo": "socio", "id": 505 },
			      { "tipo": "socio", "id": 1455 }
			    ]
			  },
			  {
			    "grupo_interno": 3,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 436 },
			      { "tipo": "socio", "id": 437 }
			    ]
			  },
			  {
			    "grupo_interno": 4,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 549 },
			      { "tipo": "socio", "id": 550 }
			    ]
			  },
			  {
			    "grupo_interno": 5,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1132 },
			      { "tipo": "socio", "id": 1796 },
			      { "tipo": "socio", "id": 1797 }
			    ]
			  },
			  {
			    "grupo_interno": 6,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1160 },
			      { "tipo": "socio", "id": 1748 }
			    ]
			  },
			  {
			    "grupo_interno": 7,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1223 },
			      { "tipo": "socio", "id": 1840 },
			      { "tipo": "socio", "id": 1841 }
			    ]
			  },
			  {
			    "grupo_interno": 8,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1477 },
			      { "tipo": "socio", "id": 1478 }
			    ]
			  },
			  {
			    "grupo_interno": 9,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1501 },
			      { "tipo": "socio", "id": 1784 }
			    ]
			  },
			  {
			    "grupo_interno": 10,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1694 },
			      { "tipo": "socio", "id": 1939 }
			    ]
			  },
			  {
			    "grupo_interno": 11,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1702 },
			      { "tipo": "socio", "id": 1834 }
			    ]
			  },
			  {
			    "grupo_interno": 12,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1782 },
			      { "tipo": "socio", "id": 1805 }
			    ]
			  },
			  {
			    "grupo_interno": 13,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1936 },
			      { "tipo": "socio", "id": 1937 }
			    ]
			  },
			  {
			    "grupo_interno": 14,
			    "esFamilia": true,
			    "integrantes": [
			      { "tipo": "socio", "id": 1943 },
			      { "tipo": "socio", "id": 1940 }
			    ]
			  }
			]';
		EXEC core.sp_Importar__Vinculos @json;
	END;
GO
PRINT '[INFO] sp_Test_Importar__Vinculos creada';
GO
