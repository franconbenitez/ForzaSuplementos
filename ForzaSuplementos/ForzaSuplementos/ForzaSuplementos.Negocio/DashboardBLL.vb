Option Strict On
Imports System.Globalization
Imports System.Data
Imports System.Linq
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades

Public Class DashboardBLL
    Private ReadOnly _dal As DashboardDAL
    Public Sub New()
        Me.New(New DashboardDAL())
    End Sub
    Public Sub New(dal As DashboardDAL)
        If dal Is Nothing Then Throw New ArgumentNullException(NameOf(dal))
        _dal = dal
    End Sub

    Public Shared Sub ValidarFechas(desde As Date, hasta As Date)
        If desde.Date < New Date(1753, 1, 1) OrElse hasta.Date > New Date(9999, 12, 30) OrElse desde.Date > hasta.Date Then Throw New ApplicationException("El rango de fechas es inválido.")
    End Sub

    Public Function Ventas(actor As Usuario, desde As Date, hasta As Date, Optional vendedor As Integer? = Nothing, Optional producto As Integer? = Nothing) As DashboardVentas
        Permisos.Exigir(actor, Permiso.Reportes)
        Dim rol = actor.NombrePerfil.Trim().ToUpperInvariant()
        If rol <> "GERENTE" AndAlso rol <> "VENDEDOR" Then Throw New ApplicationException("Perfil sin permiso para dashboard comercial.")
        ValidarFechas(desde, hasta)
        If (vendedor.HasValue AndAlso vendedor.Value <= 0) OrElse (producto.HasValue AndAlso producto.Value <= 0) Then Throw New ApplicationException("El filtro debe contener un ID positivo.")
        If rol = "VENDEDOR" Then
            If vendedor.HasValue AndAlso vendedor.Value <> actor.IdUsuario Then Throw New ApplicationException("No podés consultar estadísticas ajenas.")
            vendedor = actor.IdUsuario
        End If
        Try
            Dim data = _dal.Ventas(actor, desde, hasta, vendedor, producto)
            If data Is Nothing OrElse data.Tables.Count <> 6 OrElse data.Tables(0).Rows.Count <> 1 Then Throw New ApplicationException("Contrato de datos de dashboard incompatible.")
            Dim row = data.Tables(0).Rows(0)
            Return New DashboardVentas With {.Desde = desde.Date, .Hasta = hasta.Date, .Completo = True,
                .TotalFacturado = CDec(row("TotalFacturado")), .Operaciones = CInt(row("Operaciones")), .Unidades = CLng(row("Unidades")),
                .VentasSinDetalle = CInt(row("VentasSinDetalle")), .Diaria = Puntos(data.Tables(1)), .Mensual = Puntos(data.Tables(2)),
                .Productos = Puntos(data.Tables(3)), .Categorias = Puntos(data.Tables(4)), .Vendedores = Puntos(data.Tables(5))}
        Catch ex As ProcedimientoReportePendienteException
            If producto.HasValue OrElse (rol = "GERENTE" AndAlso vendedor.HasValue) Then Throw New ApplicationException("Los filtros por producto/vendedor requieren habilitar el dashboard completo en QA.")
            Return CalcularBasico(_dal.VentasBasicas(actor), desde, hasta)
        End Try
    End Function

    Public Function Backups(actor As Usuario, desde As Date, hasta As Date) As DashboardBackups
        Permisos.Exigir(actor, Permiso.Backups)
        ValidarFechas(desde, hasta)
        Dim data = _dal.Backups(actor, desde, hasta)
        If data Is Nothing OrElse data.Tables.Count <> 4 OrElse data.Tables(0).Rows.Count <> 1 Then Throw New ApplicationException("Contrato de auditoría incompatible.")
        Dim historial As New List(Of RegistroBackupReporte)()
        For Each row As DataRow In data.Tables(1).Rows
            historial.Add(New RegistroBackupReporte With {.IdBackup = CInt(row("IdBackup")), .IdUsuario = CInt(row("IdUsuario")), .Fecha = CDate(row("Fecha")), .Archivo = CStr(row("Archivo"))})
        Next
        Return New DashboardBackups With {.Cantidad = CInt(data.Tables(0).Rows(0)("Cantidad")), .Historial = historial,
            .Diaria = Puntos(data.Tables(2)), .Mensual = Puntos(data.Tables(3))}
    End Function

    Public Shared Function CalcularBasico(tabla As DataTable, desde As Date, hasta As Date) As DashboardVentas
        ValidarFechas(desde, hasta)
        If tabla Is Nothing OrElse Not tabla.Columns.Contains("Fecha") OrElse Not tabla.Columns.Contains("Total ($)") Then Throw New ApplicationException("El historial no contiene fecha/importe para calcular indicadores.")
        Dim fin = hasta.Date.AddDays(1)
        Dim rows = tabla.AsEnumerable().Where(Function(r) CDate(r("Fecha")) >= desde.Date AndAlso CDate(r("Fecha")) < fin).ToList()
        Dim resultado As New DashboardVentas With {.Desde = desde.Date, .Hasta = hasta.Date, .Completo = False,
            .Operaciones = rows.Count, .TotalFacturado = rows.Sum(Function(r) CDec(r("Total ($)")))}
        resultado.Diaria = rows.GroupBy(Function(r) CDate(r("Fecha")).Date).OrderBy(Function(g) g.Key).
            Select(Function(g) New PuntoReporte With {.Etiqueta = g.Key.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture), .Cantidad = g.LongCount(), .Importe = g.Sum(Function(r) CDec(r("Total ($)")))}).ToList()
        resultado.Mensual = rows.GroupBy(Function(r) CDate(r("Fecha")).ToString("yyyy-MM", CultureInfo.InvariantCulture)).OrderBy(Function(g) g.Key).
            Select(Function(g) New PuntoReporte With {.Etiqueta = g.Key, .Cantidad = g.LongCount(), .Importe = g.Sum(Function(r) CDec(r("Total ($)")))}).ToList()
        Return resultado
    End Function

    Private Shared Function Puntos(tabla As DataTable) As List(Of PuntoReporte)
        Dim result As New List(Of PuntoReporte)()
        For Each row As DataRow In tabla.Rows
            result.Add(New PuntoReporte With {.Clave = If(IsDBNull(row("Clave")), CType(Nothing, Integer?), CInt(row("Clave"))),
                .Etiqueta = CStr(row("Etiqueta")), .Importe = CDec(row("Importe")), .Cantidad = CLng(row("Cantidad"))})
        Next
        Return result
    End Function
End Class
