Option Strict On
Public Class DetalleCompra
    Public Property IdProducto As Integer
    Public Property Producto As String
    Public Property Cantidad As Integer
    Public Property CostoUnitario As Decimal
    Public ReadOnly Property Subtotal As Decimal
        Get
            Return Cantidad * CostoUnitario
        End Get
    End Property
End Class
Public Class Compra
    Public Property Operacion As Guid = Guid.NewGuid()
    Public Property IdProveedor As Integer
    Public Property Detalles As New List(Of DetalleCompra)
    Public ReadOnly Property Total As Decimal
        Get
            Dim suma As Decimal
            For Each d In Detalles
                suma += d.Subtotal
            Next
            Return suma
        End Get
    End Property
End Class
