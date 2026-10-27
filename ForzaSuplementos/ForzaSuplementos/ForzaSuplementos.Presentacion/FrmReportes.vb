Imports ForzaSuplementos.Negocio

Public Class FrmReportes
    Public Property UsuarioActual As ForzaSuplementos.Entidades.Usuario
    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
    End Sub

    Private ReadOnly _bll As New ReporteBLL()

    Public UsuarioActualId As Integer
    Public RolActual As String

    Private Sub FrmReportes_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        If Not AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Reportes) Then Return
        ConfigurarPermisos()
    End Sub

    Private Sub ConfigurarPermisos()
        Dim propio = Permisos.Puede(UsuarioActual, Permiso.ReportesPropios)

        If propio Then
            ' El vendedor solo ve lo suyo
            btnHistorial.Visible = False
            btnBajoStock.Visible = False
            btnMisVentas.Visible = True

            ' Cargar automáticamente sus ventas
            btnMisVentas.PerformClick()
        Else
            ' Admin y Gerente ven todo menos el botón individual del vendedor
            btnMisVentas.Visible = False
            btnHistorial.Visible = True
            btnBajoStock.Visible = True

            ' Cargar el historial general por defecto
            btnHistorial.PerformClick()
        End If
    End Sub

    Private Sub btnHistorial_Click(sender As Object, e As EventArgs) Handles btnHistorial.Click
        Try
            dgvReportes.DataSource = _bll.ObtenerHistorialVentas(UsuarioActual)
        Catch ex As Exception
            MessageBox.Show("Error al cargar el historial: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub btnBajoStock_Click(sender As Object, e As EventArgs) Handles btnBajoStock.Click
        Try
            dgvReportes.DataSource = _bll.ObtenerBajoStock(UsuarioActual)
        Catch ex As Exception
            MessageBox.Show("Error al cargar productos con bajo stock: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub btnMisVentas_Click(sender As Object, e As EventArgs) Handles btnMisVentas.Click
        Try
            dgvReportes.DataSource = _bll.ObtenerMisVentas(UsuarioActual)
        Catch ex As Exception
            MessageBox.Show("Error al cargar tus ventas: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub
End Class
