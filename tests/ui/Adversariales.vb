Option Strict On
Option Infer On
Imports System
Imports System.Data
Imports System.Collections.Generic
Imports System.Reflection
Imports System.Threading.Tasks
Imports System.Windows.Forms
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio
Imports ForzaSuplementos.Presentacion

Public Class LoginAdversarial
    Inherits FrmLogin
    Public Intentos As Integer, Aperturas As Integer, Errores As Integer
    Public Fallar As Boolean, Nulo As Boolean, Reentrar As Boolean, FallarApertura As Boolean
    Public Sub Ingresar()
        GetType(FrmLogin).GetMethod("btnIngresar_Click", BindingFlags.Instance Or BindingFlags.NonPublic).Invoke(Me, New Object() {Me, EventArgs.Empty})
    End Sub
    Protected Overrides Sub OnLoad(e As EventArgs)
    End Sub
    Protected Overrides Function Autenticar(nombre As String, clave As String) As Usuario
        Intentos += 1
        If Reentrar Then Ingresar()
        If Fallar Then Throw New ApplicationException("Fallo sintético de conexión/validación")
        If Nulo Then Return Nothing
        Return New Usuario With {.IdUsuario = 37, .NombrePerfil = "VENDEDOR"}
    End Function
    Protected Overrides Sub MostrarPrincipal(u As Usuario)
        If FallarApertura Then Throw New ApplicationException("Fallo sintético al abrir")
        Aperturas += 1
    End Sub
    Protected Overrides Sub InformarError(mensaje As String)
        Errores += 1
    End Sub
End Class
Public Class VentasAdversarial
    Inherits FrmVentas
    Public Registros As Integer
    Public Reentrar As Boolean, Incierta As Boolean, Fallar As Boolean, FallarRecarga As Boolean
    Public Avisos As New List(Of String)
    Public Descartar As Boolean
    Public Sub New()
        UsuarioActual = New Usuario With {.IdUsuario = 37, .NombrePerfil = "VENDEDOR"}
        UsuarioActualId = 37
        Dim cbo = DirectCast(GetType(FrmVentas).GetProperty("cboMedioPago", BindingFlags.Instance Or BindingFlags.NonPublic Or BindingFlags.Public).GetValue(Me, Nothing), ComboBox)
        cbo.Items.AddRange(New String() {"Seleccionar", "Efectivo", "Transferencia", "Tarjeta"}) : cbo.SelectedIndex = 1
        EstablecerCatalogos(New List(Of Cliente)(), New List(Of Producto)())
    End Sub
    Protected Overrides Sub OnLoad(e As EventArgs)
    End Sub
    Public Sub Cliente(c As Cliente)
        SeleccionarCliente(c)
    End Sub
    Public Sub Producto(p As Producto)
        SeleccionarProducto(p)
    End Sub
    Public Sub Agregar(c As Integer)
        AgregarProducto(c)
    End Sub
    Public Function Pendiente() As Venta
        Return CrearVentaPendiente()
    End Function
    Public Sub Confirmar()
        GetType(FrmVentas).GetMethod("btnConfirmar_Click", BindingFlags.Instance Or BindingFlags.NonPublic).Invoke(Me, New Object() {Me, EventArgs.Empty})
    End Sub
    Public Sub Vaciar()
        GetType(FrmVentas).GetMethod("btnCancelar_Click", BindingFlags.Instance Or BindingFlags.NonPublic).Invoke(Me, New Object() {Me, EventArgs.Empty})
    End Sub
    Protected Overrides Sub RegistrarVenta(v As Venta)
        VentaBLL.ValidarVenta(v)
        Registros += 1
        If Reentrar Then Confirmar()
        If Incierta Then Throw New OperacionInciertaException("Respuesta sintética perdida")
        If Fallar Then Throw New ApplicationException("Rechazo sintético antes de confirmar")
        v.IdVenta = 50
    End Sub
    Protected Overrides Function RecargarTrasConfirmacion() As Task
        If FallarRecarga Then
            Dim t As New TaskCompletionSource(Of Boolean)() : t.SetException(New ApplicationException("Fallo sintético de catálogo")) : Return t.Task
        End If
        Return Task.CompletedTask
    End Function
    Protected Overrides Sub NotificarVenta(mensaje As String, fallo As Boolean)
        Avisos.Add(mensaje)
    End Sub
    Protected Overrides Function ConfirmarDescarteIncierto() As Boolean
        Return Descartar
    End Function
End Class
Public Class ReportesAdversarial
    Inherits FrmReportes
    Public Demora As New TaskCompletionSource(Of DashboardVentas)()
    Public CantidadPuntos As Integer = 1
    Public UsarDemora As Boolean
    Public Fallar As Boolean
    Public Sub New()
        UsuarioActual = New Usuario With {.IdUsuario = 37, .NombrePerfil = "GERENTE"}
        GetType(FrmReportes).GetMethod("ConfigurarPermisos", BindingFlags.Instance Or BindingFlags.NonPublic).Invoke(Me, Nothing)
    End Sub
    Protected Overrides Sub OnLoad(e As EventArgs)
    End Sub
    Public Shared Function Modelo(Optional cantidad As Integer = 1) As DashboardVentas
        Dim d As New DashboardVentas With {.Completo = True, .TotalFacturado = 10D * cantidad, .Operaciones = cantidad, .Unidades = cantidad}
        For i As Integer = 1 To cantidad
            d.Diaria.Add(New PuntoReporte With {.Etiqueta = i.ToString(), .Importe = 10, .Cantidad = 1})
        Next
        Return d
    End Function
    Protected Overrides Function ConsultarVentasAsync(actor As Usuario, desde As Date, hasta As Date, vendedor As Integer?, producto As Integer?) As Task(Of DashboardVentas)
        If UsarDemora Then Return Demora.Task
        If Fallar Then
            Dim t As New TaskCompletionSource(Of DashboardVentas)() : t.SetException(New ApplicationException("Error sintético SQL")) : Return t.Task
        End If
        Return Task.FromResult(Modelo(CantidadPuntos))
    End Function
    Public Function Actualizar() As Task
        Return DirectCast(GetType(FrmReportes).GetMethod("ActualizarDashboard", BindingFlags.Instance Or BindingFlags.NonPublic).Invoke(Me, Nothing), Task)
    End Function
    Public Sub Heredada(falla As Boolean)
        Dim f As Func(Of DataTable) = Function()
                                         If falla Then Throw New ApplicationException("Error sintético consulta")
                                         Dim t As New DataTable() : t.Columns.Add("Resultado") : t.Rows.Add("sintético") : Return t
                                     End Function
        GetType(FrmReportes).GetMethod("ConsultaHeredada", BindingFlags.Instance Or BindingFlags.NonPublic).Invoke(Me, New Object() {f})
    End Sub
End Class
