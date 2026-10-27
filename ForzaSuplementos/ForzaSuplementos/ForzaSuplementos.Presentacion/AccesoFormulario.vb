Option Strict On
Imports System.Windows.Forms
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public NotInheritable Class AccesoFormulario
    Private Sub New()
    End Sub

    Public Shared Function Validar(formulario As Form, usuario As Usuario, operacion As Permiso) As Boolean
        If Permisos.Puede(usuario, operacion) Then Return True
        MessageBox.Show(formulario, "No tenés permiso para acceder a este módulo.", "Acceso denegado", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        formulario.Close()
        Return False
    End Function
End Class
