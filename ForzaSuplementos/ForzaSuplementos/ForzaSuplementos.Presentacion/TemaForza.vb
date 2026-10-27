Option Strict On
Imports System.ComponentModel
Imports System.Drawing
Imports System.Runtime.CompilerServices
Imports System.Windows.Forms

' Estilos de Presentacion. No consulta datos ni modifica estado funcional de controles.
Public NotInheritable Class TemaForza
    Public Shared ReadOnly Fondo As Color = Color.FromArgb(31, 36, 40)
    Public Shared ReadOnly Panel As Color = Color.FromArgb(43, 50, 55)
    Public Shared ReadOnly Primario As Color = Color.FromArgb(36, 168, 137)
    Public Shared ReadOnly Texto As Color = Color.FromArgb(232, 236, 239)
    Public Shared ReadOnly Peligro As Color = Color.FromArgb(215, 91, 91)
    Public Shared ReadOnly TextoSecundario As Color = Color.FromArgb(161, 174, 183)
    Public Shared ReadOnly Borde As Color = Color.FromArgb(70, 82, 90)

    Public Enum EstiloBoton
        Primario
        Secundario
        Peligro
    End Enum

    Private NotInheritable Class DatosBoton
        Public Estilo As EstiloBoton
    End Class

    Private Shared ReadOnly Estilos As New ConditionalWeakTable(Of Button, DatosBoton)()

    Private Sub New()
    End Sub

    Public Shared Sub Aplicar(formulario As Form)
        If formulario Is Nothing Then Throw New ArgumentNullException(NameOf(formulario))
        If LicenseManager.UsageMode = LicenseUsageMode.Designtime Then Return
        formulario.SuspendLayout()
        Try
            formulario.BackColor = Fondo
            formulario.ForeColor = Texto
            For Each control As Control In formulario.Controls
                AplicarControl(control)
            Next
        Finally
            formulario.ResumeLayout(True)
        End Try
    End Sub

    Private Shared Sub AplicarControl(control As Control)
        Dim conservarAcento = TypeOf control Is Label AndAlso control.ForeColor.ToArgb() = Primario.ToArgb()
        control.ForeColor = If(control.Enabled, Texto, TextoSecundario)
        If TypeOf control Is Button Then
            Dim boton = DirectCast(control, Button)
            Dim identificador = boton.Name & " " & boton.Text
            Dim estilo = EstiloBoton.Primario
            If identificador.IndexOf("Cancelar", StringComparison.OrdinalIgnoreCase) >= 0 OrElse
               identificador.IndexOf("Vaciar", StringComparison.OrdinalIgnoreCase) >= 0 OrElse
               identificador.IndexOf("Salir", StringComparison.OrdinalIgnoreCase) >= 0 OrElse
               identificador.IndexOf("Baja", StringComparison.OrdinalIgnoreCase) >= 0 OrElse
               identificador.IndexOf("Cerrar", StringComparison.OrdinalIgnoreCase) >= 0 Then
                estilo = EstiloBoton.Peligro
            ElseIf identificador.IndexOf("Actualizar", StringComparison.OrdinalIgnoreCase) >= 0 OrElse
                   identificador.IndexOf("Examinar", StringComparison.OrdinalIgnoreCase) >= 0 OrElse
                   identificador.IndexOf("Reporte", StringComparison.OrdinalIgnoreCase) >= 0 Then
                estilo = EstiloBoton.Secundario
            End If
            ConfigurarBoton(boton, estilo)
        ElseIf TypeOf control Is DataGridView Then
            ConfigurarGrilla(DirectCast(control, DataGridView))
        ElseIf TypeOf control Is TextBoxBase Then
            Dim caja = DirectCast(control, TextBoxBase)
            caja.BackColor = Panel
            caja.BorderStyle = BorderStyle.FixedSingle
        ElseIf TypeOf control Is ComboBox Then
            Dim combo = DirectCast(control, ComboBox)
            combo.BackColor = Panel
            combo.FlatStyle = FlatStyle.Flat
            combo.DrawMode = DrawMode.OwnerDrawFixed
            combo.ItemHeight = Math.Max(combo.ItemHeight, combo.Font.Height + 2)
            RemoveHandler combo.DrawItem, AddressOf DibujarCombo
            AddHandler combo.DrawItem, AddressOf DibujarCombo
        ElseIf TypeOf control Is NumericUpDown Then
            Dim numero = DirectCast(control, NumericUpDown)
            numero.BackColor = Panel
            numero.BorderStyle = BorderStyle.FixedSingle
        ElseIf TypeOf control Is DateTimePicker Then
            ' El editor de fecha es nativo: conservar contraste cuando Windows ignora BackColor.
            Dim fecha = DirectCast(control, DateTimePicker)
            fecha.BackColor = SystemColors.Window
            fecha.ForeColor = SystemColors.WindowText
            fecha.CalendarMonthBackground = Panel
            fecha.CalendarForeColor = Texto
            fecha.CalendarTitleBackColor = Fondo
            fecha.CalendarTitleForeColor = Texto
            fecha.CalendarTrailingForeColor = TextoSecundario
        ElseIf TypeOf control Is ToolStrip Then
            Dim barra = DirectCast(control, ToolStrip)
            barra.BackColor = Panel
            barra.Renderer = New RenderizadorForza()
            AplicarItems(barra.Items)
        ElseIf TypeOf control Is TabControl Then
            Dim pestanas = DirectCast(control, TabControl)
            pestanas.DrawMode = TabDrawMode.OwnerDrawFixed
            RemoveHandler pestanas.DrawItem, AddressOf DibujarPestana
            AddHandler pestanas.DrawItem, AddressOf DibujarPestana
            pestanas.BackColor = Fondo
        ElseIf TypeOf control Is Label Then
            control.BackColor = Color.Transparent
            Dim etiqueta = DirectCast(control, Label)
            If etiqueta.Name.Equals("lblTotal", StringComparison.OrdinalIgnoreCase) OrElse
               etiqueta.Name.Equals("lblEstado", StringComparison.OrdinalIgnoreCase) OrElse
               etiqueta.Text.StartsWith("TOTAL:", StringComparison.OrdinalIgnoreCase) OrElse
               etiqueta.Text.Equals("Estado sin consultar", StringComparison.OrdinalIgnoreCase) OrElse conservarAcento Then etiqueta.ForeColor = Primario
            If Not etiqueta.AutoSize Then etiqueta.AutoEllipsis = True
        ElseIf TypeOf control Is MdiClient Then
            control.BackColor = Fondo
        ElseIf TypeOf control Is Panel OrElse TypeOf control Is GroupBox OrElse TypeOf control Is TabPage Then
            control.BackColor = If(TypeOf control.Parent Is Form AndAlso control.Dock = DockStyle.Fill, Fondo, Panel)
        Else
            control.BackColor = Fondo
        End If
        ' Estilizar controles contenedores, sin tocar las celdas/editor interno del DataGridView.
        If TypeOf control Is DataGridView OrElse TypeOf control Is NumericUpDown Then Return
        For Each hijo As Control In control.Controls
            AplicarControl(hijo)
        Next
    End Sub

    Public Shared Sub ConfigurarBoton(boton As Button, estilo As EstiloBoton)
        Dim datos = Estilos.GetValue(boton, Function(b) New DatosBoton())
        datos.Estilo = estilo
        boton.FlatStyle = FlatStyle.Flat
        boton.UseVisualStyleBackColor = False
        boton.FlatAppearance.BorderSize = 1
        boton.FlatAppearance.BorderColor = Borde
        boton.FlatAppearance.MouseOverBackColor = If(estilo = EstiloBoton.Secundario, Borde, ControlPaint.Light(If(estilo = EstiloBoton.Peligro, Peligro, Primario)))
        boton.FlatAppearance.MouseDownBackColor = If(estilo = EstiloBoton.Secundario, Fondo, ControlPaint.Dark(If(estilo = EstiloBoton.Peligro, Peligro, Primario)))
        ' Aplicacion repetida idempotente: no acumular suscripciones ni retener formularios.
        RemoveHandler boton.EnabledChanged, AddressOf EstadoBotonCambiado
        RemoveHandler boton.Paint, AddressOf PintarBotonDeshabilitado
        AddHandler boton.EnabledChanged, AddressOf EstadoBotonCambiado
        AddHandler boton.Paint, AddressOf PintarBotonDeshabilitado
        ActualizarBoton(boton)
    End Sub

    Private Shared Sub EstadoBotonCambiado(sender As Object, e As EventArgs)
        ActualizarBoton(DirectCast(sender, Button))
    End Sub

    Private Shared Sub ActualizarBoton(boton As Button)
        Dim datos As DatosBoton = Nothing
        If Not Estilos.TryGetValue(boton, datos) Then Return
        boton.BackColor = If(Not boton.Enabled, Panel, If(datos.Estilo = EstiloBoton.Peligro, Peligro, If(datos.Estilo = EstiloBoton.Secundario, Panel, Primario)))
        boton.ForeColor = If(Not boton.Enabled, TextoSecundario, If(datos.Estilo = EstiloBoton.Secundario, Texto, Fondo))
        boton.Invalidate()
    End Sub

    Private Shared Sub PintarBotonDeshabilitado(sender As Object, e As PaintEventArgs)
        Dim boton = DirectCast(sender, Button)
        If boton.Enabled Then Return
        e.Graphics.Clear(Panel)
        ControlPaint.DrawBorder(e.Graphics, boton.ClientRectangle, Borde, ButtonBorderStyle.Solid)
        TextRenderer.DrawText(e.Graphics, boton.Text, boton.Font, Rectangle.Inflate(boton.ClientRectangle, -4, -2), TextoSecundario,
                              TextFormatFlags.HorizontalCenter Or TextFormatFlags.VerticalCenter Or TextFormatFlags.WordBreak)
    End Sub

    Private Shared Sub ConfigurarGrilla(grilla As DataGridView)
        grilla.BackgroundColor = Fondo
        grilla.BorderStyle = BorderStyle.None
        grilla.GridColor = Borde
        grilla.EnableHeadersVisualStyles = False
        grilla.DefaultCellStyle.BackColor = Panel
        grilla.DefaultCellStyle.ForeColor = Texto
        grilla.DefaultCellStyle.SelectionBackColor = Primario
        grilla.DefaultCellStyle.SelectionForeColor = Fondo
        grilla.AlternatingRowsDefaultCellStyle.BackColor = Fondo
        grilla.AlternatingRowsDefaultCellStyle.ForeColor = Texto
        grilla.AlternatingRowsDefaultCellStyle.SelectionBackColor = Primario
        grilla.AlternatingRowsDefaultCellStyle.SelectionForeColor = Fondo
        grilla.ColumnHeadersDefaultCellStyle.BackColor = Panel
        grilla.ColumnHeadersDefaultCellStyle.ForeColor = Texto
        grilla.ColumnHeadersDefaultCellStyle.SelectionBackColor = Panel
        grilla.ColumnHeadersDefaultCellStyle.SelectionForeColor = Texto
        grilla.RowHeadersDefaultCellStyle.BackColor = Panel
        grilla.RowHeadersDefaultCellStyle.ForeColor = Texto
        grilla.RowHeadersDefaultCellStyle.SelectionBackColor = Primario
        grilla.RowHeadersDefaultCellStyle.SelectionForeColor = Fondo
    End Sub

    Private Shared Sub AplicarItems(items As ToolStripItemCollection)
        For Each item As ToolStripItem In items
            item.BackColor = Panel
            item.ForeColor = Texto
            If TypeOf item Is ToolStripDropDownItem Then
                Dim desplegable = DirectCast(item, ToolStripDropDownItem)
                desplegable.DropDown.BackColor = Panel
                desplegable.DropDown.Renderer = New RenderizadorForza()
                AplicarItems(desplegable.DropDownItems)
            End If
        Next
    End Sub

    Private Shared Sub DibujarPestana(sender As Object, e As DrawItemEventArgs)
        Dim pestanas = DirectCast(sender, TabControl)
        If e.Index < 0 Then Return
        Dim seleccionado = e.Index = pestanas.SelectedIndex
        Using fondoPestana As New SolidBrush(If(seleccionado, Panel, Fondo))
            e.Graphics.FillRectangle(fondoPestana, e.Bounds)
        End Using
        TextRenderer.DrawText(e.Graphics, pestanas.TabPages(e.Index).Text, pestanas.Font, e.Bounds, Texto,
                              TextFormatFlags.HorizontalCenter Or TextFormatFlags.VerticalCenter)
        If seleccionado Then
            Using acento As New Pen(Primario, 2)
                e.Graphics.DrawLine(acento, e.Bounds.Left, e.Bounds.Bottom - 2, e.Bounds.Right, e.Bounds.Bottom - 2)
            End Using
        End If
    End Sub

    Private Shared Sub DibujarCombo(sender As Object, e As DrawItemEventArgs)
        Dim combo = DirectCast(sender, ComboBox)
        Dim seleccion = (e.State And DrawItemState.Selected) <> 0 AndAlso (e.State And DrawItemState.ComboBoxEdit) = 0
        Dim fondoItem = If(seleccion, Primario, Panel)
        Using pincel As New SolidBrush(fondoItem)
            e.Graphics.FillRectangle(pincel, e.Bounds)
        End Using
        Dim contenido = If(e.Index >= 0 AndAlso e.Index < combo.Items.Count, combo.GetItemText(combo.Items(e.Index)), combo.Text)
        Dim colorTexto = If(Not combo.Enabled, TextoSecundario, If(seleccion, Fondo, Texto))
        TextRenderer.DrawText(e.Graphics, contenido, combo.Font, Rectangle.Inflate(e.Bounds, -3, 0), colorTexto,
                              TextFormatFlags.Left Or TextFormatFlags.VerticalCenter Or TextFormatFlags.EndEllipsis)
        If (e.State And DrawItemState.Focus) <> 0 Then e.DrawFocusRectangle()
    End Sub

    Private NotInheritable Class RenderizadorForza
        Inherits ToolStripProfessionalRenderer
        Public Sub New()
            MyBase.New(New ColoresMenu())
            RoundedEdges = False
        End Sub
        Protected Overrides Sub OnRenderItemText(e As ToolStripItemTextRenderEventArgs)
            e.TextColor = If(Not e.Item.Enabled, TextoSecundario, If(e.Item.Selected OrElse e.Item.Pressed, Fondo, Texto))
            MyBase.OnRenderItemText(e)
        End Sub
    End Class

    Private NotInheritable Class ColoresMenu
        Inherits ProfessionalColorTable
        Public Overrides ReadOnly Property MenuItemSelected As Color
            Get
                Return Primario
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemSelectedGradientBegin As Color
            Get
                Return Primario
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemSelectedGradientEnd As Color
            Get
                Return Primario
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemPressedGradientBegin As Color
            Get
                Return Primario
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemPressedGradientMiddle As Color
            Get
                Return Primario
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemPressedGradientEnd As Color
            Get
                Return Primario
            End Get
        End Property
        Public Overrides ReadOnly Property ToolStripDropDownBackground As Color
            Get
                Return Panel
            End Get
        End Property
        Public Overrides ReadOnly Property ImageMarginGradientBegin As Color
            Get
                Return Panel
            End Get
        End Property
        Public Overrides ReadOnly Property ImageMarginGradientMiddle As Color
            Get
                Return Panel
            End Get
        End Property
        Public Overrides ReadOnly Property ImageMarginGradientEnd As Color
            Get
                Return Panel
            End Get
        End Property
        Public Overrides ReadOnly Property MenuBorder As Color
            Get
                Return Borde
            End Get
        End Property
        Public Overrides ReadOnly Property MenuItemBorder As Color
            Get
                Return Primario
            End Get
        End Property
        Public Overrides ReadOnly Property ToolStripGradientBegin As Color
            Get
                Return Panel
            End Get
        End Property
        Public Overrides ReadOnly Property ToolStripGradientMiddle As Color
            Get
                Return Panel
            End Get
        End Property
        Public Overrides ReadOnly Property ToolStripGradientEnd As Color
            Get
                Return Panel
            End Get
        End Property
        Public Overrides ReadOnly Property StatusStripGradientBegin As Color
            Get
                Return Panel
            End Get
        End Property
        Public Overrides ReadOnly Property StatusStripGradientEnd As Color
            Get
                Return Panel
            End Get
        End Property
    End Class
End Class
