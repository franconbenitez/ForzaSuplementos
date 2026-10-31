Imports System.Text.RegularExpressions
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades

Public Class UsuarioBLL
    Private ReadOnly _usuarioDAL As New UsuarioDAL()

    Public Function ObtenerPerfiles(actor As Usuario) As List(Of Perfil)
        Permisos.Exigir(actor, Permiso.Usuarios)
        Return _usuarioDAL.ListarPerfiles()
    End Function

    Public Function ObtenerUsuarios(activo As Boolean, actor As Usuario) As List(Of Usuario)
        Permisos.Exigir(actor, Permiso.Usuarios)
        Return _usuarioDAL.ListarUsuariosPorEstado(activo)
    End Function

    Public Sub GuardarUsuario(u As Usuario, actor As Usuario)
        Permisos.Exigir(actor, Permiso.Usuarios)
        ValidarDatosUsuario(u)
        Dim seguridad As New SeguridadBLL()
        If seguridad.Activa() Then
            Dim formato As String = Nothing
            If u.IdUsuario = 0 OrElse Not String.IsNullOrEmpty(u.Contrasena) Then formato = ClaveSegura.Crear(u.Contrasena)
            Dim dalSeguro As New SeguridadDAL()
            dalSeguro.Guardar(u, actor, formato)
            Return
        End If
        If u.IdUsuario = 0 Then
            _usuarioDAL.Insertar(u)
        Else
            _usuarioDAL.Modificar(u)
        End If
    End Sub

    Public Sub DarDeBaja(idUsuario As Integer, actor As Usuario)
        Permisos.Exigir(actor, Permiso.Usuarios)
        If idUsuario <= 0 Then Throw New ApplicationException("Seleccioná un usuario válido.")
        _usuarioDAL.CambiarEstado(idUsuario, False)
    End Sub

    Public Sub Reactivar(idUsuario As Integer, actor As Usuario)
        Permisos.Exigir(actor, Permiso.Usuarios)
        If idUsuario <= 0 Then Throw New ApplicationException("Seleccioná un usuario válido.")
        _usuarioDAL.CambiarEstado(idUsuario, True)
    End Sub

    Private Sub ValidarDatosUsuario(u As Usuario)
        If u Is Nothing Then Throw New ApplicationException("Usuario inválido.")
        If If(u.Nombre, "").Length > 50 OrElse If(u.Apellido, "").Length > 50 OrElse If(u.NombreUsuario, "").Length > 50 OrElse If(u.Email, "").Length > 100 OrElse If(u.Calle, "").Length > 100 OrElse If(u.Altura, "").Length > 20 OrElse If(u.Telefono, "").Length > 30 Then Throw New ApplicationException("Algún campo supera el tamaño permitido.")
        ' 1. Nada vacío
        If String.IsNullOrWhiteSpace(u.Nombre) Then Throw New ApplicationException("El Nombre no puede estar vacío.")
        If String.IsNullOrWhiteSpace(u.Apellido) Then Throw New ApplicationException("El Apellido no puede estar vacío.")
        If String.IsNullOrWhiteSpace(u.NombreUsuario) Then Throw New ApplicationException("El Usuario no puede estar vacío.")
        If String.IsNullOrWhiteSpace(u.Calle) Then Throw New ApplicationException("La Calle no puede estar vacía.")
        If String.IsNullOrWhiteSpace(u.Altura) Then Throw New ApplicationException("La Altura no puede estar vacía.")
        If String.IsNullOrWhiteSpace(u.Telefono) Then Throw New ApplicationException("El Teléfono no puede estar vacío.")
        If u.IdPerfil <= 0 Then Throw New ApplicationException("Tenés que seleccionar un Perfil/Rol.")

        ' 2. Contraseña: Mínimo 6 caracteres
        If (u.IdUsuario = 0 OrElse Not String.IsNullOrEmpty(u.Contrasena)) AndAlso (String.IsNullOrWhiteSpace(u.Contrasena) OrElse u.Contrasena.Length < 6) Then
            Throw New ApplicationException("La contraseña debe tener al menos 6 caracteres para ser segura.")
        End If

        ' 3. DNI: Numérico y de 7 u 8 dígitos
        If String.IsNullOrWhiteSpace(u.Dni) OrElse Not Regex.IsMatch(u.Dni.Trim(), "^\d{7,8}$") Then
            Throw New ApplicationException("El DNI debe contener únicamente entre 7 y 8 números. Sin puntos ni letras.")
        End If

        ' 4. Email: Que tenga @ y punto
        If String.IsNullOrWhiteSpace(u.Email) OrElse Not Regex.IsMatch(u.Email.Trim(), "^[^@\s]+@[^@\s]+\.[^@\s]+$") Then
            Throw New ApplicationException("El formato del correo electrónico es inválido. (Ejemplo: nombre@correo.com)")
        End If

        ' 5. Edad: Mínimo 16 años
        If u.FechaNacimiento > Date.Today.AddYears(-16) Then
            Throw New ApplicationException("El usuario debe tener al menos 16 años de edad.")
        End If
    End Sub

    Public Function IniciarSesion(usuario As String, contrasena As String) As Usuario
        If String.IsNullOrWhiteSpace(usuario) OrElse String.IsNullOrWhiteSpace(contrasena) Then
            Throw New ApplicationException("Debe ingresar usuario y contraseña.")
        End If

        If usuario.Length > 50 OrElse contrasena.Length > 256 Then Throw New ApplicationException("Usuario o contraseña incorrectos.")
        Dim seguridad As New SeguridadBLL()
        Dim userLogueado = If(seguridad.Activa(), seguridad.Login(usuario, contrasena), _usuarioDAL.Login(usuario, contrasena))
        If userLogueado Is Nothing OrElse Not userLogueado.Activo OrElse Not Permisos.Puede(userLogueado, Permiso.Reportes) Then
            Throw New ApplicationException("Usuario o contraseña incorrectos, o el usuario está inactivo.")
        End If

        userLogueado.NombreUsuario = usuario
        Return userLogueado
    End Function
End Class