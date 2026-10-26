<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmCaja
    Inherits System.Windows.Forms.Form

    Private components As System.ComponentModel.IContainer
    Friend WithEvents lblEstado As System.Windows.Forms.Label
    Friend WithEvents nudInicial As System.Windows.Forms.NumericUpDown
    Friend WithEvents nudReal As System.Windows.Forms.NumericUpDown
    Friend WithEvents btnAbrir As System.Windows.Forms.Button
    Friend WithEvents btnCerrar As System.Windows.Forms.Button
    Friend WithEvents btnActualizar As System.Windows.Forms.Button
    Friend WithEvents btnFiltrar As System.Windows.Forms.Button
    Friend WithEvents btnReporte As System.Windows.Forms.Button
    Friend WithEvents dtpDesde As System.Windows.Forms.DateTimePicker
    Friend WithEvents dtpHasta As System.Windows.Forms.DateTimePicker
    Friend WithEvents dgvHistorial As System.Windows.Forms.DataGridView
    Friend WithEvents txtReporte As System.Windows.Forms.TextBox

    Protected Overrides Sub Dispose(disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then components.Dispose()
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.lblEstado = New System.Windows.Forms.Label()
        Me.nudInicial = New System.Windows.Forms.NumericUpDown()
        Me.nudReal = New System.Windows.Forms.NumericUpDown()
        Me.btnAbrir = New System.Windows.Forms.Button()
        Me.btnCerrar = New System.Windows.Forms.Button()
        Me.btnActualizar = New System.Windows.Forms.Button()
        Me.btnFiltrar = New System.Windows.Forms.Button()
        Me.btnReporte = New System.Windows.Forms.Button()
        Me.dtpDesde = New System.Windows.Forms.DateTimePicker()
        Me.dtpHasta = New System.Windows.Forms.DateTimePicker()
        Me.dgvHistorial = New System.Windows.Forms.DataGridView()
        Me.txtReporte = New System.Windows.Forms.TextBox()
        Dim layout As New System.Windows.Forms.TableLayoutPanel()
        Dim operaciones As New System.Windows.Forms.FlowLayoutPanel()
        Dim filtros As New System.Windows.Forms.FlowLayoutPanel()
        Dim titulo As New System.Windows.Forms.Label()
        Me.SuspendLayout()
        CType(Me.nudInicial, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.nudReal, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.dgvHistorial, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.Text = "Caja — Forza Suplementos"
        Me.ClientSize = New System.Drawing.Size(1100, 720)
        Me.MinimumSize = New System.Drawing.Size(980, 650)
        Me.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.ForeColor = System.Drawing.Color.White
        Me.Font = New System.Drawing.Font("Segoe UI", 9.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent
        layout.Dock = System.Windows.Forms.DockStyle.Fill
        layout.Padding = New System.Windows.Forms.Padding(16)
        layout.ColumnCount = 1
        layout.RowCount = 6
        layout.ColumnStyles.Add(New System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100.0!))
        layout.RowStyles.Add(New System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 42))
        layout.RowStyles.Add(New System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 80))
        layout.RowStyles.Add(New System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 60))
        layout.RowStyles.Add(New System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 55))
        layout.RowStyles.Add(New System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100.0!))
        layout.RowStyles.Add(New System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 170))
        titulo.Text = "CONTROL DE CAJA — FORZA SUPLEMENTOS"
        titulo.Font = New System.Drawing.Font("Segoe UI", 16.0!, System.Drawing.FontStyle.Bold)
        titulo.Dock = System.Windows.Forms.DockStyle.Fill
        Me.lblEstado.Text = "Estado sin consultar"
        Me.lblEstado.Dock = System.Windows.Forms.DockStyle.Fill
        Me.lblEstado.ForeColor = System.Drawing.Color.FromArgb(52, 168, 132)
        operaciones.Dock = System.Windows.Forms.DockStyle.Fill
        operaciones.WrapContents = False
        Dim inicial As New System.Windows.Forms.Label() With {.Text = "Inicial ($)", .AutoSize = True, .Margin = New System.Windows.Forms.Padding(3, 9, 3, 3)}
        Dim real As New System.Windows.Forms.Label() With {.Text = "Contado ($)", .AutoSize = True, .Margin = New System.Windows.Forms.Padding(12, 9, 3, 3)}
        Me.nudInicial.DecimalPlaces = 2
        Me.nudInicial.Maximum = 99999999.99D
        Me.nudInicial.ThousandsSeparator = True
        Me.nudInicial.Width = 125
        Me.nudReal.DecimalPlaces = 2
        Me.nudReal.Maximum = 99999999.99D
        Me.nudReal.ThousandsSeparator = True
        Me.nudReal.Width = 125
        Me.btnAbrir.Text = "Abrir caja"
        Me.btnCerrar.Text = "Cerrar caja"
        Me.btnActualizar.Text = "Actualizar"
        Me.btnFiltrar.Text = "Filtrar"
        Me.btnReporte.Text = "Ver reporte"
        For Each boton As System.Windows.Forms.Button In New System.Windows.Forms.Button() {Me.btnAbrir, Me.btnCerrar, Me.btnActualizar, Me.btnFiltrar, Me.btnReporte}
            boton.Size = New System.Drawing.Size(110, 32)
            boton.FlatStyle = System.Windows.Forms.FlatStyle.Flat
            boton.BackColor = System.Drawing.Color.FromArgb(52, 168, 132)
            boton.ForeColor = System.Drawing.Color.White
            boton.Enabled = False
        Next
        operaciones.Controls.AddRange(New System.Windows.Forms.Control() {inicial, Me.nudInicial, Me.btnAbrir, real, Me.nudReal, Me.btnCerrar, Me.btnActualizar})
        filtros.Dock = System.Windows.Forms.DockStyle.Fill
        filtros.WrapContents = False
        Me.dtpDesde.Format = System.Windows.Forms.DateTimePickerFormat.Short
        Me.dtpHasta.Format = System.Windows.Forms.DateTimePickerFormat.Short
        Me.dtpDesde.Width = 120
        Me.dtpHasta.Width = 120
        filtros.Controls.Add(New System.Windows.Forms.Label() With {.Text = "Apertura desde", .AutoSize = True, .Margin = New System.Windows.Forms.Padding(3, 9, 3, 3)})
        filtros.Controls.Add(Me.dtpDesde)
        filtros.Controls.Add(New System.Windows.Forms.Label() With {.Text = "hasta", .AutoSize = True, .Margin = New System.Windows.Forms.Padding(3, 9, 3, 3)})
        filtros.Controls.AddRange(New System.Windows.Forms.Control() {Me.dtpHasta, Me.btnFiltrar, Me.btnReporte})
        Me.dgvHistorial.Dock = System.Windows.Forms.DockStyle.Fill
        Me.dgvHistorial.ReadOnly = True
        Me.dgvHistorial.AllowUserToAddRows = False
        Me.dgvHistorial.AllowUserToDeleteRows = False
        Me.dgvHistorial.MultiSelect = False
        Me.dgvHistorial.AutoGenerateColumns = False
        Me.dgvHistorial.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dgvHistorial.AutoSizeColumnsMode = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill
        Me.dgvHistorial.BackgroundColor = System.Drawing.Color.FromArgb(45, 49, 53)
        Me.dgvHistorial.DefaultCellStyle.BackColor = System.Drawing.Color.FromArgb(45, 49, 53)
        Me.dgvHistorial.DefaultCellStyle.ForeColor = System.Drawing.Color.White
        Me.dgvHistorial.ColumnHeadersDefaultCellStyle.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.dgvHistorial.ColumnHeadersDefaultCellStyle.ForeColor = System.Drawing.Color.White
        Me.dgvHistorial.EnableHeadersVisualStyles = False
        Dim propiedades = New String() {"IdSesion", "FechaApertura", "FechaCierre", "Estado", "MontoInicial", "MontoFinalEsperado", "MontoFinalReal", "Diferencia"}
        Dim encabezados = New String() {"Sesión", "Apertura", "Cierre", "Estado", "Inicial ($)", "Esperado ($)", "Contado ($)", "Diferencia ($)"}
        For i As Integer = 0 To propiedades.Length - 1
            Dim columna As New System.Windows.Forms.DataGridViewTextBoxColumn() With {.Name = propiedades(i), .DataPropertyName = propiedades(i), .HeaderText = encabezados(i)}
            If i = 1 OrElse i = 2 Then columna.DefaultCellStyle.Format = "dd/MM/yyyy HH:mm"
            If i >= 4 Then columna.DefaultCellStyle.Format = "N2"
            Me.dgvHistorial.Columns.Add(columna)
        Next
        Me.txtReporte.Dock = System.Windows.Forms.DockStyle.Fill
        Me.txtReporte.Multiline = True
        Me.txtReporte.ReadOnly = True
        Me.txtReporte.ScrollBars = System.Windows.Forms.ScrollBars.Vertical
        Me.txtReporte.BackColor = System.Drawing.Color.FromArgb(45, 49, 53)
        Me.txtReporte.ForeColor = System.Drawing.Color.White
        layout.Controls.Add(titulo, 0, 0)
        layout.Controls.Add(Me.lblEstado, 0, 1)
        layout.Controls.Add(operaciones, 0, 2)
        layout.Controls.Add(filtros, 0, 3)
        layout.Controls.Add(Me.dgvHistorial, 0, 4)
        layout.Controls.Add(Me.txtReporte, 0, 5)
        Me.Controls.Add(layout)
        CType(Me.nudInicial, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.nudReal, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.dgvHistorial, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
    End Sub
End Class
