Imports System.IO
Imports ForzaSuplementos.Negocio

Public Class FrmBackup
    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
    End Sub

    Private ReadOnly _bll As New BackupBLL()

    Private Sub btnExaminar_Click(sender As Object, e As EventArgs) Handles btnExaminar.Click
        Using fbd As New FolderBrowserDialog()
            fbd.Description = "Seleccioná la carpeta para guardar el Backup"
            If fbd.ShowDialog() = DialogResult.OK Then
                ' Armamos un nombre automático: ForzaSuplementos_20261002.bak
                Dim nombreArchivo As String = "ForzaSuplementos_" & DateTime.Now.ToString("yyyyMMdd_HHmmss") & ".bak"
                txtRuta.Text = Path.Combine(fbd.SelectedPath, nombreArchivo)
            End If
        End Using
    End Sub

    Private Sub btnGenerar_Click(sender As Object, e As EventArgs) Handles btnGenerar.Click
        Try
            If txtRuta.Text = "" Then
                MessageBox.Show("Primero hacé clic en Examinar para elegir dónde guardarlo.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Warning)
                Return
            End If

            Me.Cursor = Cursors.WaitCursor
            _bll.Generar(txtRuta.Text)
            Me.Cursor = Cursors.Default

            MessageBox.Show("¡Copia de seguridad generada con éxito!", "Backup Completado", MessageBoxButtons.OK, MessageBoxIcon.Information)
            txtRuta.Clear()

        Catch ex As ApplicationException
            Me.Cursor = Cursors.Default
            MessageBox.Show(ex.Message, "Atención", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        Catch ex As Exception
            Me.Cursor = Cursors.Default
            MessageBox.Show("Error al generar el backup. Asegurate de que SQL Server tenga permisos para escribir en esa carpeta. Error: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub
End Class
