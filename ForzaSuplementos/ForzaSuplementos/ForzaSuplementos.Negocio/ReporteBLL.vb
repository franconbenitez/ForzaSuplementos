Imports System.Data
Imports ForzaSuplementos.Datos

Public Class ReporteBLL
    Private ReadOnly _dal As New ReporteDAL()

    Public Function ObtenerHistorialVentas() As DataTable
        Return _dal.HistorialVentas()
    End Function

    Public Function ObtenerBajoStock() As DataTable
        Return _dal.BajoStock()
    End Function

    Public Function ObtenerMisVentas(idUsuario As Integer) As DataTable
        Return _dal.MisVentas(idUsuario)
    End Function
End Class