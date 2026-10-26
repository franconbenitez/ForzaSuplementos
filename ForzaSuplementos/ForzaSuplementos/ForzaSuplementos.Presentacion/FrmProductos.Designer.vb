<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmProductos
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
    Friend WithEvents txtDescripcion As System.Windows.Forms.TextBox
    Friend WithEvents txtPrecio As System.Windows.Forms.TextBox
    Friend WithEvents txtStock As System.Windows.Forms.TextBox
    Friend WithEvents cboCategoria As System.Windows.Forms.ComboBox
    Friend WithEvents btnGuardar As System.Windows.Forms.Button
    Friend WithEvents btnCancelar As System.Windows.Forms.Button
    Friend WithEvents btnBaja As System.Windows.Forms.Button
    Friend WithEvents btnReactivar As System.Windows.Forms.Button
    Friend WithEvents tabProductos As System.Windows.Forms.TabControl
    Friend WithEvents tabActivos As System.Windows.Forms.TabPage
    Friend WithEvents tabInactivos As System.Windows.Forms.TabPage
    Friend WithEvents dgvActivos As System.Windows.Forms.DataGridView
    Friend WithEvents dgvInactivos As System.Windows.Forms.DataGridView
    Friend WithEvents lbl1, lbl2, lbl3, lbl4, lbl5 As System.Windows.Forms.Label

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LblTitulo = New System.Windows.Forms.Label()
        Me.txtNombre = New System.Windows.Forms.TextBox()
        Me.txtDescripcion = New System.Windows.Forms.TextBox()
        Me.txtPrecio = New System.Windows.Forms.TextBox()
        Me.txtStock = New System.Windows.Forms.TextBox()
        Me.cboCategoria = New System.Windows.Forms.ComboBox()
        Me.btnGuardar = New System.Windows.Forms.Button()
        Me.btnCancelar = New System.Windows.Forms.Button()
        Me.btnBaja = New System.Windows.Forms.Button()
        Me.btnReactivar = New System.Windows.Forms.Button()
        Me.tabProductos = New System.Windows.Forms.TabControl()
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
        Me.tabProductos.SuspendLayout()
        Me.tabActivos.SuspendLayout()
        CType(Me.dgvActivos, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.tabInactivos.SuspendLayout()
        CType(Me.dgvInactivos, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()

        ' Panel Superior
        Me.PanelTop.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.PanelTop.Controls.Add(Me.LblTitulo)
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Height = 50

        Me.LblTitulo.AutoSize = True
        Me.LblTitulo.ForeColor = System.Drawing.Color.White
        Me.LblTitulo.Font = New System.Drawing.Font("Segoe UI", 14, System.Drawing.FontStyle.Bold)
        Me.LblTitulo.Location = New System.Drawing.Point(20, 12)
        Me.LblTitulo.Text = "ADMINISTRACION DE PRODUCTOS - FORZA SUPLEMENTOS"

        ' Etiquetas
        Me.lbl1.Text = "Nombre:" : Me.lbl1.Location = New System.Drawing.Point(30, 85) : Me.lbl1.AutoSize = True
        Me.lbl2.Text = "Categoría:" : Me.lbl2.Location = New System.Drawing.Point(30, 130) : Me.lbl2.AutoSize = True
        Me.lbl3.Text = "Descripción:" : Me.lbl3.Location = New System.Drawing.Point(350, 85) : Me.lbl3.AutoSize = True
        Me.lbl4.Text = "Precio ($):" : Me.lbl4.Location = New System.Drawing.Point(350, 175) : Me.lbl4.AutoSize = True
        Me.lbl5.Text = "Stock:" : Me.lbl5.Location = New System.Drawing.Point(680, 85) : Me.lbl5.AutoSize = True

        ' Cajas de Texto y Combos
        Me.txtNombre.Location = New System.Drawing.Point(120, 82) : Me.txtNombre.Width = 200
        Me.cboCategoria.Location = New System.Drawing.Point(120, 127) : Me.cboCategoria.Width = 200 : Me.cboCategoria.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList

        Me.txtDescripcion.Location = New System.Drawing.Point(440, 82) : Me.txtDescripcion.Width = 200 : Me.txtDescripcion.Multiline = True : Me.txtDescripcion.Height = 75
        Me.txtPrecio.Location = New System.Drawing.Point(440, 172) : Me.txtPrecio.Width = 200
        Me.txtStock.Location = New System.Drawing.Point(740, 82) : Me.txtStock.Width = 150

        ' Botones
        Me.btnGuardar.Location = New System.Drawing.Point(30, 210) : Me.btnGuardar.Size = New System.Drawing.Size(120, 35) : Me.btnGuardar.Text = "Guardar" : Me.btnGuardar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnGuardar.ForeColor = System.Drawing.Color.White : Me.btnGuardar.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnCancelar.Location = New System.Drawing.Point(160, 210) : Me.btnCancelar.Size = New System.Drawing.Size(120, 35) : Me.btnCancelar.Text = "Cancelar" : Me.btnCancelar.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnCancelar.ForeColor = System.Drawing.Color.White : Me.btnCancelar.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        Me.btnBaja.Location = New System.Drawing.Point(630, 210) : Me.btnBaja.Size = New System.Drawing.Size(130, 35) : Me.btnBaja.Text = "Dar de Baja" : Me.btnBaja.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnBaja.ForeColor = System.Drawing.Color.White : Me.btnBaja.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnReactivar.Location = New System.Drawing.Point(770, 210) : Me.btnReactivar.Size = New System.Drawing.Size(140, 35) : Me.btnReactivar.Text = "Reactivar Producto" : Me.btnReactivar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnReactivar.ForeColor = System.Drawing.Color.White : Me.btnReactivar.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        ' Grillas y Pestañas
        Me.tabProductos.Location = New System.Drawing.Point(30, 270) : Me.tabProductos.Size = New System.Drawing.Size(920, 320)
        Me.tabProductos.Controls.Add(Me.tabActivos)
        Me.tabProductos.Controls.Add(Me.tabInactivos)

        Me.tabActivos.Text = "Productos Activos" : Me.tabActivos.Controls.Add(Me.dgvActivos)
        Me.dgvActivos.Dock = System.Windows.Forms.DockStyle.Fill : Me.dgvActivos.ReadOnly = True : Me.dgvActivos.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect

        Me.tabInactivos.Text = "Productos Inactivos" : Me.tabInactivos.Controls.Add(Me.dgvInactivos)
        Me.dgvInactivos.Dock = System.Windows.Forms.DockStyle.Fill : Me.dgvInactivos.ReadOnly = True : Me.dgvInactivos.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect

        ' Configuración Formulario
        Me.ClientSize = New System.Drawing.Size(980, 620)
        Me.BackColor = System.Drawing.Color.FromArgb(245, 247, 246)
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Forza Suplementos - Gestión de Productos"
        Me.Font = New System.Drawing.Font("Segoe UI", 9)

        Me.Controls.Add(Me.PanelTop)
        Me.Controls.Add(Me.lbl1) : Me.Controls.Add(Me.txtNombre)
        Me.Controls.Add(Me.lbl2) : Me.Controls.Add(Me.cboCategoria)
        Me.Controls.Add(Me.lbl3) : Me.Controls.Add(Me.txtDescripcion)
        Me.Controls.Add(Me.lbl4) : Me.Controls.Add(Me.txtPrecio)
        Me.Controls.Add(Me.lbl5) : Me.Controls.Add(Me.txtStock)
        Me.Controls.Add(Me.btnGuardar) : Me.Controls.Add(Me.btnCancelar) : Me.Controls.Add(Me.btnBaja) : Me.Controls.Add(Me.btnReactivar)
        Me.Controls.Add(Me.tabProductos)

        Me.PanelTop.ResumeLayout(False)
        Me.PanelTop.PerformLayout()
        Me.tabProductos.ResumeLayout(False)
        Me.tabActivos.ResumeLayout(False)
        CType(Me.dgvActivos, System.ComponentModel.ISupportInitialize).EndInit()
        Me.tabInactivos.ResumeLayout(False)
        CType(Me.dgvInactivos, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class