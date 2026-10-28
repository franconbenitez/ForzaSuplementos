Option Strict On
Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades

Public Class SeguridadDAL
    Public Overridable Function Activa() As Boolean
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand("dbo.sp_Seguridad_Estado", cn)
            cmd.CommandType = CommandType.StoredProcedure
            cn.Open()
            Try
                Return Convert.ToBoolean(cmd.ExecuteScalar())
            Catch ex As SqlException When ex.Number = 2812
                ' Compatibilidad SOLO antes de desplegar 005. No se ignoran otros errores.
                Return False
            End Try
        End Using
    End Function
    Public Overridable Function Obtener(nombre As String) As CredencialAcceso
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand("dbo.sp_Seguridad_Credencial", cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@usuario", SqlDbType.VarChar, 50).Value = nombre
            cn.Open()
            Using r = cmd.ExecuteReader()
                If Not r.Read() Then Return Nothing
                Return New CredencialAcceso With {.Formato = CStr(r("formato")), .Cuenta = New Usuario With {.IdUsuario = CInt(r("idUsuario")), .IdPerfil = CInt(r("idPerfil")), .NombrePerfil = CStr(r("nombrePerfil")), .Nombre = CStr(r("nombre")), .Apellido = CStr(r("apellido")), .Activo = True}}
            End Using
        End Using
    End Function
    Public Overridable Sub Cambiar(actor As Usuario, destino As Integer, nuevo As String, anterior As String)
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand("dbo.sp_Seguridad_Cambiar", cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@idActor", SqlDbType.Int).Value = actor.IdUsuario
            cmd.Parameters.Add("@idDestino", SqlDbType.Int).Value = destino
            cmd.Parameters.Add("@nuevo", SqlDbType.VarChar, 256).Value = nuevo
            cmd.Parameters.Add("@anterior", SqlDbType.VarChar, 256).Value = If(anterior Is Nothing, CType(DBNull.Value, Object), anterior)
            cn.Open():cmd.ExecuteNonQuery()
        End Using
    End Sub
    Public Overridable Sub Guardar(u As Usuario, actor As Usuario, formato As String)
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand("dbo.sp_Seguridad_UsuarioGuardar", cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@idActor", SqlDbType.Int).Value = actor.IdUsuario
            cmd.Parameters.Add("@idUsuario", SqlDbType.Int).Value = u.IdUsuario
            cmd.Parameters.Add("@idPerfil", SqlDbType.Int).Value = u.IdPerfil
            For Each par In New KeyValuePair(Of String, String)() {New KeyValuePair(Of String, String)("nombre", u.Nombre), New KeyValuePair(Of String, String)("apellido", u.Apellido), New KeyValuePair(Of String, String)("usuario", u.NombreUsuario), New KeyValuePair(Of String, String)("email", u.Email), New KeyValuePair(Of String, String)("dni", u.Dni), New KeyValuePair(Of String, String)("calle", u.Calle), New KeyValuePair(Of String, String)("altura", u.Altura), New KeyValuePair(Of String, String)("telefono", u.Telefono)}
                cmd.Parameters.Add("@" & par.Key, SqlDbType.VarChar, 100).Value = par.Value
            Next
            cmd.Parameters.Add("@fechaNacimiento", SqlDbType.Date).Value = u.FechaNacimiento
            cmd.Parameters.Add("@sexo", SqlDbType.Char, 1).Value = u.Sexo
            cmd.Parameters.Add("@formato", SqlDbType.VarChar, 256).Value = If(formato Is Nothing, CType(DBNull.Value, Object), formato)
            cn.Open():cmd.ExecuteNonQuery()
        End Using
    End Sub
End Class
