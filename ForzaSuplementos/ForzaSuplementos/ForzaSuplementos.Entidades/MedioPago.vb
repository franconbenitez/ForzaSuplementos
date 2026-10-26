Option Strict On

' Una venta se cobra completa con un solo medio. No se infiere de ventas históricas.
Public Enum MedioPago
    SinSeleccionar = 0
    Efectivo = 1
    Transferencia = 2
    Tarjeta = 3
End Enum
