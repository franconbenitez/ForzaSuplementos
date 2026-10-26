Imports System.Data
Imports System.Data.SqlClient

Public Class BackupDAL
    Public Sub GenerarBackup(ruta As String)
        Using cn = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Backup_Generar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@rutaDestino", ruta)
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub
End Class