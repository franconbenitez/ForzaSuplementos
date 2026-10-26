Imports ForzaSuplementos.Entidades
Imports System.Drawing
Imports System.Windows.Forms

Public Class FrmPrincipal
    Private _usuarioLogueado As Usuario

    Public Sub New(usuario As Usuario)
        InitializeComponent()
        _usuarioLogueado = usuario
    End Sub

    Private Sub FrmPrincipal_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        LblEstadoUsuario.Text = $"Sesión activa: {_usuarioLogueado.Nombre} {_usuarioLogueado.Apellido} | Perfil: {_usuarioLogueado.NombrePerfil}"

        MenuPrincipal.Renderer = New RenderizadorOscuro()

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

    ' --- EVENTOS CLIC DE LOS BOTONES DEL MENÚ ---

    Private Sub MenuCaja_Click(sender As Object, e As EventArgs) Handles MenuCaja.Click
        For Each frm In Me.MdiChildren
            If TypeOf frm Is FrmCaja Then
                frm.BringToFront()
                Return
            End If
        Next

        Dim ventanaCaja As New FrmCaja()
        ventanaCaja.UsuarioActual = _usuarioLogueado
        ventanaCaja.MdiParent = Me
        ventanaCaja.Show()
    End Sub

    Private Sub MenuUsuarios_Click(sender As Object, e As EventArgs) Handles MenuUsuarios.Click
        For Each frm In Me.MdiChildren
            If TypeOf frm Is FrmUsuarios Then
                frm.BringToFront()
                Return
            End If
        Next

        Dim ventanaUsuarios As New FrmUsuarios()
        ventanaUsuarios.MdiParent = Me
        ventanaUsuarios.Show()
    End Sub

    Private Sub MenuProductos_Click(sender As Object, e As EventArgs) Handles MenuProductos.Click
        For Each frm In Me.MdiChildren
            If TypeOf frm Is FrmProductos Then
                frm.BringToFront()
                Return
            End If
        Next

        Dim ventanaProductos As New FrmProductos()
        ventanaProductos.MdiParent = Me
        ventanaProductos.Show()
    End Sub

    Private Sub MenuClientes_Click(sender As Object, e As EventArgs) Handles MenuClientes.Click
        For Each frm In Me.MdiChildren
            If TypeOf frm Is FrmClientes Then
                frm.BringToFront()
                Return
            End If
        Next
        Dim v As New FrmClientes()
        v.MdiParent = Me
        v.Show()
    End Sub

    Private Sub MenuVentas_Click(sender As Object, e As EventArgs) Handles MenuVentas.Click
        For Each frm In Me.MdiChildren
            If TypeOf frm Is FrmVentas Then
                frm.BringToFront()
                Return
            End If
        Next

        Dim ventanaVentas As New FrmVentas()
        ventanaVentas.UsuarioActualId = _usuarioLogueado.IdUsuario
        ventanaVentas.UsuarioActual = _usuarioLogueado
        ventanaVentas.MdiParent = Me
        ventanaVentas.Show()
    End Sub

    Private Sub MenuReportes_Click(sender As Object, e As EventArgs) Handles MenuReportes.Click
        For Each frm In Me.MdiChildren
            If TypeOf frm Is FrmReportes Then
                frm.BringToFront()
                Return
            End If
        Next

        Dim ventanaReportes As New FrmReportes()
        ventanaReportes.UsuarioActualId = _usuarioLogueado.IdUsuario
        ventanaReportes.RolActual = _usuarioLogueado.NombrePerfil
        ventanaReportes.MdiParent = Me
        ventanaReportes.Show()
    End Sub

    Private Sub MenuBackup_Click(sender As Object, e As EventArgs) Handles MenuBackup.Click
        For Each frm In Me.MdiChildren
            If TypeOf frm Is FrmBackup Then
                frm.BringToFront()
                Return
            End If
        Next

        Dim ventanaBackup As New FrmBackup()
        ventanaBackup.MdiParent = Me
        ventanaBackup.Show()
    End Sub

    Private Sub MenuCerrarSesion_Click(sender As Object, e As EventArgs) Handles MenuCerrarSesion.Click
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

    ' =========================================================================
    ' MAGIA VISUAL: TABLA DE COLORES ESTRICTA PARA FORZA SUPLEMENTOS
    ' =========================================================================
    Private Class RenderizadorOscuro
        Inherits ToolStripProfessionalRenderer

        Public Sub New()
            MyBase.New(New TablaColoresForza())
            Me.RoundedEdges = False
        End Sub

        Protected Overrides Sub OnRenderItemText(e As ToolStripItemTextRenderEventArgs)
            e.TextColor = Color.White
            MyBase.OnRenderItemText(e)
        End Sub
    End Class

    Private Class TablaColoresForza
        Inherits ProfessionalColorTable

        Public Overrides ReadOnly Property MenuItemSelectedGradientBegin As Color
            Get
                Return Color.FromArgb(52, 168, 132)
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemSelectedGradientEnd As Color
            Get
                Return Color.FromArgb(52, 168, 132)
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemSelected As Color
            Get
                Return Color.FromArgb(52, 168, 132)
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemBorder As Color
            Get
                Return Color.FromArgb(52, 168, 132)
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemPressedGradientBegin As Color
            Get
                Return Color.FromArgb(33, 37, 41)
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemPressedGradientMiddle As Color
            Get
                Return Color.FromArgb(33, 37, 41)
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemPressedGradientEnd As Color
            Get
                Return Color.FromArgb(33, 37, 41)
            End Get
        End Property
        Public Overrides ReadOnly Property ToolStripDropDownBackground As Color
            Get
                Return Color.FromArgb(33, 37, 41)
            End Get
        End Property
        Public Overrides ReadOnly Property ImageMarginGradientBegin As Color
            Get
                Return Color.FromArgb(33, 37, 41)
            End Get
        End Property
        Public Overrides ReadOnly Property ImageMarginGradientMiddle As Color
            Get
                Return Color.FromArgb(33, 37, 41)
            End Get
        End Property
        Public Overrides ReadOnly Property ImageMarginGradientEnd As Color
            Get
                Return Color.FromArgb(33, 37, 41)
            End Get
        End Property
    End Class
End Class
