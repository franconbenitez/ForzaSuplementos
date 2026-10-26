Public Class Venta
    Public Property IdVenta As Integer
    Public Property IdCliente As Integer
    Public Property IdUsuario As Integer
    Public Property IdSesion As Integer?
    Public Property MedioPago As MedioPago = MedioPago.SinSeleccionar
    Public Property Fecha As DateTime
    Public Property Total As Decimal
    Public Property Detalles As New List(Of DetalleVenta) ' Acá guardamos el carrito de compras

    Public Sub CalcularTotal()
        Total = 0
        For Each det In Detalles
            Total += det.Subtotal
        Next
    End Sub
End Class
