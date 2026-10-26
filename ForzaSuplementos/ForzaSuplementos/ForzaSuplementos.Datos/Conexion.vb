Imports System.Data.SqlClient

Imports System.IO
Imports System.Xml.Linq

Public Class Conexion
    Private Shared ReadOnly CadenaConexion As String = "Server=localhost;Database=ForzaSuplementosDB;Integrated Security=True;TrustServerCertificate=True;"

    Public Shared Function ObtenerConexion() As SqlConnection
        Dim entorno = Environment.GetEnvironmentVariable("FORZA_ENTORNO")
        If String.IsNullOrEmpty(entorno) Then Return New SqlConnection(CadenaConexion)
        If Not String.Equals(entorno, "QA", StringComparison.Ordinal) Then Throw New ApplicationException("Entorno de conexión desconocido. No se usará la conexión habitual.")
        Dim archivo = Environment.GetEnvironmentVariable("FORZA_QA_CONFIG")
        If String.IsNullOrWhiteSpace(archivo) OrElse Not Path.IsPathRooted(archivo) OrElse Not File.Exists(archivo) Then
            Throw New ApplicationException("Falta la configuración independiente de QA. No se usará la conexión habitual.")
        End If
        Dim cfg = XDocument.Load(archivo).Root
        If cfg Is Nothing OrElse CStr(cfg.Attribute("base")) <> "ForzaSuplementosDB_QA" OrElse CStr(cfg.Attribute("marca")) <> "Forza-QA-Aislada-v1" Then
            Throw New ApplicationException("Configuración QA rechazada.")
        End If
        Dim builder As New SqlConnectionStringBuilder With {
            .DataSource = CStr(cfg.Attribute("servidor")), .InitialCatalog = "ForzaSuplementosDB_QA",
            .IntegratedSecurity = True, .TrustServerCertificate = True, .ConnectTimeout = 5,
            .ApplicationName = "Forza Suplementos QA"
        }
        Using comprobacion As New SqlConnection(builder.ConnectionString)
            comprobacion.Open()
            Using cmd As New SqlCommand("SELECT CASE WHEN DB_NAME()=N'ForzaSuplementosDB_QA' AND CONVERT(nvarchar(128),SERVERPROPERTY('ServerName'))=@servidor AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'ForzaQaEnvironment' AND CONVERT(nvarchar(128),value)=N'Forza-QA-Aislada-v1') THEN 1 ELSE 0 END", comprobacion)
                cmd.Parameters.Add("@servidor", SqlDbType.NVarChar, 128).Value = CStr(cfg.Attribute("servidorEsperado"))
                If CInt(cmd.ExecuteScalar()) <> 1 Then Throw New ApplicationException("El servidor o la base no corresponden al entorno QA preparado.")
            End Using
        End Using
        Return New SqlConnection(builder.ConnectionString)
    End Function
End Class
