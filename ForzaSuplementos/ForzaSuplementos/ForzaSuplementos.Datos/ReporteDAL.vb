Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades

Public Class ReporteDAL
    Public Function HistorialVentas(actor As Usuario) As DataTable
        ValidarActor(actor, False)
        Using cmd As New SqlCommand("sp_Reporte_HistorialVentas")
            cmd.CommandType = CommandType.StoredProcedure
            Return Ejecutar(cmd)
        End Using
    End Function

    Public Function BajoStock(actor As Usuario) As DataTable
        ValidarActor(actor, False)
        Using cmd As New SqlCommand("sp_Reporte_BajoStock")
            cmd.CommandType = CommandType.StoredProcedure
            Return Ejecutar(cmd)
        End Using
    End Function

    Public Function MisVentas(actor As Usuario) As DataTable
        ValidarActor(actor, True)
        Using cmd As New SqlCommand("sp_Reporte_MisVentas")
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@idUsuario", SqlDbType.Int).Value = actor.IdUsuario
            Return Ejecutar(cmd)
        End Using
    End Function

    Protected Overridable Function Ejecutar(comando As SqlCommand) As DataTable
        Dim dt As New DataTable()
        Using cn = Conexion.ObtenerConexion()
            comando.Connection = cn
            Using da As New SqlDataAdapter(comando)
                da.Fill(dt)
            End Using
        End Using
        Return dt
    End Function

    Private Shared Sub ValidarActor(actor As Usuario, propio As Boolean)
        If actor Is Nothing OrElse actor.IdUsuario <= 0 Then Throw New ApplicationException("Sesión requerida para consultar reportes.")
        Dim rol = If(actor.NombrePerfil, "").Trim().ToUpperInvariant()
        If (propio AndAlso rol <> "VENDEDOR") OrElse (Not propio AndAlso rol <> "ADMINISTRADOR" AndAlso rol <> "GERENTE") Then
            Throw New ApplicationException("Perfil sin permiso para consultar este reporte.")
        End If
    End Sub
End Class
