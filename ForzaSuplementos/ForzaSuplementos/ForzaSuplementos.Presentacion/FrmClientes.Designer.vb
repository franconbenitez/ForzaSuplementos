<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmClientes
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
    Friend WithEvents txtDni, txtNombre, txtApellido, txtTelefono, txtEmail As System.Windows.Forms.TextBox
    Friend WithEvents btnGuardar, btnCancelar, btnBaja, btnReactivar As System.Windows.Forms.Button
    Friend WithEvents tabClientes As System.Windows.Forms.TabControl
    Friend WithEvents tabActivos, tabInactivos As System.Windows.Forms.TabPage
    Friend WithEvents dgvActivos, dgvInactivos As System.Windows.Forms.DataGridView
    Friend WithEvents lbl1, lbl2, lbl3, lbl4, lbl5 As System.Windows.Forms.Label

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LblTitulo = New System.Windows.Forms.Label()
        Me.txtDni = New System.Windows.Forms.TextBox()
        Me.txtNombre = New System.Windows.Forms.TextBox()
        Me.txtApellido = New System.Windows.Forms.TextBox()
        Me.txtTelefono = New System.Windows.Forms.TextBox()
        Me.txtEmail = New System.Windows.Forms.TextBox()
        Me.btnGuardar = New System.Windows.Forms.Button()
        Me.btnCancelar = New System.Windows.Forms.Button()
        Me.btnBaja = New System.Windows.Forms.Button()
        Me.btnReactivar = New System.Windows.Forms.Button()
        Me.tabClientes = New System.Windows.Forms.TabControl()
        Me.tabActivos = New System.Windows.Forms.TabPage()
        Me.dgvActivos = New System.Windows.Forms.DataGridView()
        Me.tabInactivos = New System.Windows.Forms.TabPage()
        Me.dgvInactivos = New System.Windows.Forms.DataGridView()
        Me.lbl1 = New System.Windows.Forms.Label()
        Me.lbl2 = New System.Windows.Forms.Label()
        Me.lbl3 = New System.Windows.Forms.Label()
        Me.lbl4 = New System.Windows.Forms.Label()
        Me.lbl5 = New System.Windows.Forms.Label()

        Me.PanelTop.SuspendLayout()
        Me.tabClientes.SuspendLayout()
        Me.tabActivos.SuspendLayout()
        CType(Me.dgvActivos, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.tabInactivos.SuspendLayout()
        CType(Me.dgvInactivos, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()

        ' Panel Top
        Me.PanelTop.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.PanelTop.Controls.Add(Me.LblTitulo)
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Height = 50

        Me.LblTitulo.AutoSize = True
        Me.LblTitulo.ForeColor = System.Drawing.Color.White
        Me.LblTitulo.Font = New System.Drawing.Font("Segoe UI", 14, System.Drawing.FontStyle.Bold)
        Me.LblTitulo.Location = New System.Drawing.Point(20, 12)
        Me.LblTitulo.Text = "DIRECTORIO DE CLIENTES - FORZA SUPLEMENTOS"

        ' Labels
        Me.lbl1.Text = "DNI:" : Me.lbl1.Location = New System.Drawing.Point(30, 85) : Me.lbl1.AutoSize = True
        Me.lbl2.Text = "Nombre:" : Me.lbl2.Location = New System.Drawing.Point(30, 130) : Me.lbl2.AutoSize = True
        Me.lbl3.Text = "Apellido:" : Me.lbl3.Location = New System.Drawing.Point(350, 85) : Me.lbl3.AutoSize = True
        Me.lbl4.Text = "Teléfono:" : Me.lbl4.Location = New System.Drawing.Point(350, 130) : Me.lbl4.AutoSize = True
        Me.lbl5.Text = "E-mail:" : Me.lbl5.Location = New System.Drawing.Point(680, 85) : Me.lbl5.AutoSize = True

        ' Textboxes
        Me.txtDni.Location = New System.Drawing.Point(100, 82) : Me.txtDni.Width = 180
        Me.txtNombre.Location = New System.Drawing.Point(100, 127) : Me.txtNombre.Width = 180
        Me.txtApellido.Location = New System.Drawing.Point(420, 82) : Me.txtApellido.Width = 180
        Me.txtTelefono.Location = New System.Drawing.Point(420, 127) : Me.txtTelefono.Width = 180
        Me.txtEmail.Location = New System.Drawing.Point(740, 82) : Me.txtEmail.Width = 190

        ' Botones Flat
        Me.btnGuardar.Location = New System.Drawing.Point(30, 190) : Me.btnGuardar.Size = New System.Drawing.Size(120, 35) : Me.btnGuardar.Text = "Guardar" : Me.btnGuardar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnGuardar.ForeColor = System.Drawing.Color.White : Me.btnGuardar.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnCancelar.Location = New System.Drawing.Point(160, 190) : Me.btnCancelar.Size = New System.Drawing.Size(120, 35) : Me.btnCancelar.Text = "Cancelar" : Me.btnCancelar.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnCancelar.ForeColor = System.Drawing.Color.White : Me.btnCancelar.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        Me.btnBaja.Location = New System.Drawing.Point(650, 190) : Me.btnBaja.Size = New System.Drawing.Size(130, 35) : Me.btnBaja.Text = "Dar de Baja" : Me.btnBaja.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnBaja.ForeColor = System.Drawing.Color.White : Me.btnBaja.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnReactivar.Location = New System.Drawing.Point(790, 190) : Me.btnReactivar.Size = New System.Drawing.Size(140, 35) : Me.btnReactivar.Text = "Reactivar" : Me.btnReactivar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnReactivar.ForeColor = System.Drawing.Color.White : Me.btnReactivar.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        ' Grillas
        Me.tabClientes.Location = New System.Drawing.Point(30, 250) : Me.tabClientes.Size = New System.Drawing.Size(900, 320)
        Me.tabClientes.Controls.Add(Me.tabActivos)
        Me.tabClientes.Controls.Add(Me.tabInactivos)

        Me.tabActivos.Text = "Clientes Activos" : Me.tabActivos.Controls.Add(Me.dgvActivos)
        Me.dgvActivos.Dock = System.Windows.Forms.DockStyle.Fill : Me.dgvActivos.ReadOnly = True : Me.dgvActivos.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect

        Me.tabInactivos.Text = "Clientes Inactivos" : Me.tabInactivos.Controls.Add(Me.dgvInactivos)
        Me.dgvInactivos.Dock = System.Windows.Forms.DockStyle.Fill : Me.dgvInactivos.ReadOnly = True : Me.dgvInactivos.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect

        ' Config Form
        Me.ClientSize = New System.Drawing.Size(960, 600)
        Me.BackColor = System.Drawing.Color.FromArgb(245, 247, 246)
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Gestión de Clientes"
        Me.Font = New System.Drawing.Font("Segoe UI", 9)

        Me.Controls.Add(Me.PanelTop)
        Me.Controls.Add(Me.lbl1) : Me.Controls.Add(Me.txtDni)
        Me.Controls.Add(Me.lbl2) : Me.Controls.Add(Me.txtNombre)
        Me.Controls.Add(Me.lbl3) : Me.Controls.Add(Me.txtApellido)
        Me.Controls.Add(Me.lbl4) : Me.Controls.Add(Me.txtTelefono)
        Me.Controls.Add(Me.lbl5) : Me.Controls.Add(Me.txtEmail)
        Me.Controls.Add(Me.btnGuardar) : Me.Controls.Add(Me.btnCancelar) : Me.Controls.Add(Me.btnBaja) : Me.Controls.Add(Me.btnReactivar)
        Me.Controls.Add(Me.tabClientes)

        Me.PanelTop.ResumeLayout(False)
        Me.PanelTop.PerformLayout()
        Me.tabClientes.ResumeLayout(False)
        Me.tabActivos.ResumeLayout(False)
        CType(Me.dgvActivos, System.ComponentModel.ISupportInitialize).EndInit()
        Me.tabInactivos.ResumeLayout(False)
        CType(Me.dgvInactivos, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class