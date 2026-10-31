Option Strict On
Option Infer On
Imports System
Imports System.Data
Imports System.Data.SqlClient
Imports System.Collections.Generic
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Negocio
Imports ForzaSuplementos.Presentacion
Public Class CatalogoMemoria
    Inherits ComercialDAL
    Public Ids As New List(Of Integer)
    Public Reentrar As Action
    Public SinId As Boolean, FallarLectura As Boolean
    Public Overrides Function Consultar(sp As String, ParamArray parametros As SqlParameter()) As DataTable
        Dim t As New DataTable()
        If sp.EndsWith("_Estado", StringComparison.Ordinal) Then
            t.Columns.Add("Disponible", GetType(Boolean)) : t.Rows.Add(True) : Return t
        End If
        If sp.EndsWith("_Guardar", StringComparison.Ordinal) Then
            For Each p In parametros
                If p.ParameterName = "@id" Then Ids.Add(CInt(p.Value))
            Next
            If Reentrar IsNot Nothing Then Reentrar()
            t.Columns.Add("Id", GetType(Integer))
            If Not SinId Then t.Rows.Add(42)
            Return t
        End If
        If FallarLectura Then Throw New ApplicationException("Error sintético lectura")
        t.Columns.Add("Id", GetType(Integer)) : t.Columns.Add("Nombre") : t.Columns.Add("RazonSocial") : t.Columns.Add("Cuit") : t.Columns.Add("Activo", GetType(Boolean))
        t.Rows.Add(42, "QA", "QA", DBNull.Value, True) : Return t
    End Function
End Class
Public Class CatalogoAdversarial
    Inherits FrmCatalogoComercial
    Public Sub New(d As CatalogoMemoria)
        MyBase.New("Proveedores", New ComercialBLL(d))
        UsuarioActual = New Usuario With {.IdUsuario = 37, .NombrePerfil = "GERENTE"}
    End Sub
End Class
