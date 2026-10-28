Option Strict On
Public Class AjusteStock
    Public Property Operacion As Guid = Guid.NewGuid()
    Public Property IdProducto As Integer
    Public Property Cantidad As Integer
    Public Property StockEsperado As Integer
    Public Property Motivo As String
End Class
Public Class MovimientoStock
    Public Property IdMovimiento As Integer
    Public Property IdProducto As Integer
    Public Property IdUsuario As Integer
    Public Property Fecha As Date
    Public Property Tipo As String
    Public Property Cantidad As Integer
    Public Property Anterior As Integer
    Public Property Posterior As Integer
    Public Property Motivo As String
    Public Property IdCompra As Integer?
    Public Property IdVenta As Integer?
End Class
