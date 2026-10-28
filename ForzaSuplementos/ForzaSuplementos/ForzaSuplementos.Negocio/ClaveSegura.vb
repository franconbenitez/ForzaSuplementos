Option Strict On
Imports System.Security.Cryptography
Imports System.Globalization

Public NotInheritable Class ClaveSegura
    Public Const Iteraciones As Integer = 600000
    Private Sub New()
    End Sub
    Public Shared Sub Validar(clave As String)
        If clave Is Nothing OrElse clave.Length < 12 OrElse clave.Length > 256 Then Throw New ApplicationException("Usá una contraseña de 12 a 256 caracteres.")
    End Sub
    Public Shared Function Crear(clave As String) As String
        Validar(clave)
        Dim salt(15) As Byte
        Using rng = RandomNumberGenerator.Create()
            rng.GetBytes(salt)
        End Using
        Using kdf As New Rfc2898DeriveBytes(clave, salt, Iteraciones, HashAlgorithmName.SHA256)
            Return "PBKDF2-SHA256$1$" & Iteraciones.ToString(CultureInfo.InvariantCulture) & "$" & Convert.ToBase64String(salt) & "$" & Convert.ToBase64String(kdf.GetBytes(32))
        End Using
    End Function
    Public Shared Function Verificar(clave As String, formato As String) As Boolean
        If clave Is Nothing OrElse clave.Length > 256 OrElse formato Is Nothing Then Return False
        Dim partes = formato.Split("$"c), rondas As Integer
        If partes.Length <> 5 OrElse partes(0) <> "PBKDF2-SHA256" OrElse partes(1) <> "1" OrElse Not Integer.TryParse(partes(2), rondas) OrElse rondas < 100000 OrElse rondas > 2000000 Then Return False
        Try
            Dim salt = Convert.FromBase64String(partes(3)), esperado = Convert.FromBase64String(partes(4))
            If salt.Length <> 16 OrElse esperado.Length <> 32 Then Return False
            Using kdf As New Rfc2898DeriveBytes(clave, salt, rondas, HashAlgorithmName.SHA256)
                Dim actual = kdf.GetBytes(32), diferencia As Integer = 0
                For i As Integer = 0 To 31
                    diferencia = diferencia Or (CInt(actual(i)) Xor CInt(esperado(i)))
                Next
                Return diferencia = 0
            End Using
        Catch ex As FormatException
            Return False
        End Try
    End Function
End Class
