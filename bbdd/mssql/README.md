
# Convenciones de Código 
Este documento establece las reglas, estándares de nomenclatura y patrones arquitectónicos para el diseño y desarrollo de la base de datos del sistema.

## 1. Convenciones de Nomenclatura
###  Objetos de Base de Datos
| Objeto | Convención de Case | Reglas Especificas | Ejemplo / Estructura |
| :--- | :--- | :--- | :--- |
| **Tablas** | `PascalCase + snake_case` | Siempre **Plural** (si tienen más de un registro) | `SistemaVentas.core.Detalle_de_Pagos` |
| **Columnas** | `snake_case` | Siempre **Singular** | `id_orden_compra` |
| **Schema** | `lowercase` |  Siempre **Singular** y una sola frase | `core` |
###  Prefijos de Objetos Programables
*   **`vw_`** : Vistas
*   **`fn_`** : Funciones escalares
*   **`ftv_`** : Funciones de tabla (Inline/Multi-statement)
*   **`src_`** : Scripts envueltos en Stored Procedures (SP)
####  Stored Procedures (`sp__snake_case`)
Se utiliza el doble guion bajo (`__`) para separar la acción del objeto o contexto.
*   `sp_Enviar__email_bienvenida`
*   `sp_CrearActualizar__orden_de_compra`
*   `sp_Eliminar1__Productos` *(Eliminación por 1 ID único)*
*   `sp_EliminarN__Productos` *(Eliminación de múltiples registros por IDs o condición)*
*   `sp_Eliminar__Productos` *(Eliminación dinámica / purga condicional)*
###  Restricciones y Claves (Constraints & Indexes)
*   **`pk_`** (Primary Key): `pk_cliente`, `pk_cliente_y_orden_compra`
*   **`uk_`** (Unique Key): *[Estructura sugerida: uk_tabla_columna]*
*   **`fk_`** (Foreign Key): *[Estructura sugerida: fk_tablaOrigen__tablaDestino]*
*   **`chk_`** (Check Constraint): *[Estructura sugerida: chk_tabla_columna]*
*   **`def_`** (Default Constraint): *[Estructura sugerida: def_tabla_columna]*
*   **`ix_`** (Non-Clustered Index): *[Estructura sugerida: ix_tabla_columna]*
*   **`ux_`** (Unique Index): *[Estructura sugerida: ux_tabla_columna]*
*   **`trg_`** (Trigger): `trg_Detalle_Pago__audit_insert`


## 2. Valores Centinela
Para evitar el uso excesivo de valores `NULL` en columnas críticas que requieren datos, se adoptan las siguientes reglas de negocio:
###  En Personas
*   `Documento INT NOT NULL` $\rightarrow$ Valor centinela: `0`
*   `nro_socio INT NOT NULL` $\rightarrow$ Valor centinela: `0`
*   `domicilio NVARCHAR(35) NOT NULL` $\rightarrow$ Valor centinela: `''` (String vacío)
*   `Celular CHAR(12) NOT NULL` $\rightarrow$ Valor centinela: `''` (String vacío)

###  En Socios
*   `Fecha_alta DATE NOT NULL` $\rightarrow$ Valor centinela: `0` (Equivalente a `'1900-01-01'`)

###  En Pagos
*   Un valor de **`0`** significa que el pago fue **Exihimido**.


## 3. Manejo de Errores y Transacciones
Para garantizar la consistencia de los datos, todo procedimiento almacenado (SP) que realice operaciones de escritura (`INSERT`, `UPDATE`, `DELETE`) debe implementar obligatoriamente la estructura de control `TRY...CATCH` junto con el manejo de transacciones explícitas.
```sql
CREATE OR ALTER PROCEDURE core.sp_Accion__Objeto(@id_registro INT) AS
	BEGIN
	    SET NOCOUNT ON;

	    BEGIN TRY
	        BEGIN TRANSACTION;
	        -- Logica de negocio      
	        COMMIT TRANSACTION;
	    END TRY
	    BEGIN CATCH
	        -- Si ocurrio un error y hay una transacción abierta, se revierte
	        IF @@TRANCOUNT > 0
	            ROLLBACK TRANSACTION;

	        -- Re-lanzamos el error original para que sea capturado por la aplicación
	        THROW; 
	    END CATCH
	END
GO
```
### Reglas Técnicas Obligatorias:
-   **`SET NOCOUNT ON;`**: Debe ir al inicio de todo SP para reducir el tráfico de red y evitar falsos positivos en algunos ORMs.
-   **`@@TRANCOUNT`**: La validación `IF @@TRANCOUNT > 0` es indispensable. Asegura que el `ROLLBACK` ocurra únicamente si la transacción llegó a abrirse, evitando errores en cascada dentro del bloque `CATCH`.
-   **`THROW;`**: Se prefiere el uso de `THROW` sobre `RAISERROR` por estándar de rendimiento y legibilidad en versiones modernas de SQL Server.


## 4. Ejemplo de Patrón de Implementación
```sql
CREATE OR ALTER PROCEDURE core.sp_Inscribir_Actividad (@id_persona INT, @id_actividad INT) AS
	 BEGIN
	    -- Cobramos la deuda técnica de forma global
	    -- (¡Importante!: Validación de integridad antes de proceder)
	    IF EXISTS (SELECT 1 FROM core.Personas 
	               WHERE id = @id_persona AND estado_integridad = 0)
	    BEGIN
	        DECLARE @msg NVARCHAR(250) = (
	            SELECT 'No se puede inscribir. Faltan datos críticos: ' + campos_faltantes 
	            FROM core.Personas 
	            WHERE id = @id_persona
	        );
	        THROW 50001, @msg, 1;
	    END

	    -- [Aquí inicia el flujo normal del SP]
	 END
GO
```
