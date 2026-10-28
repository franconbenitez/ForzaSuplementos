Option Strict On
Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Entidades
Public Class InventarioDAL
    Public Overridable Function Stock(actor As Usuario) As DataTable
        Return New ComercialDAL().Consultar("dbo.sp_Inventario_Stock", New SqlParameter("@idActor", actor.IdUsuario))
    End Function
    Public Overridable Function Historial(actor As Usuario, desde As Date, hasta As Date, producto As Integer?) As DataTable
        Return New ComercialDAL().Consultar("dbo.sp_Inventario_Historial", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@desde", SqlDbType.Date) With {.Value = desde.Date}, New SqlParameter("@hasta", SqlDbType.Date) With {.Value = hasta.Date}, New SqlParameter("@idProducto", SqlDbType.Int) With {.Value = If(producto.HasValue, CType(producto.Value, Object), DBNull.Value)})
    End Function
    Public Overridable Sub Ajustar(actor As Usuario, ajuste As AjusteStock)
        Dim dal As New ComercialDAL()
        dal.Consultar("dbo.sp_Inventario_Ajustar", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@idProducto", ajuste.IdProducto), New SqlParameter("@cantidad", ajuste.Cantidad), New SqlParameter("@stockEsperado", ajuste.StockEsperado), New SqlParameter("@motivo", SqlDbType.NVarChar, 250) With {.Value = ajuste.Motivo}, New SqlParameter("@operacion", SqlDbType.UniqueIdentifier) With {.Value = ajuste.Operacion})
    End Sub
    Public Overridable Sub Minimo(actor As Usuario, producto As Integer, valor As Integer)
        Dim dal As New ComercialDAL()
        dal.Consultar("dbo.sp_Inventario_Minimo", New SqlParameter("@idActor", actor.IdUsuario), New SqlParameter("@idProducto", producto), New SqlParameter("@minimo", valor))
    End Sub
End Class
