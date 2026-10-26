Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades

Public Class VentaBLL
    Private ReadOnly _dal As New VentaDAL()

    Public Sub ProcesarVenta(v As Venta)
        If v.IdCliente <= 0 Then Throw New ApplicationException("Es obligatorio seleccionar un cliente para la factura.")
        If v.IdUsuario <= 0 Then Throw New ApplicationException("Error de sesión: No se identificó al vendedor.")
        If v.Detalles.Count = 0 Then Throw New ApplicationException("El carrito de compras está vacío.")

        v.CalcularTotal()

        If v.Total <= 0 Then Throw New ApplicationException("El total de la venta debe ser mayor a cero.")

        _dal.RegistrarVenta(v)
    End Sub
End Class