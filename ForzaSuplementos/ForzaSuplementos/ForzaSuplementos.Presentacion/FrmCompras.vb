Option Strict On
Imports System.ComponentModel
Imports System.Data
Imports System.Linq
Imports System.Threading.Tasks
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio
Public Class FrmCompras
    Inherits Form
    Public Property UsuarioActual As Usuario
    Private ReadOnly _carrito As New BindingList(Of DetalleCompra)
    Private ReadOnly _seleccion As New TextBox With {.ReadOnly = True, .Width = 270, .Name = "txtProveedor"}
    Private ReadOnly _producto As New TextBox With {.ReadOnly = True, .Width = 270}
    Private ReadOnly _cantidad As New NumericUpDown With {.Minimum = 1, .Maximum = 1000000, .Width = 90}
    Private ReadOnly _costo As New NumericUpDown With {.DecimalPlaces = 2, .Minimum = 0.01D, .Maximum = 9999999999.99D, .Width = 130}
    Private ReadOnly _grid As New DataGridView With {.Dock = DockStyle.Fill, .ReadOnly = True, .AllowUserToAddRows = False, .SelectionMode = DataGridViewSelectionMode.FullRowSelect, .MultiSelect = False, .AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill}
    Private ReadOnly _estado As New Label With {.Dock = DockStyle.Bottom, .Height = 42}
    Private ReadOnly _total As New Label With {.AutoSize = True, .Text = "Total: $0,00"}
    Private ReadOnly _confirmar As New Button With {.Text = "Confirmar compra", .AutoSize = True, .Enabled = False}
    Private ReadOnly _vaciar As New Button With {.Text = "Vaciar carrito", .AutoSize = True, .Enabled = False}
    Private ReadOnly _edicion As New FlowLayoutPanel With {.Dock = DockStyle.Top, .Height = 160, .Padding = New Padding(10)}
    Private _proveedor As Integer
    Private _elegido As Producto
    Private _operacion As Guid = Guid.NewGuid()
    Private _enviando As Boolean
    Private ReadOnly _protector As ProtectorCambios
    Public Sub New()
        Text = "Compras a proveedores" : Size = New Drawing.Size(1050, 700) : MinimumSize = New Drawing.Size(940, 640)
        Dim buscarProveedor As New Button With {.Text = "Buscar proveedor", .AutoSize = True}, buscarProducto As New Button With {.Text = "Buscar producto", .AutoSize = True}, agregar As New Button With {.Text = "Agregar al carrito", .AutoSize = True}, quitar As New Button With {.Text = "Quitar seleccionado", .AutoSize = True}, historial As New Button With {.Text = "Historial y detalle…", .AutoSize = True}
        _edicion.Controls.AddRange(New Control() {_seleccion, buscarProveedor, _producto, buscarProducto, New Label With {.Text = "Cantidad", .AutoSize = True}, _cantidad, New Label With {.Text = "Costo unitario (no precio de venta)", .AutoSize = True}, _costo, agregar, quitar, _vaciar, _confirmar, historial, _total})
        Controls.Add(_grid) : Controls.Add(_edicion) : Controls.Add(_estado)
        _grid.DataSource = _carrito : TemaForza.Aplicar(Me) : _edicion.Enabled = False
        _protector = New ProtectorCambios(Me, Function() _carrito.Count > 0, "Tenés una compra sin confirmar. Si salís, se perderá el carrito. ¿Querés continuar?")
        AddHandler Me.Load, AddressOf Iniciar
        AddHandler buscarProveedor.Click, AddressOf ElegirProveedor
        AddHandler buscarProducto.Click, AddressOf ElegirProducto
        AddHandler agregar.Click, AddressOf Me.Agregar
        AddHandler quitar.Click, Sub()
                                    If _grid.CurrentRow Is Nothing Then Return
                                    _carrito.Remove(DirectCast(_grid.CurrentRow.DataBoundItem, DetalleCompra)) : Cambio()
                                End Sub
        AddHandler _vaciar.Click, Sub()
                                     _carrito.Clear() : Cambio()
                                 End Sub
        AddHandler _confirmar.Click, AddressOf Confirmar
        AddHandler historial.Click, Sub()
                                       Using f As New FrmHistorialCompras With {.UsuarioActual = UsuarioActual}
                                           f.ShowDialog(Me)
                                       End Using
                                   End Sub
        AddHandler Me.FormClosing, Sub(sender, e)
                                       If _enviando Then e.Cancel = True
                                   End Sub
    End Sub
    Private Async Sub Iniciar(sender As Object, e As EventArgs)
        If Not AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Productos) Then Return
        Try
            Dim habilitado = Await Task.Run(Function() New ComercialBLL().Disponible(UsuarioActual, "Compras"))
            If IsDisposed Then Return
            _edicion.Enabled = habilitado
            _estado.Text = If(habilitado, "Los costos se registran por compra; no cambian precios de venta.", "Requiere habilitación QA: migraciones 006 y 007. Guardado deshabilitado.")
        Catch ex As Exception
            If Not IsDisposed Then _estado.Text = ex.Message
        End Try
    End Sub
    Private Async Sub ElegirProveedor(sender As Object, e As EventArgs)
        Try
            Dim t = Await Task.Run(Function() New ComercialBLL().Buscar(UsuarioActual, "Proveedores", ""))
            If IsDisposed Then Return
            Using selector As New FrmSeleccionTabla("Buscar proveedor", t)
                If selector.ShowDialog(Me) <> DialogResult.OK Then Return
                If Not CBool(selector.Elegida("Activo")) Then Throw New ApplicationException("El proveedor está inactivo.")
                _proveedor = CInt(selector.Elegida("Id")) : _seleccion.Text = CStr(selector.Elegida("Nombre")) : _operacion = Guid.NewGuid()
            End Using
        Catch ex As Exception
            If Not IsDisposed Then _estado.Text = ex.Message
        End Try
    End Sub
    Private Sub ElegirProducto(sender As Object, e As EventArgs)
        Try
            Using selector As New FrmBuscador(New ProductoBLL().ObtenerProductos(True, UsuarioActual))
                If selector.ShowDialog(Me) <> DialogResult.OK Then Return
                _elegido = selector.ProductoSeleccionado
                If _elegido Is Nothing Then Return
                _producto.Text = _elegido.Nombre
            End Using
        Catch ex As Exception
            _estado.Text = ex.Message
        End Try
    End Sub
    Private Sub Agregar(sender As Object, e As EventArgs)
        Try
            If _elegido Is Nothing OrElse Not _elegido.Activo Then Throw New ApplicationException("Seleccioná un producto activo.")
            If _carrito.Any(Function(d) d.IdProducto = _elegido.IdProducto) Then Throw New ApplicationException("El producto ya está agregado. Quitalo para cambiar cantidad/costo.")
            _carrito.Add(New DetalleCompra With {.IdProducto = _elegido.IdProducto, .Producto = _elegido.Nombre, .Cantidad = CInt(_cantidad.Value), .CostoUnitario = _costo.Value}) : Cambio()
        Catch ex As Exception
            _estado.Text = ex.Message
        End Try
    End Sub
    Private Sub Cambio()
        _operacion = Guid.NewGuid() : _vaciar.Enabled = _carrito.Count > 0 : _confirmar.Enabled = _carrito.Count > 0
        _total.Text = "Total: $" & _carrito.Sum(Function(d) d.Subtotal).ToString("N2")
    End Sub
    Private Async Sub Confirmar(sender As Object, e As EventArgs)
        If _enviando Then Return
        _enviando = True : _edicion.Enabled = False
        Try
            Dim compra As New Compra With {.IdProveedor = _proveedor, .Operacion = _operacion, .Detalles = _carrito.ToList()}
            CompraBLL.Validar(compra)
            Dim id = Await Task.Run(Function() New CompraBLL().Registrar(UsuarioActual, compra))
            _carrito.Clear() : Cambio() : _estado.Text = "Compra confirmada: " & id.ToString()
        Catch ex As Exception
            _estado.Text = "No se recibió confirmación. Se conserva carrito e identificador. Revisá historial antes de reintentar. " & ex.Message
        Finally
            _enviando = False : _edicion.Enabled = True
        End Try
    End Sub
End Class
Public Class FrmSeleccionTabla
    Inherits Form
    Private ReadOnly _grid As New DataGridView With {.Dock = DockStyle.Fill, .ReadOnly = True, .AllowUserToAddRows = False, .MultiSelect = False, .SelectionMode = DataGridViewSelectionMode.FullRowSelect, .AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill}
    Public Property Elegida As DataRowView
    Public Sub New(titulo As String, tabla As DataTable)
        Text = titulo : Size = New Drawing.Size(850, 520) : StartPosition = FormStartPosition.CenterParent
        Dim buscar As New TextBox With {.Dock = DockStyle.Top}, aceptar As New Button With {.Dock = DockStyle.Bottom, .Text = "Seleccionar"}
        Dim vista As New DataView(tabla)
        _grid.DataSource = vista : Controls.Add(_grid) : Controls.Add(buscar) : Controls.Add(aceptar) : TemaForza.Aplicar(Me) : AcceptButton = aceptar
        AddHandler buscar.TextChanged, Sub()
                                          Dim f = buscar.Text.Replace("'", "''").Replace("[", "[[]").Replace("%", "[%]").Replace("*", "[*]")
                                          vista.RowFilter = "Nombre LIKE '%" & f & "%'" & If(tabla.Columns.Contains("RazonSocial"), " OR RazonSocial LIKE '%" & f & "%' OR Cuit LIKE '%" & f & "%'", "")
                                      End Sub
        AddHandler aceptar.Click, Sub() Seleccionar()
        AddHandler _grid.CellDoubleClick, Sub(sender, e)
                                             If e.RowIndex >= 0 Then Seleccionar()
                                         End Sub
        AddHandler Me.Disposed, Sub() vista.Dispose()
    End Sub
    Private Sub Seleccionar()
        If _grid.CurrentRow Is Nothing Then Return
        Elegida = TryCast(_grid.CurrentRow.DataBoundItem, DataRowView)
        If Elegida IsNot Nothing Then DialogResult = DialogResult.OK : Close()
    End Sub
End Class
Public Class FrmHistorialCompras
    Inherits Form
    Public Property UsuarioActual As Usuario
    Public Sub New()
        Text = "Historial de compras (doble clic para ver detalle)" : Size = New Drawing.Size(980, 620)
        Dim desde As New DateTimePicker With {.Value = Date.Today.AddMonths(-1), .Width = 140}, hasta As New DateTimePicker With {.Value = Date.Today, .Width = 140}, proveedor As New NumericUpDown With {.Maximum = Integer.MaxValue, .Width = 90}, consultar As New Button With {.Text = "Consultar", .AutoSize = True}
        Dim barra As New FlowLayoutPanel With {.Dock = DockStyle.Top, .Height = 55}
        barra.Controls.AddRange(New Control() {desde, hasta, New Label With {.Text = "Proveedor (0=todos)", .AutoSize = True}, proveedor, consultar})
        Dim grid As New DataGridView With {.Dock = DockStyle.Fill, .ReadOnly = True, .AllowUserToAddRows = False, .AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill}
        Controls.Add(grid) : Controls.Add(barra) : TemaForza.Aplicar(Me)
        AddHandler Me.Load, Sub()
                               AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Productos)
                           End Sub
        AddHandler consultar.Click, Sub()
                                       Try
                                           grid.DataSource = New CompraBLL().Historial(UsuarioActual, desde.Value, hasta.Value, If(proveedor.Value = 0, CType(Nothing, Integer?), CInt(proveedor.Value)))
                                       Catch ex As Exception
                                           MessageBox.Show(Me, ex.Message)
                                       End Try
                                   End Sub
        AddHandler grid.CellDoubleClick, Sub(sender, e)
                                            If e.RowIndex < 0 Then Return
                                            Try
                                                Dim tabla = New CompraBLL().Detalle(UsuarioActual, CInt(grid.Rows(e.RowIndex).Cells("IdCompra").Value))
                                                Using detalle As New Form With {.Text = "Detalle de compra", .Size = New Drawing.Size(850, 500)}
                                                    detalle.Controls.Add(New DataGridView With {.Dock = DockStyle.Fill, .DataSource = tabla, .ReadOnly = True, .AllowUserToAddRows = False, .AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill})
                                                    TemaForza.Aplicar(detalle) : detalle.ShowDialog(Me)
                                                End Using
                                            Catch ex As Exception
                                                MessageBox.Show(Me, ex.Message)
                                            End Try
                                        End Sub
    End Sub
End Class
