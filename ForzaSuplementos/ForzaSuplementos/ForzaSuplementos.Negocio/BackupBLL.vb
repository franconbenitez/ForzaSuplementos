Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Datos

Public Class BackupBLL
    Private ReadOnly _dal As New BackupDAL()

    Public Sub Generar(ruta As String, actor As Usuario)
        Permisos.Exigir(actor, Permiso.Backups)
        If String.IsNullOrWhiteSpace(ruta) Then Throw New ApplicationException("Tenés que seleccionar una carpeta de destino.")
        If Not ruta.EndsWith(".bak") Then Throw New ApplicationException("El archivo debe terminar con la extensión .bak")

        _dal.GenerarBackup(ruta)
    End Sub
End Class