# Modelo proyectado — NO desplegado

El esquema QA real sigue en DIAGRAMA_ER.md: 11 tablas y 30 SP. Este diagrama representa únicamente las ampliaciones 005–008 propuestas. No confundirlo con un inventario de objetos existentes. Se proponen siete tablas adicionales, no se crearon en SQL Server.

```mermaid
erDiagram
    Perfiles ||--o{ Usuarios : perfil
    Usuarios ||--o| CredencialesUsuario : credencial_versionada
    Proveedores ||--o{ Compras : abastece
    Usuarios ||--o{ Compras : registra
    Compras ||--|{ DetalleCompras : contiene
    Productos ||--o{ DetalleCompras : comprado
    Marcas o|--o{ Productos : marca_opcional
    Productos ||--o{ MovimientosStock : trazabilidad
    Usuarios ||--o{ MovimientosStock : responsable
    Compras o|--o{ MovimientosStock : entrada_opcional
    Ventas o|--o{ MovimientosStock : salida_opcional
    SeguridadEstado {
        int id PK "singleton 1"
        bit activa "corte de autenticacion"
    }
    CredencialesUsuario {
        int idUsuario PK,FK
        varchar formato "PBKDF2 versionado"
        datetime2 fechaCambio
    }
    Proveedores {
        int idProveedor PK
        nvarchar nombre
        nvarchar razonSocial
        varchar cuit UK "opcional; indice filtrado"
        bit activo
    }
    Marcas {
        int idMarca PK
        nvarchar nombre UK
        bit activo
    }
    Compras {
        int idCompra PK
        int idProveedor FK
        int idUsuario FK
        datetime2 fecha
        decimal total
        uniqueidentifier operacion UK
        varbinary huella
    }
    DetalleCompras {
        int idDetalleCompra PK
        int idCompra FK "unico junto al producto"
        int idProducto FK
        int cantidad
        decimal costoUnitario
        decimal subtotal
    }
    MovimientosStock {
        int idMovimiento PK
        int idProducto FK
        int idUsuario FK
        datetime2 fecha
        varchar tipo
        int cantidad "signada"
        int anterior
        int posterior
        nvarchar motivo
        int idCompra FK "nullable"
        int idVenta FK "nullable"
        uniqueidentifier operacion "ajuste idempotente"
    }
```

Compras con al menos un detalle es una regla del SP, no una cardinalidad mínima garantizada por una FK. No hay FK comercial desde SeguridadEstado: es configuración singleton. Nuevas columnas propuestas: Perfiles.activo, Productos.idMarca nullable y Productos.stockMinimo no negativo.

No se crea stock inicial retroactivo ni movimientos de ventas históricas. Las compras conservan costo por línea; Productos.precio sigue siendo el precio de venta. Los índices se justifican por unicidad de CUIT/marca/operación, integridad de líneas y movimientos por origen, FK de marca y filtros por fecha/producto/proveedor. No se añadieron tablas solo para incrementar su cantidad.
