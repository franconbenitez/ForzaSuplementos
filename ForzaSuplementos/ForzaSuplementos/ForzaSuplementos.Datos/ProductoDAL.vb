Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades

Public Class ProductoDAL
    Public Function ListarCategorias() As List(Of Categoria)
        Dim lista As New List(Of Categoria)()
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Categorias_Listar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cn.Open()
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        lista.Add(New Categoria(CInt(dr("idCategoria")), dr("nombreCategoria").ToString()))
                    End While
                End Using
            End Using
        End Using
        Return lista
    End Function

    Public Function ListarProductosPorEstado(activo As Boolean) As List(Of Producto)
        Dim lista As New List(Of Producto)()
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Productos_ListarPorEstado", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@activo", activo)
                cn.Open()
                Using dr As SqlDataReader = cmd.ExecuteReader()
                    While dr.Read()
                        lista.Add(New Producto() With {
                            .IdProducto = CInt(dr("idProducto")),
                            .IdCategoria = CInt(dr("idCategoria")),
                            .NombreCategoria = dr("nombreCategoria").ToString(),
                            .Nombre = dr("nombre").ToString(),
                            .Descripcion = If(IsDBNull(dr("descripcion")), "", dr("descripcion").ToString()),
                            .Precio = CDec(dr("precio")),
                            .Stock = CInt(dr("stock")),
                            .Activo = CBool(dr("activo"))
                        })
                    End While
                End Using
            End Using
        End Using
        Return lista
    End Function

    Public Sub Insertar(p As Producto)
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Productos_Insertar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idCategoria", p.IdCategoria)
                cmd.Parameters.AddWithValue("@nombre", p.Nombre)
                cmd.Parameters.AddWithValue("@descripcion", If(String.IsNullOrEmpty(p.Descripcion), CObj(DBNull.Value), p.Descripcion))
                cmd.Parameters.AddWithValue("@precio", p.Precio)
                cmd.Parameters.AddWithValue("@stock", p.Stock)

                Dim pId As New SqlParameter("@nuevoId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                cmd.Parameters.Add(pId)

                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Public Sub Modificar(p As Producto)
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Productos_Modificar", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idProducto", p.IdProducto)
                cmd.Parameters.AddWithValue("@idCategoria", p.IdCategoria)
                cmd.Parameters.AddWithValue("@nombre", p.Nombre)
                cmd.Parameters.AddWithValue("@descripcion", If(String.IsNullOrEmpty(p.Descripcion), CObj(DBNull.Value), p.Descripcion))
                cmd.Parameters.AddWithValue("@precio", p.Precio)
                cmd.Parameters.AddWithValue("@stock", p.Stock)
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub

    Public Sub CambiarEstado(idProducto As Integer, activo As Boolean)
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            Using cmd As New SqlCommand("sp_Productos_CambiarEstado", cn)
                cmd.CommandType = CommandType.StoredProcedure
                cmd.Parameters.AddWithValue("@idProducto", idProducto)
                cmd.Parameters.AddWithValue("@activo", activo)
                cn.Open()
                cmd.ExecuteNonQuery()
            End Using
        End Using
    End Sub
End Class