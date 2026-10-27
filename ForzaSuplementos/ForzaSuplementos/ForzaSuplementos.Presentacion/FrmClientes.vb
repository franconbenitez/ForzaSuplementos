Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmClientes
    Public Property UsuarioActual As ForzaSuplementos.Entidades.Usuario
    Private ReadOnly _protector As ProtectorCambios

    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
        _protector = ProtectorCambios.ParaEdicion(Me, txtDni, txtNombre, txtApellido, txtTelefono, txtEmail)
    End Sub

    Private ReadOnly _bll As New ClienteBLL()
    Private _idClienteSeleccionado As Integer = 0

    Private Sub FrmClientes_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        If Not AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Clientes) Then Return
        CargarGrillas()
        Limpiar()
    End Sub

    Private Sub CargarGrillas()
        Try
            dgvActivos.DataSource = _bll.ObtenerClientes(True, UsuarioActual)
            dgvInactivos.DataSource = _bll.ObtenerClientes(False, UsuarioActual)
            OcultarId(dgvActivos)
            OcultarId(dgvInactivos)
        Catch ex As Exception
            MessageBox.Show("Error al cargar clientes: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub OcultarId(dgv As DataGridView)
        If dgv.Columns.Contains("IdCliente") Then dgv.Columns("IdCliente").Visible = False
        If dgv.Columns.Contains("Activo") Then dgv.Columns("Activo").Visible = False
        dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
    End Sub

    Private Sub btnGuardar_Click(sender As Object, e As EventArgs) Handles btnGuardar.Click
        Try
            Dim c As New Cliente() With {
                .IdCliente = _idClienteSeleccionado,
                .Dni = txtDni.Text.Trim(),
                .Nombre = txtNombre.Text.Trim(),
                .Apellido = txtApellido.Text.Trim(),
                .Telefono = txtTelefono.Text.Trim(),
                .Email = txtEmail.Text.Trim()
            }

            _bll.Guardar(c, UsuarioActual)
            MessageBox.Show("Cliente guardado correctamente.", "Éxito", MessageBoxButtons.OK, MessageBoxIcon.Information)
            CargarGrillas()
            Limpiar()
        Catch ex As ApplicationException
            MessageBox.Show(ex.Message, "Validación", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        Catch ex As Exception
            MessageBox.Show("Error: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub dgvActivos_CellDoubleClick(sender As Object, e As DataGridViewCellEventArgs) Handles dgvActivos.CellDoubleClick
        If e.RowIndex >= 0 Then
            Dim fila = dgvActivos.Rows(e.RowIndex)
            _idClienteSeleccionado = CInt(fila.Cells("IdCliente").Value)
            txtDni.Text = fila.Cells("Dni").Value.ToString()
            txtNombre.Text = fila.Cells("Nombre").Value.ToString()
            txtApellido.Text = fila.Cells("Apellido").Value.ToString()
            txtTelefono.Text = fila.Cells("Telefono").Value.ToString()
            txtEmail.Text = fila.Cells("Email").Value.ToString()
            btnGuardar.Text = "Modificar"
            _protector.EstablecerBase()
        End If
    End Sub

    Private Sub btnBaja_Click(sender As Object, e As EventArgs) Handles btnBaja.Click
        If _idClienteSeleccionado = 0 Then
            MessageBox.Show("Seleccioná un cliente activo.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        If MessageBox.Show("¿Dar de baja al cliente?", "Confirmar", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
            _bll.CambiarEstado(_idClienteSeleccionado, False, UsuarioActual)
            CargarGrillas()
            Limpiar()
        End If
    End Sub

    Private Sub btnReactivar_Click(sender As Object, e As EventArgs) Handles btnReactivar.Click
        If dgvInactivos.CurrentRow IsNot Nothing Then
            Dim id = CInt(dgvInactivos.CurrentRow.Cells("IdCliente").Value)
            _bll.CambiarEstado(id, True, UsuarioActual)
            CargarGrillas()
        End If
    End Sub

    Private Sub Limpiar()
        _idClienteSeleccionado = 0
        txtDni.Clear()
        txtNombre.Clear()
        txtApellido.Clear()
        txtTelefono.Clear()
        txtEmail.Clear()
        btnGuardar.Text = "Guardar"
        _protector.EstablecerBase()
    End Sub

    Private Sub btnCancelar_Click(sender As Object, e As EventArgs) Handles btnCancelar.Click
        Limpiar()
    End Sub
End Class
