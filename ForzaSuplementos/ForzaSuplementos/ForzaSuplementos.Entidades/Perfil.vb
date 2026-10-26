Public Class Perfil
    Public Property IdPerfil As Integer
    Public Property NombrePerfil As String
    Public Property Descripcion As String

    Public Sub New()
    End Sub

    Public Sub New(id As Integer, nombre As String)
        Me.IdPerfil = id
        Me.NombrePerfil = nombre
    End Sub

    Public Overrides Function ToString() As String
        Return NombrePerfil
    End Function
End Class