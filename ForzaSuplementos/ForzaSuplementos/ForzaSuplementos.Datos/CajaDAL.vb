Option Strict On
Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades

Public Class CajaDAL
    Public Function ObtenerAbierta(idUsuario As Integer) As SesionCaja
        Return ConsultarUna("dbo.sp_Caja_ObtenerAbierta", idUsuario, Nothing)
    End Function

    Public Function ObtenerReporte(idUsuario As Integer, idSesion As Integer) As SesionCaja
        Return ConsultarUna("dbo.sp_Caja_Reporte", idUsuario, idSesion)
    End Function

    Private Function ConsultarUna(procedimiento As String, idUsuario As Integer, idSesion As Integer?) As SesionCaja
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand(procedimiento, cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@idUsuario", SqlDbType.Int).Value = idUsuario
            If idSesion.HasValue Then cmd.Parameters.Add("@idSesion", SqlDbType.Int).Value = idSesion.Value
            cn.Open()
            Using dr = cmd.ExecuteReader()
                If dr.Read() Then Return LeerSesion(dr)
            End Using
        End Using
        Return Nothing
    End Function

    Public Function ListarHistorial(idUsuario As Integer, desde As Date, hasta As Date) As List(Of SesionCaja)
        Dim resultado As New List(Of SesionCaja)()
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand("dbo.sp_Caja_Historial", cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@idUsuario", SqlDbType.Int).Value = idUsuario
            cmd.Parameters.Add("@desde", SqlDbType.Date).Value = desde.Date
            cmd.Parameters.Add("@hasta", SqlDbType.Date).Value = hasta.Date
            cn.Open()
            Using dr = cmd.ExecuteReader()
                While dr.Read()
                    resultado.Add(LeerSesion(dr))
                End While
            End Using
        End Using
        Return resultado
    End Function

    Public Function Abrir(idUsuario As Integer, montoInicial As Decimal) As Integer
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand("dbo.sp_Caja_Abrir", cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@idUsuario", SqlDbType.Int).Value = idUsuario
            AgregarImporte(cmd, "@montoInicial", montoInicial)
            Dim id = cmd.Parameters.Add("@idSesion", SqlDbType.Int)
            id.Direction = ParameterDirection.Output
            cn.Open()
            cmd.ExecuteNonQuery()
            Return CInt(id.Value)
        End Using
    End Function

    Public Sub Cerrar(idUsuario As Integer, idSesion As Integer, montoReal As Decimal)
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand("dbo.sp_Caja_Cerrar", cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@idUsuario", SqlDbType.Int).Value = idUsuario
            cmd.Parameters.Add("@idSesion", SqlDbType.Int).Value = idSesion
            AgregarImporte(cmd, "@montoReal", montoReal)
            cn.Open()
            cmd.ExecuteNonQuery()
        End Using
    End Sub

    Friend Shared Sub AgregarImporte(cmd As SqlCommand, nombre As String, valor As Decimal)
        Dim parametro = cmd.Parameters.Add(nombre, SqlDbType.Decimal)
        parametro.Precision = 10
        parametro.Scale = 2
        parametro.Value = valor
    End Sub

    Private Shared Function LeerSesion(dr As SqlDataReader) As SesionCaja
        Return New SesionCaja With {
            .IdSesion = CInt(dr("idSesion")),
            .IdUsuarioApertura = CInt(dr("idUsuarioApertura")),
            .IdUsuarioCierre = If(IsDBNull(dr("idUsuarioCierre")), CType(Nothing, Integer?), CInt(dr("idUsuarioCierre"))),
            .UsuarioApertura = CStr(dr("usuarioApertura")),
            .UsuarioCierre = If(IsDBNull(dr("usuarioCierre")), Nothing, CStr(dr("usuarioCierre"))),
            .FechaApertura = CDate(dr("fechaApertura")),
            .FechaCierre = If(IsDBNull(dr("fechaCierre")), CType(Nothing, DateTime?), CDate(dr("fechaCierre"))),
            .MontoInicial = CDec(dr("montoInicial")),
            .MontoFinalEsperado = If(IsDBNull(dr("montoFinalEsperado")), CType(Nothing, Decimal?), CDec(dr("montoFinalEsperado"))),
            .MontoFinalReal = If(IsDBNull(dr("montoFinalReal")), CType(Nothing, Decimal?), CDec(dr("montoFinalReal"))),
            .Diferencia = If(IsDBNull(dr("diferencia")), CType(Nothing, Decimal?), CDec(dr("diferencia"))),
            .Estado = CStr(dr("estado")),
            .CantidadVentas = CInt(dr("cantidadVentas")),
            .ImporteVentas = CDec(dr("importeVentas")),
            .VentasEfectivo = CDec(dr("ventasEfectivo")),
            .VentasSinPago = CInt(dr("ventasSinPago"))
        }
    End Function
End Class
