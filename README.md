# Proyecto Achiras

Este es el repositorio central de una solucion AMS (Association Management Software), una solución integral diseñada para la gestión de socios, cobros, actividades culturales, entre otras.

El sistema utiliza una arquitectura robusta que incluye:
* **Base de Datos:** Centralizada para la persistencia de datos de socios y finanzas.
* **Frontend:** Plataforma interactiva para administración y usuarios.
* **Backend:** Arquitectura de microservicios especializada.
* **Infraestructura:** Todo el ecosistema está contenedorizado bajo Docker para un despliegue rápido y consistente.

> [!NOTE]
> Esta plataforma está siendo utilizada activamente por la ***Casa Cultural UVAyJ***.
> * **Institución:** [Instagram UVAyJ](https://www.instagram.com/casacultural.uvayj/)
> * **Plataforma en vivo:** [Enlace de Acceso](https://bok-unenraptured-bridgett.ngrok-free.dev/)

> [!WARNING]
> El sistema se encuentra en proceso de migración desde ejecución local hacia infraestructura en la nube.
> Actualmente se utiliza Render para el despliegue del frontend y backend, y Supabase como servicio de base de datos.
>
> Puede revisar los avances en:
> * **Backend:** [API Rest](https://casacultural-backend.onrender.com/docs)
> * **Frontend:** [Punto de Entrada](https://casacultural-uvayj.onrender.com/)
---

### 📦 Módulos del Sistema

* **Generador de Comprobantes:** [Ver documentación técnica aquí](./microservicios/generador-comprobantes/README.md)
