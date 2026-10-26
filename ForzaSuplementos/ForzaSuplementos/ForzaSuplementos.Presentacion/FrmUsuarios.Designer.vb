<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmUsuarios
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
    Friend WithEvents txtNombre As System.Windows.Forms.TextBox
    Friend WithEvents txtApellido As System.Windows.Forms.TextBox
    Friend WithEvents txtUsuario As System.Windows.Forms.TextBox
    Friend WithEvents txtContrasena As System.Windows.Forms.TextBox
    Friend WithEvents txtEmail As System.Windows.Forms.TextBox
    Friend WithEvents txtDni As System.Windows.Forms.TextBox
    Friend WithEvents txtCalle As System.Windows.Forms.TextBox
    Friend WithEvents txtAltura As System.Windows.Forms.TextBox
    Friend WithEvents txtTelefono As System.Windows.Forms.TextBox
    Friend WithEvents cboPerfil As System.Windows.Forms.ComboBox
    Friend WithEvents dtpFechaNac As System.Windows.Forms.DateTimePicker
    Friend WithEvents rbHombre As System.Windows.Forms.RadioButton
    Friend WithEvents rbMujer As System.Windows.Forms.RadioButton
    Friend WithEvents btnGuardar As System.Windows.Forms.Button
    Friend WithEvents btnCancelar As System.Windows.Forms.Button
    Friend WithEvents btnBaja As System.Windows.Forms.Button
    Friend WithEvents btnReactivar As System.Windows.Forms.Button
    Friend WithEvents tabUsuarios As System.Windows.Forms.TabControl
    Friend WithEvents tabActivos As System.Windows.Forms.TabPage
    Friend WithEvents tabInactivos As System.Windows.Forms.TabPage
    Friend WithEvents dgvActivos As System.Windows.Forms.DataGridView
    Friend WithEvents dgvInactivos As System.Windows.Forms.DataGridView
    Friend WithEvents lbl1, lbl2, lbl3, lbl4, lbl5, lbl6, lbl7, lblAltura, lbl8, lbl9, lbl10, lbl11 As System.Windows.Forms.Label

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LblTitulo = New System.Windows.Forms.Label()
        Me.txtNombre = New System.Windows.Forms.TextBox()
        Me.txtApellido = New System.Windows.Forms.TextBox()
        Me.txtUsuario = New System.Windows.Forms.TextBox()
        Me.txtContrasena = New System.Windows.Forms.TextBox()
        Me.txtEmail = New System.Windows.Forms.TextBox()
        Me.txtDni = New System.Windows.Forms.TextBox()
        Me.txtCalle = New System.Windows.Forms.TextBox()
        Me.txtAltura = New System.Windows.Forms.TextBox()
        Me.txtTelefono = New System.Windows.Forms.TextBox()
        Me.cboPerfil = New System.Windows.Forms.ComboBox()
        Me.dtpFechaNac = New System.Windows.Forms.DateTimePicker()
        Me.rbHombre = New System.Windows.Forms.RadioButton()
        Me.rbMujer = New System.Windows.Forms.RadioButton()
        Me.btnGuardar = New System.Windows.Forms.Button()
        Me.btnCancelar = New System.Windows.Forms.Button()
        Me.btnBaja = New System.Windows.Forms.Button()
        Me.btnReactivar = New System.Windows.Forms.Button()
        Me.tabUsuarios = New System.Windows.Forms.TabControl()
        Me.tabActivos = New System.Windows.Forms.TabPage()
        Me.dgvActivos = New System.Windows.Forms.DataGridView()
        Me.tabInactivos = New System.Windows.Forms.TabPage()
        Me.dgvInactivos = New System.Windows.Forms.DataGridView()
        Me.lbl1 = New System.Windows.Forms.Label()
        Me.lbl2 = New System.Windows.Forms.Label()
        Me.lbl3 = New System.Windows.Forms.Label()
        Me.lbl4 = New System.Windows.Forms.Label()
        Me.lbl5 = New System.Windows.Forms.Label()
        Me.lbl6 = New System.Windows.Forms.Label()
        Me.lbl7 = New System.Windows.Forms.Label()
        Me.lblAltura = New System.Windows.Forms.Label()
        Me.lbl8 = New System.Windows.Forms.Label()
        Me.lbl9 = New System.Windows.Forms.Label()
        Me.lbl10 = New System.Windows.Forms.Label()
        Me.lbl11 = New System.Windows.Forms.Label()

        Me.PanelTop.SuspendLayout()
        Me.tabUsuarios.SuspendLayout()
        Me.tabActivos.SuspendLayout()
        CType(Me.dgvActivos, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.tabInactivos.SuspendLayout()
        CType(Me.dgvInactivos, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()

        Me.PanelTop.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.PanelTop.Controls.Add(Me.LblTitulo)
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Height = 50

        Me.LblTitulo.AutoSize = True
        Me.LblTitulo.ForeColor = System.Drawing.Color.White
        Me.LblTitulo.Font = New System.Drawing.Font("Segoe UI", 14, System.Drawing.FontStyle.Bold)
        Me.LblTitulo.Location = New System.Drawing.Point(20, 12)
        Me.LblTitulo.Text = "ADMINISTRACION DE USUARIOS - FORZA SUPLEMENTOS"

        Me.lbl1.Text = "Nombre:" : Me.lbl1.Location = New System.Drawing.Point(30, 80) : Me.lbl1.AutoSize = True
        Me.lbl2.Text = "Apellido:" : Me.lbl2.Location = New System.Drawing.Point(30, 120) : Me.lbl2.AutoSize = True
        Me.lbl3.Text = "Usuario:" : Me.lbl3.Location = New System.Drawing.Point(30, 160) : Me.lbl3.AutoSize = True
        Me.lbl4.Text = "Contraseña:" : Me.lbl4.Location = New System.Drawing.Point(30, 200) : Me.lbl4.AutoSize = True
        Me.lbl5.Text = "Email:" : Me.lbl5.Location = New System.Drawing.Point(320, 80) : Me.lbl5.AutoSize = True
        Me.lbl6.Text = "DNI:" : Me.lbl6.Location = New System.Drawing.Point(320, 120) : Me.lbl6.AutoSize = True
        Me.lbl7.Text = "Calle:" : Me.lbl7.Location = New System.Drawing.Point(320, 160) : Me.lbl7.AutoSize = True
        Me.lblAltura.Text = "Altura:" : Me.lblAltura.Location = New System.Drawing.Point(320, 200) : Me.lblAltura.AutoSize = True
        Me.lbl8.Text = "Teléfono:" : Me.lbl8.Location = New System.Drawing.Point(600, 80) : Me.lbl8.AutoSize = True
        Me.lbl9.Text = "Nacimiento:" : Me.lbl9.Location = New System.Drawing.Point(600, 120) : Me.lbl9.AutoSize = True
        Me.lbl10.Text = "Perfil/Rol:" : Me.lbl10.Location = New System.Drawing.Point(600, 160) : Me.lbl10.AutoSize = True
        Me.lbl11.Text = "Sexo:" : Me.lbl11.Location = New System.Drawing.Point(600, 200) : Me.lbl11.AutoSize = True

        Me.txtNombre.Location = New System.Drawing.Point(110, 77) : Me.txtNombre.Width = 180
        Me.txtApellido.Location = New System.Drawing.Point(110, 117) : Me.txtApellido.Width = 180
        Me.txtUsuario.Location = New System.Drawing.Point(110, 157) : Me.txtUsuario.Width = 180
        Me.txtContrasena.Location = New System.Drawing.Point(110, 197) : Me.txtContrasena.Width = 180 : Me.txtContrasena.PasswordChar = "*"c
        Me.txtEmail.Location = New System.Drawing.Point(390, 77) : Me.txtEmail.Width = 180
        Me.txtDni.Location = New System.Drawing.Point(390, 117) : Me.txtDni.Width = 180
        Me.txtCalle.Location = New System.Drawing.Point(390, 157) : Me.txtCalle.Width = 180
        Me.txtAltura.Location = New System.Drawing.Point(390, 197) : Me.txtAltura.Width = 180
        Me.txtTelefono.Location = New System.Drawing.Point(680, 77) : Me.txtTelefono.Width = 180
        Me.dtpFechaNac.Location = New System.Drawing.Point(680, 117) : Me.dtpFechaNac.Width = 180 : Me.dtpFechaNac.Format = System.Windows.Forms.DateTimePickerFormat.Short
        Me.cboPerfil.Location = New System.Drawing.Point(680, 157) : Me.cboPerfil.Width = 180 : Me.cboPerfil.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList
        Me.rbHombre.Location = New System.Drawing.Point(680, 197) : Me.rbHombre.Text = "Hombre" : Me.rbHombre.Checked = True : Me.rbHombre.Width = 80
        Me.rbMujer.Location = New System.Drawing.Point(760, 197) : Me.rbMujer.Text = "Mujer" : Me.rbMujer.Width = 80

        Me.btnGuardar.Location = New System.Drawing.Point(30, 240) : Me.btnGuardar.Size = New System.Drawing.Size(120, 35) : Me.btnGuardar.Text = "Guardar" : Me.btnGuardar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnGuardar.ForeColor = System.Drawing.Color.White : Me.btnGuardar.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnCancelar.Location = New System.Drawing.Point(160, 240) : Me.btnCancelar.Size = New System.Drawing.Size(120, 35) : Me.btnCancelar.Text = "Cancelar" : Me.btnCancelar.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnCancelar.ForeColor = System.Drawing.Color.White : Me.btnCancelar.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnBaja.Location = New System.Drawing.Point(580, 240) : Me.btnBaja.Size = New System.Drawing.Size(130, 35) : Me.btnBaja.Text = "Dar de Baja" : Me.btnBaja.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnBaja.ForeColor = System.Drawing.Color.White : Me.btnBaja.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnReactivar.Location = New System.Drawing.Point(720, 240) : Me.btnReactivar.Size = New System.Drawing.Size(140, 35) : Me.btnReactivar.Text = "Reactivar Usuario" : Me.btnReactivar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnReactivar.ForeColor = System.Drawing.Color.White : Me.btnReactivar.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        Me.tabUsuarios.Location = New System.Drawing.Point(30, 300) : Me.tabUsuarios.Size = New System.Drawing.Size(920, 300)
        Me.tabUsuarios.Controls.Add(Me.tabActivos)
        Me.tabUsuarios.Controls.Add(Me.tabInactivos)

        Me.tabActivos.Text = "Activos" : Me.tabActivos.Controls.Add(Me.dgvActivos)
        Me.dgvActivos.Dock = System.Windows.Forms.DockStyle.Fill : Me.dgvActivos.ReadOnly = True : Me.dgvActivos.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.tabInactivos.Text = "Inactivos" : Me.tabInactivos.Controls.Add(Me.dgvInactivos)
        Me.dgvInactivos.Dock = System.Windows.Forms.DockStyle.Fill : Me.dgvInactivos.ReadOnly = True : Me.dgvInactivos.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect

        Me.ClientSize = New System.Drawing.Size(980, 630)
        Me.BackColor = System.Drawing.Color.FromArgb(245, 247, 246)
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Forza Suplementos - Gestión de Usuarios"
        Me.Font = New System.Drawing.Font("Segoe UI", 9)

        Me.Controls.Add(Me.PanelTop)
        Me.Controls.Add(Me.lbl1) : Me.Controls.Add(Me.txtNombre)
        Me.Controls.Add(Me.lbl2) : Me.Controls.Add(Me.txtApellido)
        Me.Controls.Add(Me.lbl3) : Me.Controls.Add(Me.txtUsuario)
        Me.Controls.Add(Me.lbl4) : Me.Controls.Add(Me.txtContrasena)
        Me.Controls.Add(Me.lbl5) : Me.Controls.Add(Me.txtEmail)
        Me.Controls.Add(Me.lbl6) : Me.Controls.Add(Me.txtDni)
        Me.Controls.Add(Me.lbl7) : Me.Controls.Add(Me.txtCalle)
        Me.Controls.Add(Me.lblAltura) : Me.Controls.Add(Me.txtAltura)
        Me.Controls.Add(Me.lbl8) : Me.Controls.Add(Me.txtTelefono)
        Me.Controls.Add(Me.lbl9) : Me.Controls.Add(Me.dtpFechaNac)
        Me.Controls.Add(Me.lbl10) : Me.Controls.Add(Me.cboPerfil)
        Me.Controls.Add(Me.lbl11) : Me.Controls.Add(Me.rbHombre) : Me.Controls.Add(Me.rbMujer)
        Me.Controls.Add(Me.btnGuardar) : Me.Controls.Add(Me.btnCancelar) : Me.Controls.Add(Me.btnBaja) : Me.Controls.Add(Me.btnReactivar)
        Me.Controls.Add(Me.tabUsuarios)

        Me.PanelTop.ResumeLayout(False)
        Me.PanelTop.PerformLayout()
        Me.tabUsuarios.ResumeLayout(False)
        Me.tabActivos.ResumeLayout(False)
        CType(Me.dgvActivos, System.ComponentModel.ISupportInitialize).EndInit()
        Me.tabInactivos.ResumeLayout(False)
        CType(Me.dgvInactivos, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class