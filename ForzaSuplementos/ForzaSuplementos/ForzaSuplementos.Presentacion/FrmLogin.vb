Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmLogin
    Private ReadOnly _bll As New UsuarioBLL()
    Private _autenticando As Boolean

    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
        Dim versionQA = Environment.GetEnvironmentVariable("FORZA_QA_BUILD_ID")
        If Environment.GetEnvironmentVariable("FORZA_ENTORNO") = "QA" AndAlso Not String.IsNullOrWhiteSpace(versionQA) Then
            Me.Text = "QA PRINCIPAL | " & versionQA
        End If
    End Sub

    Private Sub btnIngresar_Click(sender As Object, e As EventArgs) Handles btnIngresar.Click
        If _autenticando Then Return
        _autenticando = True
        btnIngresar.Enabled = False
        Try
            Dim userLogueado = Autenticar(txtUsuario.Text.Trim(), txtContrasena.Text)
            MostrarPrincipal(userLogueado)

        Catch ex As ApplicationException
            MessageBox.Show(ex.Message, "Acceso Denegado", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        Catch ex As SqlException
            MessageBox.Show("Error de base de datos: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Catch ex As Exception
            MessageBox.Show("Error inesperado: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            _autenticando = False
            btnIngresar.Enabled = True
        End Try
    End Sub

    ' Unica ruta de autenticacion para clic y AcceptButton; conserva la BLL existente.
    Protected Overridable Function Autenticar(usuario As String, contrasena As String) As Usuario
        Return _bll.IniciarSesion(usuario, contrasena)
    End Function

    Protected Overridable Sub MostrarPrincipal(usuario As Usuario)
        Dim frmMain As New FrmPrincipal(usuario)
        frmMain.Show()
        Me.Hide()
    End Sub

    Private Sub btnSalir_Click(sender As Object, e As EventArgs) Handles btnSalir.Click
        Application.Exit() ' Cierra todo el programa
    End Sub
End Class
