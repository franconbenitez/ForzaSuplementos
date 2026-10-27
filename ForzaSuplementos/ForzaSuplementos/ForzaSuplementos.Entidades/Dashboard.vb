Option Strict On
Public Class PuntoReporte
    Public Property Clave As Integer?
    Public Property Etiqueta As String
    Public Property Importe As Decimal
    Public Property Cantidad As Long
End Class

Public Class DashboardVentas
    Public Property Desde As Date
    Public Property Hasta As Date
    Public Property TotalFacturado As Decimal
    Public Property Operaciones As Integer
    Public Property Unidades As Long?
    Public Property VentasSinDetalle As Integer?
    Public Property Completo As Boolean
    Public Property Diaria As New List(Of PuntoReporte)()
    Public Property Mensual As New List(Of PuntoReporte)()
    Public Property Productos As New List(Of PuntoReporte)()
    Public Property Categorias As New List(Of PuntoReporte)()
    Public Property Vendedores As New List(Of PuntoReporte)()
End Class

Public Class RegistroBackupReporte
    Public Property IdBackup As Integer
    Public Property IdUsuario As Integer
    Public Property Fecha As Date
    Public Property Archivo As String
End Class

Public Class DashboardBackups
    Public Property Cantidad As Integer
    ' El esquema no registra resultado: Nothing no equivale a cero fallos.
    Public Property Exitosos As Integer?
    Public Property Fallidos As Integer?
    Public Property Historial As New List(Of RegistroBackupReporte)()
    Public Property Diaria As New List(Of PuntoReporte)()
    Public Property Mensual As New List(Of PuntoReporte)()
End Class
