Imports System.ComponentModel
Imports System.Threading.Tasks
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmVentas
    Private ReadOnly _clienteBLL As New ClienteBLL()
    Private ReadOnly _productoBLL As New ProductoBLL()
    Private ReadOnly _ventaBLL As New VentaBLL()
    Private _carrito As New BindingList(Of DetalleVenta)()
    Private _clientes As New List(Of Cliente)()
    Private _productos As New List(Of Producto)()
    Private _clienteSeleccionado As Cliente
    Private _productoSeleccionado As Producto
    Private _buscadorAbierto As Boolean
    Private _catalogoDisponible As Boolean
    Public UsuarioActualId As Integer = 0
    Public Property UsuarioActual As Usuario
    Private ReadOnly _protector As ProtectorCambios

    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
        AddHandler _carrito.ListChanged, AddressOf CarritoCambiado
        ActualizarTotal()
        _protector = New ProtectorCambios(Me, Function() _carrito.Count > 0,
            "Tenés productos en el carrito. Si salís, se perderá la venta sin confirmar. ¿Querés continuar?",
            AddressOf DescartarCarritoAlCerrar)
    End Sub

    Private Sub DescartarCarritoAlCerrar()
        RemoveHandler _carrito.ListChanged, AddressOf CarritoCambiado
        _carrito.Clear()
    End Sub

    Private Sub CarritoCambiado(sender As Object, e As ListChangedEventArgs)
        ActualizarTotal()
    End Sub

    Private Async Sub FrmVentas_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        If Not AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Ventas) Then Return
        dgvCarrito.DataSource = _carrito
        ConfigurarGrilla()
        cboMedioPago.DataSource = New String() {"Seleccionar medio de pago", "Efectivo", "Transferencia", "Tarjeta"}
        Try
            CajaBLL.ValidarVendedor(UsuarioActual)
            Await CargarCatalogosAsync()
        Catch ex As Exception
            If Not IsDisposed Then MessageBox.Show(ex.Message, "Ventas", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        End Try
    End Sub

    Private Async Function CargarCatalogosAsync() As Task
        _catalogoDisponible = False
        btnBuscarCliente.Enabled = False
        btnBuscarProducto.Enabled = False
        btnAgregar.Enabled = False
        btnConfirmar.Enabled = False
        Try
            Dim actor = UsuarioActual
            Dim datos = Await Task.Run(Function() Tuple.Create(_clienteBLL.ObtenerClientes(True, actor), _productoBLL.ObtenerProductos(True, actor)))
            If IsDisposed Then Return
            EstablecerCatalogos(datos.Item1, datos.Item2)
        Finally
            If Not IsDisposed Then
                btnBuscarCliente.Enabled = _catalogoDisponible
                btnBuscarProducto.Enabled = _catalogoDisponible
                btnAgregar.Enabled = _catalogoDisponible
                btnConfirmar.Enabled = _catalogoDisponible
            End If
        End Try
    End Function

    Protected Sub EstablecerCatalogos(clientes As IEnumerable(Of Cliente), productos As IEnumerable(Of Producto))
        _clientes = If(clientes, Enumerable.Empty(Of Cliente)()).ToList()
        _productos = If(productos, Enumerable.Empty(Of Producto)()).ToList()
        _catalogoDisponible = True
    End Sub

    Protected Overridable Function BuscarCliente() As Cliente
        Using selector As New FrmBuscador(_clientes)
            If selector.ShowDialog(Me) = DialogResult.OK Then Return selector.ClienteSeleccionado
        End Using
        Return Nothing
    End Function

    Protected Overridable Function BuscarProducto() As Producto
        Using selector As New FrmBuscador(_productos)
            If selector.ShowDialog(Me) = DialogResult.OK Then Return selector.ProductoSeleccionado
        End Using
        Return Nothing
    End Function

    Private Sub btnBuscarCliente_Click(sender As Object, e As EventArgs) Handles btnBuscarCliente.Click
        If _buscadorAbierto Then Return
        _buscadorAbierto = True
        Try
            SeleccionarCliente(BuscarCliente())
        Finally
            _buscadorAbierto = False
        End Try
    End Sub

    Private Sub btnBuscarProducto_Click(sender As Object, e As EventArgs) Handles btnBuscarProducto.Click
        If _buscadorAbierto Then Return
        _buscadorAbierto = True
        Try
            SeleccionarProducto(BuscarProducto())
        Finally
            _buscadorAbierto = False
        End Try
    End Sub

    Protected Sub SeleccionarCliente(cliente As Cliente)
        If cliente Is Nothing Then Return
        If Not cliente.Activo OrElse cliente.IdCliente <= 0 Then Throw New ApplicationException("Seleccioná un cliente activo válido.")
        _clienteSeleccionado = cliente
        txtClienteSeleccionado.Text = $"#{cliente.IdCliente} · {cliente.Apellido}, {cliente.Nombre} · DNI {cliente.Dni}"
    End Sub

    Protected Sub SeleccionarProducto(producto As Producto)
        If producto Is Nothing Then Return
        If Not producto.Activo OrElse producto.IdProducto <= 0 OrElse producto.Stock <= 0 Then Throw New ApplicationException("Seleccioná un producto activo con stock disponible.")
        _productoSeleccionado = producto
        txtProductoSeleccionado.Text = $"#{producto.IdProducto} · {producto.Nombre}"
        lblPrecioSeleccionado.Text = $"Precio unitario: $ {producto.Precio:N2}   |   Stock disponible: {producto.Stock}"
        txtCantidad.Select()
    End Sub

    Private Sub ConfigurarGrilla()
        If dgvCarrito.Columns.Count > 0 Then
            dgvCarrito.Columns("IdProducto").Visible = False
            dgvCarrito.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        End If
    End Sub

    Private Sub btnAgregar_Click(sender As Object, e As EventArgs) Handles btnAgregar.Click
        Dim cantidad As Integer
        If Not Integer.TryParse(txtCantidad.Text, cantidad) Then
            MessageBox.Show("Ingresá una cantidad numérica mayor a 0.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Warning)
            Return
        End If
        Try
            AgregarProducto(cantidad)
        Catch ex As ApplicationException
            MessageBox.Show(ex.Message, "Atención", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        End Try
    End Sub

    Protected Sub AgregarProducto(cantidad As Integer)
        Dim prodSel = _productoSeleccionado
        If prodSel Is Nothing OrElse Not prodSel.Activo OrElse prodSel.IdProducto <= 0 Then Throw New ApplicationException("Seleccioná un producto activo del catálogo.")
        If cantidad <= 0 Then Throw New ApplicationException("Ingresá una cantidad numérica mayor a 0.")
        If cantidad > prodSel.Stock Then Throw New ApplicationException($"Stock insuficiente. Solo quedan {prodSel.Stock} unidades.")
        Dim itemExistente = _carrito.FirstOrDefault(Function(d) d.IdProducto = prodSel.IdProducto)
        If itemExistente IsNot Nothing Then
            If CLng(itemExistente.Cantidad) + cantidad > prodSel.Stock Then Throw New ApplicationException("La cantidad acumulada en el carrito supera el stock físico disponible.")
            itemExistente.Cantidad += cantidad
            itemExistente.CalcularSubtotal()
        Else
            Dim nuevoDetalle As New DetalleVenta With {.IdProducto = prodSel.IdProducto, .NombreProducto = prodSel.Nombre, .Cantidad = cantidad, .PrecioUnitario = prodSel.Precio}
            nuevoDetalle.CalcularSubtotal()
            _carrito.Add(nuevoDetalle)
        End If
        _carrito.ResetBindings()
        ActualizarTotal()
        txtCantidad.Text = "1"
        LimpiarProductoSeleccionado()
    End Sub

    Private Sub ActualizarTotal()
        Dim total As Decimal = _carrito.Sum(Function(d) d.Subtotal)
        lblTotal.Text = $"TOTAL: $ {total:N2}"
        btnCancelar.Enabled = _carrito.Count > 0
    End Sub

    Protected Function CrearVentaPendiente() As Venta
        If _clienteSeleccionado Is Nothing OrElse Not _clienteSeleccionado.Activo OrElse _clienteSeleccionado.IdCliente <= 0 Then Throw New ApplicationException("Tenés que seleccionar un cliente activo para facturar.")
        If _carrito.Count = 0 Then Throw New ApplicationException("El carrito de compras está vacío.")
        Return New Venta With {.IdCliente = _clienteSeleccionado.IdCliente, .IdUsuario = UsuarioActualId,
            .MedioPago = CType(Math.Max(0, cboMedioPago.SelectedIndex), MedioPago), .Detalles = _carrito.ToList()}
    End Function

    Private Async Sub btnConfirmar_Click(sender As Object, e As EventArgs) Handles btnConfirmar.Click
        Try
            Dim nuevaVenta = CrearVentaPendiente()
            btnConfirmar.Enabled = False
            _ventaBLL.ProcesarVenta(nuevaVenta, UsuarioActual)
            MessageBox.Show("¡Venta registrada con éxito! El stock ha sido descontado.", "Transacción Exitosa", MessageBoxButtons.OK, MessageBoxIcon.Information)
            LimpiarVenta()
            Await CargarCatalogosAsync()
        Catch ex As Exception
            If Not IsDisposed Then MessageBox.Show(ex.Message, "Error en la Venta", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Finally
            If Not IsDisposed Then btnConfirmar.Enabled = _catalogoDisponible
        End Try
    End Sub

    Private Sub LimpiarProductoSeleccionado()
        _productoSeleccionado = Nothing
        txtProductoSeleccionado.Text = "Sin producto seleccionado"
        lblPrecioSeleccionado.Text = "Precio unitario: —   |   Stock disponible: —"
    End Sub

    Private Sub LimpiarVenta()
        _clienteSeleccionado = Nothing
        txtClienteSeleccionado.Text = "Sin cliente seleccionado"
        LimpiarProductoSeleccionado()
        txtCantidad.Text = "1"
        _carrito.Clear()
        If cboMedioPago.Items.Count > 0 Then cboMedioPago.SelectedIndex = 0
        ActualizarTotal()
    End Sub

    Private Sub btnCancelar_Click(sender As Object, e As EventArgs) Handles btnCancelar.Click
        LimpiarVenta()
    End Sub
End Class
