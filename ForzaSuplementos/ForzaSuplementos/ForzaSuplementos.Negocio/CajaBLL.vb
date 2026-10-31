Option Strict On
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades

Public Class CajaBLL
    Private ReadOnly _dal As New CajaDAL()

    Public Shared Sub ValidarVendedor(usuario As Usuario)
        Permisos.Exigir(usuario, Permiso.Caja)
        ' El SP vuelve a verificar perfil y activo en la base, sin confiar en la interfaz.
    End Sub

    Public Shared Sub ValidarImporte(monto As Decimal)
        If monto < 0D OrElse monto > 99999999.99D OrElse Decimal.Round(monto, 2) <> monto Then
            Throw New ApplicationException("El importe debe estar entre 0 y 99.999.999,99 y tener hasta dos decimales.")
        End If
    End Sub

    Public Function ObtenerAbierta(usuario As Usuario) As SesionCaja
        ValidarVendedor(usuario)
        Return _dal.ObtenerAbierta(usuario.IdUsuario)
    End Function

    Public Function RequerirAbierta(usuario As Usuario) As SesionCaja
        Dim sesion = ObtenerAbierta(usuario)
        If sesion Is Nothing Then Throw New ApplicationException("Abrí tu caja antes de registrar una venta.")
        Return sesion
    End Function

    Public Function Abrir(usuario As Usuario, montoInicial As Decimal) As Integer
        ValidarVendedor(usuario)
        ValidarImporte(montoInicial)
        If ObtenerAbierta(usuario) IsNot Nothing Then Throw New ApplicationException("Ya tenés una caja abierta.")
        ' La exclusión global de sesiones simultáneas se garantiza atómicamente en SQL.
        Return _dal.Abrir(usuario.IdUsuario, montoInicial)
    End Function

    Public Sub Cerrar(usuario As Usuario, idSesion As Integer, montoReal As Decimal)
        ValidarVendedor(usuario)
        ValidarImporte(montoReal)
        Dim abierta = RequerirAbierta(usuario)
        If abierta.IdSesion <> idSesion Then Throw New ApplicationException("La sesión ya no es la caja abierta actual. Actualizá la pantalla.")
        If abierta.VentasSinPago > 0 Then Throw New ApplicationException("Hay ventas sin pago registrado. No se puede calcular un cierre confiable.")
        _dal.Cerrar(usuario.IdUsuario, idSesion, montoReal)
    End Sub

    Public Function Historial(usuario As Usuario, desde As Date, hasta As Date) As List(Of SesionCaja)
        ValidarVendedor(usuario)
        If desde.Date < New Date(1753, 1, 1) OrElse desde.Date > hasta.Date OrElse hasta.Date = Date.MaxValue.Date Then Throw New ApplicationException("El rango de fechas es inválido.")
        Return _dal.ListarHistorial(usuario.IdUsuario, desde, hasta)
    End Function

    Public Function Reporte(usuario As Usuario, idSesion As Integer) As SesionCaja
        ValidarVendedor(usuario)
        If idSesion <= 0 Then Throw New ApplicationException("Seleccioná una sesión válida.")
        Dim sesion = _dal.ObtenerReporte(usuario.IdUsuario, idSesion)
        If sesion Is Nothing Then Throw New ApplicationException("La sesión no existe o no pertenece al vendedor.")
        Return sesion
    End Function
End Class
