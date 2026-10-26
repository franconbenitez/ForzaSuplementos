Imports System.Data.SqlClient

Public Class Conexion
    Private Shared ReadOnly CadenaConexion As String = "Server=localhost;Database=ForzaSuplementosDB;Integrated Security=True;TrustServerCertificate=True;"

    Public Shared Function ObtenerConexion() As SqlConnection
        Return New SqlConnection(CadenaConexion)
    End Function
End Class