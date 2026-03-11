FROM python:3.11-slim

# Evitar prompts durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalar dependencias base y librerías para PostgreSQL (libpq-dev)
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    gnupg \
    unixodbc-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Agregar la clave de Microsoft para SQL Server (Método Seguro)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/debian/11/prod bullseye main" > /etc/apt/sources.list.d/mssql-release.list

# 3. Instalar el driver de SQL Server
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17 && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configuración del trabajo y la instalación de dependencias de Python
WORKDIR /app

# Copiar archivo requirements.txt y ejecutar pip install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el resto del código de la aplicación
COPY . .

# Exponer el puerto de la aplicación (5000)
EXPOSE 5000

# Ejecutar la aplicación
CMD ["python", "app.py"]