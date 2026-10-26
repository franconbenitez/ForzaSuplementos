<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmLogin
    Inherits System.Windows.Forms.Form

    <System.Diagnostics.DebuggerNonUserCode()>
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    Private components As System.ComponentModel.IContainer
    Friend WithEvents PanelTop As System.Windows.Forms.Panel
    Friend WithEvents LblTitulo As System.Windows.Forms.Label
    Friend WithEvents lbl1 As System.Windows.Forms.Label
    Friend WithEvents lbl2 As System.Windows.Forms.Label
    Friend WithEvents txtUsuario As System.Windows.Forms.TextBox
    Friend WithEvents txtContrasena As System.Windows.Forms.TextBox
    Friend WithEvents btnIngresar As System.Windows.Forms.Button
    Friend WithEvents btnSalir As System.Windows.Forms.Button

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LblTitulo = New System.Windows.Forms.Label()
        Me.lbl1 = New System.Windows.Forms.Label()
        Me.lbl2 = New System.Windows.Forms.Label()
        Me.txtUsuario = New System.Windows.Forms.TextBox()
        Me.txtContrasena = New System.Windows.Forms.TextBox()
        Me.btnIngresar = New System.Windows.Forms.Button()
        Me.btnSalir = New System.Windows.Forms.Button()
        Me.PanelTop.SuspendLayout()
        Me.SuspendLayout()

        ' Panel Superior
        Me.PanelTop.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.PanelTop.Controls.Add(Me.LblTitulo)
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Height = 50

        ' Título
        Me.LblTitulo.AutoSize = True
        Me.LblTitulo.ForeColor = System.Drawing.Color.White
        Me.LblTitulo.Font = New System.Drawing.Font("Segoe UI", 12.0!, System.Drawing.FontStyle.Bold)
        Me.LblTitulo.Location = New System.Drawing.Point(75, 14)
        Me.LblTitulo.Text = "FORZA SUPLEMENTOS - LOGIN"

        ' Labels
        Me.lbl1.Text = "Usuario:" : Me.lbl1.Location = New System.Drawing.Point(50, 90) : Me.lbl1.AutoSize = True
        Me.lbl2.Text = "Contraseña:" : Me.lbl2.Location = New System.Drawing.Point(50, 140) : Me.lbl2.AutoSize = True

        ' TextBoxes
        Me.txtUsuario.Location = New System.Drawing.Point(140, 87) : Me.txtUsuario.Width = 180
        Me.txtContrasena.Location = New System.Drawing.Point(140, 137) : Me.txtContrasena.Width = 180 : Me.txtContrasena.PasswordChar = "*"c

        ' Botones
        Me.btnIngresar.Location = New System.Drawing.Point(50, 200) : Me.btnIngresar.Size = New System.Drawing.Size(120, 35) : Me.btnIngresar.Text = "Ingresar" : Me.btnIngresar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnIngresar.ForeColor = System.Drawing.Color.White : Me.btnIngresar.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnSalir.Location = New System.Drawing.Point(200, 200) : Me.btnSalir.Size = New System.Drawing.Size(120, 35) : Me.btnSalir.Text = "Salir" : Me.btnSalir.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnSalir.ForeColor = System.Drawing.Color.White : Me.btnSalir.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        ' FrmLogin
        Me.ClientSize = New System.Drawing.Size(380, 270)
        Me.BackColor = System.Drawing.Color.FromArgb(245, 247, 246)
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog
        Me.MaximizeBox = False
        Me.Text = "Iniciar Sesión"
        Me.Font = New System.Drawing.Font("Segoe UI", 9.0!)

        Me.Controls.Add(Me.PanelTop)
        Me.Controls.Add(Me.lbl1) : Me.Controls.Add(Me.txtUsuario)
        Me.Controls.Add(Me.lbl2) : Me.Controls.Add(Me.txtContrasena)
        Me.Controls.Add(Me.btnIngresar) : Me.Controls.Add(Me.btnSalir)

        Me.PanelTop.ResumeLayout(False)
        Me.PanelTop.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class