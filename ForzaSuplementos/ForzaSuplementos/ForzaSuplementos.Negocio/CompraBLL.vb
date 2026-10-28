Option Strict On
Imports System.Data
Imports System.Linq
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades
Public Class CompraBLL
    Private ReadOnly _dal As CompraDAL
    Public Sub New()
        Me.New(New CompraDAL())
    End Sub
    Public Sub New(dal As CompraDAL)
        _dal = dal
    End Sub
    Public Shared Sub Validar(compra As Compra)
        If compra Is Nothing OrElse compra.Operacion = Guid.Empty OrElse compra.IdProveedor <= 0 OrElse compra.Detalles Is Nothing OrElse compra.Detalles.Count = 0 OrElse compra.Detalles.Count > 500 Then Throw New ApplicationException("Seleccioná proveedor y entre 1 y 500 productos.")
        Dim vistos As New HashSet(Of Integer)
        For Each d In compra.Detalles
            If d Is Nothing OrElse d.IdProducto <= 0 OrElse d.Cantidad <= 0 OrElse d.CostoUnitario <= 0 OrElse d.CostoUnitario > 9999999999.99D OrElse Decimal.Round(d.CostoUnitario, 2) <> d.CostoUnitario Then Throw New ApplicationException("Producto, cantidad y costo de hasta dos decimales deben ser válidos.")
            If Not vistos.Add(d.IdProducto) Then Throw New ApplicationException("Unificá las cantidades del mismo producto en una sola línea.")
            If d.Subtotal > 9999999999999999.99D Then Throw New ApplicationException("El subtotal excede el límite permitido.")
        Next
        If compra.Total > 9999999999999999.99D Then Throw New ApplicationException("El total excede el límite permitido.")
    End Sub
    Public Function Registrar(actor As Usuario, compra As Compra) As Integer
        Permisos.Exigir(actor, Permiso.Productos) : Validar(compra)
        ' Snapshot para que cambios de UI no alteren el pedido durante el envío.
        Dim snapshot As New Compra With {.Operacion = compra.Operacion, .IdProveedor = compra.IdProveedor, .Detalles = compra.Detalles.Select(Function(d) New DetalleCompra With {.IdProducto = d.IdProducto, .Cantidad = d.Cantidad, .CostoUnitario = d.CostoUnitario, .Producto = d.Producto}).ToList()}
        Return _dal.Registrar(actor, snapshot)
    End Function
    Public Shared Sub Fechas(desde As Date, hasta As Date)
        If desde.Date < New Date(1753, 1, 1) OrElse hasta.Date >= New Date(9999, 12, 31) OrElse desde.Date > hasta.Date Then Throw New ApplicationException("Rango de fechas inválido.")
    End Sub
    Public Function Historial(actor As Usuario, desde As Date, hasta As Date, proveedor As Integer?) As DataTable
        Permisos.Exigir(actor, Permiso.Productos) : Fechas(desde, hasta)
        If proveedor.HasValue AndAlso proveedor.Value <= 0 Then Throw New ApplicationException("Proveedor inválido.")
        Return _dal.Historial(actor, desde, hasta, proveedor)
    End Function
    Public Function Detalle(actor As Usuario, id As Integer) As DataTable
        Permisos.Exigir(actor, Permiso.Productos)
        If id <= 0 Then Throw New ApplicationException("Compra inválida.")
        Return _dal.Detalle(actor, id)
    End Function
End Class
