Imports System.Data
Imports System.Data.SqlClient

Public Class ReporteDAL
    Public Function HistorialVentas() As DataTable
        Dim dt As New DataTable()
        Using cn = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Reporte_HistorialVentas", cn)
                cmd.CommandType = CommandType.StoredProcedure
                Dim da As New SqlDataAdapter(cmd)
                da.Fill(dt)
            End Using
        End Using
        Return dt
    End Function

    Public Function BajoStock() As DataTable
        Dim dt As New DataTable()
        Using cn = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Reporte_BajoStock", cn)
                cmd.CommandType = CommandType.StoredProcedure
                Dim da As New SqlDataAdapter(cmd)
                da.Fill(dt)
            End Using
        End Using
        Return dt
    End Function

    Public Function MisVentas(idUsuario As Integer) As DataTable
        Dim dt As New DataTable()
        Using cn = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Reporte_MisVentas", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idUsuario", idUsuario)
                Dim da As New SqlDataAdapter(cmd)
                da.Fill(dt)
            End Using
        End Using
        Return dt
    End Function
End Class