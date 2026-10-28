Option Strict On
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades
Public Class SeguridadBLL
    Private ReadOnly _dal As SeguridadDAL
    Public Sub New()
        Me.New(New SeguridadDAL())
    End Sub
    Public Sub New(dal As SeguridadDAL)
        _dal = If(dal, New SeguridadDAL())
    End Sub
    Public Function Activa() As Boolean
        Return _dal.Activa()
    End Function
    Public Function Login(nombre As String, clave As String) As Usuario
        Dim credencial = _dal.Obtener(nombre)
        If credencial Is Nothing Then
            ' Trabajo PBKDF2 también para cuentas desconocidas; no expone existencia.
            ClaveSegura.Verificar(If(clave, ""), "PBKDF2-SHA256$1$600000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
            Return Nothing
        End If
        If Not ClaveSegura.Verificar(clave, credencial.Formato) Then Return Nothing
        Return credencial.Cuenta
    End Function
    Public Sub Cambiar(actor As Usuario, nombre As String, actual As String, nueva As String)
        Permisos.Exigir(actor, Permiso.Reportes)
        ClaveSegura.Validar(nueva)
        Dim credencial = _dal.Obtener(nombre)
        If credencial Is Nothing OrElse credencial.Cuenta.IdUsuario <> actor.IdUsuario OrElse Not ClaveSegura.Verificar(actual, credencial.Formato) Then Throw New ApplicationException("La contraseña actual no es válida.")
        _dal.Cambiar(actor, actor.IdUsuario, ClaveSegura.Crear(nueva), credencial.Formato)
    End Sub
    Public Sub Restablecer(actor As Usuario, destino As Integer, nueva As String)
        Permisos.Exigir(actor, Permiso.Usuarios)
        If destino <= 0 Then Throw New ApplicationException("Seleccioná un usuario.")
        ClaveSegura.Validar(nueva)
        _dal.Cambiar(actor, destino, ClaveSegura.Crear(nueva), Nothing)
    End Sub
End Class
