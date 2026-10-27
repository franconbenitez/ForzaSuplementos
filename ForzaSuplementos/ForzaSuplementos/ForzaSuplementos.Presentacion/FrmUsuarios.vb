Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmUsuarios
    Public Property UsuarioActual As ForzaSuplementos.Entidades.Usuario
    Private ReadOnly _protector As ProtectorCambios

    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
        _protector = ProtectorCambios.ParaEdicion(Me, txtNombre, txtApellido, txtUsuario, txtContrasena, txtEmail, txtDni, txtCalle, txtAltura, txtTelefono, dtpFechaNac, rbHombre, rbMujer, cboPerfil)
    End Sub

    Private ReadOnly _bll As New UsuarioBLL()
    Private _idUsuarioSeleccionado As Integer = 0

    Private Sub FrmUsuarios_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        If Not AccesoFormulario.Validar(Me, UsuarioActual, Permiso.Usuarios) Then Return
        CargarPerfiles()
        CargarGrillaActivos()
        CargarGrillaInactivos()
        LimpiarCampos()
    End Sub

    Private Sub CargarPerfiles()
        Try
            Dim perfiles = _bll.ObtenerPerfiles(UsuarioActual)
            cboPerfil.DataSource = perfiles
            cboPerfil.DisplayMember = "NombrePerfil"
            cboPerfil.ValueMember = "IdPerfil"
            cboPerfil.SelectedIndex = -1
        Catch ex As Exception
            MessageBox.Show("Error al cargar roles. Verificá si SQL Server está abierto: " & ex.Message, "Error de Conexión", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub CargarGrillaActivos()
        Try
            dgvActivos.DataSource = Nothing
            dgvActivos.DataSource = _bll.ObtenerUsuarios(True, UsuarioActual)
            ConfigurarColumnasGrilla(dgvActivos)
        Catch ex As Exception
            MessageBox.Show("Error al listar usuarios activos: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub CargarGrillaInactivos()
        Try
            dgvInactivos.DataSource = Nothing
            dgvInactivos.DataSource = _bll.ObtenerUsuarios(False, UsuarioActual)
            ConfigurarColumnasGrilla(dgvInactivos)
        Catch ex As Exception
            MessageBox.Show("Error al listar usuarios inactivos: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub ConfigurarColumnasGrilla(dgv As DataGridView)
        If dgv.Columns.Count > 0 Then
            dgv.Columns("Contrasena").Visible = False
            dgv.Columns("IdPerfil").Visible = False
            dgv.Columns("Activo").Visible = False
            dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
        End If
    End Sub

    Private Sub btnGuardar_Click(sender As Object, e As EventArgs) Handles btnGuardar.Click
        Try
            Dim u As New Usuario() With {
                .IdUsuario = _idUsuarioSeleccionado,
                .Nombre = txtNombre.Text.Trim(),
                .Apellido = txtApellido.Text.Trim(),
                .NombreUsuario = txtUsuario.Text.Trim(),
                .Contrasena = txtContrasena.Text.Trim(),
                .Email = txtEmail.Text.Trim(),
                .Dni = txtDni.Text.Trim(),
                .Calle = txtCalle.Text.Trim(),
                .Altura = txtAltura.Text.Trim(),
                .Telefono = txtTelefono.Text.Trim(),
                .FechaNacimiento = dtpFechaNac.Value.Date,
                .Sexo = If(rbHombre.Checked, "M"c, "F"c),
                .IdPerfil = If(cboPerfil.SelectedValue IsNot Nothing, CInt(cboPerfil.SelectedValue), 0)
            }

            _bll.GuardarUsuario(u, UsuarioActual)

            Dim accion = If(_idUsuarioSeleccionado = 0, "registrado", "modificado")
            MessageBox.Show($"Usuario {accion} con éxito en Forza.", "Éxito", MessageBoxButtons.OK, MessageBoxIcon.Information)

            LimpiarCampos()
            CargarGrillaActivos()
            CargarGrillaInactivos()

        Catch ex As ApplicationException
            MessageBox.Show(ex.Message, "Validación Estricta", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        Catch ex As SqlException
            MessageBox.Show("Error de Base de Datos: " & ex.Message, "Error SQL", MessageBoxButtons.OK, MessageBoxIcon.Error)
        Catch ex As Exception
            MessageBox.Show("Ocurrió un error inesperado: " & ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub btnCancelar_Click(sender As Object, e As EventArgs) Handles btnCancelar.Click
        LimpiarCampos()
    End Sub

    Private Sub btnBaja_Click(sender As Object, e As EventArgs) Handles btnBaja.Click
        If _idUsuarioSeleccionado = 0 Then
            MessageBox.Show("Seleccioná un usuario activo de la tabla.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        If MessageBox.Show("¿Dar de baja lógica al usuario?", "Confirmar Baja", MessageBoxButtons.YesNo, MessageBoxIcon.Question) = DialogResult.Yes Then
            Try
                _bll.DarDeBaja(_idUsuarioSeleccionado, UsuarioActual)
                MessageBox.Show("Usuario dado de baja exitosamente.", "Baja Lógica", MessageBoxButtons.OK, MessageBoxIcon.Information)
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
            MessageBox.Show("Seleccioná un usuario de la tabla de inactivos.", "Atención", MessageBoxButtons.OK, MessageBoxIcon.Information)
            Return
        End If

        Dim idInactivo As Integer = CInt(dgvInactivos.CurrentRow.Cells("IdUsuario").Value)
        Try
            _bll.Reactivar(idInactivo, UsuarioActual)
            MessageBox.Show("Usuario reactivado.", "Reactivación", MessageBoxButtons.OK, MessageBoxIcon.Information)
            CargarGrillaActivos()
            CargarGrillaInactivos()
        Catch ex As Exception
            MessageBox.Show(ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error)
        End Try
    End Sub

    Private Sub dgvActivos_CellDoubleClick(sender As Object, e As DataGridViewCellEventArgs) Handles dgvActivos.CellDoubleClick
        If e.RowIndex >= 0 Then
            Dim fila = dgvActivos.Rows(e.RowIndex)
            _idUsuarioSeleccionado = CInt(fila.Cells("IdUsuario").Value)
            txtNombre.Text = fila.Cells("Nombre").Value.ToString()
            txtApellido.Text = fila.Cells("Apellido").Value.ToString()
            txtUsuario.Text = fila.Cells("NombreUsuario").Value.ToString()
            txtContrasena.Text = fila.Cells("Contrasena").Value.ToString()
            txtDni.Text = fila.Cells("Dni").Value.ToString()
            txtEmail.Text = fila.Cells("Email").Value.ToString()
            txtCalle.Text = fila.Cells("Calle").Value.ToString()
            txtAltura.Text = fila.Cells("Altura").Value.ToString()
            txtTelefono.Text = fila.Cells("Telefono").Value.ToString()
            dtpFechaNac.Value = CDate(fila.Cells("FechaNacimiento").Value)

            Dim sexo As String = fila.Cells("Sexo").Value.ToString()
            rbHombre.Checked = (sexo = "M")
            rbMujer.Checked = (sexo = "F")

            cboPerfil.SelectedValue = CInt(fila.Cells("IdPerfil").Value)
            btnGuardar.Text = "Modificar"
            _protector.EstablecerBase()
        End If
    End Sub

    Private Sub LimpiarCampos()
        _idUsuarioSeleccionado = 0
        txtNombre.Clear() : txtApellido.Clear() : txtUsuario.Clear() : txtContrasena.Clear()
        txtEmail.Clear() : txtDni.Clear() : txtCalle.Clear() : txtAltura.Clear() : txtTelefono.Clear()
        dtpFechaNac.Value = Date.Today.AddYears(-20)
        rbHombre.Checked = True
        cboPerfil.SelectedIndex = -1
        btnGuardar.Text = "Guardar"
        _protector.EstablecerBase()
    End Sub

    ' =========================================================
    ' VALIDACIONES DE TECLADO EN INTERFAZ
    ' =========================================================

    Private Sub txtDni_KeyPress(sender As Object, e As KeyPressEventArgs) Handles txtDni.KeyPress, txtTelefono.KeyPress
        ' Bloquea letras en DNI y teléfono. Solo permite números y borrar.
        If Not Char.IsDigit(e.KeyChar) AndAlso Not Char.IsControl(e.KeyChar) Then
            e.Handled = True
        End If
    End Sub

    Private Sub txtNombre_KeyPress(sender As Object, e As KeyPressEventArgs) Handles txtNombre.KeyPress, txtApellido.KeyPress, txtCalle.KeyPress
        ' Bloquea números.
        If Not Char.IsLetter(e.KeyChar) AndAlso Not Char.IsControl(e.KeyChar) AndAlso Not Char.IsWhiteSpace(e.KeyChar) Then
            e.Handled = True
        End If
    End Sub
End Class
