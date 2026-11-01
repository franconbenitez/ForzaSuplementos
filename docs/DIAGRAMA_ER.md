# Diagrama entidad-relación auditado

Fecha: 2026-10-31. Basado en las 13 FK reales de QA; no se deducen relaciones por semejanza de nombres. qa.Fixtures es auxiliar de pruebas y no tiene FK. Ver INVENTARIO_BASE_DATOS.md para tipos completos y restricciones.

```mermaid
erDiagram
    dbo_AuditoriaBackups {
        int idBackup PK "int required"
        int idUsuario FK "int required"
        datetime fecha "datetime required"
        varchar rutaArchivo "varchar(255) required"
    }
    dbo_Categorias {
        int idCategoria PK "int required"
        varchar nombreCategoria "varchar(50) required"
    }
    dbo_Clientes {
        int idCliente PK "int required"
        varchar dni "varchar(20) required"
        varchar nombre "varchar(50) required"
        varchar apellido "varchar(50) required"
        varchar telefono "varchar(30) nullable"
        varchar email "varchar(100) nullable"
        bit activo "bit required"
    }
    dbo_CredencialesUsuario {
        int idUsuario PK,FK "int required"
        varchar formato "varchar(256) required"
        datetime2 fechaCambio "datetime2 required"
    }
    dbo_DetalleVentas {
        int idDetalle PK "int required"
        int idVenta FK "int required"
        int idProducto FK "int required"
        int cantidad "int required"
        decimal precioUnitario "decimal(10,2) required"
        decimal subtotal "decimal(10,2) required"
    }
    dbo_Marcas {
        int idMarca PK "int required"
        nvarchar nombre "nvarchar(100) required"
        bit activo "bit required"
    }
    dbo_PagosVenta {
        int idVenta PK,FK "int required"
        varchar medioPago "varchar(20) required"
        decimal importe "decimal(10,2) required"
    }
    dbo_Perfiles {
        int idPerfil PK "int required"
        varchar nombrePerfil "varchar(50) required"
        varchar descripcion "varchar(150) nullable"
        bit activo "bit required"
    }
    dbo_Productos {
        int idProducto PK "int required"
        int idCategoria FK "int required"
        varchar nombre "varchar(100) required"
        varchar descripcion "varchar(255) nullable"
        decimal precio "decimal(10,2) required"
        int stock "int required"
        bit activo "bit required"
        int idMarca FK "int nullable"
    }
    dbo_Proveedores {
        int idProveedor PK "int required"
        nvarchar nombre "nvarchar(100) required"
        nvarchar razonSocial "nvarchar(150) required"
        varchar cuit "varchar(11) nullable"
        bit activo "bit required"
    }
    dbo_SeguridadEstado {
        int id PK "int required"
        bit activa "bit required"
    }
    dbo_SesionesCaja {
        int idSesion PK "int required"
        int idUsuarioApertura FK "int required"
        int idUsuarioCierre FK "int nullable"
        datetime fechaApertura "datetime required"
        datetime fechaCierre "datetime nullable"
        decimal montoInicial "decimal(10,2) required"
        decimal montoFinalEsperado "decimal(10,2) nullable"
        decimal montoFinalReal "decimal(10,2) nullable"
        decimal diferencia "decimal(10,2) nullable"
        varchar estado "varchar(20) required"
    }
    dbo_Usuarios {
        int idUsuario PK "int required"
        int idPerfil FK "int required"
        varchar nombre "varchar(50) required"
        varchar apellido "varchar(50) required"
        varchar usuario "varchar(50) required"
        varchar contrasena "varchar(100) required"
        varchar email "varchar(100) required"
        varchar dni "varchar(20) required"
        varchar telefono "varchar(30) required"
        date fechaNacimiento "date required"
        char sexo "char(1) required"
        bit activo "bit required"
        datetime fechaAlta "datetime required"
        varchar calle "varchar(100) required"
        varchar altura "varchar(20) required"
    }
    dbo_Ventas {
        int idVenta PK "int required"
        int idCliente FK "int required"
        int idUsuario FK "int required"
        datetime fecha "datetime required"
        decimal total "decimal(10,2) required"
        int idSesion FK "int nullable"
    }
    qa_Fixtures {
        int vendedor "int required"
        int otroVendedor "int required"
        int administrador "int required"
        int gerente "int required"
        int inactivo "int required"
        int cliente "int required"
        int categoria "int required"
        int productoHistorico "int required"
        int ventaHistorica "int required"
    }
    dbo_Usuarios ||--o{ dbo_AuditoriaBackups : FK__Auditoria__idUsu__1DB06A4F
    dbo_Productos ||--o{ dbo_DetalleVentas : FK__DetalleVe__idPro__76969D2E
    dbo_Ventas ||--o{ dbo_DetalleVentas : FK__DetalleVe__idVen__75A278F5
    dbo_Categorias ||--o{ dbo_Productos : FK__Productos__idCat__619B8048
    dbo_Usuarios ||--o{ dbo_SesionesCaja : FK__SesionesC__idUsu__17F790F9
    dbo_Usuarios o|--o{ dbo_SesionesCaja : FK__SesionesC__idUsu__18EBB532
    dbo_Clientes ||--o{ dbo_Ventas : FK__Ventas__idClient__70DDC3D8
    dbo_SesionesCaja o|--o{ dbo_Ventas : FK__Ventas__idSesion__19DFD96B
    dbo_Usuarios ||--o{ dbo_Ventas : FK__Ventas__idUsuari__71D1E811
    dbo_Usuarios ||--o| dbo_CredencialesUsuario : FK_Credenciales_Usuario
    dbo_Ventas ||--o| dbo_PagosVenta : FK_PagosVenta_Ventas
    dbo_Marcas o|--o{ dbo_Productos : FK_Productos_Marca
    dbo_Perfiles ||--o{ dbo_Usuarios : FK_Usuarios_Perfiles
```

La opcionalidad se obtiene de NULL en la FK; la cardinalidad uno a uno solo se usa cuando las columnas FK tienen unicidad real. Las dos relaciones Usuario/SesionCaja (apertura/cierre) se conservan por separado. No se dibuja qa.Fixtures como FK comercial.
