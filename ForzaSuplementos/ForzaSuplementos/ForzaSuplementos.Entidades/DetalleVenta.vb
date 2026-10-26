Public Class DetalleVenta
    Public Property IdProducto As Integer
    Public Property NombreProducto As String ' Sirve para mostrarlo en la grilla visual
    Public Property Cantidad As Integer
    Public Property PrecioUnitario As Decimal
    Public Property Subtotal As Decimal

    Public Sub CalcularSubtotal()
        Subtotal = Cantidad * PrecioUnitario
    End Sub
End Class