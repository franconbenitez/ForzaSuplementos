Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades

Public Class VentaDAL
    Public Sub RegistrarVenta(v As Venta)
        Using cn As SqlConnection = Conexion.ObtenerConexion()
            cn.Open()
            ' Iniciamos la transacción de seguridad
            Using tr As SqlTransaction = cn.BeginTransaction()
                Try
                    ' 1. Guardar la cabecera de la venta
                    Using cmd As New SqlCommand("sp_Ventas_Registrar", cn, tr)
                        cmd.CommandType = CommandType.StoredProcedure
                        cmd.Parameters.AddWithValue("@idCliente", v.IdCliente)
                        cmd.Parameters.AddWithValue("@idUsuario", v.IdUsuario)
                        cmd.Parameters.AddWithValue("@total", v.Total)

                        Dim pId As New SqlParameter("@nuevaVentaId", SqlDbType.Int) With {.Direction = ParameterDirection.Output}
                        cmd.Parameters.Add(pId)

                        cmd.ExecuteNonQuery()
                        v.IdVenta = CInt(pId.Value) ' Recuperamos el ID generado
                    End Using

                    ' 2. Guardar cada detalle y descontar stock automáticamente
                    For Each det In v.Detalles
                        Using cmdD As New SqlCommand("sp_DetalleVentas_Insertar", cn, tr)
                            cmdD.CommandType = CommandType.StoredProcedure
                            cmdD.Parameters.AddWithValue("@idVenta", v.IdVenta)
                            cmdD.Parameters.AddWithValue("@idProducto", det.IdProducto)
                            cmdD.Parameters.AddWithValue("@cantidad", det.Cantidad)
                            cmdD.Parameters.AddWithValue("@precioUnitario", det.PrecioUnitario)
                            cmdD.Parameters.AddWithValue("@subtotal", det.Subtotal)
                            cmdD.ExecuteNonQuery()
                        End Using
                    Next

                    ' Si todo salió bien, confirmamos los cambios
                    tr.Commit()
                Catch ex As Exception
                    ' Si algo falla, deshacemos todo para no dejar datos corruptos
                    tr.Rollback()
                    Throw New ApplicationException("Error crítico en la base de datos al registrar la venta: " & ex.Message)
                End Try
            End Using
        End Using
    End Sub
End Class