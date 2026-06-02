# Usamos una imagen liviana y oficial de Python
FROM python:3.11-slim

# Evita que Python escriba archivos .pyc en el disco y asegura que los logs salgan de inmediato
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Instalamos dependencias del sistema necesarias para compilar herramientas de Postgres
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiamos e instalamos los requerimientos
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiamos el resto del código del backend
COPY . .

# Exponemos el puerto estándar
EXPOSE 8000

# Comando para arrancar FastAPI en producción usando uvicorn nativo
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]