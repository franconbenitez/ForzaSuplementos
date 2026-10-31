Option Strict On
Public Class OperacionInciertaException
    Inherits ApplicationException
    Public Sub New(mensaje As String, Optional causa As Exception = Nothing)
        MyBase.New(mensaje, causa)
    End Sub
End Class
