Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades

Public Class VentaBLL
    Private ReadOnly _dal As New VentaDAL()

    Public Sub ProcesarVenta(v As Venta, usuario As Usuario)
        CajaBLL.ValidarVendedor(usuario)
        ValidarVenta(v)
        If v.IdUsuario <> usuario.IdUsuario Then Throw New ApplicationException("El vendedor de la venta no coincide con la sesión autenticada.")
        v.IdSesion = New CajaBLL().RequerirAbierta(usuario).IdSesion
        _dal.RegistrarVenta(v)
    End Sub

    Public Shared Sub ValidarVenta(v As Venta)
        If v Is Nothing Then Throw New ApplicationException("La venta no puede estar vacía.")
        If v.IdCliente <= 0 Then Throw New ApplicationException("Es obligatorio seleccionar un cliente para la factura.")
        If v.IdUsuario <= 0 Then Throw New ApplicationException("Error de sesión: No se identificó al vendedor.")
        If v.Detalles Is Nothing OrElse v.Detalles.Count = 0 Then Throw New ApplicationException("El carrito de compras está vacío.")
        If v.MedioPago = MedioPago.SinSeleccionar OrElse Not [Enum].IsDefined(GetType(MedioPago), v.MedioPago) Then Throw New ApplicationException("Seleccioná un medio de pago.")
        Dim ids As New HashSet(Of Integer)()
        For Each detalle In v.Detalles
            If detalle Is Nothing OrElse detalle.IdProducto <= 0 OrElse detalle.Cantidad <= 0 Then Throw New ApplicationException("Cada detalle debe tener producto y cantidad positiva.")
            If Not ids.Add(detalle.IdProducto) Then Throw New ApplicationException("Agrupá las cantidades de cada producto en un solo detalle.")
            CajaBLL.ValidarImporte(detalle.PrecioUnitario)
            If detalle.PrecioUnitario = 0 Then Throw New ApplicationException("El precio debe ser mayor a cero.")
            detalle.CalcularSubtotal()
            CajaBLL.ValidarImporte(detalle.Subtotal)
        Next

        v.CalcularTotal()

        If v.Total <= 0 Then Throw New ApplicationException("El total de la venta debe ser mayor a cero.")

        CajaBLL.ValidarImporte(v.Total)
    End Sub
End Class
