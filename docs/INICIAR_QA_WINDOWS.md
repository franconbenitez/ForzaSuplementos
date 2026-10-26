# Iniciar Forza Suplementos exclusivamente contra QA

Validación realizada el 26/10/2026: 18/18 ensayos SQL aprobados, integración de las DLL VB con QA aprobada y compilación Debug/AnyCPU exitosa. La interfaz visual todavía debe probarse manualmente.

## 1. Abrir Windows PowerShell en el proyecto

```powershell
Set-Location -LiteralPath '<CARPETA_DEL_PROYECTO>'
```

## 2. Elegir una clave ficticia para ingresar

Solo la primera vez, o si se desea cambiar las claves ficticias de QA:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Establecer-Clave-QA.ps1 -AutorizarEscrituras
```

Ingresar una clave nueva de prueba de 6 a 100 caracteres, sin espacios al principio/final. No usar contraseñas reales. El script verifica servidor/base/marca y actualiza únicamente los cuatro usuarios ficticios de qa.Fixtures. No muestra ni guarda la clave en archivos. Esta interacción no fue ejecutada por el agente: debe realizarla el estudiante para conocer la clave de acceso.

Usuarios disponibles, respetando exactamente minúsculas:

- `qa_vendedor`: Caja, Ventas y clientes.
- `qa_vendedor2`: segundo vendedor para pruebas de permisos/caja ocupada.
- `qa_admin`: no debe operar Caja ni vender.
- `qa_gerente`: no debe operar Caja ni vender.

## 3. Iniciar con el lanzador protegido

Opcionalmente comprobar primero el destino sin iniciar ventanas:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1 -SoloVerificar
```

Iniciar la aplicación:

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\qa\Iniciar-App-QA.ps1
```

El lanzador usa el ejecutable Debug compilado, verifica que QA tenga sus procedimientos y configura FORZA_ENTORNO=QA y FORZA_QA_CONFIG solo en el proceso hijo. Si falla la configuración, servidor, base o marca, se detiene: no utiliza la conexión habitual. Después de ingresar, el título principal debe incluir `[QA — ForzaSuplementosDB_QA]`.

No abrir el EXE por doble clic ni usar F5 normal para este ensayo: esas rutas no seleccionan el perfil QA. No modificar Conexion.vb ni establecer variables persistentes de Windows. La política RemoteSigned del comando solo afecta ese proceso PowerShell, no cambia la configuración permanente del equipo.

## 4. Depurar desde Visual Studio sin cambiar el destino

1. Abrir ForzaSuplementos/ForzaSuplementos/ForzaSuplementos.slnx.
2. Seleccionar Debug y Any CPU; usar **Compilar > Recompilar solución** con la aplicación cerrada.
3. Ejecutar el lanzador anterior desde PowerShell.
4. Usar **Depurar > Asociar al proceso** y seleccionar el PID informado por el lanzador, correspondiente a ForzaSuplementos.Presentacion.exe.

## 5. Ensayo visual recomendado

1. Entrar con qa_vendedor, ir a Control de Caja, actualizar y abrir con monto inicial 500.
2. En Ventas elegir el cliente ficticio y el producto `QA Historico`, precio 100; registrar una unidad con Efectivo.
3. Repetir seleccionando otra vez cliente/producto, una unidad con Transferencia y una con Tarjeta. Confirmar cada venta; no repetir ante un resultado de red ambiguo sin consultar el historial.
4. Actualizar Caja: tres ventas, importe vendido 300, efectivo vendido 100 y esperado 600.
5. Cerrar con contado 590: esperado 600, real 590 y diferencia -10. Seleccionar la sesión y ver su reporte.
6. Verificar filtros, grillas, formato decimal, botones deshabilitados, selección obligatoria de pago y permisos de administrador/gerente. No operar el módulo Backup físico: está bloqueado expresamente en QA.

Los productos de los ensayos automáticos tienen nombres QA Run/QA Ultima/QA Capas; se conservan para inspección. No son productos reales. Al terminar dejar la caja cerrada para que pueda volver a ejecutarse el runner.

## 6. Inspeccionar con SSMS

Conectar a localhost (SERVIDOR_QA_VERIFICADO, instancia predeterminada MSSQLSERVER), seleccionar expresamente ForzaSuplementosDB_QA y comprobar en una consulta:

```sql
SELECT SERVERPROPERTY('ServerName') AS servidor, DB_NAME() AS baseActual;
IF DB_NAME()<>N'ForzaSuplementosDB_QA'
    THROW 51200, 'Seleccionar exclusivamente la base QA.', 1;
SELECT idSesion, estado, montoInicial, montoFinalEsperado, montoFinalReal, diferencia
FROM dbo.SesionesCaja ORDER BY idSesion DESC;
```

No volver a ejecutar el creador 000: QA ya existe y ese script la rechaza. No se necesitan nuevas migraciones para iniciar esta versión validada. Las instrucciones y resultados completos están en RESULTADOS_QA.md y sql/qa/README.md.
