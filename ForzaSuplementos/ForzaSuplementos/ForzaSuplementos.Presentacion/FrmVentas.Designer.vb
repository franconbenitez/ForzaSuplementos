<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmVentas
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
    Friend WithEvents txtClienteSeleccionado As System.Windows.Forms.TextBox
    Friend WithEvents btnBuscarCliente As System.Windows.Forms.Button
    Friend WithEvents cboMedioPago As System.Windows.Forms.ComboBox
    Friend WithEvents lblMedioPago As System.Windows.Forms.Label
    Friend WithEvents txtProductoSeleccionado As System.Windows.Forms.TextBox
    Friend WithEvents btnBuscarProducto As System.Windows.Forms.Button
    Friend WithEvents lblPrecioSeleccionado As System.Windows.Forms.Label
    Friend WithEvents txtCantidad As System.Windows.Forms.TextBox
    Friend WithEvents btnAgregar As System.Windows.Forms.Button
    Friend WithEvents btnConfirmar As System.Windows.Forms.Button
    Friend WithEvents btnCancelar As System.Windows.Forms.Button
    Friend WithEvents dgvCarrito As System.Windows.Forms.DataGridView
    Friend WithEvents lbl1, lbl2, lbl3, lblTotal As System.Windows.Forms.Label

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.PanelTop = New System.Windows.Forms.Panel()
        Me.LblTitulo = New System.Windows.Forms.Label()
        Me.txtClienteSeleccionado = New System.Windows.Forms.TextBox()
        Me.btnBuscarCliente = New System.Windows.Forms.Button()
        Me.cboMedioPago = New System.Windows.Forms.ComboBox()
        Me.lblMedioPago = New System.Windows.Forms.Label()
        Me.txtProductoSeleccionado = New System.Windows.Forms.TextBox()
        Me.btnBuscarProducto = New System.Windows.Forms.Button()
        Me.lblPrecioSeleccionado = New System.Windows.Forms.Label()
        Me.txtCantidad = New System.Windows.Forms.TextBox()
        Me.btnAgregar = New System.Windows.Forms.Button()
        Me.btnConfirmar = New System.Windows.Forms.Button()
        Me.btnCancelar = New System.Windows.Forms.Button()
        Me.dgvCarrito = New System.Windows.Forms.DataGridView()
        Me.lbl1 = New System.Windows.Forms.Label()
        Me.lbl2 = New System.Windows.Forms.Label()
        Me.lbl3 = New System.Windows.Forms.Label()
        Me.lblTotal = New System.Windows.Forms.Label()

        Me.PanelTop.SuspendLayout()
        CType(Me.dgvCarrito, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()

        ' Panel Superior
        Me.PanelTop.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.PanelTop.Controls.Add(Me.LblTitulo)
        Me.PanelTop.Dock = System.Windows.Forms.DockStyle.Top
        Me.PanelTop.Height = 50

        Me.LblTitulo.AutoSize = True
        Me.LblTitulo.ForeColor = System.Drawing.Color.White
        Me.LblTitulo.Font = New System.Drawing.Font("Segoe UI", 14.0!, System.Drawing.FontStyle.Bold)
        Me.LblTitulo.Location = New System.Drawing.Point(20, 12)
        Me.LblTitulo.Text = "GENERADOR DE VENTAS - FORZA SUPLEMENTOS"

        ' Etiquetas
        Me.lbl1.Text = "Cliente:" : Me.lbl1.Location = New System.Drawing.Point(30, 85) : Me.lbl1.AutoSize = True
        Me.lbl2.Text = "Producto:" : Me.lbl2.Location = New System.Drawing.Point(30, 130) : Me.lbl2.AutoSize = True
        Me.lbl3.Text = "Cantidad:" : Me.lbl3.Location = New System.Drawing.Point(550, 130) : Me.lbl3.AutoSize = True

        Me.lblTotal.Text = "TOTAL: $ 0.00" : Me.lblTotal.Location = New System.Drawing.Point(450, 480) : Me.lblTotal.AutoSize = False
        Me.lblTotal.Size = New System.Drawing.Size(430, 35)
        Me.lblTotal.TextAlign = System.Drawing.ContentAlignment.MiddleRight
        Me.lblTotal.Anchor = System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Right
        Me.lblTotal.Font = New System.Drawing.Font("Segoe UI", 16.0!, System.Drawing.FontStyle.Bold)
        Me.lblTotal.ForeColor = System.Drawing.Color.FromArgb(52, 168, 132)

        ' Controles
        Me.txtClienteSeleccionado.Location = New System.Drawing.Point(100, 82) : Me.txtClienteSeleccionado.Width = 600 : Me.txtClienteSeleccionado.ReadOnly = True : Me.txtClienteSeleccionado.Text = "Sin cliente seleccionado"
        Me.btnBuscarCliente.Location = New System.Drawing.Point(710, 79) : Me.btnBuscarCliente.Size = New System.Drawing.Size(170, 30) : Me.btnBuscarCliente.Text = "Buscar cliente..."
        Me.lblMedioPago.Text = "Medio de pago:"
        Me.lblMedioPago.Location = New System.Drawing.Point(30, 480)
        Me.lblMedioPago.AutoSize = True
        Me.cboMedioPago.Location = New System.Drawing.Point(130, 477)
        Me.cboMedioPago.Width = 250
        Me.cboMedioPago.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList
        Me.txtProductoSeleccionado.Location = New System.Drawing.Point(100, 127) : Me.txtProductoSeleccionado.Width = 280 : Me.txtProductoSeleccionado.ReadOnly = True : Me.txtProductoSeleccionado.Text = "Sin producto seleccionado"
        Me.btnBuscarProducto.Location = New System.Drawing.Point(390, 124) : Me.btnBuscarProducto.Size = New System.Drawing.Size(145, 30) : Me.btnBuscarProducto.Text = "Buscar producto..."
        Me.lblPrecioSeleccionado.Location = New System.Drawing.Point(100, 157) : Me.lblPrecioSeleccionado.Size = New System.Drawing.Size(780, 22) : Me.lblPrecioSeleccionado.Text = "Precio unitario: —   |   Stock disponible: —"
        Me.txtCantidad.Location = New System.Drawing.Point(620, 127) : Me.txtCantidad.Width = 60 : Me.txtCantidad.Text = "1"

        Me.btnAgregar.Location = New System.Drawing.Point(710, 124) : Me.btnAgregar.Size = New System.Drawing.Size(170, 30) : Me.btnAgregar.Text = "Agregar al Carrito" : Me.btnAgregar.BackColor = System.Drawing.Color.FromArgb(33, 37, 41) : Me.btnAgregar.ForeColor = System.Drawing.Color.White : Me.btnAgregar.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        ' Grilla Carrito
        Me.dgvCarrito.Location = New System.Drawing.Point(30, 190) : Me.dgvCarrito.Size = New System.Drawing.Size(850, 270)
        Me.dgvCarrito.ReadOnly = True : Me.dgvCarrito.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.dgvCarrito.AllowUserToAddRows = False

        ' Botones Finales
        Me.btnConfirmar.Location = New System.Drawing.Point(30, 525) : Me.btnConfirmar.Size = New System.Drawing.Size(150, 40) : Me.btnConfirmar.Text = "Confirmar Venta" : Me.btnConfirmar.BackColor = System.Drawing.Color.FromArgb(52, 168, 132) : Me.btnConfirmar.ForeColor = System.Drawing.Color.White : Me.btnConfirmar.FlatStyle = System.Windows.Forms.FlatStyle.Flat
        Me.btnCancelar.Location = New System.Drawing.Point(200, 525) : Me.btnCancelar.Size = New System.Drawing.Size(150, 40) : Me.btnCancelar.Text = "Vaciar carrito" : Me.btnCancelar.Enabled = False : Me.btnCancelar.BackColor = System.Drawing.Color.FromArgb(217, 83, 79) : Me.btnCancelar.ForeColor = System.Drawing.Color.White : Me.btnCancelar.FlatStyle = System.Windows.Forms.FlatStyle.Flat

        ' Formulario
        Me.ClientSize = New System.Drawing.Size(910, 590)
        Me.BackColor = System.Drawing.Color.FromArgb(245, 247, 246)
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Gestión de Ventas"
        Me.Font = New System.Drawing.Font("Segoe UI", 9.0!)

        Me.Controls.Add(Me.PanelTop)
        Me.Controls.Add(Me.lbl1) : Me.Controls.Add(Me.txtClienteSeleccionado) : Me.Controls.Add(Me.btnBuscarCliente)
        Me.Controls.Add(Me.lblMedioPago) : Me.Controls.Add(Me.cboMedioPago)
        Me.Controls.Add(Me.lbl2) : Me.Controls.Add(Me.txtProductoSeleccionado) : Me.Controls.Add(Me.btnBuscarProducto) : Me.Controls.Add(Me.lblPrecioSeleccionado)
        Me.Controls.Add(Me.lbl3) : Me.Controls.Add(Me.txtCantidad)
        Me.Controls.Add(Me.btnAgregar)
        Me.Controls.Add(Me.dgvCarrito)
        Me.Controls.Add(Me.lblTotal)
        Me.Controls.Add(Me.btnConfirmar) : Me.Controls.Add(Me.btnCancelar)

        Me.PanelTop.ResumeLayout(False)
        Me.PanelTop.PerformLayout()
        CType(Me.dgvCarrito, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class
