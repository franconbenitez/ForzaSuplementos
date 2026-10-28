Option Strict On
Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades
Public Class ComercialDAL
    Public Overridable Function Disponible(modulo As String) As Boolean
        Try
            Dim t = Consultar("dbo.sp_Comercial_Estado", New SqlParameter("@modulo", SqlDbType.VarChar, 30) With {.Value = modulo})
            Return t.Rows.Count = 1 AndAlso Convert.ToBoolean(t.Rows(0)(0))
        Catch ex As SqlException When ex.Number = 2812
            Return False
        End Try
    End Function
    Public Overridable Function Consultar(sp As String, ParamArray parametros As SqlParameter()) As DataTable
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand(sp, cn)
            cmd.CommandType = CommandType.StoredProcedure : cmd.Parameters.AddRange(parametros)
            Using adapter As New SqlDataAdapter(cmd)
                Dim t As New DataTable() : adapter.Fill(t) : Return t
            End Using
        End Using
    End Function
    Public Function Listar(actor As Usuario, tipo As String, filtro As String) As DataTable
        Return Consultar("dbo.sp_" & tipo & "_Buscar", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@filtro", SqlDbType.NVarChar, 100) With {.Value = filtro})
    End Function
    Public Sub Guardar(actor As Usuario, p As Proveedor)
        Consultar("dbo.sp_Proveedores_Guardar", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@id", p.IdProveedor), New SqlParameter("@nombre", SqlDbType.NVarChar, 100) With {.Value = p.Nombre}, New SqlParameter("@razonSocial", SqlDbType.NVarChar, 150) With {.Value = p.RazonSocial}, New SqlParameter("@cuit", SqlDbType.VarChar, 11) With {.Value = If(String.IsNullOrWhiteSpace(p.Cuit), CType(DBNull.Value, Object), p.Cuit)}, New SqlParameter("@activo", p.Activo))
    End Sub
    Public Sub Guardar(actor As Usuario, m As Marca)
        Consultar("dbo.sp_Marcas_Guardar", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@id", m.IdMarca), New SqlParameter("@nombre", SqlDbType.NVarChar, 100) With {.Value = m.Nombre}, New SqlParameter("@activo", m.Activo))
    End Sub
    Public Sub Asociar(actor As Usuario, producto As Integer, marca As Integer)
        Consultar("dbo.sp_Marcas_AsociarProducto", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@idProducto", producto), New SqlParameter("@idMarca", marca))
    End Sub
End Class
