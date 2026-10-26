<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmBackup
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
    Friend WithEvents lblInfo As System.Windows.Forms.Label
    Friend WithEvents txtRuta As System.Windows.Forms.TextBox
    Friend WithEvents btnExaminar As System.Windows.Forms.Button
    Friend WithEvents btnGenerar As System.Windows.Forms.Button

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LblTitulo = New System.Windows.Forms.Label()
        Me.lblInfo = New System.Windows.Forms.Label()
        Me.txtRuta = New System.Windows.Forms.TextBox()
        Me.btnExaminar = New System.Windows.Forms.Button()
        Me.btnGenerar = New System.Windows.Forms.Button()

        Me.PanelTop.SuspendLayout()
        Me.SuspendLayout()

        ' Panel Superior
        Me.PanelTop.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.PanelTop.Controls.Add(Me.LblTitulo)
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Height = 50

        Me.LblTitulo.AutoSize = True
        Me.LblTitulo.ForeColor = System.Drawing.Color.White
        Me.LblTitulo.Font = New System.Drawing.Font("Segoe UI", 12.0!, System.Drawing.FontStyle.Bold)
        Me.LblTitulo.Location = New System.Drawing.Point(20, 14)
        Me.LblTitulo.Text = "COPIA DE SEGURIDAD (BACKUP)"

        ' Controles Centrales
        Me.lblInfo.Text = "Seleccioná la carpeta donde querés guardar el archivo de respaldo de la base de datos:"
        Me.lblInfo.Location = New System.Drawing.Point(40, 90) : Me.lblInfo.AutoSize = True : Me.lblInfo.Font = New System.Drawing.Font("Segoe UI", 10.0!)

        Me.txtRuta.Location = New System.Drawing.Point(40, 125) : Me.txtRuta.Width = 380 : Me.txtRuta.ReadOnly = True

        Me.btnExaminar.Location = New System.Drawing.Point(430, 124) : Me.btnExaminar.Size = New System.Drawing.Size(100, 25)
        Me.btnExaminar.Text = "Examinar..." : Me.btnExaminar.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnExaminar.ForeColor = System.Drawing.Color.White : Me.btnExaminar.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        Me.btnGenerar.Location = New System.Drawing.Point(180, 190) : Me.btnGenerar.Size = New System.Drawing.Size(200, 45)
        Me.btnGenerar.Text = "GENERAR RESPALDO" : Me.btnGenerar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnGenerar.ForeColor = System.Drawing.Color.White : Me.btnGenerar.FlatStyle = System.Windows.Forms.FlatStyle.Flat : Me.btnGenerar.Font = New System.Drawing.Font("Segoe UI", 10.0!, System.Drawing.FontStyle.Bold)

        ' Formulario
        Me.ClientSize = New System.Drawing.Size(580, 280)
        Me.BackColor = System.Drawing.Color.FromArgb(245, 247, 246)
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog
        Me.MaximizeBox = False
        Me.Text = "Respaldo del Sistema"
        Me.Font = New System.Drawing.Font("Segoe UI", 9.0!)

        Me.Controls.Add(Me.PanelTop)
        Me.Controls.Add(Me.lblInfo)
        Me.Controls.Add(Me.txtRuta)
        Me.Controls.Add(Me.btnExaminar)
        Me.Controls.Add(Me.btnGenerar)

        Me.PanelTop.ResumeLayout(False)
        Me.PanelTop.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class