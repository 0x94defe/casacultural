# 🖨️ Microservicio: Generador de Comprobantes (PDF)
Este microservicio forma parte del ecosistema **Achiras**. Su función principal es interceptar las solicitudes de cobro, consultar la base de datos correspondiente y estructurar un comprobante de pago en formato PDF de forma dinámica e interna (en memoria).

### 🚀 Características Principales
* **Generación On-the-Fly:** Los archivos PDF se renderizan directamente en la memoria RAM (`BytesIO`) y se transmiten al cliente sin necesidad de almacenamiento temporal en disco.
* **Compatibilidad Multi-Motor (BD):** Soporte nativo para **Microsoft SQL Server** (`pyodbc`) y **PostgreSQL** (`psycopg2`), configurable mediante variables de entorno.
* **Diseño Responsivo con ReportLab:** El documento utiliza coordenadas dinámicas, maneja tipografías estándar de alta fidelidad, parsea blobs de imágenes de forma segura para los logos institucionales y respeta los husos horarios locales (`America/Argentina/Buenos_Aires`).
* **Tipado Estricto:** Implementación de `@dataclass(frozen=True)` para asegurar la inmutabilidad y legibilidad de las estructuras de datos intervinientes.

### 🛠️ Tecnologías Utilizadas
* **Framework:** Flask 3.x (o compatible)
* **Motor Gráfico PDF:** ReportLab (Canvas, ImageReader)
* **Controladores BD:** `pyodbc` (MSSQL) y `psycopg2` (PostgreSQL)
* **Manejo del Tiempo:** `pytz` y `datetime`


### ⚙️ Variables de Entorno Requeridas
El sistema valida en el inicio que todas las variables estén presentes; de lo contrario, lanzará un error de entorno (`EnvironmentError`).

| Variable | Tipo / Valores válidos | Descripción |
| :--- | :--- | :--- |
| `DB_NAME` | `MSSQL` / `POSTGRES` | Selecciona el driver y la sintaxis de query a utilizar. |
| `DB_SERVER` | String | IP o Host DNS del servidor de base de datos. |
| `DB_DATABASE` | String | Nombre del catálogo o base de datos. |
| `DB_USER` | String | Usuario con permisos de lectura (`SELECT`). |
| `DB_PASSWORD`| String | Contraseña de acceso. |


## 🛣️ API Endpoints
### 1. Generar Comprobante Oficial
Genera y descarga el comprobante en PDF para un socio y período específicos.
* **URL:** `/generar-comprobante/<int:nro_socio>/<periodo_pago>`
* **Método:** `GET`
* **Parámetros:**
  * `nro_socio` *(int)*: Número de socio único.
  * `periodo_pago` *(string)*: Fecha en formato `YYYY-MM-DD` para ubicar el cobro exacto.
* **Respuesta exitosa (200):** Archivo binario con `mimetype='application/pdf'` adjunto bajo el formato de nombre `Comprobante_[Mes_Año]_Socio_[Nro].pdf`.

### 2. Verificar Conexión a Base de Datos (Healthcheck)
Valida la conectividad inmediata con el motor configurado.
* **URL:** `/test-conn`
* **Método:** `GET`
* **Respuesta exitosa (200 JSON):**
  ```json
  {
    "status": "OK",
    "server": "tu-servidor.database",
    "database": "tu_db",
    "message": "Conexión exitosa"
  }

### 3. Generar PDF de Prueba (Mock)

Permite verificar visualmente el diseño del comprobante (estructuras, márgenes y fuentes) sin necesidad de conectarse a la base de datos.

    URL: /test-pdf

    Método: GET

    Respuesta exitosa (200): Descarga directa de un PDF mockeado con datos ficticios (Comprobante_PRUEBA.pdf).

## 🏗️ Arquitectura y Flujo de Datos

```
[Cliente HTTP] ──(GET Request)──────────> [Flask Endpoint]
                                                 │
                                           (Valida Params)
                                                 │
                                                 ▼
                                         [Conectar BD]
                                 (Query params.Organizacion y core)
                                                 │
                                                 ▼
                                       [Mapeo a DataClasses]
                                   (Datos, Metadatos y Logo BLOB)
                                                 │
                                                 ▼
                                     [Motor ReportLab Canvas]
                                 (Renderizado a BytesIO en memoria)
                                                 │
                                                 ▼
[Cliente HTTP] <──(PDF Streaming)────── [send_file()]
```

## 🐳 Despliegue Local (Modo Desarrollo)
Instalá las dependencias necesarias:


```bash
pip install Flask reportlab pytz psycopg2-binary pyodbc
```

> **Nota:** Si utilizás la opción MSSQL, recordá tener instalado el driver oficial de Microsoft — [ODBC Driver 17 for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server) — en tu sistema operativo.

Exportá las variables de entorno y ejecutá:

```bash
python app.py
```

El microservicio se levantará por defecto en el puerto `5000` escuchando en `http://localhost:5000`.
