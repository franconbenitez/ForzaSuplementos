Option Strict On
Imports System.Data
Imports System.Text.RegularExpressions
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades
Public Class ComercialBLL
    Private ReadOnly _dal As ComercialDAL
    Public Sub New()
        Me.New(New ComercialDAL())
    End Sub
    Public Sub New(dal As ComercialDAL)
        _dal = dal
    End Sub
    Public Function Disponible(actor As Usuario, modulo As String) As Boolean
        Permisos.Exigir(actor, Permiso.Productos)
        Return _dal.Disponible(modulo)
    End Function
    Public Function Buscar(actor As Usuario, tipo As String, filtro As String) As DataTable
        Permisos.Exigir(actor, Permiso.Productos)
        If tipo <> "Proveedores" AndAlso tipo <> "Marcas" Then Throw New ApplicationException("Catálogo desconocido.")
        Return _dal.Listar(actor, tipo, If(filtro, "").Trim())
    End Function
    Public Shared Sub Validar(p As Proveedor)
        If p Is Nothing OrElse p.IdProveedor < 0 Then Throw New ApplicationException("Proveedor inválido.")
        Texto(p.Nombre, 100, "Nombre") : Texto(p.RazonSocial, 150, "Razón social")
        If Not String.IsNullOrWhiteSpace(p.Cuit) AndAlso Not CuitValido(p.Cuit) Then Throw New ApplicationException("CUIT inválido; ingresá 11 dígitos sin guiones.")
    End Sub
    Public Shared Function CuitValido(cuit As String) As Boolean
        If cuit Is Nothing OrElse Not Regex.IsMatch(cuit, "^[0-9]{11}$") Then Return False
        Dim pesos = New Integer() {5, 4, 3, 2, 7, 6, 5, 4, 3, 2}, suma As Integer
        For i As Integer = 0 To 9
            suma += (AscW(cuit(i)) - 48) * pesos(i)
        Next
        Dim digito = 11 - suma Mod 11
        If digito = 11 Then digito = 0
        If digito = 10 Then Return False
        Return digito = AscW(cuit(10)) - 48
    End Function
    Public Shared Sub Texto(valor As String, limite As Integer, campo As String)
        If String.IsNullOrWhiteSpace(valor) OrElse valor.Trim().Length > limite Then Throw New ApplicationException(campo & " es obligatorio; máximo " & limite.ToString() & " caracteres.")
    End Sub
    Public Sub Guardar(actor As Usuario, p As Proveedor)
        Permisos.Exigir(actor, Permiso.Productos) : Validar(p) : _dal.Guardar(actor, p)
    End Sub
    Public Sub Guardar(actor As Usuario, m As Marca)
        Permisos.Exigir(actor, Permiso.Productos)
        If m Is Nothing OrElse m.IdMarca < 0 Then Throw New ApplicationException("Marca inválida.")
        Texto(m.Nombre, 100, "Marca") : _dal.Guardar(actor, m)
    End Sub
    Public Sub Asociar(actor As Usuario, producto As Integer, marca As Integer)
        Permisos.Exigir(actor, Permiso.Productos)
        If producto <= 0 OrElse marca <= 0 Then Throw New ApplicationException("Seleccioná producto y marca.")
        _dal.Asociar(actor, producto, marca)
    End Sub
End Class
