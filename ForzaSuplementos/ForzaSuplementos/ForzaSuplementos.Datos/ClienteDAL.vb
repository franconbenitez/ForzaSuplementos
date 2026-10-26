Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades

Public Class ClienteDAL
    Public Function ListarPorEstado(activo As Boolean) As List(Of Cliente)
        Dim lista As New List(Of Cliente)()
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Clientes_ListarPorEstado", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@activo", activo)
                cn.Open()
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        lista.Add(New Cliente() With {
                            .IdCliente = CInt(dr("idCliente")),
                            .Dni = dr("dni").ToString(),
                            .Nombre = dr("nombre").ToString(),
                            .Apellido = dr("apellido").ToString(),
                            .Telefono = If(IsDBNull(dr("telefono")), "", dr("telefono").ToString()),
                            .Email = If(IsDBNull(dr("email")), "", dr("email").ToString()),
                            .Activo = CBool(dr("activo"))
                        })
                    End While
                End Using
            End Using
        End Using
        Return lista
    End Function

    Public Sub Insertar(c As Cliente)
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Clientes_Insertar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@dni", c.Dni)
                cmd.Parameters.AddWithValue("@nombre", c.Nombre)
                cmd.Parameters.AddWithValue("@apellido", c.Apellido)
                cmd.Parameters.AddWithValue("@telefono", If(String.IsNullOrEmpty(c.Telefono), CObj(DBNull.Value), c.Telefono))
                cmd.Parameters.AddWithValue("@email", If(String.IsNullOrEmpty(c.Email), CObj(DBNull.Value), c.Email))

                ' ESTAS DOS LÍNEAS SON LAS QUE FALTABAN
                Dim pId As New SqlParameter("@nuevoId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                cmd.Parameters.Add(pId)

                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Public Sub Modificar(c As Cliente)
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Clientes_Modificar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idCliente", c.IdCliente)
                cmd.Parameters.AddWithValue("@dni", c.Dni)
                cmd.Parameters.AddWithValue("@nombre", c.Nombre)
                cmd.Parameters.AddWithValue("@apellido", c.Apellido)
                cmd.Parameters.AddWithValue("@telefono", If(String.IsNullOrEmpty(c.Telefono), CObj(DBNull.Value), c.Telefono))
                cmd.Parameters.AddWithValue("@email", If(String.IsNullOrEmpty(c.Email), CObj(DBNull.Value), c.Email))
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Public Sub CambiarEstado(idCliente As Integer, activo As Boolean)
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Clientes_CambiarEstado", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idCliente", idCliente)
                cmd.Parameters.AddWithValue("@activo", activo)
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub
End Class