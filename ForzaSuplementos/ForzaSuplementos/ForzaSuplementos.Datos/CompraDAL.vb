Option Strict On
Imports System.Data
Imports System.Data.SqlClient
Imports System.Xml.Linq
Imports ForzaSuplementos.Entidades
Public Class CompraDAL
    Public Overridable Function Registrar(actor As Usuario, compra As Compra) As Integer
        Dim xml As New XElement("detalles")
        For Each d In compra.Detalles
            xml.Add(New XElement("item", New XAttribute("producto", d.IdProducto), New XAttribute("cantidad", d.Cantidad), New XAttribute("costo", d.CostoUnitario.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture))))
        Next
        Dim t = New ComercialDAL().Consultar("dbo.sp_Compras_Registrar", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@idProveedor", compra.IdProveedor), New SqlParameter("@operacion", SqlDbType.UniqueIdentifier) With {.Value = compra.Operacion}, New SqlParameter("@detalles", SqlDbType.Xml) With {.Value = xml.ToString(SaveOptions.DisableFormatting)})
        If t.Rows.Count <> 1 OrElse Not t.Columns.Contains("IdCompra") OrElse IsDBNull(t.Rows(0)("IdCompra")) OrElse Convert.ToInt32(t.Rows(0)("IdCompra")) <= 0 Then Throw New OperacionInciertaException("No se recibió confirmación de compra. Conservar carrito y consultar historial antes de reintentar.")
        Return CInt(t.Rows(0)("IdCompra"))
    End Function
    Public Overridable Function Historial(actor As Usuario, desde As Date, hasta As Date, proveedor As Integer?) As DataTable
        Return New ComercialDAL().Consultar("dbo.sp_Compras_Historial", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@desde", SqlDbType.Date) With {.Value = desde.Date}, New SqlParameter("@hasta", SqlDbType.Date) With {.Value = hasta.Date}, New SqlParameter("@idProveedor", SqlDbType.Int) With {.Value = If(proveedor.HasValue, CType(proveedor.Value, Object), DBNull.Value)})
    End Function
    Public Overridable Function Detalle(actor As Usuario, id As Integer) As DataTable
        Return New ComercialDAL().Consultar("dbo.sp_Compras_Detalle", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@idCompra", id))
    End Function
End Class
