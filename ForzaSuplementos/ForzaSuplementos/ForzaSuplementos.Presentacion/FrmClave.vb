Option Strict On
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio
Public Class FrmClave
    Inherits Form
    Private ReadOnly _actual As New TextBox With {.UseSystemPasswordChar = True, .Dock = DockStyle.Fill}
    Private ReadOnly _nueva As New TextBox With {.UseSystemPasswordChar = True, .Dock = DockStyle.Fill}
    Private ReadOnly _repetir As New TextBox With {.UseSystemPasswordChar = True, .Dock = DockStyle.Fill}
    Private ReadOnly _guardar As New Button With {.Text = "Guardar contraseña", .AutoSize = True}
    Private ReadOnly _actor As Usuario
    Private ReadOnly _destino As Integer
    Public Sub New(actor As Usuario, Optional destino As Integer = 0)
        Permisos.Exigir(actor, If(destino = 0, Permiso.Reportes, Permiso.Usuarios))
        _actor = actor : _destino = destino
        Text = If(destino = 0, "Cambiar mi contraseña", "Restablecer contraseña")
        Size = New Drawing.Size(480, 310) : FormBorderStyle = FormBorderStyle.FixedDialog
        MaximizeBox = False : MinimizeBox = False : StartPosition = FormStartPosition.CenterParent
        Dim panel As New TableLayoutPanel With {.Dock = DockStyle.Fill, .Padding = New Padding(20), .ColumnCount = 1, .RowCount = 7}
        panel.Controls.Add(New Label With {.Text = "Contraseña actual", .AutoSize = True}) : panel.Controls.Add(_actual)
        panel.Controls.Add(New Label With {.Text = "Nueva: entre 12 y 256 caracteres", .AutoSize = True}) : panel.Controls.Add(_nueva)
        panel.Controls.Add(New Label With {.Text = "Repetir nueva contraseña", .AutoSize = True}) : panel.Controls.Add(_repetir) : panel.Controls.Add(_guardar)
        _actual.Enabled = destino = 0
        Controls.Add(panel) : TemaForza.Aplicar(Me) : AcceptButton = _guardar
        AddHandler _guardar.Click, AddressOf Guardar
    End Sub
    Private Sub Guardar(sender As Object, e As EventArgs)
        _guardar.Enabled = False
        Try
            Dim b As New SeguridadBLL()
            If Not b.Activa() Then Throw New ApplicationException("Requiere habilitar la migración de seguridad 005 en QA. No se cambió ninguna clave.")
            If _nueva.Text <> _repetir.Text Then Throw New ApplicationException("Las contraseñas no coinciden.")
            If _destino = 0 Then
                b.Cambiar(_actor, _actor.NombreUsuario, _actual.Text, _nueva.Text)
            Else
                b.Restablecer(_actor, _destino, _nueva.Text)
            End If
            DialogResult = DialogResult.OK : Close()
        Catch ex As Exception
            MessageBox.Show(Me, ex.Message, "Contraseña", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        Finally
            _guardar.Enabled = True
        End Try
    End Sub
End Class
