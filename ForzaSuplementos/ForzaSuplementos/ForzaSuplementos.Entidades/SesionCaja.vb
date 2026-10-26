Option Strict On

Public Class SesionCaja
    Public Property IdSesion As Integer
    Public Property IdUsuarioApertura As Integer
    Public Property IdUsuarioCierre As Integer?
    Public Property UsuarioApertura As String
    Public Property UsuarioCierre As String
    Public Property FechaApertura As DateTime
    Public Property FechaCierre As DateTime?
    Public Property MontoInicial As Decimal
    Public Property MontoFinalEsperado As Decimal?
    Public Property MontoFinalReal As Decimal?
    Public Property Diferencia As Decimal?
    Public Property Estado As String
    Public Property CantidadVentas As Integer
    Public Property ImporteVentas As Decimal
    Public Property VentasEfectivo As Decimal
    Public Property VentasSinPago As Integer

    Public ReadOnly Property EstaAbierta As Boolean
        Get
            Return String.Equals(Estado, "Abierta", StringComparison.OrdinalIgnoreCase)
        End Get
    End Property
End Class
