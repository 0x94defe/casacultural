# Proyecto Achiras

Este es el repositorio central del ecosistema **Achiras**, una solución integral diseñada para la gestión de socios, cobros y actividades culturales.

El sistema utiliza una arquitectura robusta que incluye:
* **Base de Datos:** Centralizada para la persistencia de datos de socios y finanzas.
* **Frontend:** Plataforma interactiva para administración y usuarios.
* **Backend:** Arquitectura de microservicios especializada.
* **Infraestructura:** Todo el ecosistema está contenedorizado bajo Docker para un despliegue rápido y consistente.

> [!NOTE]
> **Estado en Producción**
> Esta plataforma está siendo utilizada activamente por la **Casa Cultural UVAyJ**.
> * **Institución:** [Instagram UVAyJ](https://www.instagram.com/casacultural.uvayj/)
> * **Plataforma en vivo:** [Enlace de Acceso](https://bok-unenraptured-bridgett.ngrok-free.dev/)

> [!WARNING]
> **Información de Despliegue e Infraestructura**
> Dado que el proyecto se encuentra en **integración continua**, actualmente no se dispone de un dominio propio. El sistema se está migrando para utilizar **Render** y **Supabase** bajo un subdominio temporal.

---

### 📦 Módulos del Sistema

* **Generador de Comprobantes:** [Ver documentación técnica aquí](./microservicios/generador-comprobantes/README.md)