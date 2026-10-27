Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmProductos
    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
    End Sub

    Private ReadOnly _bll As New ProductoBLL()
    Private _idProductoSeleccionado As Integer = 0

    Private Sub FrmProductos_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        CargarCategorias()
        CargarGrillaActivos()
        CargarGrillaInactivos()
        LimpiarCampos()
    End Sub

    Private Sub CargarCategorias()
        Try
            Dim lista = _bll.ObtenerCategorias()
            cboCategoria.DataSource = lista
            cboCategoria.DisplayMember = "NombreCategoria"
            cboCategoria.ValueMember = "IdCategoria"
            cboCategoria.SelectedIndex = -1
        Catch ex As Exception
            MessageBox.Show("Error al cargar categorías: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub CargarGrillaActivos()
        Try
            dgvActivos.DataSource = Nothing
            dgvActivos.DataSource = _bll.ObtenerProductos(True)
            ConfigurarColumnasGrilla(dgvActivos)
        Catch ex As Exception
            MessageBox.Show("Error al listar productos activos: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub CargarGrillaInactivos()
        Try
            dgvInactivos.DataSource = Nothing
            dgvInactivos.DataSource = _bll.ObtenerProductos(False)
            ConfigurarColumnasGrilla(dgvInactivos)
        Catch ex As Exception
            MessageBox.Show("Error al listar productos inactivos: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub ConfigurarColumnasGrilla(dgv As DataGridView)
        If dgv.Columns.Count > 0 Then
            dgv.Columns("IdCategoria").Visible = False
            dgv.Columns("Activo").Visible = False
            dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        End If
    End Sub

    Private Sub btnGuardar_Click(sender As Object, e As EventArgs) Handles btnGuardar.Click
        Try
            Dim precioVal As Decimal = 0
            Decimal.TryParse(txtPrecio.Text.Trim(), precioVal)

            Dim stockVal As Integer = 0
            Integer.TryParse(txtStock.Text.Trim(), stockVal)

            Dim p As New Producto() With {
                .IdProducto = _idProductoSeleccionado,
                .Nombre = txtNombre.Text.Trim(),
                .Descripcion = txtDescripcion.Text.Trim(),
                .Precio = precioVal,
                .Stock = stockVal,
                .IdCategoria = If(cboCategoria.SelectedValue IsNot Nothing, CInt(cboCategoria.SelectedValue), 0)
            }

            _bll.GuardarProducto(p)

            Dim accion = If(_idProductoSeleccionado = 0, "registrado", "modificado")
            MessageBox.Show($"Producto {accion} con éxito en Forza.", "Éxito", MessageBoxButtons.OK, MessageBoxIcon.Information)

            LimpiarCampos()
            CargarGrillaActivos()
            CargarGrillaInactivos()

        Catch ex As ApplicationException
            MessageBox.Show(ex.Message, "Validación", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        Catch ex As Exception
            MessageBox.Show("Ocurrió un error: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub btnBaja_Click(sender As Object, e As EventArgs) Handles btnBaja.Click
        If _idProductoSeleccionado = 0 Then
            MessageBox.Show("Seleccioná un producto activo de la tabla.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        If MessageBox.Show("¿Dar de baja lógica al producto?", "Confirmar Baja", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
            Try
                _bll.DarDeBaja(_idProductoSeleccionado)
                MessageBox.Show("Producto dado de baja.", "Baja Lógica", MessageBoxButtons.OK, MessageBoxIcon.Information)
                LimpiarCampos()
                CargarGrillaActivos()
                CargarGrillaInactivos()
            Catch ex As Exception
                MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
            End Try
        End If
    End Sub

    Private Sub btnReactivar_Click(sender As Object, e As EventArgs) Handles btnReactivar.Click
        If dgvInactivos.CurrentRow Is Nothing Then
            MessageBox.Show("Seleccioná un producto inactivo de la tabla.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        Dim idInactivo As Integer = CInt(dgvInactivos.CurrentRow.Cells("IdProducto").Value)
        Try
            _bll.Reactivar(idInactivo)
            MessageBox.Show("Producto reactivado.", "Reactivación", MessageBoxButtons.OK, MessageBoxIcon.Information)
            CargarGrillaActivos()
            CargarGrillaInactivos()
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub dgvActivos_CellDoubleClick(sender As Object, e As DataGridViewCellEventArgs) Handles dgvActivos.CellDoubleClick
        If e.RowIndex >= 0 Then
            Dim fila = dgvActivos.Rows(e.RowIndex)
            _idProductoSeleccionado = CInt(fila.Cells("IdProducto").Value)
            txtNombre.Text = fila.Cells("Nombre").Value.ToString()
            txtDescripcion.Text = fila.Cells("Descripcion").Value.ToString()
            txtPrecio.Text = fila.Cells("Precio").Value.ToString()
            txtStock.Text = fila.Cells("Stock").Value.ToString()
            cboCategoria.SelectedValue = CInt(fila.Cells("IdCategoria").Value)
            btnGuardar.Text = "Modificar"
        End If
    End Sub

    Private Sub LimpiarCampos()
        _idProductoSeleccionado = 0
        txtNombre.Clear()
        txtDescripcion.Clear()
        txtPrecio.Clear()
        txtStock.Clear()
        cboCategoria.SelectedIndex = -1
        btnGuardar.Text = "Guardar"
    End Sub

    Private Sub btnCancelar_Click(sender As Object, e As EventArgs) Handles btnCancelar.Click
        LimpiarCampos()
    End Sub
End Class
