Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmLogin
    Private ReadOnly _bll As New UsuarioBLL()

    Private Sub btnIngresar_Click(sender As Object, e As EventArgs) Handles btnIngresar.Click
        Try
            Dim userLogueado = _bll.IniciarSesion(txtUsuario.Text.Trim(), txtContrasena.Text.Trim())

            ' ABRIR EL MDI PRINCIPAL PASÁNDOLE EL USUARIO
            Dim frmMain As New FrmPrincipal(userLogueado)
            frmMain.Show()
            Me.Hide()

        Catch ex As ApplicationException
            MessageBox.Show(ex.Message, "Acceso Denegado", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        Catch ex As SqlException
            MessageBox.Show("Error de base de datos: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Catch ex As Exception
            MessageBox.Show("Error inesperado: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub btnSalir_Click(sender As Object, e As EventArgs) Handles btnSalir.Click
        Application.Exit() ' Cierra todo el programa
    End Sub
End Class