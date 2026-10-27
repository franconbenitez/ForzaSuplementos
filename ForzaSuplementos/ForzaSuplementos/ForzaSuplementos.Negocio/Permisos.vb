Option Strict On
Imports ForzaSuplementos.Entidades

Public Enum Permiso
    Usuarios
    Productos
    Clientes
    Backups
    Reportes
    ReportesGlobales
    ReportesPropios
    Ventas
    Caja
    CatalogoVenta
End Enum

Public NotInheritable Class Permisos
    Private Sub New()
    End Sub

    Public Shared Function Puede(usuario As Usuario, operacion As Permiso) As Boolean
        If usuario Is Nothing OrElse usuario.IdUsuario <= 0 Then Return False
        Dim rol = If(usuario.NombrePerfil, "").Trim().ToUpperInvariant()
        Select Case operacion
            Case Permiso.Usuarios, Permiso.Backups
                Return rol = "ADMINISTRADOR"
            Case Permiso.Productos
                Return rol = "GERENTE"
            Case Permiso.Clientes, Permiso.Ventas, Permiso.Caja, Permiso.ReportesPropios, Permiso.CatalogoVenta
                Return rol = "VENDEDOR"
            Case Permiso.ReportesGlobales
                Return rol = "ADMINISTRADOR" OrElse rol = "GERENTE"
            Case Permiso.Reportes
                Return rol = "ADMINISTRADOR" OrElse rol = "GERENTE" OrElse rol = "VENDEDOR"
            Case Else
                Return False
        End Select
    End Function

    Public Shared Sub Exigir(usuario As Usuario, operacion As Permiso)
        If Not Puede(usuario, operacion) Then Throw New ApplicationException("El usuario de la sesión no tiene permiso para esta operación.")
    End Sub
End Class
