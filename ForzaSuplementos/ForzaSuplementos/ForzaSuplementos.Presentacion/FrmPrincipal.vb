Imports ForzaSuplementos.Entidades
Imports System.Drawing
Imports System.Windows.Forms

Public Class FrmPrincipal
    Private _usuarioLogueado As Usuario

    Public Sub New(usuario As Usuario)
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
        MenuCaja.Visible = String.Equals(_usuarioLogueado.NombrePerfil, "VENDEDOR", StringComparison.OrdinalIgnoreCase)
        MenuVentas.Visible = MenuCaja.Visible
        Dim rol As String = _usuarioLogueado.NombrePerfil.ToUpper()

        ' REGLA DEL PROFESOR: El Administrador controla el sistema pero NO factura
        If rol = "ADMINISTRADOR" Then
            MenuVentas.Visible = False
            MenuCaja.Visible = False

        ElseIf rol = "GERENTE" Then
            ' El Gerente NO vende, NO abre caja, NO toca clientes y NO hace backups
            MenuVentas.Visible = False
            MenuClientes.Visible = False
            MenuBackup.Visible = False
            MenuCaja.Visible = False

        ElseIf rol = "VENDEDOR" Then
            ' El Vendedor NO toca usuarios, NO toca productos y NO hace backups
            MenuUsuarios.Visible = False
            MenuProductos.Visible = False
            MenuBackup.Visible = False
        End If
    End Sub

    Private _navegando As Boolean

    ' Crear únicamente después de que el hijo anterior acepte cerrar.
    Protected Sub AbrirModulo(tipo As Type)
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
        If tipo Is GetType(FrmCaja) Then Return New FrmCaja With {.UsuarioActual = _usuarioLogueado}
        If tipo Is GetType(FrmVentas) Then Return New FrmVentas With {.UsuarioActual = _usuarioLogueado, .UsuarioActualId = _usuarioLogueado.IdUsuario}
        If tipo Is GetType(FrmReportes) Then Return New FrmReportes With {.UsuarioActualId = _usuarioLogueado.IdUsuario, .RolActual = _usuarioLogueado.NombrePerfil}
        If tipo Is GetType(FrmUsuarios) Then Return New FrmUsuarios()
        If tipo Is GetType(FrmProductos) Then Return New FrmProductos()
        If tipo Is GetType(FrmClientes) Then Return New FrmClientes()
        If tipo Is GetType(FrmBackup) Then Return New FrmBackup()
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
