Imports System.Text.RegularExpressions
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades

Public Class ProductoBLL
    Private ReadOnly _productoDAL As New ProductoDAL()

    Public Function ObtenerCategorias(actor As Usuario) As List(Of Categoria)
        Permisos.Exigir(actor, Permiso.Productos)
        Return _productoDAL.ListarCategorias()
    End Function

    Public Function ObtenerProductos(activo As Boolean, actor As Usuario) As List(Of Producto)
        If Permisos.Puede(actor, Permiso.Productos) Then
            ' El gerente consulta activos e inactivos para su ABM.
        Else
            Permisos.Exigir(actor, Permiso.CatalogoVenta)
            If Not activo Then Throw New ApplicationException("El catálogo de ventas solo permite productos activos.")
        End If
        Return _productoDAL.ListarProductosPorEstado(activo)
    End Function

    Public Sub GuardarProducto(p As Producto, actor As Usuario)
        Permisos.Exigir(actor, Permiso.Productos)
        ValidarDatosProducto(p)
        If p.IdProducto = 0 Then
            _productoDAL.Insertar(p)
        Else
            _productoDAL.Modificar(p)
        End If
    End Sub

    Public Sub DarDeBaja(idProducto As Integer, actor As Usuario)
        Permisos.Exigir(actor, Permiso.Productos)
        If idProducto <= 0 Then Throw New ApplicationException("Seleccioná un producto válido.")
        _productoDAL.CambiarEstado(idProducto, False)
    End Sub

    Public Sub Reactivar(idProducto As Integer, actor As Usuario)
        Permisos.Exigir(actor, Permiso.Productos)
        If idProducto <= 0 Then Throw New ApplicationException("Seleccioná un producto válido.")
        _productoDAL.CambiarEstado(idProducto, True)
    End Sub

    Private Sub ValidarDatosProducto(p As Producto)
        If String.IsNullOrWhiteSpace(p.Nombre) Then Throw New ApplicationException("El nombre del producto no puede estar vacío.")
        If p.IdCategoria <= 0 Then Throw New ApplicationException("Tenés que seleccionar una categoría.")
        If p.Precio <= 0 Then Throw New ApplicationException("El precio debe ser mayor a cero.")
        If p.Stock < 0 Then Throw New ApplicationException("El stock no puede ser negativo.")
    End Sub
End Class