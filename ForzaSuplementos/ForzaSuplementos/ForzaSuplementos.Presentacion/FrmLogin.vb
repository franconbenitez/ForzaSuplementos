Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmLogin
    Private ReadOnly _bll As New UsuarioBLL()
    Private _autenticando As Boolean
    Private _sesionIniciada As Boolean

    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
        Dim versionQA = Environment.GetEnvironmentVariable("FORZA_QA_BUILD_ID")
        If Environment.GetEnvironmentVariable("FORZA_ENTORNO") = "QA" AndAlso Not String.IsNullOrWhiteSpace(versionQA) Then
            Me.Text = "QA PRINCIPAL | " & versionQA
        End If
    End Sub

    Private Sub btnIngresar_Click(sender As Object, e As EventArgs) Handles btnIngresar.Click
        If _autenticando OrElse _sesionIniciada Then Return
        _autenticando = True
        btnIngresar.Enabled = False
        Try
            Dim userLogueado = Autenticar(txtUsuario.Text.Trim(), txtContrasena.Text)
            If userLogueado Is Nothing Then Throw New ApplicationException("Usuario o contraseña incorrectos.")
            _sesionIniciada = True
            Try
                MostrarPrincipal(userLogueado)
                txtContrasena.Clear()
            Catch
                _sesionIniciada = False
                Throw
            End Try

        Catch ex As ApplicationException
            InformarError(ex.Message)
        Catch ex As SqlException
            InformarError("No se pudo validar la sesión con SQL Server. Revisá la conexión e intentá nuevamente.")
        Catch ex As Exception
            InformarError("No se pudo abrir la sesión. " & ex.Message)
        Finally
            _autenticando = False
            btnIngresar.Enabled = Not _sesionIniciada
        End Try
    End Sub

    Protected Overridable Sub InformarError(mensaje As String)
        MessageBox.Show(Me, mensaje, "Acceso denegado", MessageBoxButtons.OK, MessageBoxIcon.Warning)
    End Sub

    Public Sub PrepararNuevoIngreso()
        _sesionIniciada = False
        _autenticando = False
        txtContrasena.Clear()
        btnIngresar.Enabled = True
        txtUsuario.Select()
    End Sub

    ' Unica ruta de autenticacion para clic y AcceptButton; conserva la BLL existente.
    Protected Overridable Function Autenticar(usuario As String, contrasena As String) As Usuario
        Return _bll.IniciarSesion(usuario, contrasena)
    End Function

    Protected Overridable Sub MostrarPrincipal(usuario As Usuario)
        Dim frmMain As New FrmPrincipal(usuario) With {.LoginOrigen = Me}
        frmMain.Show()
        Me.Hide()
    End Sub

    Private Sub btnSalir_Click(sender As Object, e As EventArgs) Handles btnSalir.Click
        Application.Exit() ' Cierra todo el programa
    End Sub
End Class
