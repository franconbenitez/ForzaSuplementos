Imports System
Imports System.Windows.Forms
Imports ForzaSuplementos.Entidades
Imports ForzaSuplementos.Presentacion

Namespace ForzaPruebasUI
    ' Solo para pruebas: no ejecutar los Load de negocio ni autenticar contra SQL.
    Public Class LoginVista
        Inherits FrmLogin
        Public Intentos As Integer
        Public Aperturas As Integer
        Public Reentrar As Boolean

        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub

        Public Function PulsarEnter() As Boolean
            Return MyBase.ProcessDialogKey(Keys.Enter)
        End Function

        Protected Overrides Function Autenticar(usuario As String, contrasena As String) As Usuario
            Intentos += 1
            If Reentrar Then
                Dim metodo As Reflection.MethodInfo = GetType(FrmLogin).GetMethod("btnIngresar_Click", Reflection.BindingFlags.NonPublic Or Reflection.BindingFlags.Instance)
                metodo.Invoke(Me, New Object() {Me, EventArgs.Empty})
            End If
            Return New Usuario With {.IdUsuario = 1, .NombrePerfil = "VENDEDOR"}
        End Function

        Protected Overrides Sub MostrarPrincipal(usuario As Usuario)
            Aperturas += 1
        End Sub
    End Class

    Public Class CajaVista
        Inherits FrmCaja
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
    End Class

    Public Class VentasVista
        Inherits FrmVentas
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
    End Class

    Public Class UsuariosVista
        Inherits FrmUsuarios
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
    End Class

    Public Class ProductosVista
        Inherits FrmProductos
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
    End Class

    Public Class ClientesVista
        Inherits FrmClientes
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
    End Class

    Public Class BackupVista
        Inherits FrmBackup
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
    End Class

    Public Class ReportesVista
        Inherits FrmReportes
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
    End Class

    Public Class PrincipalVista
        Inherits FrmPrincipal
        Public Sub New()
            MyBase.New(New Usuario With {.IdUsuario = 1, .NombrePerfil = "VENDEDOR", .Nombre = "Prueba", .Apellido = "Visual"})
            WindowState = FormWindowState.Normal
        End Sub
        Protected Overrides Sub OnLoad(e As EventArgs)
        End Sub
        Protected Overrides Sub OnFormClosed(e As FormClosedEventArgs)
        End Sub
    End Class
End Namespace
