Imports System.Data
Imports System.Data.SqlClient
Imports ForzaSuplementos.Datos

Namespace ForzaPruebasUI
    ' Captura el comando REAL construido por DAL antes de conectar al servidor.
    Public Class ReporteCaptura
        Inherits ReporteDAL
        Public Ejecuciones As Integer
        Public Procedimiento As String
        Public IdSolicitado As Integer
        Public Tipo As CommandType
        Protected Overrides Function Ejecutar(comando As SqlCommand) As DataTable
            Ejecuciones += 1
            Procedimiento = comando.CommandText
            Tipo = comando.CommandType
            IdSolicitado = If(comando.Parameters.Contains("@idUsuario"), CInt(comando.Parameters("@idUsuario").Value), 0)
            Return New DataTable()
        End Function
    End Class
End Namespace
