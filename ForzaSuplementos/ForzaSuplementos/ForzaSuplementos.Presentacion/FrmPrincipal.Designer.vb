<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()>
Partial Class FrmPrincipal
    Inherits System.Windows.Forms.Form

    <System.Diagnostics.DebuggerNonUserCode()>
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    Private components As System.ComponentModel.IContainer
    Friend WithEvents MenuPrincipal As System.Windows.Forms.MenuStrip
    Friend WithEvents MenuArchivo As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuBackup As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuCerrarSesion As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuSalir As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuGestion As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuUsuarios As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuProductos As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuClientes As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuCaja As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuVentas As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents MenuReportes As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents BarraEstado As System.Windows.Forms.StatusStrip
    Friend WithEvents LblEstadoUsuario As System.Windows.Forms.ToolStripStatusLabel

    <System.Diagnostics.DebuggerStepThrough()>
    Private Sub InitializeComponent()
        Me.MenuPrincipal = New System.Windows.Forms.MenuStrip()
        Me.MenuArchivo = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuBackup = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuCerrarSesion = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuSalir = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuGestion = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuUsuarios = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuProductos = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuClientes = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuCaja = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuVentas = New System.Windows.Forms.ToolStripMenuItem()
        Me.MenuReportes = New System.Windows.Forms.ToolStripMenuItem()
        Me.BarraEstado = New System.Windows.Forms.StatusStrip()
        Me.LblEstadoUsuario = New System.Windows.Forms.ToolStripStatusLabel()
        Me.MenuPrincipal.SuspendLayout()
        Me.BarraEstado.SuspendLayout()
        Me.SuspendLayout()

        ' MenuPrincipal
        Me.MenuPrincipal.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.MenuPrincipal.ForeColor = System.Drawing.Color.White
        Me.MenuPrincipal.Items.AddRange(New System.Windows.Forms.ToolStripItem() {Me.MenuArchivo, Me.MenuGestion, Me.MenuCaja, Me.MenuVentas, Me.MenuReportes})
        Me.MenuPrincipal.Location = New System.Drawing.Point(0, 0)
        Me.MenuPrincipal.Name = "MenuPrincipal"
        Me.MenuPrincipal.Size = New System.Drawing.Size(1024, 28)
        Me.MenuPrincipal.Font = New System.Drawing.Font("Segoe UI", 10.0!)

        ' MenuArchivo
        Me.MenuArchivo.DropDownItems.AddRange(New System.Windows.Forms.ToolStripItem() {Me.MenuBackup, Me.MenuCerrarSesion, Me.MenuSalir})
        Me.MenuArchivo.Name = "MenuArchivo"
        Me.MenuArchivo.Text = "Archivo"

        Me.MenuBackup.Name = "MenuBackup"
        Me.MenuBackup.Text = "Backup (Respaldo)"
        Me.MenuBackup.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.MenuBackup.ForeColor = System.Drawing.Color.White

        Me.MenuCerrarSesion.Name = "MenuCerrarSesion"
        Me.MenuCerrarSesion.Text = "Cerrar Sesión"
        Me.MenuCerrarSesion.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.MenuCerrarSesion.ForeColor = System.Drawing.Color.White

        Me.MenuSalir.Name = "MenuSalir"
        Me.MenuSalir.Text = "Salir del Sistema"
        Me.MenuSalir.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.MenuSalir.ForeColor = System.Drawing.Color.White

        ' MenuGestion
        Me.MenuGestion.DropDownItems.AddRange(New System.Windows.Forms.ToolStripItem() {Me.MenuUsuarios, Me.MenuProductos, Me.MenuClientes})
        Me.MenuGestion.Name = "MenuGestion"
        Me.MenuGestion.Text = "Gestión"

        Me.MenuUsuarios.Name = "MenuUsuarios"
        Me.MenuUsuarios.Text = "Usuarios"
        Me.MenuUsuarios.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.MenuUsuarios.ForeColor = System.Drawing.Color.White

        Me.MenuProductos.Name = "MenuProductos"
        Me.MenuProductos.Text = "Catálogo de Productos"
        Me.MenuProductos.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.MenuProductos.ForeColor = System.Drawing.Color.White

        Me.MenuClientes.Name = "MenuClientes"
        Me.MenuClientes.Text = "Directorio de Clientes"
        Me.MenuClientes.BackColor = System.Drawing.Color.FromArgb(33, 37, 41)
        Me.MenuClientes.ForeColor = System.Drawing.Color.White

        ' MenuCaja
        Me.MenuCaja.Name = "MenuCaja"
        Me.MenuCaja.Text = "Control de Caja"

        ' MenuVentas
        Me.MenuVentas.Name = "MenuVentas"
        Me.MenuVentas.Text = "Generar Venta"

        ' MenuReportes
        Me.MenuReportes.Name = "MenuReportes"
        Me.MenuReportes.Text = "Reportes y Estadísticas"

        ' BarraEstado
        Me.BarraEstado.BackColor = System.Drawing.Color.FromArgb(52, 168, 132)
        Me.BarraEstado.ForeColor = System.Drawing.Color.White
        Me.BarraEstado.Items.AddRange(New System.Windows.Forms.ToolStripItem() {Me.LblEstadoUsuario})
        Me.BarraEstado.Location = New System.Drawing.Point(0, 700)
        Me.BarraEstado.Name = "BarraEstado"
        Me.BarraEstado.Size = New System.Drawing.Size(1024, 26)
        Me.BarraEstado.Font = New System.Drawing.Font("Segoe UI", 10.0!, System.Drawing.FontStyle.Bold)

        Me.LblEstadoUsuario.Name = "LblEstadoUsuario"
        Me.LblEstadoUsuario.Text = "Usuario: -"

        ' FrmPrincipal
        Me.ClientSize = New System.Drawing.Size(1024, 768)
        Me.Controls.Add(Me.BarraEstado)
        Me.Controls.Add(Me.MenuPrincipal)
        Me.IsMdiContainer = True
        Me.MainMenuStrip = Me.MenuPrincipal
        Me.Name = "FrmPrincipal"
        Me.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen
        Me.Text = "Forza Suplementos - Panel Principal"
        Me.WindowState = System.Windows.Forms.FormWindowState.Maximized

        Me.MenuPrincipal.ResumeLayout(False)
        Me.MenuPrincipal.PerformLayout()
        Me.BarraEstado.ResumeLayout(False)
        Me.BarraEstado.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()
    End Sub
End Class