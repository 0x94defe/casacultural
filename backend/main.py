import os
from datetime import date, datetime, timezone
from typing import List, Optional
from uuid import UUID
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, Query
from sqlmodel import Field, Session, SQLModel, create_engine, select, text

# 1. CARGA DE CONFIGURACIÓN Y CONEXIÓN
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

if not DATABASE_URL:
    raise ValueError("La variable DATABASE_URL no está configurada en el archivo .env")

# Optimizaciones para conexión continua hacia Supabase
engine = create_engine(DATABASE_URL, echo=False, pool_pre_ping=True)

app = FastAPI(
    title="Sistema de Gestión de la Casa Cultural",
    description="Backend en FastAPI y SQLModel conectado a Supabase",
    version="1.0.0"
    # Si estamos en producción (Render), ocultamos la documentación
    docs_url=None if ENVIRONMENT == "production" else "/docs",
    redoc_url=None if ENVIRONMENT == "production" else "/redoc"
)

def get_session():
    with Session(engine) as session:
        yield session

# ------------------------------------------------------------------------------
# 2. MODELOS DE SQLMODEL (Mapeo de Esquemas y Tablas)
# ------------------------------------------------------------------------------

# === ESQUEMA: LOOKUPS ===
class OrigenesCobro(SQLModel, table=True):
    __tablename__ = "origenes_de_cobro"
    __table_args__ = {"schema": "lookups"}
    id: Optional[int] = Field(default=None, primary_key=True)
    descripcion: str

class TiposPago(SQLModel, table=True):
    __tablename__ = "tipos_de_pago"
    __table_args__ = {"schema": "lookups"}
    id: Optional[int] = Field(default=None, primary_key=True)
    descripcion: str

class Nacionalidad(SQLModel, table=True):
    __tablename__ = "nacionalidad"
    __table_args__ = {"schema": "core"}  # Nota: En tu DDL indicaste que Nacionalidad y Ciudad están en core
    id: Optional[int] = Field(default=None, primary_key=True)
    descripcion: str

class Ciudad(SQLModel, table=True):
    __tablename__ = "ciudad"
    __table_args__ = {"schema": "core"}
    id: Optional[int] = Field(default=None, primary_key=True)
    descripcion: str


# === ESQUEMA: CORE ===
class PersonasBase(SQLModel):
    # Usamos 'alias' para mapear el nombre real de la columna en Postgres
    dni: Optional[int] = None
    nombre_fisico: Optional[str] = Field(default=None, max_length=48, alias="__nombre")
    apellido_fisico: Optional[str] = Field(default=None, max_length=48, alias="__apellido")
    celular_fisico: Optional[str] = Field(default=None, max_length=16, alias="__celular")
    domicilio_fisico: Optional[str] = Field(default=None, max_length=48, alias="__domicilio")
    email_fisico: Optional[str] = Field(default=None, max_length=64, alias="__email")
    fecha_nacimiento: Optional[date] = None
    ciudad: Optional[int] = None
    telefono_fisico: Optional[str] = Field(default=None, max_length=16, alias="__telefono")
    observaciones_fisico: Optional[str] = Field(default=None, max_length=128, alias="__observaciones")
    nacionalidad: Optional[int] = None
    genero: Optional[str] = Field(default=None, max_length=1)

    # Configuración crucial para que Pydantic acepte los aliases al leer y escribir JSONs
    model_config = {
        "populate_by_name": True
    }

class Personas(PersonasBase, table=True):
    __tablename__ = "personas"
    __table_args__ = {"schema": "core"}
    
    id: Optional[int] = Field(default=None, primary_key=True)
    dni: Optional[int] = None
    
    # Usamos sa_column_kwargs para obligar a SQLAlchemy a usar el nombre real en Postgres
    nombre_fisico: Optional[str] = Field(default=None, max_length=48, sa_column_kwargs={"name": "__nombre"})
    apellido_fisico: Optional[str] = Field(default=None, max_length=48, sa_column_kwargs={"name": "__apellido"})
    celular_fisico: Optional[str] = Field(default=None, max_length=16, sa_column_kwargs={"name": "__celular"})
    domicilio_fisico: Optional[str] = Field(default=None, max_length=48, sa_column_kwargs={"name": "__domicilio"})
    email_fisico: Optional[str] = Field(default=None, max_length=64, sa_column_kwargs={"name": "__email"})
    
    fecha_nacimiento: Optional[date] = None
    ciudad: Optional[int] = None
    
    telefono_fisico: Optional[str] = Field(default=None, max_length=16, sa_column_kwargs={"name": "__telefono"})
    observaciones_fisico: Optional[str] = Field(default=None, max_length=128, sa_column_kwargs={"name": "__observaciones"})
    
    nacionalidad: Optional[int] = None
    genero: Optional[str] = Field(default=None, max_length=1)

    # Columnas generadas (STORED) en Postgres: se dejan para lectura
    nombre: Optional[str] = None
    apellido: Optional[str] = None
    nombre_completo: Optional[str] = None
    domicilio_completo: Optional[str] = None

class PersonasUpdate(SQLModel):
    # Campos permitidos para actualización (replicamos los nuevos nombres con sus alias)
    celular_fisico: Optional[str] = None
    domicilio_fisico: Optional[str] = None
    email_fisico: Optional[str] = None
    telefono_fisico: Optional[str] = None
    observaciones_fisico: Optional[str] = None

class PersonasUpdate(SQLModel):
    # Campos permitidos para actualización
    __celular: Optional[str] = None
    __domicilio: Optional[str] = None
    __email: Optional[str] = None
    __telefono: Optional[str] = None
    __observaciones: Optional[str] = None

class Socios(SQLModel, table=True):
    __tablename__ = "socios"
    __table_args__ = {"schema": "core"}
    id: Optional[int] = Field(default=None, primary_key=True)
    nro_socio: int
    id_persona: int
    fecha_alta: Optional[date] = None
    fecha_baja: Optional[date] = None
    necesita_cupon: bool = False
    desea_email_pago: bool = False
    pago_preferido: Optional[int] = None
    motivo_baja: Optional[str] = None

class SociosUpdate(SQLModel):
    necesita_cupon: Optional[bool] = None
    desea_email_pago: Optional[bool] = None
    pago_preferido: Optional[int] = None

class Cuotas(SQLModel, table=True):
    __tablename__ = "cuotas"
    __table_args__ = {"schema": "core"}
    periodo: date = Field(primary_key=True)
    valor: float

class Pagos(SQLModel, table=True):
    __tablename__ = "pagos"
    __table_args__ = {"schema": "core"}
    id: Optional[int] = Field(default=None, primary_key=True)
    fecha_hora_pago: datetime
    id_persona_pagadora: Optional[int] = None
    medio_pago: int
    origen_carga: int
    monto_pagado_real: float
    comentario: Optional[str] = None
    fecha_hora_registro: Optional[datetime] = Field(default_factory=datetime.utcnow)

class DetallesDelPago(SQLModel, table=True):
    __tablename__ = "detalles_del_pago"
    __table_args__ = {"schema": "core"}
    id: Optional[int] = Field(default=None, primary_key=True)
    id_pago: int
    nro_socio: int
    periodo_pago: date
    monto: float
    comentario: Optional[str] = None

class Actividades(SQLModel, table=True):
    __tablename__ = "actividades"
    __table_args__ = {"schema": "core"}
    id: Optional[int] = Field(default=None, primary_key=True)
    descripcion: str
    id_persona_a_cargo: int
    fecha_inicio: date
    fecha_fin: Optional[date] = None
    motivo_baja: Optional[str] = None

class Grupos(SQLModel, table=True):
    __tablename__ = "grupos"
    __table_args__ = {"schema": "core"}
    id: Optional[int] = Field(default=None, primary_key=True)
    descripcion: str
    esFamilia: bool = False


# ------------------------------------------------------------------------------
# 3. ENDPOINTS API REST
# ------------------------------------------------------------------------------

# === SISTEMA / HEALTHCHECK ===
@app.get("/healthz", status_code=200, tags=["Sistema"])
def health_check(session: Session = Depends(get_session)):
    try:
        session.exec(text("SELECT 1"))
        return {
            "status": "healthy",
            "database": "connected",
            "timestamp": datetime.now(timezone.utc)
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error de conexión con Supabase: {str(e)}"
        )

# === LOOKUPS (Solo Lectura) ===
@app.get("/lookups/origenes-cobro", response_model=List[OrigenesCobro], tags=["Lookups"])
def listar_origenes_cobro(session: Session = Depends(get_session)):
    return session.exec(select(OrigenesCobro)).all()

@app.get("/lookups/tipos-pago", response_model=List[TiposPago], tags=["Lookups"])
def listar_tipos_pago(session: Session = Depends(get_session)):
    return session.exec(select(TiposPago)).all()

@app.get("/core/nacionalidades", response_model=List[Nacionalidad], tags=["Lookups"])
def listar_nacionalidades(session: Session = Depends(get_session)):
    return session.exec(select(Nacionalidad)).all()

@app.get("/core/ciudades", response_model=List[Ciudad], tags=["Lookups"])
def listar_ciudades(session: Session = Depends(get_session)):
    return session.exec(select(Ciudad)).all()


# === ENTIDAD: PERSONAS (Append-Only / Actualización Parcial) ===
@app.post("/core/personas", response_model=Personas, status_code=201, tags=["Personas"])
def crear_persona(persona: Personas, session: Session = Depends(get_session)):
    session.add(persona)
    session.commit()
    session.refresh(persona)
    return persona

@app.get("/core/personas", response_model=List[Personas], tags=["Personas"])
def listar_personas(session: Session = Depends(get_session)):
    return session.exec(select(Personas)).all()

@app.get("/core/personas/{persona_id}", response_model=Personas, tags=["Personas"])
def obtener_persona(persona_id: int, session: Session = Depends(get_session)):
    persona = session.get(Personas, persona_id)
    if not persona:
        raise HTTPException(status_code=404, detail="Persona no encontrada")
    return persona

@app.patch("/core/personas/{persona_id}", response_model=Personas, tags=["Personas"])
def actualizar_persona(persona_id: int, persona_data: PersonasUpdate, session: Session = Depends(get_session)):
    db_persona = session.get(Personas, persona_id)
    if not db_persona:
        raise HTTPException(status_code=404, detail="Persona no encontrada")
    
    # Solo actualiza los campos permitidos que vengan informados
    update_data = persona_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_persona, key, value)
        
    session.add(db_persona)
    session.commit()
    session.refresh(db_persona)
    return db_persona


# === ENTIDAD: SOCIOS (Filtros de Activos / Actualización Parcial) ===
@app.post("/core/socios", response_model=Socios, status_code=201, tags=["Socios"])
def crear_socio(socio: Socios, session: Session = Depends(get_session)):
    session.add(socio)
    session.commit()
    session.refresh(socio)
    return socio

@app.get("/core/socios", response_model=List[Socios], tags=["Socios"])
def listar_socios(
    activos: Optional[bool] = Query(None, description="Filtrar por estado activo (true/false)"),
    session: Session = Depends(get_session)
):
    statement = select(Socios)
    if activos is True:
        statement = statement.where(Socios.fecha_baja == None)
    elif activos is False:
        statement = statement.where(Socios.fecha_baja != None)
        
    return session.exec(statement).all()

@app.get("/core/socios/{socio_id}", response_model=Socios, tags=["Socios"])
def obtener_socio(socio_id: int, session: Session = Depends(get_session)):
    socio = session.get(Socios, socio_id)
    if not socio:
        raise HTTPException(status_code=404, detail="Socio no encontrado")
    return socio

@app.patch("/core/socios/{socio_id}", response_model=Socios, tags=["Socios"])
def actualizar_socio(socio_id: int, socio_data: SociosUpdate, session: Session = Depends(get_session)):
    db_socio = session.get(Socios, socio_id)
    if not db_socio:
        raise HTTPException(status_code=404, detail="Socio no encontrado")
    
    update_data = socio_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_socio, key, value)
        
    session.add(db_socio)
    session.commit()
    session.refresh(db_socio)
    return db_socio

# Endpoint específico para dar de baja lógicamente a un Socio
@app.post("/core/socios/{socio_id}/baja", response_model=Socios, tags=["Socios"])
def dar_baja_socio(socio_id: int, motivo: str = Query(..., min_length=3), session: Session = Depends(get_session)):
    db_socio = session.get(Socios, socio_id)
    if not db_socio:
        raise HTTPException(status_code=404, detail="Socio no encontrado")
    if db_socio.fecha_baja is not None:
        raise HTTPException(status_code=400, detail="El socio ya se encuentra de baja")
        
    db_socio.fecha_baja = date.today()
    db_socio.motivo_baja = motivo
    
    session.add(db_socio)
    session.commit()
    session.refresh(db_socio)
    return db_socio


# === ENTIDADES INMUTABLES / APPEND-ONLY (Cuotas, Pagos, Detalles, Actividades, Grupos) ===
@app.post("/core/cuotas", response_model=Cuotas, status_code=201, tags=["Inmutables / Operaciones"])
def registrar_cuota(cuota: Cuotas, session: Session = Depends(get_session)):
    if cuota.periodo.day != 1:
        raise HTTPException(status_code=400, detail="El periodo de la cuota debe ser obligatoriamente el dia 1 del mes")
    session.add(cuota)
    session.commit()
    session.refresh(cuota)
    return cuota

@app.post("/core/pagos", response_model=Pagos, status_code=201, tags=["Inmutables / Operaciones"])
def registrar_pago(pago: Pagos, session: Session = Depends(get_session)):
    pago.fecha_hora_registro = datetime.now(timezone.utc)
    session.add(pago)
    session.commit()
    session.refresh(pago)
    return pago

@app.post("/core/detalles-pago", response_model=DetallesDelPago, status_code=201, tags=["Inmutables / Operaciones"])
def registrar_detalle_pago(detalle: DetallesDelPago, session: Session = Depends(get_session)):
    if detalle.periodo_pago.day != 1:
        raise HTTPException(status_code=400, detail="El periodo_pago debe ser el dia 1 del mes")
    session.add(detalle)
    session.commit()
    session.refresh(detalle)
    return detalle

@app.post("/core/actividades", response_model=Actividades, status_code=201, tags=["Inmutables / Operaciones"])
def crear_actividad(actividad: Actividades, session: Session = Depends(get_session)):
    session.add(actividad)
    session.commit()
    session.refresh(actividad)
    return actividad

@app.post("/core/grupos", response_model=Grupos, status_code=201, tags=["Inmutables / Operaciones"])
def crear_grupo(grupo: Grupos, session: Session = Depends(get_session)):
    session.add(grupo)
    session.commit()
    session.refresh(grupo)
    return grupo


# Conector directo para ejecuciones locales
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)