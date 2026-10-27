Option Strict On
Imports System.Globalization
Imports System.Linq
Imports System.Text.RegularExpressions
Imports System.Threading
Imports ForzaSuplementos.Entidades

' Filtrado puro de una copia del catálogo ya autorizada por BLL/DAL. Nunca consulta SQL.
Public NotInheritable Class BuscadorCatalogo
    Private Sub New()
    End Sub

    Private Shared Function Coincide(texto As String, palabras As String()) As Boolean
        Return palabras.All(Function(p) CultureInfo.InvariantCulture.CompareInfo.IndexOf(texto, p, CompareOptions.IgnoreCase Or CompareOptions.IgnoreNonSpace) >= 0)
    End Function

    Private Shared Function Palabras(criterio As String) As String()
        Return Regex.Split(If(criterio, "").Trim(), "\s+").Where(Function(p) p.Length > 0).ToArray()
    End Function

    Public Shared Function Clientes(catalogo As IEnumerable(Of Cliente), criterio As String, Optional cancelacion As CancellationToken = Nothing) As List(Of Cliente)
        Dim resultado As New List(Of Cliente)()
        Dim tokens = Palabras(criterio)
        If catalogo Is Nothing Then Return resultado
        For Each c In catalogo
            cancelacion.ThrowIfCancellationRequested()
            If c IsNot Nothing AndAlso c.Activo AndAlso c.IdCliente > 0 AndAlso
                Coincide(c.IdCliente.ToString(CultureInfo.InvariantCulture) & " " & c.Nombre & " " & c.Apellido & " " & c.Dni, tokens) Then resultado.Add(c)
        Next
        Return resultado
    End Function

    Public Shared Function Productos(catalogo As IEnumerable(Of Producto), criterio As String, Optional cancelacion As CancellationToken = Nothing) As List(Of Producto)
        Dim resultado As New List(Of Producto)()
        Dim tokens = Palabras(criterio)
        If catalogo Is Nothing Then Return resultado
        For Each p In catalogo
            cancelacion.ThrowIfCancellationRequested()
            If p IsNot Nothing AndAlso p.Activo AndAlso p.IdProducto > 0 AndAlso
                Coincide(p.IdProducto.ToString(CultureInfo.InvariantCulture) & " " & p.Nombre & " " & p.NombreCategoria, tokens) Then resultado.Add(p)
        Next
        Return resultado
    End Function
End Class
