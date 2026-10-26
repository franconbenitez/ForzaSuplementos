<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmReportes
    Inherits System.Windows.Forms.Form

    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
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

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LblTitulo = New System.Windows.Forms.Label()
        Me.btnHistorial = New System.Windows.Forms.Button()
        Me.btnBajoStock = New System.Windows.Forms.Button()
        Me.btnMisVentas = New System.Windows.Forms.Button()
        Me.dgvReportes = New System.Windows.Forms.DataGridView()

        Me.PanelTop.SuspendLayout()
        CType(Me.dgvReportes, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()

        ' Panel Superior
        Me.PanelTop.BackColor = System.Drawing.Color.FromArgb(52, 168, 132)
        Me.PanelTop.Controls.Add(Me.LblTitulo)
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Height = 50

        Me.LblTitulo.AutoSize = True
        Me.LblTitulo.ForeColor = System.Drawing.Color.White
        Me.LblTitulo.Font = New System.Drawing.Font("Segoe UI", 14.0!, System.Drawing.FontStyle.Bold)
        Me.LblTitulo.Location = New System.Drawing.Point(20, 12)
        Me.LblTitulo.Text = "REPORTES Y ESTADÍSTICAS - FORZA SUPLEMENTOS"

        ' Botones
        Me.btnHistorial.Location = New System.Drawing.Point(30, 70) : Me.btnHistorial.Size = New System.Drawing.Size(200, 40) : Me.btnHistorial.Text = "Historial General de Ventas" : Me.btnHistorial.BackColor = System.Drawing.Color.FromArgb(33, 37, 41) : Me.btnHistorial.ForeColor = System.Drawing.Color.White : Me.btnHistorial.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        Me.btnBajoStock.Location = New System.Drawing.Point(240, 70) : Me.btnBajoStock.Size = New System.Drawing.Size(200, 40) : Me.btnBajoStock.Text = "Alerta: Bajo Stock" : Me.btnBajoStock.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnBajoStock.ForeColor = System.Drawing.Color.White : Me.btnBajoStock.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        Me.btnMisVentas.Location = New System.Drawing.Point(30, 70) : Me.btnMisVentas.Size = New System.Drawing.Size(200, 40) : Me.btnMisVentas.Text = "Mis Ventas Mensuales" : Me.btnMisVentas.BackColor = System.Drawing.Color.FromArgb(33, 37, 41) : Me.btnMisVentas.ForeColor = System.Drawing.Color.White : Me.btnMisVentas.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        ' Grilla de Datos
        Me.dgvReportes.Location = New System.Drawing.Point(30, 130) : Me.dgvReportes.Size = New System.Drawing.Size(850, 400)
        Me.dgvReportes.ReadOnly = True : Me.dgvReportes.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dgvReportes.AllowUserToAddRows = False : Me.dgvReportes.AutoSizeColumnsMode = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill

        ' Formulario
        Me.ClientSize = New System.Drawing.Size(910, 560)
        Me.BackColor = System.Drawing.Color.FromArgb(245, 247, 246)
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Reportes"
        Me.Font = New System.Drawing.Font("Segoe UI", 9.0!)

        Me.Controls.Add(Me.PanelTop)
        Me.Controls.Add(Me.btnHistorial)
        Me.Controls.Add(Me.btnBajoStock)
        Me.Controls.Add(Me.btnMisVentas)
        Me.Controls.Add(Me.dgvReportes)

        Me.PanelTop.ResumeLayout(False)
        Me.PanelTop.PerformLayout()
        CType(Me.dgvReportes, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class