Option Strict On
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio

Public Class FrmCaja
    Private ReadOnly _bll As New CajaBLL()
    Private _sesion As SesionCaja
    Private _ocupado As Boolean
    Private _estadoConocido As Boolean
    Public Property UsuarioActual As Usuario

    Public Sub New()
        InitializeComponent()
        TemaForza.Aplicar(Me)
    End Sub

    Private Sub FrmCaja_Load(sender As Object, e As EventArgs) Handles MyBase.Load
        dtpDesde.Value = Date.Today.AddMonths(-1)
        dtpHasta.Value = Date.Today
        Ejecutar(Sub()
                     CajaBLL.ValidarVendedor(UsuarioActual)
                     Actualizar()
                 End Sub)
    End Sub

    Private Sub Actualizar()
        _estadoConocido = False
        _sesion = Nothing
        lblEstado.Text = "Consultando estado de Caja..."
        _sesion = _bll.ObtenerAbierta(UsuarioActual)
        _estadoConocido = True
        If _sesion Is Nothing Then
            lblEstado.Text = "Sin caja propia abierta. Una única caja física puede estar abierta a la vez."
        Else
            lblEstado.Text = $"Sesión #{_sesion.IdSesion} | {_sesion.UsuarioApertura} | Apertura: {_sesion.FechaApertura:dd/MM/yyyy HH:mm}" & Environment.NewLine &
                $"Inicial: $ {_sesion.MontoInicial:N2} | Efectivo vendido: $ {_sesion.VentasEfectivo:N2} | Esperado: {Importe(_sesion.MontoFinalEsperado)}"
            If _sesion.VentasSinPago > 0 Then lblEstado.Text &= Environment.NewLine & "Cierre bloqueado: existen ventas sin pago identificado."
        End If
        CargarHistorial()
    End Sub

    Private Sub CargarHistorial()
        dgvHistorial.DataSource = _bll.Historial(UsuarioActual, dtpDesde.Value, dtpHasta.Value)
        txtReporte.Clear()
    End Sub

    Private Sub ConfigurarEstado()
        btnAbrir.Enabled = Not _ocupado AndAlso _estadoConocido AndAlso _sesion Is Nothing
        btnCerrar.Enabled = Not _ocupado AndAlso _estadoConocido AndAlso _sesion IsNot Nothing AndAlso _sesion.VentasSinPago = 0
        nudInicial.Enabled = btnAbrir.Enabled
        nudReal.Enabled = btnCerrar.Enabled
        btnActualizar.Enabled = Not _ocupado
        btnFiltrar.Enabled = Not _ocupado
        btnReporte.Enabled = Not _ocupado AndAlso dgvHistorial.CurrentRow IsNot Nothing
    End Sub

    Private Sub Ejecutar(accion As Action)
        If _ocupado Then Return
        _ocupado = True
        ConfigurarEstado()
        Cursor = Cursors.WaitCursor
        Try
            accion()
        Catch ex As Exception
            _estadoConocido = False
            ' Ante un error de consulta se deshabilita operar hasta actualizar con éxito.
            btnAbrir.Enabled = False
            btnCerrar.Enabled = False
            MessageBox.Show(ex.Message, "Caja", MessageBoxButtons.OK, MessageBoxIcon.Warning)
        Finally
            Cursor = Cursors.Default
            _ocupado = False
            ConfigurarEstado()
        End Try
    End Sub

    Private Sub btnAbrir_Click(sender As Object, e As EventArgs) Handles btnAbrir.Click
        Ejecutar(Sub()
                     _bll.Abrir(UsuarioActual, nudInicial.Value)
                     Actualizar()
                 End Sub)
    End Sub

    Private Sub btnCerrar_Click(sender As Object, e As EventArgs) Handles btnCerrar.Click
        If _sesion Is Nothing Then Return
        If MessageBox.Show($"¿Cerrar la sesión #{_sesion.IdSesion} con $ {nudReal.Value:N2} contados?", "Confirmar cierre", MessageBoxButtons.YesNo, MessageBoxIcon.Question) <> DialogResult.Yes Then Return
        Dim id = _sesion.IdSesion
        Ejecutar(Sub()
                     _bll.Cerrar(UsuarioActual, id, nudReal.Value)
                     Actualizar()
                     MostrarReporte(id)
                 End Sub)
    End Sub

    Private Sub btnActualizar_Click(sender As Object, e As EventArgs) Handles btnActualizar.Click
        Ejecutar(AddressOf Actualizar)
    End Sub

    Private Sub btnFiltrar_Click(sender As Object, e As EventArgs) Handles btnFiltrar.Click
        Ejecutar(AddressOf CargarHistorial)
    End Sub

    Private Sub btnReporte_Click(sender As Object, e As EventArgs) Handles btnReporte.Click
        If dgvHistorial.CurrentRow Is Nothing Then Return
        Dim seleccion = TryCast(dgvHistorial.CurrentRow.DataBoundItem, SesionCaja)
        If seleccion IsNot Nothing Then Ejecutar(Sub() MostrarReporte(seleccion.IdSesion))
    End Sub

    Private Sub dgvHistorial_SelectionChanged(sender As Object, e As EventArgs) Handles dgvHistorial.SelectionChanged
        If btnReporte IsNot Nothing Then ConfigurarEstado()
    End Sub

    Private Sub MostrarReporte(idSesion As Integer)
        Dim s = _bll.Reporte(UsuarioActual, idSesion)
        txtReporte.Text = $"SESIÓN #{s.IdSesion} — {s.Estado}" & Environment.NewLine &
            $"Apertura: {s.UsuarioApertura} | {s.FechaApertura:dd/MM/yyyy HH:mm}" & Environment.NewLine &
            $"Cierre: {If(s.UsuarioCierre, "Pendiente")} | {If(s.FechaCierre.HasValue, s.FechaCierre.Value.ToString("dd/MM/yyyy HH:mm"), "Pendiente")}" & Environment.NewLine &
            $"Inicial: {Importe(s.MontoInicial)} | Ventas: {s.CantidadVentas} | Importe vendido: {Importe(s.ImporteVentas)}" & Environment.NewLine &
            $"Ventas en efectivo: {Importe(s.VentasEfectivo)} | Esperado: {Importe(s.MontoFinalEsperado)}" & Environment.NewLine &
            $"Real contado: {Importe(s.MontoFinalReal)} | Diferencia: {Importe(s.Diferencia)}" & Environment.NewLine &
            $"Ventas sin medio identificado: {s.VentasSinPago}. Transferencias y tarjetas no integran el efectivo."
    End Sub

    Private Shared Function Importe(valor As Decimal?) As String
        Return If(valor.HasValue, "$ " & valor.GetValueOrDefault().ToString("N2"), "No determinado")
    End Function
End Class
