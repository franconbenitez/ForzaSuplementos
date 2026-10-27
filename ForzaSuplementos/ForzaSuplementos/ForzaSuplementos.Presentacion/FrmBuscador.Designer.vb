<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmBuscador
    Inherits System.Windows.Forms.Form

    Protected Overrides Sub Dispose(disposing As Boolean)
        Try
            If disposing Then
                CancelarBusqueda()
                If components IsNot Nothing Then components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    Private components As System.ComponentModel.IContainer
    Friend WithEvents lblTitulo As System.Windows.Forms.Label
    Friend WithEvents lblAyuda As System.Windows.Forms.Label
    Friend WithEvents txtBuscar As System.Windows.Forms.TextBox
    Friend WithEvents dgvResultados As System.Windows.Forms.DataGridView
    Friend WithEvents lblEstado As System.Windows.Forms.Label
    Friend WithEvents btnSeleccionar As System.Windows.Forms.Button
    Friend WithEvents btnCancelar As System.Windows.Forms.Button
    Friend WithEvents tmrBusqueda As System.Windows.Forms.Timer

    Private Sub InitializeComponent()
        Me.components = New System.ComponentModel.Container()
        Me.lblTitulo = New System.Windows.Forms.Label()
        Me.lblAyuda = New System.Windows.Forms.Label()
        Me.txtBuscar = New System.Windows.Forms.TextBox()
        Me.dgvResultados = New System.Windows.Forms.DataGridView()
        Me.lblEstado = New System.Windows.Forms.Label()
        Me.btnSeleccionar = New System.Windows.Forms.Button()
        Me.btnCancelar = New System.Windows.Forms.Button()
        Me.tmrBusqueda = New System.Windows.Forms.Timer(Me.components)
        CType(Me.dgvResultados, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()
        Me.lblTitulo.Location = New System.Drawing.Point(20, 15)
        Me.lblTitulo.Size = New System.Drawing.Size(820, 30)
        Me.lblTitulo.Font = New System.Drawing.Font("Segoe UI", 14.0!, System.Drawing.FontStyle.Bold)
        Me.lblTitulo.Text = "BUSCAR CLIENTE"
        Me.lblAyuda.Location = New System.Drawing.Point(20, 53)
        Me.lblAyuda.Size = New System.Drawing.Size(820, 22)
        Me.lblAyuda.Text = "Nombre, apellido, DNI o ID. Enter o doble clic para seleccionar; Esc para volver."
        Me.txtBuscar.Location = New System.Drawing.Point(20, 80)
        Me.txtBuscar.Size = New System.Drawing.Size(820, 27)
        Me.txtBuscar.Anchor = System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Left Or System.Windows.Forms.AnchorStyles.Right
        Me.txtBuscar.MaxLength = 120
        Me.dgvResultados.Location = New System.Drawing.Point(20, 120)
        Me.dgvResultados.Size = New System.Drawing.Size(820, 335)
        Me.dgvResultados.Anchor = System.Windows.Forms.AnchorStyles.Top Or System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left Or System.Windows.Forms.AnchorStyles.Right
        Me.dgvResultados.ReadOnly = True
        Me.dgvResultados.MultiSelect = False
        Me.dgvResultados.AllowUserToAddRows = False
        Me.dgvResultados.AllowUserToDeleteRows = False
        Me.dgvResultados.AllowUserToResizeRows = False
        Me.dgvResultados.RowHeadersVisible = False
        Me.dgvResultados.AutoGenerateColumns = False
        Me.dgvResultados.AutoSizeColumnsMode = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill
        Me.dgvResultados.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect
        Me.lblEstado.Location = New System.Drawing.Point(20, 468)
        Me.lblEstado.Size = New System.Drawing.Size(470, 45)
        Me.lblEstado.Anchor = System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Left
        Me.lblEstado.Text = "Preparando catálogo..."
        Me.btnSeleccionar.Location = New System.Drawing.Point(500, 470)
        Me.btnSeleccionar.Size = New System.Drawing.Size(165, 38)
        Me.btnSeleccionar.Anchor = System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right
        Me.btnSeleccionar.Text = "Seleccionar"
        Me.btnSeleccionar.Enabled = False
        Me.btnCancelar.Location = New System.Drawing.Point(680, 470)
        Me.btnCancelar.Size = New System.Drawing.Size(160, 38)
        Me.btnCancelar.Anchor = System.Windows.Forms.AnchorStyles.Bottom Or System.Windows.Forms.AnchorStyles.Right
        Me.btnCancelar.Text = "Cancelar"
        Me.btnCancelar.DialogResult = System.Windows.Forms.DialogResult.Cancel
        Me.tmrBusqueda.Interval = 180
        Me.AcceptButton = Me.btnSeleccionar
        Me.CancelButton = Me.btnCancelar
        Me.ClientSize = New System.Drawing.Size(860, 530)
        Me.MinimumSize = New System.Drawing.Size(876, 569)
        Me.Font = New System.Drawing.Font("Segoe UI", 9.0!)
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent
        Me.ShowInTaskbar = False
        Me.MinimizeBox = False
        Me.Text = "Buscar - Forza Suplementos"
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.lblTitulo, Me.lblAyuda, Me.txtBuscar, Me.dgvResultados, Me.lblEstado, Me.btnSeleccionar, Me.btnCancelar})
        CType(Me.dgvResultados, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class
