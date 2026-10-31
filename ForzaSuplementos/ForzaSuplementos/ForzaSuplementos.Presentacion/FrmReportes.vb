Imports System.Threading.Tasks
Imports System.Windows.Forms.DataVisualization.Charting
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmReportes
    Public Property UsuarioActual As Usuario
    ' Compatibilidad: estos campos heredados no conceden acceso ni determinan alcance.
    Public UsuarioActualId As Integer
    Public RolActual As String
    Private ReadOnly _bll As New ReporteBLL()
    Private ReadOnly _dashboard As New DashboardBLL()
    Private _ventas As DashboardVentas
    Private _backups As DashboardBackups
    Private _ocupado As Boolean
    Private _versionFiltro As Integer

    Public Sub New()
        InitializeComponent()
        ' Mantener el lienzo aprobado y permitir alcanzarlo en un MDI pequeño.
        AutoScroll = True
        AutoScrollMinSize = ClientSize
        MinimumSize = New Drawing.Size(640, 480)
        TemaForza.Aplicar(Me)
        ConfigurarGrafico()
    End Sub

    Private Sub ConfigurarGrafico()
        grafico.BackColor = TemaForza.Fondo
        grafico.Legends.Clear()
        Dim area As New ChartArea("Principal") With {.BackColor = TemaForza.Fondo}
        area.AxisX.LabelStyle.ForeColor = TemaForza.Texto
        area.AxisY.LabelStyle.ForeColor = TemaForza.Texto
        area.AxisX.LineColor = TemaForza.Borde : area.AxisY.LineColor = TemaForza.Borde
        area.AxisX.MajorGrid.Enabled = False : area.AxisY.MajorGrid.LineColor = TemaForza.Borde
        area.AxisX.LabelStyle.Angle = -25
        area.AxisX.Interval = 1
        grafico.ChartAreas.Add(area)
    End Sub

    Private Async Sub FrmReportes_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        If Not AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Reportes) Then Return
        dtpDesde.Value = New Date(Date.Today.Year, Date.Today.Month, 1)
        dtpHasta.Value = Date.Today
        ConfigurarPermisos()
        Await ActualizarDashboard()
    End Sub

    Private Sub ConfigurarPermisos()
        Dim rol = If(UsuarioActual.NombrePerfil, "").Trim().ToUpperInvariant()
        btnHistorial.Visible = Permisos.Puede(UsuarioActual, Permiso.ReportesGlobales)
        btnBajoStock.Visible = btnHistorial.Visible
        btnMisVentas.Visible = Permisos.Puede(UsuarioActual, Permiso.ReportesPropios)
        nudVendedor.Visible = rol = "GERENTE" : lblVendedor.Visible = nudVendedor.Visible
        nudProducto.Visible = rol = "GERENTE" : lblProducto.Visible = nudProducto.Visible
        cboGrafico.Items.Clear()
        If rol = "ADMINISTRADOR" Then
            LblTitulo.Text = "ADMINISTRACIÓN — AUDITORÍA DE BACKUPS"
            cboGrafico.Items.AddRange(New String() {"Backups diarios", "Backups mensuales"})
        Else
            LblTitulo.Text = If(rol = "VENDEDOR", "MIS VENTAS — INDICADORES PERSONALES", "GERENCIA — INDICADORES COMERCIALES")
            cboGrafico.Items.AddRange(New String() {"Evolución diaria", "Evolución mensual", "Productos más vendidos"})
            If rol = "GERENTE" Then cboGrafico.Items.AddRange(New String() {"Categorías más vendidas", "Ventas por vendedor"})
        End If
        cboGrafico.SelectedIndex = 0
    End Sub

    Private Async Function ActualizarDashboard() As Task
        If _ocupado Then Return
        _ocupado = True
        Dim version = _versionFiltro
        EstadoControles(False)
        _ventas = Nothing : _backups = Nothing
        grafico.Series.Clear() : grafico.Visible = False : dgvReportes.DataSource = Nothing
        lblResumen.Text = "Consultando datos..." : lblEstado.Text = ""
        Try
            Dim actor = UsuarioActual
            Dim desde = dtpDesde.Value.Date, hasta = dtpHasta.Value.Date
            If Permisos.Puede(actor, Permiso.Backups) Then
                Dim datos = Await ConsultarBackupsAsync(actor, desde, hasta)
                If IsDisposed OrElse version <> _versionFiltro Then Return
                _backups = datos
                lblResumen.Text = $"Backups registrados: {datos.Cantidad:N0}"
            Else
                ' El vendedor no aporta un ID desde controles: BLL/DAL/SP derivan su identidad.
                Dim vendedor As Integer? = Nothing, producto As Integer? = Nothing
                If String.Equals(actor.NombrePerfil.Trim(), "GERENTE", StringComparison.OrdinalIgnoreCase) Then
                    If nudVendedor.Value > 0 Then vendedor = CInt(nudVendedor.Value)
                    If nudProducto.Value > 0 Then producto = CInt(nudProducto.Value)
                End If
                Dim datos = Await ConsultarVentasAsync(actor, desde, hasta, vendedor, producto)
                If IsDisposed OrElse version <> _versionFiltro Then Return
                _ventas = datos
                Dim unidades = If(datos.Unidades.HasValue, datos.Unidades.Value.ToString("N0"), "pendiente de habilitar")
                lblResumen.Text = $"Facturado: $ {datos.TotalFacturado:N2}   |   Operaciones: {datos.Operaciones:N0}   |   Unidades: {unidades}"
            End If
            MostrarGrafico()
        Catch ex As Exception
            If Not IsDisposed AndAlso version = _versionFiltro Then
                LimpiarResultados()
                lblResumen.Text = "Reporte no disponible para este filtro."
                lblEstado.Text = ex.Message
            End If
        Finally
            _ocupado = False
            If Not IsDisposed Then EstadoControles(True)
        End Try
    End Function

    Private Sub LimpiarResultados()
        _ventas = Nothing : _backups = Nothing
        grafico.Series.Clear() : grafico.Visible = False : dgvReportes.DataSource = Nothing
    End Sub

    Protected Overridable Function ConsultarVentasAsync(actor As Usuario, desde As Date, hasta As Date, vendedor As Integer?, producto As Integer?) As Task(Of DashboardVentas)
        Return Task.Run(Function() _dashboard.Ventas(actor, desde, hasta, vendedor, producto))
    End Function

    Protected Overridable Function ConsultarBackupsAsync(actor As Usuario, desde As Date, hasta As Date) As Task(Of DashboardBackups)
        Return Task.Run(Function() _dashboard.Backups(actor, desde, hasta))
    End Function

    Private Sub EstadoControles(activo As Boolean)
        btnActualizar.Enabled = activo : dtpDesde.Enabled = activo : dtpHasta.Enabled = activo
        nudVendedor.Enabled = activo AndAlso (_ventas Is Nothing OrElse _ventas.Completo)
        nudProducto.Enabled = nudVendedor.Enabled : cboGrafico.Enabled = activo
        btnHistorial.Enabled = activo : btnBajoStock.Enabled = activo : btnMisVentas.Enabled = activo
    End Sub

    Private Sub FiltrosCambiados(sender As Object, e As EventArgs) Handles dtpDesde.ValueChanged, dtpHasta.ValueChanged, nudVendedor.ValueChanged, nudProducto.ValueChanged
        _versionFiltro += 1
        _ventas = Nothing : _backups = Nothing
        grafico.Series.Clear() : grafico.Visible = False : dgvReportes.DataSource = Nothing
        lblResumen.Text = "Filtros modificados"
        lblEstado.Text = "Pulsá Actualizar dashboard para consultar este período."
    End Sub

    Private Async Sub btnActualizar_Click(sender As Object, e As EventArgs) Handles btnActualizar.Click
        Await ActualizarDashboard()
    End Sub

    Private Sub cboGrafico_SelectedIndexChanged(sender As Object, e As EventArgs) Handles cboGrafico.SelectedIndexChanged
        MostrarGrafico()
    End Sub

    Private Sub MostrarGrafico()
        grafico.Series.Clear() : grafico.Visible = False
        If _ventas Is Nothing AndAlso _backups Is Nothing Then Return
        Dim puntos As List(Of PuntoReporte) = Nothing
        Dim cantidad As Boolean = False
        If _backups IsNot Nothing Then
            puntos = If(cboGrafico.SelectedIndex = 1, _backups.Mensual, _backups.Diaria)
            cantidad = True
            dgvReportes.DataSource = _backups.Historial
            lblEstado.Text = "Estados exitoso/fallido no registrados en el esquema actual."
        Else
            Select Case cboGrafico.SelectedIndex
                Case 0 : puntos = _ventas.Diaria
                Case 1 : puntos = _ventas.Mensual
                Case 2 : puntos = _ventas.Productos : cantidad = True
                Case 3 : puntos = _ventas.Categorias : cantidad = True
                Case 4 : puntos = _ventas.Vendedores
            End Select
            dgvReportes.DataSource = puntos
            If Not _ventas.Completo Then
                lblEstado.Text = "Resumen con datos reales. Detalle y rankings pendientes de habilitar en QA."
                If cboGrafico.SelectedIndex >= 2 Then Return
            Else
                lblEstado.Text = If(_ventas.VentasSinDetalle.GetValueOrDefault() > 0, "Hay ventas sin detalle: unidades y rankings representan solo lo registrado.", "Datos del período seleccionado.")
            End If
        End If
        If dgvReportes.Columns.Contains("Clave") Then dgvReportes.Columns("Clave").Visible = puntos IsNot Nothing AndAlso puntos.Any(Function(p) p.Clave.HasValue)
        If dgvReportes.Columns.Contains("Importe") Then
            dgvReportes.Columns("Importe").HeaderText = "Importe ($)"
            dgvReportes.Columns("Importe").DefaultCellStyle.Format = "N2"
        End If
        If dgvReportes.Columns.Contains("Etiqueta") Then dgvReportes.Columns("Etiqueta").HeaderText = If(cboGrafico.SelectedIndex = 0, "Fecha", If(cboGrafico.SelectedIndex = 1, "Mes", "Descripción"))
        If dgvReportes.Columns.Contains("Cantidad") Then dgvReportes.Columns("Cantidad").HeaderText = If(cantidad, "Unidades", "Operaciones")
        If puntos Is Nothing OrElse puntos.Count = 0 Then
            lblEstado.Text = "Sin datos para el período seleccionado"
            Return
        End If
        grafico.ChartAreas(0).AxisX.Interval = Math.Max(1, CInt(Math.Ceiling(puntos.Count / 12.0)))
        Dim serie As New Series("Datos") With {.ChartType = SeriesChartType.Column, .Color = TemaForza.Primario, .IsValueShownAsLabel = puntos.Count <= 30, .LabelForeColor = TemaForza.Texto}
        serie.LabelFormat = If(cantidad, "N0", "N2")
        For Each punto In puntos
            serie.Points.AddXY(punto.Etiqueta, If(cantidad, CDbl(punto.Cantidad), CDbl(punto.Importe)))
        Next
        grafico.ChartAreas(0).AxisY.Title = If(cantidad, "Cantidad registrada", "Importe ($)")
        grafico.ChartAreas(0).AxisY.TitleForeColor = TemaForza.Texto
        grafico.Series.Add(serie)
        grafico.Visible = True
    End Sub

    Private Sub ConsultaHeredada(accion As Func(Of System.Data.DataTable))
        If _ocupado Then Return
        LimpiarResultados()
        Try
            dgvReportes.DataSource = accion()
            grafico.Series.Clear() : grafico.Visible = False
            lblResumen.Text = "Consulta existente"
            lblEstado.Text = "Consulta heredada sin filtros del dashboard; Actualizar vuelve al período seleccionado."
        Catch ex As Exception
            LimpiarResultados()
            lblResumen.Text = "Consulta no disponible."
            lblEstado.Text = ex.Message
        End Try
    End Sub

    Private Sub btnHistorial_Click(sender As Object, e As EventArgs) Handles btnHistorial.Click
        ConsultaHeredada(Function() _bll.ObtenerHistorialVentas(UsuarioActual))
    End Sub
    Private Sub btnBajoStock_Click(sender As Object, e As EventArgs) Handles btnBajoStock.Click
        ConsultaHeredada(Function() _bll.ObtenerBajoStock(UsuarioActual))
    End Sub
    Private Sub btnMisVentas_Click(sender As Object, e As EventArgs) Handles btnMisVentas.Click
        ConsultaHeredada(Function() _bll.ObtenerMisVentas(UsuarioActual))
    End Sub
End Class
