Option Strict On
Imports System.Data
Imports System.Threading.Tasks
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio
Public Class FrmInventario
    Inherits Form
    Public Property UsuarioActual As Usuario
    Private ReadOnly _grid As New DataGridView With {.Dock = DockStyle.Fill, .ReadOnly = True, .AllowUserToAddRows = False, .MultiSelect = False, .SelectionMode = DataGridViewSelectionMode.FullRowSelect, .AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill}
    Private ReadOnly _acciones As New FlowLayoutPanel With {.Dock = DockStyle.Top, .Height = 150, .Padding = New Padding(10)}
    Private ReadOnly _estado As New Label With {.Dock = DockStyle.Bottom, .Height = 40}
    Private ReadOnly _desde As New DateTimePicker With {.Value = Date.Today.AddMonths(-1), .Width = 150}
    Private ReadOnly _hasta As New DateTimePicker With {.Value = Date.Today, .Width = 150}
    Private ReadOnly _producto As New NumericUpDown With {.Maximum = Integer.MaxValue, .Width = 100}
    Private ReadOnly _cantidad As New NumericUpDown With {.Minimum = -1000000, .Maximum = 1000000, .Width = 100}
    Private ReadOnly _minimo As New NumericUpDown With {.Maximum = Integer.MaxValue, .Width = 100}
    Private ReadOnly _motivo As New TextBox With {.MaxLength = 250, .Width = 250}
    Private ReadOnly _protector As ProtectorCambios
    Private _enviando As Boolean
    Private _operacion As Guid = Guid.NewGuid()
    Public Sub New()
        Text = "Inventario y trazabilidad" : Size = New Drawing.Size(1120, 720) : MinimumSize = New Drawing.Size(1000, 640)
        Dim stock As New Button With {.Text = "Stock y alertas", .AutoSize = True}, movimientos As New Button With {.Text = "Movimientos", .AutoSize = True}, ajustar As New Button With {.Text = "Aplicar ajuste seleccionado", .AutoSize = True}, minimo As New Button With {.Text = "Guardar mínimo seleccionado", .AutoSize = True}
        _acciones.Controls.AddRange(New Control() {stock, _desde, _hasta, New Label With {.Text = "ID producto (0=todos)", .AutoSize = True}, _producto, movimientos, New Label With {.Text = "Ajuste (+entrada / -salida)", .AutoSize = True}, _cantidad, New Label With {.Text = "Motivo obligatorio", .AutoSize = True}, _motivo, ajustar, New Label With {.Text = "Stock mínimo", .AutoSize = True}, _minimo, minimo})
        Controls.Add(_grid) : Controls.Add(_acciones) : Controls.Add(_estado) : TemaForza.Aplicar(Me) : _acciones.Enabled = False
        _protector = ProtectorCambios.ParaEdicion(Me, _cantidad, _motivo, _minimo)
        AddHandler Me.FormClosing, Sub(sender, e)
                                       If _enviando Then e.Cancel = True
                                   End Sub
        AddHandler Me.Load, AddressOf Iniciar
        AddHandler stock.Click, Async Sub(sender, e) Await CargarStock()
        AddHandler movimientos.Click, AddressOf Historial
        AddHandler ajustar.Click, AddressOf Me.Ajustar
        AddHandler minimo.Click, AddressOf GuardarMinimo
        AddHandler _cantidad.ValueChanged, Sub() _operacion = Guid.NewGuid()
        AddHandler _motivo.TextChanged, Sub() _operacion = Guid.NewGuid()
    End Sub
    Private Async Sub Iniciar(sender As Object, e As EventArgs)
        If Not AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Productos) Then Return
        Try
            Dim habilitado = Await Task.Run(Function() New ComercialBLL().Disponible(UsuarioActual, "Inventario"))
            If IsDisposed Then Return
            _acciones.Enabled = habilitado
            If habilitado Then
                Await CargarStock()
            Else
                _estado.Text = "Requiere habilitación QA: migración 008. No se ajustó stock ni se generaron movimientos."
            End If
        Catch ex As Exception
            If Not IsDisposed Then _estado.Text = ex.Message
        End Try
    End Sub
    Private Async Function CargarStock() As Task
        Try
            Dim tabla = Await Task.Run(Function() New InventarioBLL().Stock(UsuarioActual))
            If IsDisposed Then Return
            _grid.DataSource = tabla : _estado.Text = "Stock actual: Agotado / Bajo / Disponible. Seleccioná una fila para ajustar o cambiar su mínimo."
        Catch ex As Exception
            If Not IsDisposed Then _estado.Text = ex.Message
        End Try
    End Function
    Private Async Sub Historial(sender As Object, e As EventArgs)
        Try
            Dim desde = _desde.Value, hasta = _hasta.Value, producto As Integer? = If(_producto.Value = 0, CType(Nothing, Integer?), CInt(_producto.Value))
            Dim tabla = Await Task.Run(Function() New InventarioBLL().Historial(UsuarioActual, desde, hasta, producto))
            If IsDisposed Then Return
            _grid.DataSource = tabla : _estado.Text = If(tabla.Rows.Count = 0, "Sin movimientos para el período seleccionado.", "Movimientos registrados desde habilitación; máximo 2000. No se inventa historia previa.")
        Catch ex As Exception
            If Not IsDisposed Then _estado.Text = ex.Message
        End Try
    End Sub
    Private Function SeleccionStock() As DataRowView
        If _grid.CurrentRow Is Nothing OrElse Not _grid.Columns.Contains("Stock") Then Throw New ApplicationException("Consultá Stock y alertas y seleccioná un producto.")
        Return DirectCast(_grid.CurrentRow.DataBoundItem, DataRowView)
    End Function
    Private Async Sub Ajustar(sender As Object, e As EventArgs)
        If _enviando Then Return
        _enviando = True : _acciones.Enabled = False
        Try
            Dim row = SeleccionStock()
            Dim a As New AjusteStock With {.IdProducto = CInt(row("IdProducto")), .StockEsperado = CInt(row("Stock")), .Cantidad = CInt(_cantidad.Value), .Motivo = _motivo.Text.Trim(), .Operacion = _operacion}
            InventarioBLL.Validar(a)
            If MessageBox.Show(Me, "¿Confirmar ajuste de stock con el motivo indicado?", "Inventario", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) <> DialogResult.Yes Then Return
            Dim b As New InventarioBLL()
            Await Task.Run(Sub() b.Ajustar(UsuarioActual, a))
            _cantidad.Value = 0 : _motivo.Clear() : _protector.EstablecerBase() : Await CargarStock()
            _estado.Text = "Ajuste confirmado por SQL Server."
        Catch ex As Exception
            _estado.Text = "No se recibió confirmación. Consultá movimientos antes de reintentar. " & ex.Message
        Finally
            _enviando = False : _acciones.Enabled = True
        End Try
    End Sub
    Private Sub GuardarMinimo(sender As Object, e As EventArgs)
        Try
            Dim row = SeleccionStock(), b As New InventarioBLL()
            b.Minimo(UsuarioActual, CInt(row("IdProducto")), CInt(_minimo.Value))
            _protector.EstablecerBase() : _estado.Text = "Stock mínimo guardado. Consultá Stock y alertas para actualizar."
        Catch ex As Exception
            _estado.Text = "No se guardó: " & ex.Message
        End Try
    End Sub
End Class
