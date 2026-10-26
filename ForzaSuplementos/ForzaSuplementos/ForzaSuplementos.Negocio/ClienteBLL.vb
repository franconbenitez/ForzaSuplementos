Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades

Public Class ClienteBLL
    Private ReadOnly _dal As New ClienteDAL()

    Public Function ObtenerClientes(activo As Boolean) As List(Of Cliente)
        Return _dal.ListarPorEstado(activo)
    End Function

    Public Sub Guardar(c As Cliente)
        If String.IsNullOrWhiteSpace(c.Dni) Then Throw New ApplicationException("El DNI es obligatorio.")
        If String.IsNullOrWhiteSpace(c.Nombre) Then Throw New ApplicationException("El nombre es obligatorio.")
        If String.IsNullOrWhiteSpace(c.Apellido) Then Throw New ApplicationException("El apellido es obligatorio.")

        If c.IdCliente = 0 Then
            _dal.Insertar(c)
        Else
            _dal.Modificar(c)
        End If
    End Sub

    Public Sub CambiarEstado(idCliente As Integer, activo As Boolean)
        _dal.CambiarEstado(idCliente, activo)
    End Sub
End Class