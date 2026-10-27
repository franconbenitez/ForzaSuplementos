Imports System.ComponentModel
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmVentas
    Private ReadOnly _clienteBLL As New ClienteBLL()
    Private ReadOnly _productoBLL As New ProductoBLL()
    Private ReadOnly _ventaBLL As New VentaBLL()

    Private _carrito As New BindingList(Of DetalleVenta)()
    Public UsuarioActualId As Integer = 0 ' Este valor lo inyecta el menú principal
    Public Property UsuarioActual As Usuario

    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
        AddHandler _carrito.ListChanged, AddressOf CarritoCambiado
        ActualizarTotal()
    End Sub

    Private Sub CarritoCambiado(sender As Object, e As ListChangedEventArgs)
        ActualizarTotal()
    End Sub

    Private Sub FrmVentas_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        Try
            CajaBLL.ValidarVendedor(UsuarioActual)
            CargarCombos()
            cboMedioPago.DataSource = New String() {"Seleccionar medio de pago", "Efectivo", "Transferencia", "Tarjeta"}
        Catch ex As Exception
            btnConfirmar.Enabled = False
            MessageBox.Show(ex.Message, "Ventas", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        End Try
        dgvCarrito.DataSource = _carrito
        ConfigurarGrilla()
    End Sub

    Private Sub CargarCombos()
        cboCliente.DataSource = _clienteBLL.ObtenerClientes(True)
        cboCliente.DisplayMember = "Nombre"
        cboCliente.ValueMember = "IdCliente"
        cboCliente.SelectedIndex = -1

        cboProducto.DataSource = _productoBLL.ObtenerProductos(True)
        cboProducto.DisplayMember = "Nombre"
        cboProducto.ValueMember = "IdProducto"
        cboProducto.SelectedIndex = -1
    End Sub

    Private Sub ConfigurarGrilla()
        If dgvCarrito.Columns.Count > 0 Then
            dgvCarrito.Columns("IdProducto").Visible = False
            dgvCarrito.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        End If
    End Sub

    Private Sub btnAgregar_Click(sender As Object, e As EventArgs) Handles btnAgregar.Click
        If cboProducto.SelectedItem Is Nothing Then
            MessageBox.Show("Seleccioná un producto del catálogo.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Dim cantidad As Integer
        If Not Integer.TryParse(txtCantidad.Text, cantidad) OrElse cantidad <= 0 Then
            MessageBox.Show("Ingresá una cantidad numérica mayor a 0.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Dim prodSel = CType(cboProducto.SelectedItem, Producto)

        ' Validar stock inicial
        If cantidad > prodSel.Stock Then
            MessageBox.Show($"Stock insuficiente. Solo quedan {prodSel.Stock} unidades.", "Sin Stock", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        ' Buscar si el producto ya está en el carrito para sumar la cantidad
        Dim itemExistente = _carrito.FirstOrDefault(Function(d) d.IdProducto = prodSel.IdProducto)

        If itemExistente IsNot Nothing Then
            If itemExistente.Cantidad + cantidad > prodSel.Stock Then
                MessageBox.Show("La cantidad acumulada en el carrito supera el stock físico disponible.", "Stock Límite", MessageBoxButtons.OK, MessageBoxIcon.Warning)
                Return
            End If
            itemExistente.Cantidad += cantidad
            itemExistente.CalcularSubtotal()
        Else
            Dim nuevoDetalle As New DetalleVenta() With {
                .IdProducto = prodSel.IdProducto,
                .NombreProducto = prodSel.Nombre,
                .Cantidad = cantidad,
                .PrecioUnitario = prodSel.Precio
            }
            nuevoDetalle.CalcularSubtotal()
            _carrito.Add(nuevoDetalle)
        End If

        _carrito.ResetBindings()
        ActualizarTotal()

        txtCantidad.Text = "1"
        cboProducto.SelectedIndex = -1
    End Sub

    Private Sub ActualizarTotal()
        Dim total As Decimal = _carrito.Sum(Function(d) d.Subtotal)
        lblTotal.Text = $"TOTAL: $ {total:N2}"
        btnCancelar.Enabled = _carrito.Count > 0
    End Sub

    Private Sub btnConfirmar_Click(sender As Object, e As EventArgs) Handles btnConfirmar.Click
        If cboCliente.SelectedItem Is Nothing Then
            MessageBox.Show("Tenés que seleccionar un cliente para facturar.", "Falta Cliente", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        If _carrito.Count = 0 Then
            MessageBox.Show("El carrito de compras está vacío.", "Carrito Vacío", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If

        Try
            Dim nuevaVenta As New Venta() With {
                .IdCliente = CInt(cboCliente.SelectedValue),
                .IdUsuario = UsuarioActualId,
                .MedioPago = CType(Math.Max(0, cboMedioPago.SelectedIndex), MedioPago),
                .Detalles = _carrito.ToList()
            }

            btnConfirmar.Enabled = False
            _ventaBLL.ProcesarVenta(nuevaVenta, UsuarioActual)

            MessageBox.Show("¡Venta registrada con éxito! El stock ha sido descontado.", "Transacción Exitosa", MessageBoxButtons.OK, MessageBoxIcon.Information)

            LimpiarVenta()
            ' Recargar combo de productos para tener el stock actualizado en tiempo real
            cboProducto.DataSource = _productoBLL.ObtenerProductos(True)
            cboProducto.SelectedIndex = -1

        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error en la Venta", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            btnConfirmar.Enabled = True
        End Try
    End Sub

    Private Sub LimpiarVenta()
        cboCliente.SelectedIndex = -1
        cboProducto.SelectedIndex = -1
        txtCantidad.Text = "1"
        _carrito.Clear()
        If cboMedioPago.Items.Count > 0 Then cboMedioPago.SelectedIndex = 0
        ActualizarTotal()
    End Sub

    Private Sub btnCancelar_Click(sender As Object, e As EventArgs) Handles btnCancelar.Click
        LimpiarVenta()
    End Sub
End Class
