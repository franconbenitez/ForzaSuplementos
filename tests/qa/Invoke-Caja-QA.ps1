param([switch]$Ejecutar,[switch]$AutorizarEscrituras)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$plan=Get-Content (Join-Path $PSScriptRoot 'casos.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if(!$Ejecutar){$plan | Select-Object id,nombre,resultadoReal;Write-Output 'Plan solamente: no se abrio SQL.';return}
if(!$AutorizarEscrituras){throw 'Se requiere autorizacion expresa y -AutorizarEscrituras para ejecutar ensayos en QA.'}
Import-Module (Join-Path $projectRoot 'scripts\qa\QA.Common.psm1') -Force
$cn=Open-QaConnection
$results=New-Object System.Collections.Generic.List[object]
$context=@{}
function Query([string]$sql,[hashtable]$parameters=@{}) {return ,(Invoke-QaQuery $cn $sql $parameters)}
function Scalar([string]$sql,[hashtable]$parameters=@{}) { $t=Query $sql $parameters; return $t.Rows[0][0] }
function Check([bool]$condition,[string]$message){if(!$condition){throw $message}}
function Expect-SqlError([int]$number,[scriptblock]$action){
    $rejected=$false
    try{& $action | Out-Null}catch{
        $e=$_.Exception;while($e.InnerException){$e=$e.InnerException}
        if($e -isnot [Data.SqlClient.SqlException] -or !(@($e.Errors | ForEach-Object Number) -contains $number)){throw}
        $rejected=$true
    }
    Check $rejected "No se rechazo con error $number."
}
function Case([int]$id,[scriptblock]$action){
    $item=$plan | Where-Object id -eq $id
    try{& $action; $item.resultadoReal='OK (ejecutado sobre QA)';$item.estado='OK';Write-Output "OK caso $id : $($item.nombre)"}
    catch{$item.resultadoReal='FALLO: '+$_.Exception.Message;$item.estado='FALLO';throw}
    finally{$results.Add($item)}
}
function Open-Till([int]$actor,[decimal]$amount=500){
    return [int](Scalar 'DECLARE @id int; EXEC dbo.sp_Caja_Abrir @u,@m,@id OUTPUT; SELECT @id;' @{'@u'=$actor;'@m'=$amount})
}
function Sell([int]$session,[string]$method,[int]$quantity=1,[int]$actor=$script:seller){
    $xml='<detalles><detalle idProducto="'+$script:product+'" cantidad="'+$quantity+'" precio="100.00" /></detalles>'
    return [int](Scalar 'DECLARE @id int; EXEC dbo.sp_Ventas_RegistrarConCaja @c,@u,@s,@medio,@xml,@total,@id OUTPUT; SELECT @id;' @{'@c'=$script:client;'@u'=$actor;'@s'=$session;'@medio'=$method;'@xml'=$xml;'@total'=[decimal](100*$quantity)})
}
function Close-Till([int]$session,[decimal]$amount){$null=Query 'EXEC dbo.sp_Caja_Cerrar @u,@s,@m;' @{'@u'=$script:seller;'@s'=$session;'@m'=$amount}}
function Snapshot {
    return [string](Scalar "SELECT CONCAT((SELECT COUNT(*) FROM dbo.Ventas),'|',(SELECT COUNT(*) FROM dbo.DetalleVentas),'|',(SELECT COUNT(*) FROM dbo.PagosVenta),'|',(SELECT stock FROM dbo.Productos WHERE idProducto=@p));" @{'@p'=$script:product})
}
try {
    # Contrato del DAL contra parametros publicados por SQL, solo lectura de metadatos.
    $contracts=Get-Content (Join-Path $PSScriptRoot 'contratos.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($contract in $contracts){
        Assert-QaDestination $cn
        $cmd=$cn.CreateCommand();$cmd.CommandType=[Data.CommandType]::StoredProcedure;$cmd.CommandText='dbo.'+$contract.procedure
        try {
            [Data.SqlClient.SqlCommandBuilder]::DeriveParameters($cmd)
            Check (($cmd.Parameters.Count-1) -eq $contract.parameters.Count) ('Cantidad de parametros incompatible: '+$contract.procedure)
            foreach($param in $contract.parameters){
                $actual=$cmd.Parameters[$param.name]
                Check ($null -ne $actual -and $actual.SqlDbType.ToString() -eq $param.type) ('Tipo incompatible: '+$contract.procedure+$param.name)
                # DeriveParameters representa OUTPUT de T-SQL como InputOutput.
                $hasOutput=$actual.Direction -in @([Data.ParameterDirection]::Output,[Data.ParameterDirection]::InputOutput)
                Check ($hasOutput -eq [bool]$param.output) ('Direccion incompatible: '+$param.name)
                if($param.type -eq 'Decimal'){Check ($actual.Precision -eq $param.size -and $actual.Scale -eq $param.scale) ('Precision incompatible: '+$param.name)}
                if($param.type -eq 'VarChar'){Check ($actual.Size -eq $param.size) ('Tamano incompatible: '+$param.name)}
            }
        } finally {$cmd.Dispose()}
    }
    Check (([int](Scalar "SELECT COUNT(*) FROM dbo.SesionesCaja WHERE estado='Abierta';")) -eq 0) 'Comenzar sin caja QA abierta; no se fuerza el cierre de sesiones existentes.'
    $f=(Query 'SELECT vendedor,otroVendedor,administrador,gerente,inactivo,cliente,categoria,ventaHistorica FROM qa.Fixtures;').Rows[0]
    $script:seller=[int]$f.vendedor;$script:client=[int]$f.cliente
    $script:product=[int](Scalar 'INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@cat,@nombre,@descripcion,100,100,1); SELECT CONVERT(int,SCOPE_IDENTITY());' @{'@cat'=[int]$f.categoria;'@nombre'=('QA Run '+[Guid]::NewGuid().ToString('N'));'@descripcion'='Producto de ensayo reproducible'})
    $historicBefore=[string](Scalar "SELECT CONCAT(total,'|',CONVERT(varchar(23),fecha,121),'|',COALESCE(CONVERT(varchar(12),idSesion),'NULL')) FROM dbo.Ventas WHERE idVenta=@id;" @{'@id'=[int]$f.ventaHistorica})
    $context=@{servidor=(Get-QaConfig).ExpectedServer;base='ForzaSuplementosDB_QA';producto=$script:product;vendedor=$script:seller;cliente=$script:client;ventaHistorica=[int]$f.ventaHistorica;inicio=(Get-Date).ToString('o')}

    Case 3 {Expect-SqlError 51003 {Open-Till $script:seller -1};Expect-SqlError 51003 {Close-Till 0 -1};Expect-SqlError 51011 {Sell 0 'Efectivo' -1};Check (([int](Scalar "SELECT COUNT(*) FROM dbo.SesionesCaja WHERE estado='Abierta';")) -eq 0) 'Operacion negativa altero caja.'}
    Case 4 {Expect-SqlError 51006 {Sell 0 'Efectivo'};Check (([int](Scalar 'SELECT stock FROM dbo.Productos WHERE idProducto=@p' @{'@p'=$script:product})) -eq 100) 'Venta rechazada altero stock.'}
    $script:s1=0
    Case 1 {$script:s1=Open-Till $script:seller;Check ($script:s1 -gt 0) 'No se devolvio la sesion.';Check (([int](Scalar "SELECT COUNT(*) FROM dbo.SesionesCaja WHERE idSesion=@s AND idUsuarioApertura=@u AND estado='Abierta' AND montoInicial=500" @{'@s'=$script:s1;'@u'=$script:seller})) -eq 1) 'Apertura incorrecta.'}
    $context.sesion1=$script:s1
    Case 2 {Expect-SqlError 51005 {Open-Till ([int]$f.otroVendedor)};Check (([int](Scalar "SELECT COUNT(*) FROM dbo.SesionesCaja WHERE estado='Abierta';")) -eq 1) 'Hay varias cajas abiertas.'}
    Case 18 {
        foreach($actor in @([int]$f.administrador,[int]$f.gerente,[int]$f.inactivo)){
            Expect-SqlError 51001 {Open-Till $actor}
            Expect-SqlError 51001 {Sell $script:s1 'Efectivo' 1 $actor}
            Expect-SqlError 51001 {$null=Query 'EXEC dbo.sp_Caja_Cerrar @u,@s,500;' @{'@u'=$actor;'@s'=$script:s1}}
            Expect-SqlError 51001 {$null=Query 'EXEC dbo.sp_Caja_Historial @u,@d,@h;' @{'@u'=$actor;'@d'=[datetime]'2020-01-01';'@h'=[datetime]'2099-01-01'}}
        }
        $other=Query 'EXEC dbo.sp_Caja_Reporte @u,@s;' @{'@u'=[int]$f.otroVendedor;'@s'=$script:s1}
        Check ($other.Rows.Count -eq 0) 'El vendedor accedio al reporte ajeno.'
        Expect-SqlError 51006 {Sell $script:s1 'Efectivo' 1 ([int]$f.otroVendedor)}
    }
    $script:sales=New-Object System.Collections.Generic.List[int]
    Case 5 {$id=Sell $script:s1 'Efectivo';$script:sales.Add($id);Check (([string](Scalar 'SELECT medioPago FROM dbo.PagosVenta WHERE idVenta=@v' @{'@v'=$id})) -eq 'Efectivo') 'Pago incorrecto.'}
    Case 6 {$id=Sell $script:s1 'Transferencia';$script:sales.Add($id);Check (([string](Scalar 'SELECT medioPago FROM dbo.PagosVenta WHERE idVenta=@v' @{'@v'=$id})) -eq 'Transferencia') 'Pago incorrecto.'}
    Case 7 {$id=Sell $script:s1 'Tarjeta';$script:sales.Add($id);Check (([string](Scalar 'SELECT medioPago FROM dbo.PagosVenta WHERE idVenta=@v' @{'@v'=$id})) -eq 'Tarjeta') 'Pago incorrecto.'}
    Case 8 {Check (([int](Scalar 'SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@s AND idUsuario=@u AND total=100' @{'@s'=$script:s1;'@u'=$script:seller})) -eq 3) 'Asociacion incorrecta.'}
    Case 9 {Check (([int](Scalar 'SELECT stock FROM dbo.Productos WHERE idProducto=@p' @{'@p'=$script:product})) -eq 97) 'Descuento de stock incorrecto.'}
    Case 10 {$before=Snapshot;Expect-SqlError 51013 {Sell $script:s1 'Efectivo' 98};Check ((Snapshot) -eq $before) 'Stock insuficiente dejo escrituras parciales.'}
    Case 11 {
        # Trigger exclusivamente QA; queda inerte al limpiar SESSION_CONTEXT. No se borra ningun objeto/dato.
        $trigger="CREATE OR ALTER TRIGGER dbo.tr_QA_FalloPago ON dbo.PagosVenta AFTER INSERT AS BEGIN IF DB_NAME()<>N'ForzaSuplementosDB_QA' THROW 51200,'Destino no QA',1; IF TRY_CONVERT(int,SESSION_CONTEXT(N'ForzaQA_FalloPago'))=1 THROW 51211,'Fallo de pago inyectado exclusivamente para prueba QA',1; END;"
        $null=Query ('EXEC sys.sp_executesql @ddl;') @{'@ddl'=$trigger}
        $before=Snapshot
        $null=Query "EXEC sys.sp_set_session_context @key=N'ForzaQA_FalloPago',@value=1;"
        try{Expect-SqlError 51211 {Sell $script:s1 'Efectivo'}}finally{$null=Query "EXEC sys.sp_set_session_context @key=N'ForzaQA_FalloPago',@value=NULL;"}
        Check ((Snapshot) -eq $before) 'Fallo despues del stock/pago dejo cabecera, detalle, pago o stock cambiado.'
    }
    Case 15 {
        $history=Query 'EXEC dbo.sp_Caja_Historial @u,@d,@h;' @{'@u'=$script:seller;'@d'=(Get-Date).Date.AddDays(-1);'@h'=(Get-Date).Date.AddDays(1)}
        Check (@($history.Rows | Where-Object {[int]$_.idSesion -eq $script:s1}).Count -eq 1) 'Historial no incluye sesion actual.'
        Check (@($history.Rows | Where-Object {[int]$_.idUsuarioApertura -ne $script:seller}).Count -eq 0) 'Historial mezcla responsables.'
    }
    Case 12 {Close-Till $script:s1 600;Check (([int](Scalar "SELECT COUNT(*) FROM dbo.SesionesCaja WHERE idSesion=@s AND estado='Cerrada' AND montoFinalEsperado=600 AND montoFinalReal=600 AND diferencia=0" @{'@s'=$script:s1})) -eq 1) 'Cierre no separa medios o saldo incorrecto.'}
    Case 14 {Expect-SqlError 51006 {Close-Till $script:s1 600}}
    $script:s2=Open-Till $script:seller
    $context.sesion2=$script:s2
    Case 13 {
        $null=Sell $script:s2 'Efectivo';Close-Till $script:s2 610
        $script:s3=Open-Till $script:seller;$null=Sell $script:s3 'Efectivo';Close-Till $script:s3 590
        $context.sesion3=$script:s3
        Check (([decimal](Scalar 'SELECT diferencia FROM dbo.SesionesCaja WHERE idSesion=@s' @{'@s'=$script:s2})) -eq 10) 'Diferencia positiva incorrecta.'
        Check (([decimal](Scalar 'SELECT diferencia FROM dbo.SesionesCaja WHERE idSesion=@s' @{'@s'=$script:s3})) -eq -10) 'Diferencia negativa incorrecta.'
    }
    Case 16 {
        Check (([int](Scalar 'SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@s' @{'@s'=$script:s1})) -eq 3) 'Sesion1 mezclada.'
        Check (([int](Scalar 'SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@s' @{'@s'=$script:s2})) -eq 1) 'Sesion2 mezclada.'
        Check (([int](Scalar 'SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@s' @{'@s'=$script:s3})) -eq 1) 'Sesion3 mezclada.'
        $historicAfter=[string](Scalar "SELECT CONCAT(total,'|',CONVERT(varchar(23),fecha,121),'|',COALESCE(CONVERT(varchar(12),idSesion),'NULL')) FROM dbo.Ventas WHERE idVenta=@id;" @{'@id'=[int]$f.ventaHistorica})
        Check ($historicAfter -ceq $historicBefore) 'Se altero venta historica sintetica.'
    }
    Case 17 {
        $raceProduct=[int](Scalar 'INSERT dbo.Productos(idCategoria,nombre,descripcion,precio,stock,activo) VALUES(@cat,@nombre,@desc,100,1,1); SELECT CONVERT(int,SCOPE_IDENTITY());' @{'@cat'=[int]$f.categoria;'@nombre'=('QA Ultima '+[Guid]::NewGuid().ToString('N'));'@desc'='Ultima unidad para dos conexiones'})
        $raceSession=Open-Till $script:seller
        $context.sesionConcurrente=$raceSession;$context.productoConcurrente=$raceProduct
        $gate=Open-QaConnection;$a=Open-QaConnection;$b=Open-QaConnection
        $tx=$null;$commands=@();$pending=@();$success=0;$rejected=0
        try {
            Assert-QaDestination $gate
            $tx=$gate.BeginTransaction()
            $lock=$gate.CreateCommand();$lock.Transaction=$tx
            $lock.CommandText="DECLARE @r int; EXEC @r=sys.sp_getapplock @Resource='Forza.Caja.Unica',@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000; IF @r<0 THROW 51212,'No se pudo preparar barrera concurrente',1;"
            $null=$lock.ExecuteNonQuery();$lock.Dispose()
            foreach($connection in @($a,$b)) {
                Assert-QaDestination $connection
                $cmd=$connection.CreateCommand();$cmd.CommandTimeout=30
                $cmd.CommandText='DECLARE @v int; EXEC dbo.sp_Ventas_RegistrarConCaja @c,@u,@s,@m,@x,100,@v OUTPUT;'
                $null=$cmd.Parameters.Add('@c',[Data.SqlDbType]::Int);$cmd.Parameters['@c'].Value=$script:client
                $null=$cmd.Parameters.Add('@u',[Data.SqlDbType]::Int);$cmd.Parameters['@u'].Value=$script:seller
                $null=$cmd.Parameters.Add('@s',[Data.SqlDbType]::Int);$cmd.Parameters['@s'].Value=$raceSession
                $null=$cmd.Parameters.Add('@m',[Data.SqlDbType]::VarChar,20);$cmd.Parameters['@m'].Value='Efectivo'
                $null=$cmd.Parameters.Add('@x',[Data.SqlDbType]::Xml);$cmd.Parameters['@x'].Value='<detalles><detalle idProducto="'+$raceProduct+'" cantidad="1" precio="100.00" /></detalles>'
                $commands+=,$cmd;$pending+=,$cmd.BeginExecuteNonQuery()
            }
            Check (!$pending[0].IsCompleted -and !$pending[1].IsCompleted) 'Las operaciones no coincidieron en la barrera.'
            $tx.Commit();$tx.Dispose();$tx=$null
            for($n=0;$n -lt 2;$n++) {
                try{$null=$commands[$n].EndExecuteNonQuery($pending[$n]);$success++}
                catch{$e=$_.Exception;while($e.InnerException){$e=$e.InnerException};if($e -is [Data.SqlClient.SqlException] -and @($e.Errors|ForEach-Object Number) -contains 51013){$rejected++}else{throw}}
            }
            Check ($success -eq 1 -and $rejected -eq 1) 'Se esperaba una venta y un rechazo por stock.'
            Check (([int](Scalar 'SELECT stock FROM dbo.Productos WHERE idProducto=@p' @{'@p'=$raceProduct})) -eq 0) 'Stock final de carrera incorrecto.'
            Check (([int](Scalar 'SELECT COUNT(*) FROM dbo.Ventas WHERE idSesion=@s' @{'@s'=$raceSession})) -eq 1) 'La carrera duplico ventas.'
        } finally {if($tx){$tx.Rollback();$tx.Dispose()};foreach($cmd in $commands){$cmd.Dispose()};$a.Dispose();$b.Dispose();$gate.Dispose()}
        Close-Till $raceSession 600
    }
    Check ($results.Count -eq 18) 'El plan no ejecuto sus 18 casos.'
} finally {
    $cn.Dispose()
    $dir=Join-Path $projectRoot 'tests\artifacts\qa';$null=[IO.Directory]::CreateDirectory($dir)
    $report=@{contexto=$context;casos=@($results.ToArray());pendientes=@($plan | Where-Object { $_.id -notin @($results | ForEach-Object id) })}
    $report | ConvertTo-Json -Depth 20 | Set-Content (Join-Path $dir ('resultado-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.json')) -Encoding UTF8
    Write-Output "Resultados locales guardados en tests/artifacts/qa. Los registros QA se conservan para inspeccion."
}
