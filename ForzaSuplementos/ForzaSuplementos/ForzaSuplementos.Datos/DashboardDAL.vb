Option Strict On
Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades

Public Class ProcedimientoReportePendienteException
    Inherits ApplicationException
    Public Sub New(nombre As String)
        MyBase.New("Reporte pendiente de habilitar en QA: " & nombre & ". Requiere aplicar la migración autorizada.")
    End Sub
End Class

Public Class DashboardDAL
    Private Shared Sub Validar(actor As Usuario, backups As Boolean)
        If actor Is Nothing OrElse actor.IdUsuario <= 0 Then Throw New ApplicationException("Sesión requerida para consultar indicadores.")
        Dim rol = If(actor.NombrePerfil, "").Trim().ToUpperInvariant()
        If If(backups, rol <> "ADMINISTRADOR", rol <> "GERENTE" AndAlso rol <> "VENDEDOR") Then Throw New ApplicationException("Perfil sin permiso para este dashboard.")
    End Sub

    Public Overridable Function Ventas(actor As Usuario, desde As Date, hasta As Date, vendedor As Integer?, producto As Integer?) As DataSet
        Validar(actor, False)
        If String.Equals(actor.NombrePerfil.Trim(), "VENDEDOR", StringComparison.OrdinalIgnoreCase) AndAlso vendedor.HasValue AndAlso vendedor.Value <> actor.IdUsuario Then Throw New ApplicationException("No podés consultar estadísticas ajenas.")
        Using cmd As New SqlCommand("dbo.sp_Reportes_VentasDashboard")
            Parametros(cmd, actor, desde, hasta)
            cmd.Parameters.Add("@idVendedor", SqlDbType.Int).Value = If(vendedor.HasValue, CType(vendedor.Value, Object), DBNull.Value)
            cmd.Parameters.Add("@idProducto", SqlDbType.Int).Value = If(producto.HasValue, CType(producto.Value, Object), DBNull.Value)
            Return Ejecutar(cmd)
        End Using
    End Function

    Public Overridable Function Backups(actor As Usuario, desde As Date, hasta As Date) As DataSet
        Validar(actor, True)
        Using cmd As New SqlCommand("dbo.sp_Reportes_BackupsDashboard")
            Parametros(cmd, actor, desde, hasta)
            Return Ejecutar(cmd)
        End Using
    End Function

    Public Overridable Function VentasBasicas(actor As Usuario) As DataTable
        Validar(actor, False)
        Dim dal As New ReporteDAL()
        If String.Equals(actor.NombrePerfil.Trim(), "VENDEDOR", StringComparison.OrdinalIgnoreCase) Then Return dal.MisVentas(actor)
        Return dal.HistorialVentas(actor)
    End Function

    Private Shared Sub Parametros(cmd As SqlCommand, actor As Usuario, desde As Date, hasta As Date)
        cmd.CommandType = CommandType.StoredProcedure
        cmd.Parameters.Add("@idActor", SqlDbType.Int).Value = actor.IdUsuario
        cmd.Parameters.Add("@desde", SqlDbType.Date).Value = desde.Date
        cmd.Parameters.Add("@hasta", SqlDbType.Date).Value = hasta.Date
    End Sub

    Protected Overridable Function Ejecutar(cmd As SqlCommand) As DataSet
        Try
            Using cn = Conexion.ObtenerConexion()
                cmd.Connection = cn
                Dim datos As New DataSet()
                Using adaptador As New SqlDataAdapter(cmd)
                    adaptador.Fill(datos)
                End Using
                Return datos
            End Using
        Catch ex As SqlException When ex.Number = 2812
            Throw New ProcedimientoReportePendienteException(cmd.CommandText)
        End Try
    End Function
End Class
