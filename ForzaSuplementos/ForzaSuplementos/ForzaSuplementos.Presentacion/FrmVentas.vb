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
    Private _confirmando As Boolean
    Private _resultadoIncierto As Boolean
    Public UsuarioActualId As Integer = 0
    Public Property UsuarioActual As Usuario
    Private ReadOnly _protector As ProtectorCambios

    Public Sub New()
        InitializeComponent()
        AddHandler Me.FormClosing, Sub(sender, e)
                                       If _confirmando Then e.Cancel = True
                                   End Sub
        TemaForza.Aplicar(Me)
        dgvCarrito.AllowUserToDeleteRows = False
        AddHandler dgvCarrito.KeyDown, Sub(sender, e)
                                          If e.KeyCode <> Keys.Delete Then Return
                                          e.Handled = True : e.SuppressKeyPress = True
                                          If _confirmando OrElse _resultadoIncierto OrElse dgvCarrito.CurrentRow Is Nothing Then Return
                                          Dim detalle = TryCast(dgvCarrito.CurrentRow.DataBoundItem, DetalleVenta)
                                          If detalle IsNot Nothing Then _carrito.Remove(detalle)
                                      End Sub
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
                btnConfirmar.Enabled = _catalogoDisponible AndAlso Not _confirmando AndAlso Not _resultadoIncierto
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
        Catch ex As Exception
            NotificarVenta("No se pudo seleccionar el cliente. " & ex.Message, True)
        Finally
            _buscadorAbierto = False
        End Try
    End Sub

    Private Sub btnBuscarProducto_Click(sender As Object, e As EventArgs) Handles btnBuscarProducto.Click
        If _buscadorAbierto Then Return
        _buscadorAbierto = True
        Try
            SeleccionarProducto(BuscarProducto())
        Catch ex As Exception
            NotificarVenta("No se pudo seleccionar el producto. " & ex.Message, True)
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
        CajaBLL.ValidarImporte(prodSel.Precio)
        If prodSel.Precio = 0 Then Throw New ApplicationException("El precio debe ser mayor a cero.")
        Dim itemExistente = _carrito.FirstOrDefault(Function(d) d.IdProducto = prodSel.IdProducto)
        If itemExistente IsNot Nothing Then
            If CLng(itemExistente.Cantidad) + cantidad > prodSel.Stock Then Throw New ApplicationException("La cantidad acumulada en el carrito supera el stock físico disponible.")
            CajaBLL.ValidarImporte((CDec(itemExistente.Cantidad) + cantidad) * itemExistente.PrecioUnitario)
            itemExistente.Cantidad += cantidad
            itemExistente.CalcularSubtotal()
        Else
            Dim nuevoDetalle As New DetalleVenta With {.IdProducto = prodSel.IdProducto, .NombreProducto = prodSel.Nombre, .Cantidad = cantidad, .PrecioUnitario = prodSel.Precio}
            nuevoDetalle.CalcularSubtotal()
            CajaBLL.ValidarImporte(nuevoDetalle.Subtotal)
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
            .MedioPago = CType(Math.Max(0, cboMedioPago.SelectedIndex), MedioPago), .Detalles = _carrito.Select(Function(d) New DetalleVenta With {.IdProducto = d.IdProducto, .NombreProducto = d.NombreProducto, .Cantidad = d.Cantidad, .PrecioUnitario = d.PrecioUnitario, .Subtotal = d.Subtotal}).ToList()}
    End Function

    Private Async Sub btnConfirmar_Click(sender As Object, e As EventArgs) Handles btnConfirmar.Click
        If _confirmando OrElse _resultadoIncierto Then Return
        _confirmando = True
        btnConfirmar.Enabled = False
        Try
            Dim nuevaVenta = CrearVentaPendiente()
            RegistrarVenta(nuevaVenta)
            LimpiarVenta()
            NotificarVenta("¡Venta registrada con éxito! El stock ha sido descontado.", False)
            Try
                Await RecargarTrasConfirmacion()
            Catch ex As Exception
                _catalogoDisponible = False
                btnBuscarCliente.Enabled = False : btnBuscarProducto.Enabled = False : btnAgregar.Enabled = False
                NotificarVenta("La venta ya fue confirmada. Falló la recarga del catálogo; volvé a abrir Ventas para actualizar. No repitas la venta. " & ex.Message, True)
            End Try
        Catch ex As OperacionInciertaException
            _resultadoIncierto = True
            NotificarVenta("No se conoce el resultado de la confirmación. Consultá el historial antes de repetir la operación. Se conserva el carrito y se bloquea Confirmar para evitar duplicados.", True)
        Catch ex As Exception
            If Not IsDisposed Then NotificarVenta(ex.Message, True)
        Finally
            _confirmando = False
            If Not IsDisposed Then btnConfirmar.Enabled = _catalogoDisponible AndAlso Not _resultadoIncierto
        End Try
    End Sub

    Protected Overridable Sub RegistrarVenta(venta As Venta)
        _ventaBLL.ProcesarVenta(venta, UsuarioActual)
    End Sub

    Protected Overridable Function RecargarTrasConfirmacion() As Task
        Return CargarCatalogosAsync()
    End Function

    Protected Overridable Sub NotificarVenta(mensaje As String, errorOperacion As Boolean)
        MessageBox.Show(Me, mensaje, "Ventas", MessageBoxButtons.OK, If(errorOperacion, MessageBoxIcon.Warning, MessageBoxIcon.Information))
    End Sub

    Protected Overridable Function ConfirmarDescarteIncierto() As Boolean
        Return MessageBox.Show(Me, "El resultado de la venta es incierto. ¿Verificaste el historial y querés descartar únicamente el carrito en memoria?", "Verificar venta", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) = DialogResult.Yes
    End Function

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
        If _confirmando Then Return
        If _resultadoIncierto AndAlso Not ConfirmarDescarteIncierto() Then Return
        Dim eraIncierto = _resultadoIncierto
        _resultadoIncierto = False
        LimpiarVenta()
        If eraIncierto Then btnConfirmar.Enabled = _catalogoDisponible
    End Sub
End Class
