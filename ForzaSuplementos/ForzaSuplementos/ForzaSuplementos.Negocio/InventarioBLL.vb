Option Strict On
Imports System.Data
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades
Public Class InventarioBLL
    Private ReadOnly _dal As InventarioDAL
    Public Sub New()
        Me.New(New InventarioDAL())
    End Sub
    Public Sub New(dal As InventarioDAL)
        _dal = dal
    End Sub
    Public Shared Sub Validar(a As AjusteStock)
        If a Is Nothing OrElse a.IdProducto <= 0 OrElse a.Operacion = Guid.Empty OrElse a.Cantidad = 0 OrElse a.StockEsperado < 0 Then Throw New ApplicationException("Seleccioná producto, cantidad distinta de cero y stock vigente.")
        ComercialBLL.Texto(a.Motivo, 250, "Motivo")
        Dim posterior = CLng(a.StockEsperado) + a.Cantidad
        If posterior < 0 OrElse posterior > Integer.MaxValue Then Throw New ApplicationException("El ajuste deja un stock negativo o excede su límite.")
    End Sub
    Public Sub Ajustar(actor As Usuario, a As AjusteStock)
        Permisos.Exigir(actor, Permiso.Productos) : Validar(a) : _dal.Ajustar(actor, a)
    End Sub
    Public Sub Minimo(actor As Usuario, producto As Integer, valor As Integer)
        Permisos.Exigir(actor, Permiso.Productos)
        If producto <= 0 OrElse valor < 0 Then Throw New ApplicationException("Producto o mínimo inválido.")
        _dal.Minimo(actor, producto, valor)
    End Sub
    Public Function Stock(actor As Usuario) As DataTable
        Permisos.Exigir(actor, Permiso.Productos) : Return _dal.Stock(actor)
    End Function
    Public Function Historial(actor As Usuario, desde As Date, hasta As Date, producto As Integer?) As DataTable
        Permisos.Exigir(actor, Permiso.Productos) : CompraBLL.Fechas(desde, hasta)
        If producto.HasValue AndAlso producto.Value <= 0 Then Throw New ApplicationException("Producto inválido.")
        Return _dal.Historial(actor, desde, hasta, producto)
    End Function
End Class
