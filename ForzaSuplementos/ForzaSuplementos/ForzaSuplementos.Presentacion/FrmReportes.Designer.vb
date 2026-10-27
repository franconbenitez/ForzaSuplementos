<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmReportes
    Inherits System.Windows.Forms.Form
    Protected Overrides Sub Dispose(disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then components.Dispose()
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub
    Private components As System.ComponentModel.IContainer
    Friend WithEvents PanelTop As System.Windows.Forms.Panel
    Friend WithEvents LblTitulo As System.Windows.Forms.Label
    Friend WithEvents btnHistorial As System.Windows.Forms.Button
    Friend WithEvents btnBajoStock As System.Windows.Forms.Button
    Friend WithEvents btnMisVentas As System.Windows.Forms.Button
    Friend WithEvents dgvReportes As System.Windows.Forms.DataGridView
    Friend WithEvents dtpDesde As System.Windows.Forms.DateTimePicker
    Friend WithEvents dtpHasta As System.Windows.Forms.DateTimePicker
    Friend WithEvents nudVendedor As System.Windows.Forms.NumericUpDown
    Friend WithEvents nudProducto As System.Windows.Forms.NumericUpDown
    Friend WithEvents lblVendedor As System.Windows.Forms.Label
    Friend WithEvents lblProducto As System.Windows.Forms.Label
    Friend WithEvents lblDesde As System.Windows.Forms.Label
    Friend WithEvents lblHasta As System.Windows.Forms.Label
    Friend WithEvents lblResumen As System.Windows.Forms.Label
    Friend WithEvents lblEstado As System.Windows.Forms.Label
    Friend WithEvents btnActualizar As System.Windows.Forms.Button
    Friend WithEvents cboGrafico As System.Windows.Forms.ComboBox
    Friend WithEvents grafico As System.Windows.Forms.DataVisualization.Charting.Chart

    Private Sub InitializeComponent()
        Me.components = New System.ComponentModel.Container()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LblTitulo = New System.Windows.Forms.Label()
        Me.btnHistorial = New System.Windows.Forms.Button()
        Me.btnBajoStock = New System.Windows.Forms.Button()
        Me.btnMisVentas = New System.Windows.Forms.Button()
        Me.dgvReportes = New System.Windows.Forms.DataGridView()
        Me.dtpDesde = New System.Windows.Forms.DateTimePicker()
        Me.dtpHasta = New System.Windows.Forms.DateTimePicker()
        Me.nudVendedor = New System.Windows.Forms.NumericUpDown()
        Me.nudProducto = New System.Windows.Forms.NumericUpDown()
        Me.lblVendedor = New System.Windows.Forms.Label()
        Me.lblProducto = New System.Windows.Forms.Label()
        Me.lblDesde = New System.Windows.Forms.Label()
        Me.lblHasta = New System.Windows.Forms.Label()
        Me.lblResumen = New System.Windows.Forms.Label()
        Me.lblEstado = New System.Windows.Forms.Label()
        Me.btnActualizar = New System.Windows.Forms.Button()
        Me.cboGrafico = New System.Windows.Forms.ComboBox()
        Me.grafico = New System.Windows.Forms.DataVisualization.Charting.Chart()
        CType(Me.dgvReportes, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.nudVendedor, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.nudProducto, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.grafico, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Height = 50
        Me.PanelTop.Controls.Add(Me.LblTitulo)
        Me.LblTitulo.Location = New System.Drawing.Point(20, 12)
        Me.LblTitulo.AutoSize = True
        Me.LblTitulo.Font = New System.Drawing.Font("Segoe UI", 14.0!, System.Drawing.FontStyle.Bold)
        Me.LblTitulo.Text = "REPORTES Y ESTADÍSTICAS - FORZA SUPLEMENTOS"
        Me.lblDesde.Text = "Desde:" : Me.lblDesde.Location = New System.Drawing.Point(20, 74) : Me.lblDesde.AutoSize = True
        Me.dtpDesde.Location = New System.Drawing.Point(70, 70) : Me.dtpDesde.Width = 130 : Me.dtpDesde.Format = System.Windows.Forms.DateTimePickerFormat.Short
        Me.lblHasta.Text = "Hasta:" : Me.lblHasta.Location = New System.Drawing.Point(220, 74) : Me.lblHasta.AutoSize = True
        Me.dtpHasta.Location = New System.Drawing.Point(270, 70) : Me.dtpHasta.Width = 130 : Me.dtpHasta.Format = System.Windows.Forms.DateTimePickerFormat.Short
        Me.btnActualizar.Text = "Actualizar dashboard" : Me.btnActualizar.Location = New System.Drawing.Point(425, 65) : Me.btnActualizar.Size = New System.Drawing.Size(175, 36)
        Me.lblVendedor.Text = "Vendedor ID (0=todos):" : Me.lblVendedor.Location = New System.Drawing.Point(625, 58) : Me.lblVendedor.Size = New System.Drawing.Size(155, 20)
        Me.nudVendedor.Location = New System.Drawing.Point(625, 80) : Me.nudVendedor.Width = 130 : Me.nudVendedor.Maximum = 2147483647D
        Me.lblProducto.Text = "Producto ID (0=todos):" : Me.lblProducto.Location = New System.Drawing.Point(810, 58) : Me.lblProducto.Size = New System.Drawing.Size(170, 20)
        Me.nudProducto.Location = New System.Drawing.Point(810, 80) : Me.nudProducto.Width = 130 : Me.nudProducto.Maximum = 2147483647D
        Me.lblResumen.Location = New System.Drawing.Point(20, 115) : Me.lblResumen.Size = New System.Drawing.Size(1050, 45)
        Me.lblResumen.Font = New System.Drawing.Font("Segoe UI", 12.0!, System.Drawing.FontStyle.Bold)
        Me.lblResumen.Anchor = System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left Or System.Windows.Forms.AnchorStyles.Right
        Me.lblResumen.Text = "Seleccione un período."
        Me.cboGrafico.Location = New System.Drawing.Point(20, 165) : Me.cboGrafico.Width = 280 : Me.cboGrafico.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList
        Me.lblEstado.Location = New System.Drawing.Point(320, 163) : Me.lblEstado.Size = New System.Drawing.Size(750, 45)
        Me.lblEstado.Anchor = System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left Or System.Windows.Forms.AnchorStyles.Right
        Me.grafico.Location = New System.Drawing.Point(20, 210) : Me.grafico.Size = New System.Drawing.Size(1050, 275)
        Me.grafico.Anchor = System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left Or System.Windows.Forms.AnchorStyles.Right
        Me.grafico.Visible = False
        Me.dgvReportes.Location = New System.Drawing.Point(20, 500) : Me.dgvReportes.Size = New System.Drawing.Size(1050, 215)
        Me.dgvReportes.Anchor = System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left Or System.Windows.Forms.AnchorStyles.Right
        Me.dgvReportes.ReadOnly = True : Me.dgvReportes.AllowUserToAddRows = False : Me.dgvReportes.AllowUserToDeleteRows = False
        Me.dgvReportes.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dgvReportes.AutoSizeColumnsMode = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill
        Me.btnHistorial.Text = "Historial general (consulta)" : Me.btnHistorial.Location = New System.Drawing.Point(20, 735) : Me.btnHistorial.Size = New System.Drawing.Size(215, 35)
        Me.btnBajoStock.Text = "Alerta: bajo stock" : Me.btnBajoStock.Location = New System.Drawing.Point(250, 735) : Me.btnBajoStock.Size = New System.Drawing.Size(200, 35)
        Me.btnMisVentas.Text = "Mis ventas (consulta)" : Me.btnMisVentas.Location = New System.Drawing.Point(465, 735) : Me.btnMisVentas.Size = New System.Drawing.Size(215, 35)
        Me.btnHistorial.Anchor = System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left
        Me.btnBajoStock.Anchor = Me.btnHistorial.Anchor : Me.btnMisVentas.Anchor = Me.btnHistorial.Anchor
        Me.ClientSize = New System.Drawing.Size(1090, 790)
        Me.MinimumSize = New System.Drawing.Size(1000, 720)
        Me.Font = New System.Drawing.Font("Segoe UI", 9.0!)
        Me.Text = "Reportes - Forza Suplementos"
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.PanelTop, Me.lblDesde, Me.dtpDesde, Me.lblHasta, Me.dtpHasta, Me.btnActualizar, Me.lblVendedor, Me.nudVendedor, Me.lblProducto, Me.nudProducto, Me.lblResumen, Me.cboGrafico, Me.lblEstado, Me.grafico, Me.dgvReportes, Me.btnHistorial, Me.btnBajoStock, Me.btnMisVentas})
        CType(Me.dgvReportes, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.nudVendedor, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.nudProducto, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.grafico, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class
