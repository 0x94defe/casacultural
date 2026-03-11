from flask import Flask, request, send_file, jsonify
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import cm
from reportlab.lib.utils import ImageReader
from dataclasses import dataclass
from io import BytesIO
from datetime import datetime
import pytz
import os
import psycopg2
import pyodbc

app = Flask(__name__)


@dataclass(frozen=True)
class Params:
    name: str
    server: str
    database: str
    user: str
    password: str

DB_CONFIG = Params(
    name= os.getenv('DB_NAME'),
    server= os.getenv('DB_SERVER'),
    database= os.getenv('DB_DATABASE'),
    user= os.getenv('DB_USER'),
    password= os.getenv('DB_PASSWORD')
)
# Validar que todas las variables esten presentes
for attr in DB_CONFIG.__dataclass_fields__:
    if not getattr(DB_CONFIG, attr):
        raise EnvironmentError(f"Variable de entorno para {attr} no definida")

@dataclass(frozen=True)
class Datos:
    Id: int
    Periodo: str
    Persona: str
    Socio: int
    Monto: float
    Fecha: str
    Medio: str
    DNI: int
    
@dataclass(frozen=True)
class Metadatos:
    Nombre: str
    RRSS: str
    CUIT: str
    Telefono: str
    Direccion: str

# ================== MODULOS ==================
def generar_pdf_comprobante(_datos: Datos, _metadatos: Metadatos, _logo_bytes: bytes = None):
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4
    
    # ================== TIPOGRAFÍA ==================
    FONT = "Helvetica"
    FONT_BOLD = "Helvetica-Bold"

    SIZE_SMALL = 8
    SIZE_NORMAL = 11
    SIZE_BIG = 13
    SIZE_TITLE = 18

    # ================== LAYOUT ==================
    MARGIN_X = 1.5 * cm
    MARGIN_Y = 1 * cm

    BOX_WIDTH = width - 2 * MARGIN_X
    BOX_HEIGHT = 10 * cm

    INTERLINE = 0.3 * cm
    ROW_HEIGHT = 0.6 * cm

    LABEL_OFFSET = 0
    VALUE_OFFSET = 3 * cm

    LOGO_SIZE = 4 * cm
    LOGO_MARGIN = 1 * cm

     # ================== CALCULADOS ==================
    BOX_TOP = height - MARGIN_Y
    BOX_BOTTOM = BOX_TOP - BOX_HEIGHT

    LEFT = MARGIN_X + 1 * cm
    CENTER = width / 2
    RIGHT = MARGIN_X + BOX_WIDTH - 1 * cm

    LABEL_X = LEFT + LABEL_OFFSET
    VALUE_X = LEFT + VALUE_OFFSET
    LOGO_X = RIGHT - LOGO_MARGIN/2 - LOGO_SIZE
    LOGO_Y = BOX_BOTTOM + 1.5*LOGO_MARGIN

    cursor = BOX_TOP - 2 * ROW_HEIGHT

    # ================== FUNCIONES AUXILIARES ==================
    def campo(label, value, size=SIZE_NORMAL):
        nonlocal cursor
        pdf.setFont(FONT_BOLD, size)
        pdf.drawString(LABEL_X, cursor, label)
        pdf.setFont(FONT, size)
        pdf.drawString(VALUE_X, cursor, value)
        cursor -= ROW_HEIGHT
    def titulo(label, font, size):
        nonlocal cursor
        pdf.setFont(font, size)
        pdf.drawCentredString(CENTER, cursor, label)
        cursor -= ROW_HEIGHT

    # ================== DISEÑO DEL COMPROBANTE ==================
    # Borde exterior
    pdf.setLineWidth(2)
    pdf.rect(MARGIN_X, BOX_BOTTOM, BOX_WIDTH, BOX_HEIGHT)

    # Header
    titulo("COMPROBANTE DE PAGO", FONT_BOLD, SIZE_TITLE)
    titulo(_metadatos.Nombre, FONT, SIZE_BIG)
    cursor -= INTERLINE
    titulo(f"{_metadatos.RRSS}     Cuit: {_metadatos.CUIT}", FONT, SIZE_NORMAL)
    titulo(f"Direccion: {_metadatos.Direccion}     Telefono: {_metadatos.Telefono}", FONT, SIZE_NORMAL)

    # Línea separadora
    pdf.setLineWidth(1)
    pdf.line(LEFT, cursor, RIGHT, cursor)
    cursor -= 2*INTERLINE

    # Datos del pago
    campo("Nro Socio:", str(_datos.Socio))
    campo("Persona:", _datos.Persona)
    campo("Documento:", f"{_datos.DNI:,}".replace(",", "."))
    cursor -= INTERLINE
    campo("Periodo Pago:", _datos.Periodo)
    campo("Fecha Pago:", _datos.Fecha)
    campo("Medio Pago:", _datos.Medio)
    cursor -= 2*INTERLINE
    campo("Monto:", f"$ {_datos.Monto:,.2f}", SIZE_BIG)

    # Logo
    if logo_bytes:
        try:
            logo_image = ImageReader(BytesIO(logo_bytes))
            pdf.drawImage(logo_image,
                          LOGO_X,
                          LOGO_Y,
                          width=LOGO_SIZE,
                          height=LOGO_SIZE,
                          preserveAspectRatio=True,
                          mask='auto')
        except Exception as e:
            print(f"No se pudo cargar el logo desde BDD: {e}")
    else:
        print("No se encontró logo en la base de datos para la organización.")
            
    # Firma
    #cursor -= 1.5*cm
    #pdf.setLineWidth(0.5)
    #pdf.line(12*cm, cursor, width - 3.5*cm, cursor)
    #pdf.setFont(FONT, LETTER_NORMAL)
    #pdf.drawCentredString((12*cm + width - 3.5*cm)/2, cursor - 0.4*cm, "Firma")

    # Footer
    tz = pytz.timezone("America/Argentina/Buenos_Aires")
    ahora = datetime.now(tz)
    titulo(f"ID Comprobante de pago: {_datos.Id}  -  Estampa de creacion: {ahora.strftime('%d/%m/%Y %H:%M')}", FONT, SIZE_SMALL)


    pdf.save()
    buffer.seek(0)
    return buffer
def conectar_bd():
    """
    Conecta a la base de datos segun DB_CONFIG.name:
    - 'MSSQL' usa pyodbc
    - 'POSTGRES' usa psycopg2
    """
    if DB_CONFIG.name.upper() == 'MSSQL':
        conn_str = (
            "DRIVER={ODBC Driver 17 for SQL Server};"
            f"SERVER={DB_CONFIG.server};"
            f"DATABASE={DB_CONFIG.database};"
            f"UID={DB_CONFIG.user};"
            f"PWD={DB_CONFIG.password};"
            "TrustServerCertificate=yes;"
        )
        return pyodbc.connect(conn_str)
    
    elif DB_CONFIG.name.upper() == 'POSTGRES':
        return psycopg2.connect(
            host=DB_CONFIG.server,
            database=DB_CONFIG.database,
            user=DB_CONFIG.user,
            password=DB_CONFIG.password
        )
    else:
        raise ValueError(f"DB_NAME inválido: {DB_CONFIG.name}. Debe ser 'MSSQL' o 'POSTGRES'.")

# ================== RUTAS ==================
@app.route('/generar-comprobante/<int:nro_socio>/<periodo_pago>', methods=['GET'])
def generar_comprobante_id(nro_socio, periodo_pago):
    conn = None #para el finally
    try:
        fecha_periodo = datetime.strptime(periodo_pago, "%Y-%m-%d").date()
        conn = conectar_bd()
        cursor = conn.cursor()
        
        # Obtener datos de la origanizacion
        query_metadata = """
            SELECT 
                nombre,
                direccion,
                telefono,
                razon_social,
                cuit,
                logo                
            FROM params.Organizacion;
        """
        cursor.execute(query_metadata)
        row_m = cursor.fetchone()
        
        if not row_m:
            return jsonify({'error': 'Configuración de organización no encontrada'}), 404

        res_metadata = Metadatos(
            Nombre=row_m.nombre,
            RRSS=row_m.razon_social,
            CUIT=row_m.cuit,
            Telefono=row_m.telefono,
            Direccion=row_m.direccion
        )
        logo_bytes = row_m.logo  # Esto es un objeto bytes si hay imagen
        
        # Obtener datos del pago
        if DB_CONFIG.name.upper() == 'MSSQL':
            query_data = """
                SELECT 
                    s.nro_socio AS socio,
                    FORMAT(dp.periodo_pago, 'MMMM yyyy', 'es-ES') AS periodo_pagado,
                    p.nombre_completo AS persona,
                    p.dni AS dni,
                    pg.id AS id_pago,
                    dp.monto AS monto,
                    FORMAT(pg.fecha_hora_pago, 'dd/MM/yyyy') AS fecha_pago,
                    tp.descripcion AS medio 
                FROM core.Socios s
                JOIN core.Personas p ON p.id = s.id_persona
                JOIN core.Detalles_del_Pago dp ON dp.nro_socio = s.nro_socio
                JOIN core.Pagos pg ON pg.id = dp.id_pago
                JOIN lookups.Tipos_de_Pago tp ON tp.id = pg.medio_pago
                WHERE s.nro_socio = ? AND dp.periodo_pago = ?;
            """

        elif DB_CONFIG.name.upper() == 'POSTGRES':
            query_data = """
                SELECT 
                    s.nro_socio AS socio,
                    TO_CHAR(dp.periodo_pago, 'TMMonth YYYY') AS periodo_pagado,
                    p.nombre_completo AS persona,
                    p.dni AS dni,
                    pg.id AS id_pago,
                    dp.monto AS monto,
                    TO_CHAR(pg.fecha_hora_pago, 'DD/MM/YYYY') AS fecha_pago,
                    tp.descripcion AS medio 
                FROM core.Socios s
                JOIN core.Personas p ON p.id = s.id_persona
                JOIN core.Detalles_del_Pago dp ON dp.nro_socio = s.nro_socio
                JOIN core.Pagos pg ON pg.id = dp.id_pago
                JOIN lookups.Tipos_de_Pago tp ON tp.id = pg.medio_pago
                WHERE s.nro_socio = %s AND dp.periodo_pago = %s;
            """

        else:
            raise ValueError(f"DB_NAME inválido: {DB_CONFIG.name}. Debe ser 'MSSQL' o 'POSTGRES'.")
        
        cursor.execute(query_data, nro_socio, fecha_periodo)
        row_p = cursor.fetchone()
        
        if not row_p:
            return jsonify({'error': 'Pago no encontrado para el socio y periodo indicados'}), 404
        
        # Mapeo SEGURO después de verificar que existe la fila
        res_data = Datos(
            Id=row_p.id_pago,
            # Reemplazamos espacios por guiones bajos para el nombre del archivo
            Periodo=row_p.periodo_pagado.capitalize().replace(' ', '_'),
            Persona=row_p.persona,
            Socio=row_p.socio,
            Monto=row_p.monto,
            Fecha=row_p.fecha_pago,
            Medio=row_p.medio,
            DNI=row_p.dni
        )
        
        # Generar PDF
        pdf_buffer = generar_pdf_comprobante(res_data, res_metadata, logo_bytes)
        
        return send_file(
            pdf_buffer,
            mimetype='application/pdf',
            as_attachment=True,
            download_name=f'Comprobante_{res_data.Periodo}_Socio_{res_data.Socio}.pdf'
        )
        
    except Exception as e:
        print(f"Error crítico: {str(e)}")
        return jsonify({'error': 'Error interno del servidor', 'detalle': str(e)}), 500
        
    finally:
        if conn:
            conn.close()

# ================== TEST ==================
@app.route('/test-pdf', methods=['GET'])
def test_generation():
    """PDF de prueba con datos hardcodeados"""
    try:
        Datos_fictisios = Datos(
            Id= 999,
            Periodo= 'Enero 2026',
            Persona= 'Juan Carlos Pérez García',
            Socio= 12345,
            Monto= 15750.50,
            Fecha= '23/01/2026',
            Medio= 'Virtual',
            DNI= 35123456
        )
        Metadatos_fictisios = Metadatos(
            Nombre= 'Casa Cultural LLLPM',
            RRSS= 'Ladio loreno lopium presto maas',
            CUIT= '30-99955511-5',
            Telefono= '11 6565-8877',
            Direccion= 'calle falsa 777, inexistente'
        )
        
        print("Generando PDF de prueba")
        return send_file(
            generar_pdf_comprobante(Datos_fictisios, Metadatos_fictisios),
            mimetype='application/pdf',
            as_attachment=True,
            download_name='Comprobante_PRUEBA.pdf'
        )
        
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/test-conn', methods=['GET'])
def test_connection():
    """Verificar conexión a SQL Server"""
    try:
        conn = conectar_bd()
        conn.close()
        return jsonify({
            'status': 'OK', 
            'server': DB_CONFIG.server,
            'database': DB_CONFIG.database,
            'message': 'Conexión exitosa'
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'ERROR',
            'error': str(e)
        }), 500


if __name__ == '__main__':
    print("=" * 70)
    print("Servidor de comprobantes iniciado")
    print(f"Proveedor: {DB_CONFIG.name}")
    print(f"Servidor: {DB_CONFIG.server}")
    print(f"Catalogo: {DB_CONFIG.database}")
    print("Test conexion: http://localhost:5000/test-conn")
    print("Test generacion: http://localhost:5000/test-pdf")
    print("Generar PDF: http://localhost:5000/generar-comprobante/<nro_socio>/<periodo_pagado>")
    print("=" * 70)
    app.run(host='0.0.0.0', port=5000, debug=True)