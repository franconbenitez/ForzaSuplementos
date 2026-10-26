Public Class Categoria
    Public Property IdCategoria As Integer
    Public Property NombreCategoria As String

    Public Sub New()
    End Sub

    Public Sub New(id As Integer, nombre As String)
        IdCategoria = id
        NombreCategoria = nombre
    End Sub
End Class