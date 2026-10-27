Imports ForzaSuplementos.Negocio
Imports ForzaSuplementos.Entidades
Imports System.Drawing
Imports System.Windows.Forms

Public Class FrmPrincipal
    Private ReadOnly _usuarioLogueado As Usuario

    Public Sub New(usuario As Usuario)
        Permisos.Exigir(usuario, Permiso.Reportes)
        InitializeComponent()
        TemaForza.Aplicar(Me)
        If Environment.GetEnvironmentVariable("FORZA_ENTORNO") = "QA" Then Me.Text &= " [QA — ForzaSuplementosDB_QA]"
        _usuarioLogueado = usuario
    End Sub

    Private Sub FrmPrincipal_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        LblEstadoUsuario.Text = $"Sesión activa: {_usuarioLogueado.Nombre} {_usuarioLogueado.Apellido} | Perfil: {_usuarioLogueado.NombrePerfil}"

        ConfigurarPermisos()
    End Sub

    Private Sub ConfigurarPermisos()
        MenuUsuarios.Visible = Permisos.Puede(_usuarioLogueado, Permiso.Usuarios)
        MenuProductos.Visible = Permisos.Puede(_usuarioLogueado, Permiso.Productos)
        MenuClientes.Visible = Permisos.Puede(_usuarioLogueado, Permiso.Clientes)
        MenuVentas.Visible = Permisos.Puede(_usuarioLogueado, Permiso.Ventas)
        MenuCaja.Visible = Permisos.Puede(_usuarioLogueado, Permiso.Caja)
        MenuBackup.Visible = Permisos.Puede(_usuarioLogueado, Permiso.Backups)
        MenuReportes.Visible = Permisos.Puede(_usuarioLogueado, Permiso.Reportes)
    End Sub

    Private Shared Function PermisoDelModulo(tipo As Type) As Permiso
        If tipo Is GetType(FrmUsuarios) Then Return Permiso.Usuarios
        If tipo Is GetType(FrmProductos) Then Return Permiso.Productos
        If tipo Is GetType(FrmClientes) Then Return Permiso.Clientes
        If tipo Is GetType(FrmVentas) Then Return Permiso.Ventas
        If tipo Is GetType(FrmCaja) Then Return Permiso.Caja
        If tipo Is GetType(FrmBackup) Then Return Permiso.Backups
        If tipo Is GetType(FrmReportes) Then Return Permiso.Reportes
        Throw New ArgumentException("Módulo desconocido.", NameOf(tipo))
    End Function

    Private _navegando As Boolean

    ' Crear únicamente después de que el hijo anterior acepte cerrar.
    Protected Sub AbrirModulo(tipo As Type)
        If Not Permisos.Puede(_usuarioLogueado, PermisoDelModulo(tipo)) Then Return
        If _navegando Then Return
        _navegando = True
        Try
            For Each hijo As Form In MdiChildren
                If tipo.IsInstanceOfType(hijo) Then
                    If hijo.WindowState = FormWindowState.Minimized Then hijo.WindowState = FormWindowState.Normal
                    hijo.Activate()
                    Return
                End If
            Next
            If Not CerrarModulos() Then Return
            Dim nuevo As Form = CrearModulo(tipo)
            Try
                nuevo.MdiParent = Me
                nuevo.Show()
            Catch
                nuevo.Dispose()
                Throw
            End Try
        Finally
            _navegando = False
        End Try
    End Sub

    Private Function CerrarModulos() As Boolean
        For Each hijo As Form In MdiChildren
            hijo.Close()
            If Not hijo.IsDisposed Then Return False
        Next
        Return True
    End Function

    Protected Overridable Function CrearModulo(tipo As Type) As Form
        Permisos.Exigir(_usuarioLogueado, PermisoDelModulo(tipo))
        If tipo Is GetType(FrmCaja) Then Return New FrmCaja With {.UsuarioActual = _usuarioLogueado}
        If tipo Is GetType(FrmVentas) Then Return New FrmVentas With {.UsuarioActual = _usuarioLogueado, .UsuarioActualId = _usuarioLogueado.IdUsuario}
        If tipo Is GetType(FrmReportes) Then Return New FrmReportes With {.UsuarioActual = _usuarioLogueado, .UsuarioActualId = _usuarioLogueado.IdUsuario, .RolActual = _usuarioLogueado.NombrePerfil}
        If tipo Is GetType(FrmUsuarios) Then Return New FrmUsuarios With {.UsuarioActual = _usuarioLogueado}
        If tipo Is GetType(FrmProductos) Then Return New FrmProductos With {.UsuarioActual = _usuarioLogueado}
        If tipo Is GetType(FrmClientes) Then Return New FrmClientes With {.UsuarioActual = _usuarioLogueado}
        If tipo Is GetType(FrmBackup) Then Return New FrmBackup With {.UsuarioActual = _usuarioLogueado}
        Throw New ArgumentException("Módulo desconocido.", NameOf(tipo))
    End Function

    Private Sub MenuCaja_Click(sender As Object, e As EventArgs) Handles MenuCaja.Click
        If MenuCaja.Available Then AbrirModulo(GetType(FrmCaja))
    End Sub

    Private Sub MenuUsuarios_Click(sender As Object, e As EventArgs) Handles MenuUsuarios.Click
        If MenuUsuarios.Available Then AbrirModulo(GetType(FrmUsuarios))
    End Sub

    Private Sub MenuProductos_Click(sender As Object, e As EventArgs) Handles MenuProductos.Click
        If MenuProductos.Available Then AbrirModulo(GetType(FrmProductos))
    End Sub

    Private Sub MenuClientes_Click(sender As Object, e As EventArgs) Handles MenuClientes.Click
        If MenuClientes.Available Then AbrirModulo(GetType(FrmClientes))
    End Sub

    Private Sub MenuVentas_Click(sender As Object, e As EventArgs) Handles MenuVentas.Click
        If MenuVentas.Available Then AbrirModulo(GetType(FrmVentas))
    End Sub

    Private Sub MenuReportes_Click(sender As Object, e As EventArgs) Handles MenuReportes.Click
        If MenuReportes.Available Then AbrirModulo(GetType(FrmReportes))
    End Sub

    Private Sub MenuBackup_Click(sender As Object, e As EventArgs) Handles MenuBackup.Click
        If MenuBackup.Available Then AbrirModulo(GetType(FrmBackup))
    End Sub

    Private Sub MenuCerrarSesion_Click(sender As Object, e As EventArgs) Handles MenuCerrarSesion.Click
        If Not CerrarModulos() Then Return
        Dim login As New FrmLogin()
        login.Show()
        Me.Close()
    End Sub

    Private Sub MenuSalir_Click(sender As Object, e As EventArgs) Handles MenuSalir.Click
        Application.Exit()
    End Sub

    Private Sub FrmPrincipal_FormClosed(sender As Object, e As FormClosedEventArgs) Handles MyBase.FormClosed
        If Application.OpenForms.Count = 0 Then Application.Exit()
    End Sub

End Class
