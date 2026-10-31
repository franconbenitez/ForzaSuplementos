Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades

Public Class UsuarioDAL
    Public Function ListarPerfiles() As List(Of Perfil)
        Dim lista As New List(Of Perfil)()
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Perfiles_Listar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cn.Open()
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        lista.Add(New Perfil(CInt(dr("idPerfil")), dr("nombrePerfil").ToString()))
                    End While
                End Using
            End Using
        End Using
        Return lista
    End Function

    Public Function ListarUsuariosPorEstado(activo As Boolean) As List(Of Usuario)
        Dim lista As New List(Of Usuario)()
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Usuarios_ListarPorEstado", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@activo", activo)
                cn.Open()
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        lista.Add(New Usuario() With {
                            .IdUsuario = CInt(dr("idUsuario")),
                            .IdPerfil = CInt(dr("idPerfil")),
                            .NombrePerfil = dr("nombrePerfil").ToString(),
                            .Nombre = dr("nombre").ToString(),
                            .Apellido = dr("apellido").ToString(),
                            .NombreUsuario = dr("usuario").ToString(),
                            .Contrasena = String.Empty,
                            .Email = dr("email").ToString(),
                            .Dni = dr("dni").ToString(),
                            .Calle = dr("calle").ToString(),
                            .Altura = dr("altura").ToString(),
                            .Telefono = dr("telefono").ToString(),
                            .FechaNacimiento = CDate(dr("fechaNacimiento")),
                            .Sexo = CChar(dr("sexo")),
                            .Activo = CBool(dr("activo"))
                        })
                    End While
                End Using
            End Using
        End Using
        Return lista
    End Function

    Public Function Insertar(u As Usuario) As Integer
        If New SeguridadDAL().Activa() Then Throw New ApplicationException("El alta debe utilizar el contrato seguro de 005.")
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Usuarios_Insertar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idPerfil", u.IdPerfil)
                cmd.Parameters.AddWithValue("@nombre", u.Nombre)
                cmd.Parameters.AddWithValue("@apellido", u.Apellido)
                cmd.Parameters.AddWithValue("@usuario", u.NombreUsuario)
                cmd.Parameters.AddWithValue("@contrasena", u.Contrasena)
                cmd.Parameters.AddWithValue("@email", u.Email)
                cmd.Parameters.AddWithValue("@dni", u.Dni)
                cmd.Parameters.AddWithValue("@calle", u.Calle)
                cmd.Parameters.AddWithValue("@altura", u.Altura)
                cmd.Parameters.AddWithValue("@telefono", u.Telefono)
                cmd.Parameters.AddWithValue("@fechaNacimiento", u.FechaNacimiento)
                cmd.Parameters.AddWithValue("@sexo", u.Sexo)

                Dim pId As New SqlParameter("@nuevoId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                cmd.Parameters.Add(pId)

                cn.Open()
                cmd.ExecuteNonQuery()
                Return CInt(pId.Value)
            End Using
        End Using
    End Function

    Public Sub Modificar(u As Usuario)
        If New SeguridadDAL().Activa() Then Throw New ApplicationException("Usá la edición segura habilitada por el despliegue 005; no se sobrescribirá la credencial.")
        Dim clave = u.Contrasena
        If String.IsNullOrEmpty(clave) Then
            Using lectura = Conexion.ObtenerConexion(), consulta As New SqlCommand("sp_Usuarios_ListarPorEstado", lectura)
                consulta.CommandType = CommandType.StoredProcedure
                consulta.Parameters.Add("@activo", SqlDbType.Bit).Value = True
                lectura.Open()
                Using r = consulta.ExecuteReader()
                    While r.Read()
                        If CInt(r("idUsuario")) = u.IdUsuario Then clave = CStr(r("contrasena")) : Exit While
                    End While
                End Using
            End Using
            If String.IsNullOrEmpty(clave) Then Throw New ApplicationException("No se pudo conservar la clave existente.")
        End If
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Usuarios_Modificar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idUsuario", u.IdUsuario)
                cmd.Parameters.AddWithValue("@idPerfil", u.IdPerfil)
                cmd.Parameters.AddWithValue("@nombre", u.Nombre)
                cmd.Parameters.AddWithValue("@apellido", u.Apellido)
                cmd.Parameters.AddWithValue("@usuario", u.NombreUsuario)
                cmd.Parameters.AddWithValue("@contrasena", clave)
                cmd.Parameters.AddWithValue("@email", u.Email)
                cmd.Parameters.AddWithValue("@dni", u.Dni)
                cmd.Parameters.AddWithValue("@calle", u.Calle)
                cmd.Parameters.AddWithValue("@altura", u.Altura)
                cmd.Parameters.AddWithValue("@telefono", u.Telefono)
                cmd.Parameters.AddWithValue("@fechaNacimiento", u.FechaNacimiento)
                cmd.Parameters.AddWithValue("@sexo", u.Sexo)
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Public Sub CambiarEstado(idUsuario As Integer, activo As Boolean)
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Usuarios_CambiarEstado", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idUsuario", idUsuario)
                cmd.Parameters.AddWithValue("@activo", activo)
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Public Function Login(usuario As String, contrasena As String) As Usuario
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Usuarios_Login", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@usuario", usuario)
                cmd.Parameters.AddWithValue("@contrasena", contrasena)
                cn.Open()
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    If dr.Read() Then
                        Return New Usuario() With {
                            .IdUsuario = CInt(dr("idUsuario")),
                            .Activo = True,
                            .IdPerfil = CInt(dr("idPerfil")),
                            .NombrePerfil = dr("nombrePerfil").ToString(),
                            .Nombre = dr("nombre").ToString(),
                            .Apellido = dr("apellido").ToString()
                        }
                    End If
                End Using
            End Using
        End Using
        Return Nothing ' Si no encuentra coincidencia, devuelve nada
    End Function
End Class