Option Strict On
Imports System.Linq
Imports System.Threading
Imports System.Threading.Tasks
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmBuscador
    Private _clientes As Cliente() = New Cliente() {}
    Private _productos As Producto() = New Producto() {}
    Private _esProducto As Boolean
    Private _version As Integer
    Private _busqueda As CancellationTokenSource
    Private _cerrado As Boolean
    Private _filtrando As Boolean
    Private _clienteSeleccionado As Cliente
    Private _productoSeleccionado As Producto

    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
    End Sub

    Public Sub New(clientes As IEnumerable(Of Cliente))
        Me.New()
        _clientes = If(clientes, Enumerable.Empty(Of Cliente)()).ToArray()
        Columna("IdCliente", "ID", 45)
        Columna("Dni", "DNI", 100)
        Columna("Apellido", "Apellido", 150)
        Columna("Nombre", "Nombre", 150)
        Columna("Telefono", "Teléfono", 110)
    End Sub

    Public Sub New(productos As IEnumerable(Of Producto))
        Me.New()
        _esProducto = True
        _productos = If(productos, Enumerable.Empty(Of Producto)()).ToArray()
        lblTitulo.Text = "BUSCAR PRODUCTO"
        lblAyuda.Text = "Nombre, categoría o ID del producto. Enter o doble clic para seleccionar; Esc para volver."
        Columna("IdProducto", "ID", 45)
        Columna("Nombre", "Producto", 210)
        Columna("NombreCategoria", "Categoría", 130)
        Columna("Precio", "Precio ($)", 90).DefaultCellStyle.Format = "N2"
        Columna("Stock", "Stock", 65)
        Columna("Activo", "Estado", 85)
    End Sub

    Public ReadOnly Property ClienteSeleccionado As Cliente
        Get
            Return _clienteSeleccionado
        End Get
    End Property

    Public ReadOnly Property ProductoSeleccionado As Producto
        Get
            Return _productoSeleccionado
        End Get
    End Property

    Public ReadOnly Property BusquedaEnCurso As Boolean
        Get
            Return _filtrando
        End Get
    End Property

    Private Function Columna(propiedad As String, titulo As String, peso As Single) As DataGridViewTextBoxColumn
        Dim c As New DataGridViewTextBoxColumn With {.Name = propiedad, .DataPropertyName = propiedad, .HeaderText = titulo, .FillWeight = peso, .SortMode = DataGridViewColumnSortMode.NotSortable}
        dgvResultados.Columns.Add(c)
        Return c
    End Function

    Protected Overrides Sub OnShown(e As EventArgs)
        MyBase.OnShown(e)
        SolicitarFiltro()
        txtBuscar.Select()
    End Sub

    Private Sub SolicitarFiltro() Handles txtBuscar.TextChanged
        If _cerrado Then Return
        _version += 1
        _filtrando = True
        If _busqueda IsNot Nothing Then _busqueda.Cancel()
        btnSeleccionar.Enabled = False
        lblEstado.Text = "Buscando..."
        tmrBusqueda.Stop()
        tmrBusqueda.Start()
    End Sub

    Private Async Sub tmrBusqueda_Tick(sender As Object, e As EventArgs) Handles tmrBusqueda.Tick
        tmrBusqueda.Stop()
        Dim version = _version
        Dim texto = txtBuscar.Text
        Dim cts As New CancellationTokenSource()
        _busqueda = cts
        Try
            Dim datos As Object = Await Task.Run(Function() As Object
                                                    If _esProducto Then Return BuscadorCatalogo.Productos(_productos, texto, cts.Token)
                                                    Return BuscadorCatalogo.Clientes(_clientes, texto, cts.Token)
                                                End Function, cts.Token)
            If _cerrado OrElse IsDisposed OrElse version <> _version Then Return
            dgvResultados.DataSource = datos
            lblEstado.Text = If(dgvResultados.Rows.Count = 0, "Sin resultados. Probá otra búsqueda.", $"{dgvResultados.Rows.Count} resultado(s). Seleccioná una fila.")
        Catch ex As OperationCanceledException
            ' Una consulta nueva o el cierre reemplazó esta búsqueda.
        Catch ex As Exception
            If Not _cerrado AndAlso version = _version Then
                dgvResultados.DataSource = Nothing
                lblEstado.Text = "No se pudo filtrar. Volvé a intentar."
            End If
        Finally
            If Object.ReferenceEquals(_busqueda, cts) Then _busqueda = Nothing
            cts.Dispose()
            If Not _cerrado AndAlso version = _version Then
                _filtrando = False
                ActualizarSeleccion()
            End If
        End Try
    End Sub

    Private Sub ActualizarSeleccion() Handles dgvResultados.SelectionChanged, dgvResultados.CurrentCellChanged, dgvResultados.DataBindingComplete
        Dim item = If(dgvResultados.CurrentRow Is Nothing, Nothing, dgvResultados.CurrentRow.DataBoundItem)
        Dim cliente = TryCast(item, Cliente)
        Dim producto = TryCast(item, Producto)
        btnSeleccionar.Enabled = Not _filtrando AndAlso Not _cerrado AndAlso
            If(_esProducto, producto IsNot Nothing AndAlso producto.Activo AndAlso producto.IdProducto > 0 AndAlso producto.Stock > 0,
               cliente IsNot Nothing AndAlso cliente.Activo AndAlso cliente.IdCliente > 0)
        If Not _filtrando AndAlso producto IsNot Nothing AndAlso producto.Stock <= 0 Then lblEstado.Text = "Este producto no tiene stock disponible."
    End Sub

    Private Sub SeleccionarActual() Handles btnSeleccionar.Click
        ActualizarSeleccion()
        If Not btnSeleccionar.Enabled Then Return
        If _esProducto Then
            _productoSeleccionado = TryCast(dgvResultados.CurrentRow.DataBoundItem, Producto)
        Else
            _clienteSeleccionado = TryCast(dgvResultados.CurrentRow.DataBoundItem, Cliente)
        End If
        DialogResult = DialogResult.OK
        Close()
    End Sub

    Private Sub dgvResultados_CellDoubleClick(sender As Object, e As DataGridViewCellEventArgs) Handles dgvResultados.CellDoubleClick
        If e.RowIndex >= 0 Then SeleccionarActual()
    End Sub

    Private Sub Busqueda_KeyDown(sender As Object, e As KeyEventArgs) Handles txtBuscar.KeyDown, dgvResultados.KeyDown
        If e.KeyCode <> Keys.Enter Then Return
        e.Handled = True
        e.SuppressKeyPress = True
        SeleccionarActual()
    End Sub

    Private Sub dgvResultados_CellFormatting(sender As Object, e As DataGridViewCellFormattingEventArgs) Handles dgvResultados.CellFormatting
        If dgvResultados.Columns(e.ColumnIndex).DataPropertyName = "Activo" AndAlso e.Value IsNot Nothing Then
            e.Value = If(CBool(e.Value), "Activo", "Inactivo")
            e.FormattingApplied = True
        End If
    End Sub

    Private Sub CancelarBusqueda()
        _cerrado = True
        _version += 1
        If tmrBusqueda IsNot Nothing Then tmrBusqueda.Stop()
        If _busqueda IsNot Nothing Then _busqueda.Cancel()
    End Sub

    Protected Overrides Sub OnFormClosing(e As FormClosingEventArgs)
        MyBase.OnFormClosing(e)
        If Not e.Cancel Then CancelarBusqueda()
    End Sub
End Class
