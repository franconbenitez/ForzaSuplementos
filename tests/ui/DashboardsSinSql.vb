Option Strict On
Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Windows.Forms
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Presentacion

Namespace ForzaPruebasUI
    Public Class DashboardSimulado
        Inherits DashboardDAL
        Public Datos As DataSet
        Public Basico As DataTable
        Public Pendiente As Boolean
        Public Fallar As Boolean
        Public Llamadas As Integer
        Public LlamadasBasicas As Integer
        Public VendedorSolicitado As Integer?
        Public ProductoSolicitado As Integer?
        Public Overrides Function Ventas(actor As Usuario, desde As Date, hasta As Date, vendedor As Integer?, producto As Integer?) As DataSet
            Llamadas += 1 : VendedorSolicitado = vendedor : ProductoSolicitado = producto
            If Fallar Then Throw New InvalidOperationException("Error SQL simulado sin fallback")
            If Pendiente Then Throw New ProcedimientoReportePendienteException("SP pendiente")
            Return Datos
        End Function
        Public Overrides Function VentasBasicas(actor As Usuario) As DataTable
            LlamadasBasicas += 1
            Return Basico
        End Function
        Public Overrides Function Backups(actor As Usuario, desde As Date, hasta As Date) As DataSet
            Llamadas += 1
            If Pendiente Then Throw New ProcedimientoReportePendienteException("SP backups pendiente")
            Return Datos
        End Function
    End Class
    Public Class DashboardCaptura
        Inherits DashboardDAL
        Public ActorId As Integer
        Public VendedorId As Integer?
        Public EsSP As Boolean
        Public FechaTipo As SqlDbType
        Protected Overrides Function Ejecutar(cmd As SqlCommand) As DataSet
            ActorId = CInt(cmd.Parameters("@idActor").Value)
            VendedorId = Nothing
            If cmd.Parameters.Contains("@idVendedor") AndAlso Not Convert.IsDBNull(cmd.Parameters("@idVendedor").Value) Then VendedorId = CInt(cmd.Parameters("@idVendedor").Value)
            EsSP = cmd.CommandType = CommandType.StoredProcedure
            FechaTipo = cmd.Parameters("@desde").SqlDbType
            Return New DataSet()
        End Function
    End Class
    Public Class DashboardVista
        Inherits FrmReportes
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
        Public Sub Perfil(actor As Usuario)
            UsuarioActual = actor
            GetType(FrmReportes).GetMethod("ConfigurarPermisos", Reflection.BindingFlags.Instance Or Reflection.BindingFlags.NonPublic).Invoke(Me, Nothing)
        End Sub
        Public Sub Modelo(datos As DashboardVentas)
            GetType(FrmReportes).GetField("_ventas", Reflection.BindingFlags.Instance Or Reflection.BindingFlags.NonPublic).SetValue(Me, datos)
            GetType(FrmReportes).GetMethod("MostrarGrafico", Reflection.BindingFlags.Instance Or Reflection.BindingFlags.NonPublic).Invoke(Me, Nothing)
        End Sub
    End Class
End Namespace
