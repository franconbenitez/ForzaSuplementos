Option Strict On
Imports System.Linq
Imports System.Windows.Forms

' Solo estado de interfaz en memoria. No llama a negocio ni a datos.
Public NotInheritable Class ProtectorCambios
    Private ReadOnly _formulario As Form
    Private ReadOnly _pendiente As Func(Of Boolean)
    Private ReadOnly _mensaje As String
    Private ReadOnly _descartar As Action
    Private _campos As Control()
    Private _base As String()

    Public Sub New(formulario As Form, pendiente As Func(Of Boolean), mensaje As String, Optional descartar As Action = Nothing)
        _formulario = formulario
        _pendiente = pendiente
        _mensaje = mensaje
        _descartar = descartar
        Consultar = Function(propietario, texto) MessageBox.Show(propietario, texto, "Cambios sin guardar", MessageBoxButtons.YesNo, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button2) = DialogResult.Yes
        AddHandler formulario.FormClosing, AddressOf AlCerrar
        AddHandler formulario.FormClosed, AddressOf AlCerrarse
    End Sub

    ' Punto de sustitución para ensayar Sí/No sin abrir diálogos ni acceder a SQL.
    Public Property Consultar As Func(Of IWin32Window, String, Boolean)

    Public Shared Function ParaEdicion(formulario As Form, ParamArray campos As Control()) As ProtectorCambios
        Dim protector As ProtectorCambios = Nothing
        protector = New ProtectorCambios(formulario, Function() Not protector.Valores().SequenceEqual(protector._base),
            "Tenés cambios sin guardar. Si salís, se perderán. ¿Querés continuar?")
        protector._campos = campos
        protector.EstablecerBase()
        Return protector
    End Function

    Public Sub EstablecerBase()
        If _campos IsNot Nothing Then _base = Valores()
    End Sub

    Private Function Valores() As String()
        Return _campos.Select(Function(c)
                                  If TypeOf c Is ComboBox Then Return DirectCast(c, ComboBox).SelectedIndex.ToString() & ":" & c.Text
                                  If TypeOf c Is DateTimePicker Then Return DirectCast(c, DateTimePicker).Value.Date.Ticks.ToString()
                                  If TypeOf c Is CheckBox Then Return DirectCast(c, CheckBox).Checked.ToString()
                                  If TypeOf c Is RadioButton Then Return DirectCast(c, RadioButton).Checked.ToString()
                                  Return c.Text
                              End Function).ToArray()
    End Function

    Private Sub AlCerrar(sender As Object, e As FormClosingEventArgs)
        If e.Cancel Then Return
        If _pendiente() AndAlso Not Consultar(_formulario, _mensaje) Then e.Cancel = True
    End Sub

    Private Sub AlCerrarse(sender As Object, e As FormClosedEventArgs)
        ' Descartar solo cuando el cierre efectivamente terminó, nunca al responder Sí
        ' si otro manejador todavía puede cancelar el cierre.
        RemoveHandler _formulario.FormClosing, AddressOf AlCerrar
        RemoveHandler _formulario.FormClosed, AddressOf AlCerrarse
        If _descartar IsNot Nothing Then _descartar()
        _base = Nothing
    End Sub
End Class
