Imports System.Data
Imports ForzaSuplementos.Datos
Imports ForzaSuplementos.Entidades

Public Class ReporteBLL
    Private ReadOnly _dal As ReporteDAL

    Public Sub New()
        Me.New(New ReporteDAL())
    End Sub

    Public Sub New(dal As ReporteDAL)
        If dal Is Nothing Then Throw New ArgumentNullException(NameOf(dal))
        _dal = dal
    End Sub

    Public Function ObtenerHistorialVentas(actor As Usuario) As DataTable
        Permisos.Exigir(actor, Permiso.ReportesGlobales)
        Return _dal.HistorialVentas(actor)
    End Function

    Public Function ObtenerBajoStock(actor As Usuario) As DataTable
        Permisos.Exigir(actor, Permiso.ReportesGlobales)
        Return _dal.BajoStock(actor)
    End Function

    Public Function ObtenerMisVentas(actor As Usuario) As DataTable
        Permisos.Exigir(actor, Permiso.ReportesPropios)
        Return _dal.MisVentas(actor)
    End Function

    Public Function ObtenerMisVentas(idUsuario As Integer, actor As Usuario) As DataTable
        Permisos.Exigir(actor, Permiso.ReportesPropios)
        If idUsuario <> actor.IdUsuario Then Throw New ApplicationException("No podés consultar ventas de otro vendedor.")
        Return ObtenerMisVentas(actor)
    End Function
End Class
