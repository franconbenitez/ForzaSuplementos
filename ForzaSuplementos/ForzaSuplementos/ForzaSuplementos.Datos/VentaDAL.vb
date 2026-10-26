Option Strict On
Imports System.Data
Imports System.Data.SqlClient
Imports System.Globalization
Imports System.Xml.Linq
Imports ForzaSuplementos.Entidades

Public Class VentaDAL
    Public Sub RegistrarVenta(v As Venta)
        Dim detalles As New XElement("detalles")
        For Each detalle In v.Detalles.OrderBy(Function(d) d.IdProducto)
            detalles.Add(New XElement("detalle",
                New XAttribute("idProducto", detalle.IdProducto),
                New XAttribute("cantidad", detalle.Cantidad),
                New XAttribute("precio", detalle.PrecioUnitario.ToString("0.00", CultureInfo.InvariantCulture))))
        Next
        Using cn = Conexion.ObtenerConexion(), cmd As New SqlCommand("dbo.sp_Ventas_RegistrarConCaja", cn)
            cmd.CommandType = CommandType.StoredProcedure
            cmd.Parameters.Add("@idCliente", SqlDbType.Int).Value = v.IdCliente
            cmd.Parameters.Add("@idUsuario", SqlDbType.Int).Value = v.IdUsuario
            cmd.Parameters.Add("@idSesion", SqlDbType.Int).Value = If(v.IdSesion.HasValue, CObj(v.IdSesion.Value), DBNull.Value)
            cmd.Parameters.Add("@medioPago", SqlDbType.VarChar, 20).Value = v.MedioPago.ToString()
            cmd.Parameters.Add("@detalles", SqlDbType.Xml).Value = detalles.ToString(SaveOptions.DisableFormatting)
            CajaDAL.AgregarImporte(cmd, "@totalEsperado", v.Total)
            Dim nuevoId = cmd.Parameters.Add("@nuevaVentaId", SqlDbType.Int)
            nuevoId.Direction = ParameterDirection.Output
            cn.Open()
            ' SQL confirma cabecera, detalles, pago y stock en una sola transaccion.
            ' No se modifica el objeto hasta que el procedimiento haya confirmado todo.
            cmd.ExecuteNonQuery()
            v.IdVenta = CInt(nuevoId.Value)
        End Using
    End Sub
End Class
