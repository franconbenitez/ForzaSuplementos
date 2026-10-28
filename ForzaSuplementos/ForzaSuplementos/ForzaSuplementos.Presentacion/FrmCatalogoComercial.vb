Option Strict On
Imports System.Data
Imports System.Threading.Tasks
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio
Public Class FrmCatalogoComercial
    Inherits Form
    Public Property UsuarioActual As Usuario
    Private ReadOnly _tipo As String
    Private ReadOnly _bll As New ComercialBLL()
    Private ReadOnly _buscar As New TextBox With {.Width = 280, .Name = "txtBuscar"}
    Private ReadOnly _nombre As New TextBox With {.Width = 250, .MaxLength = 100}
    Private ReadOnly _razon As New TextBox With {.Width = 250, .MaxLength = 150}
    Private ReadOnly _cuit As New TextBox With {.Width = 150, .MaxLength = 11}
    Private ReadOnly _activo As New CheckBox With {.Text = "Activo", .Checked = True, .AutoSize = True}
    Private ReadOnly _grid As New DataGridView With {.Dock = DockStyle.Fill, .ReadOnly = True, .AllowUserToAddRows = False, .MultiSelect = False, .SelectionMode = DataGridViewSelectionMode.FullRowSelect, .AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill}
    Private ReadOnly _estado As New Label With {.Dock = DockStyle.Top, .Height = 38}
    Private ReadOnly _editor As New FlowLayoutPanel With {.Dock = DockStyle.Bottom, .Height = 145, .Padding = New Padding(10)}
    Private ReadOnly _protector As ProtectorCambios
    Private _id As Integer
    Public Sub New(tipo As String)
        If tipo <> "Proveedores" AndAlso tipo <> "Marcas" Then Throw New ArgumentException("Catálogo desconocido.")
        _tipo = tipo : Text = tipo : Size = New Drawing.Size(980, 640) : MinimumSize = New Drawing.Size(850, 560)
        Dim barra As New FlowLayoutPanel With {.Dock = DockStyle.Top, .Height = 52, .Padding = New Padding(10)}
        Dim buscar As New Button With {.Text = "Buscar", .AutoSize = True}
        barra.Controls.AddRange(New Control() {_buscar, buscar})
        _editor.Controls.AddRange(New Control() {New Label With {.Text = "Nombre", .AutoSize = True}, _nombre})
        If tipo = "Proveedores" Then _editor.Controls.AddRange(New Control() {New Label With {.Text = "Razón social", .AutoSize = True}, _razon, New Label With {.Text = "CUIT", .AutoSize = True}, _cuit})
        Dim guardar As New Button With {.Text = "Guardar", .AutoSize = True}, nuevo As New Button With {.Text = "Nuevo / limpiar", .AutoSize = True}
        _editor.Controls.AddRange(New Control() {_activo, guardar, nuevo})
        If tipo = "Marcas" Then
            Dim asociar As New Button With {.Text = "Asignar marca a producto…", .AutoSize = True}
            _editor.Controls.Add(asociar) : AddHandler asociar.Click, AddressOf Me.Asociar
        End If
        Controls.Add(_grid) : Controls.Add(_estado) : Controls.Add(barra) : Controls.Add(_editor)
        TemaForza.Aplicar(Me)
        _protector = ProtectorCambios.ParaEdicion(Me, _nombre, _razon, _cuit, _activo)
        AddHandler buscar.Click, Async Sub(sender, e) Await Cargar()
        AddHandler nuevo.Click, Sub()
                                    If Not ConfirmarDescartar() Then Return
                                    _id = 0 : _nombre.Clear() : _razon.Clear() : _cuit.Clear() : _activo.Checked = True : _base = Valores() : _protector.EstablecerBase()
                                End Sub
        AddHandler guardar.Click, AddressOf Me.Guardar
        AddHandler _grid.CellDoubleClick, AddressOf Seleccionar
        AddHandler Me.Load, AddressOf Iniciar
    End Sub
    Private _base As String = ""
    Private Function Valores() As String
        Return _nombre.Text & "|" & _razon.Text & "|" & _cuit.Text & "|" & _activo.Checked.ToString()
    End Function
    Private Function ConfirmarDescartar() As Boolean
        Return Valores() = _base OrElse MessageBox.Show(Me, "Tenés cambios sin guardar. ¿Querés descartarlos?", "Edición", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) = DialogResult.Yes
    End Function
    Private Async Sub Iniciar(sender As Object, e As EventArgs)
        If Not AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Productos) Then Return
        _base = Valores()
        Try
            Dim disponible = Await Task.Run(Function() _bll.Disponible(UsuarioActual, "Catalogos"))
            If IsDisposed Then Return
            _editor.Enabled = disponible
            If Not disponible Then
                _estado.Text = "Requiere habilitación QA: migración 006. No se puede guardar ni modificar datos."
                Return
            End If
            Await Cargar()
        Catch ex As Exception
            If Not IsDisposed Then _estado.Text = ex.Message : _editor.Enabled = False
        End Try
    End Sub
    Private Async Function Cargar() As Task
        Try
            Dim filtro = _buscar.Text
            Dim tabla = Await Task.Run(Function() _bll.Buscar(UsuarioActual, _tipo, filtro))
            If IsDisposed Then Return
            _grid.DataSource = tabla : _estado.Text = If(tabla.Rows.Count = 0, "Sin resultados.", tabla.Rows.Count.ToString() & " resultados (máximo 500).")
        Catch ex As Exception
            If Not IsDisposed Then _estado.Text = "No se pudo consultar. " & ex.Message
        End Try
    End Function
    Private Sub Seleccionar(sender As Object, e As DataGridViewCellEventArgs)
        If e.RowIndex < 0 OrElse Not ConfirmarDescartar() Then Return
        Dim row = DirectCast(_grid.Rows(e.RowIndex).DataBoundItem, DataRowView)
        _id = CInt(row("Id")) : _nombre.Text = CStr(row("Nombre")) : _activo.Checked = CBool(row("Activo"))
        If _tipo = "Proveedores" Then _razon.Text = CStr(row("RazonSocial")) : _cuit.Text = Convert.ToString(row("Cuit"))
        _base = Valores() : _protector.EstablecerBase()
    End Sub
    Private Async Sub Guardar(sender As Object, e As EventArgs)
        _editor.Enabled = False
        Try
            If _tipo = "Proveedores" Then
                _bll.Guardar(UsuarioActual, New Proveedor With {.IdProveedor = _id, .Nombre = _nombre.Text.Trim(), .RazonSocial = _razon.Text.Trim(), .Cuit = _cuit.Text.Trim(), .Activo = _activo.Checked})
            Else
                _bll.Guardar(UsuarioActual, New Marca With {.IdMarca = _id, .Nombre = _nombre.Text.Trim(), .Activo = _activo.Checked})
            End If
            _base = Valores() : _protector.EstablecerBase() : Await Cargar()
            _estado.Text = "Guardado confirmado por SQL Server. Seleccioná Nuevo para otra alta."
        Catch ex As Exception
            _estado.Text = "No se guardó: " & ex.Message
        Finally
            _editor.Enabled = True
        End Try
    End Sub
    Private Sub Asociar(sender As Object, e As EventArgs)
        Try
            If _id <= 0 Then Throw New ApplicationException("Seleccioná una marca de la grilla.")
            Using selector As New FrmBuscador(New ProductoBLL().ObtenerProductos(True, UsuarioActual))
                If selector.ShowDialog(Me) <> DialogResult.OK Then Return
                Dim p = selector.ProductoSeleccionado
                If p Is Nothing Then Return
                _bll.Asociar(UsuarioActual, p.IdProducto, _id)
                _estado.Text = "Marca asignada al producto seleccionado."
            End Using
        Catch ex As Exception
            _estado.Text = "No se asignó: " & ex.Message
        End Try
    End Sub
End Class
Public Class FrmProveedores
    Inherits FrmCatalogoComercial
    Public Sub New()
        MyBase.New("Proveedores")
    End Sub
End Class
Public Class FrmMarcas
    Inherits FrmCatalogoComercial
    Public Sub New()
        MyBase.New("Marcas")
    End Sub
End Class
