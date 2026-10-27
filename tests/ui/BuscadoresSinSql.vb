Imports System
Imports System.Windows.Forms
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Presentacion

Namespace ForzaPruebasUI
    Public Class VentasBuscadorVista
        Inherits FrmVentas
        Public ProximoCliente As Cliente
        Public ProximoProducto As Producto
        Public AperturasCliente As Integer
        Public AperturasProducto As Integer
        Public Reentrar As Boolean
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
        Protected Overrides Function BuscarCliente() As Cliente
            AperturasCliente += 1
            Return ProximoCliente
        End Function
        Protected Overrides Function BuscarProducto() As Producto
            AperturasProducto += 1
            If Reentrar Then
                GetType(FrmVentas).GetMethod("btnBuscarProducto_Click", Reflection.BindingFlags.Instance Or Reflection.BindingFlags.NonPublic).Invoke(Me, New Object() {Me, EventArgs.Empty})
            End If
            Return ProximoProducto
        End Function
        Public Sub Agregar(cantidad As Integer)
            MyBase.AgregarProducto(cantidad)
        End Sub
        Public Sub ElegirProducto(p As Producto)
            MyBase.SeleccionarProducto(p)
        End Sub
        Public Function PrepararVenta() As Venta
            Return MyBase.CrearVentaPendiente()
        End Function
    End Class
End Namespace
