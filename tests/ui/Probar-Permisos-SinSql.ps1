param([string]$Configuration='Debug')
$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $root "ForzaSuplementos\ForzaSuplementos\ForzaSuplementos.Presentacion\bin\$Configuration"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$refs=@('System.dll','System.Core.dll','System.Data.dll','System.Xml.dll','System.Drawing.dll','System.Windows.Forms.dll')
foreach($layer in @('Entidades','Datos','Negocio','Presentacion')){
    $suffix=if($layer -eq 'Presentacion'){'exe'}else{'dll'}
    $file=Join-Path $out "ForzaSuplementos.$layer.$suffix"
    $null=[Reflection.Assembly]::LoadFrom($file);$refs+=,$file
}
$provider=New-Object Microsoft.VisualBasic.VBCodeProvider
$options=New-Object CodeDom.Compiler.CompilerParameters
$options.GenerateInMemory=$true;$options.CompilerOptions='/optionstrict+ /optionexplicit+'
foreach($ref in $refs){$null=$options.ReferencedAssemblies.Add($ref)}
$sources=@((Join-Path $PSScriptRoot 'VistasSinSql.vb'),(Join-Path $PSScriptRoot 'ReporteSinSql.vb'))
$compiled=$provider.CompileAssemblyFromFile($options,[string[]]$sources)
if($compiled.Errors.HasErrors){throw ($compiled.Errors | Out-String)}
$script:checks=0
function Assert-Perm([bool]$ok,[string]$name){if(!$ok){throw $name};$script:checks++;Write-Output "OK: $name"}
function Reject([string]$name,[scriptblock]$action){
    try{& $action}catch{
        $cause=$_.Exception;while($cause.InnerException){$cause=$cause.InnerException}
        if($cause -isnot [ApplicationException] -or $cause.Message -notmatch 'permiso|Sesión requerida|Perfil sin permiso|otro vendedor|solo permite productos activos'){throw}
        Assert-Perm $true $name;return
    };throw "No rechazo: $name"
}
function Actor([string]$role,[int]$id=1){$u=New-Object ForzaSuplementos.Entidades.Usuario;$u.IdUsuario=$id;$u.NombrePerfil=$role;return $u}
$old=$env:FORZA_ENTORNO;$env:FORZA_ENTORNO='PRUEBA_PERMISOS_SIN_SQL'
try{
    $matrix=@{ADMINISTRADOR=@('Usuarios','Backups','Reportes','ReportesGlobales');GERENTE=@('Productos','Reportes','ReportesGlobales');VENDEDOR=@('Clientes','Ventas','Caja','CatalogoVenta','Reportes','ReportesPropios')}
    $userBll=New-Object ForzaSuplementos.Negocio.UsuarioBLL
    $productBll=New-Object ForzaSuplementos.Negocio.ProductoBLL
    $clientBll=New-Object ForzaSuplementos.Negocio.ClienteBLL
    $backupBll=New-Object ForzaSuplementos.Negocio.BackupBLL
    $saleBll=New-Object ForzaSuplementos.Negocio.VentaBLL
    $cashBll=New-Object ForzaSuplementos.Negocio.CajaBLL
    $reportDal=New-Object ForzaPruebasUI.ReporteCaptura
    $reportBll=New-Object ForzaSuplementos.Negocio.ReporteBLL($reportDal)
    foreach($role in @('ADMINISTRADOR','GERENTE','VENDEDOR','DESCONOCIDO')){
        $u=Actor $role
        foreach($operation in [Enum]::GetValues([ForzaSuplementos.Negocio.Permiso])){
            $expected=$matrix.ContainsKey($role) -and $matrix[$role] -contains $operation.ToString()
            Assert-Perm ([ForzaSuplementos.Negocio.Permisos]::Puede($u,$operation) -eq $expected) "$role politica $operation"
        }
        if($role -ne 'ADMINISTRADOR'){
            Reject "$role no lista perfiles" {$userBll.ObtenerPerfiles($u)}
            Reject "$role no lista usuarios" {$userBll.ObtenerUsuarios($true,$u)}
            Reject "$role no guarda usuarios" {$userBll.GuardarUsuario($null,$u)}
            Reject "$role no da baja usuarios" {$userBll.DarDeBaja(1,$u)}
            Reject "$role no reactiva usuarios" {$userBll.Reactivar(1,$u)}
            Reject "$role no ejecuta backups" {$backupBll.Generar('ficticio.bak',$u)}
        }
        if($role -ne 'GERENTE'){
            Reject "$role no lista categorias ABM" {$productBll.ObtenerCategorias($u)}
            Reject "$role no guarda productos" {$productBll.GuardarProducto($null,$u)}
            Reject "$role no baja productos" {$productBll.DarDeBaja(1,$u)}
            Reject "$role no reactiva productos" {$productBll.Reactivar(1,$u)}
            Reject "$role no consulta productos inactivos" {$productBll.ObtenerProductos($false,$u)}
        }
        if($role -ne 'VENDEDOR'){
            Reject "$role no consulta clientes" {$clientBll.ObtenerClientes($true,$u)}
            Reject "$role no guarda clientes" {$clientBll.Guardar($null,$u)}
            Reject "$role no cambia estado clientes" {$clientBll.CambiarEstado(1,$false,$u)}
            Reject "$role no registra ventas" {$saleBll.ProcesarVenta($null,$u)}
            Reject "$role no abre Caja" {$cashBll.Abrir($u,0)}
            Reject "$role no cierra Caja" {$cashBll.Cerrar($u,1,0)}
            Reject "$role no consulta Caja" {$cashBll.ObtenerAbierta($u)}
            Reject "$role no consulta historial Caja" {$cashBll.Historial($u,[datetime]::Today,[datetime]::Today)}
            Reject "$role no consulta reporte Caja" {$cashBll.Reporte($u,1)}
            Reject "$role no consulta reporte propio" {$reportBll.ObtenerMisVentas($u)}
        }
        if($role -notin @('ADMINISTRADOR','GERENTE')){
            Reject "$role no consulta ventas globales" {$reportBll.ObtenerHistorialVentas($u)}
            Reject "$role no consulta bajo stock global" {$reportBll.ObtenerBajoStock($u)}
            Reject "$role DAL tampoco permite ventas globales" {$reportDal.HistorialVentas($u)}
        }
    }
    foreach($u in @($null,(Actor 'ADMINISTRADOR' 0),(Actor ''),(Actor 'DESCONOCIDO'))){
        foreach($operation in [Enum]::GetValues([ForzaSuplementos.Negocio.Permiso])){
            Assert-Perm (![ForzaSuplementos.Negocio.Permisos]::Puede($u,$operation)) "Sesion ausente/invalida rechazada: $operation"
        }
    }
    Reject 'ABM sin actor no llega a DAL' {$userBll.ObtenerUsuarios($true,$null)}
    Reject 'Reportes DAL sin actor no conectan' {$reportDal.MisVentas($null)}
    $vendor=Actor 'VENDEDOR' 7
    $before=$reportDal.Ejecuciones
    Reject 'Vendedor no puede pedir ventas de otro id en BLL' {$reportBll.ObtenerMisVentas(8,$vendor)}
    Assert-Perm ($reportDal.Ejecuciones -eq $before) 'Rechazo de ventas ajenas ocurre antes de ejecutar DAL'
    $null=$reportBll.ObtenerMisVentas($vendor)
    Assert-Perm ($reportDal.IdSolicitado -eq 7 -and $reportDal.Procedimiento -ceq 'sp_Reporte_MisVentas' -and $reportDal.Tipo -eq [Data.CommandType]::StoredProcedure) 'DAL parametriza exclusivamente id de la sesion para ventas propias'
    $null=$reportBll.ObtenerMisVentas(7,$vendor)
    Assert-Perm ($reportDal.IdSolicitado -eq 7) 'Id propio explicito conserva alcance'
    foreach($role in @('ADMINISTRADOR','GERENTE')){
        $u=Actor $role
        $null=$reportBll.ObtenerHistorialVentas($u)
        Assert-Perm ($reportDal.Procedimiento -ceq 'sp_Reporte_HistorialVentas') "$role puede leer historial global"
        $null=$reportBll.ObtenerBajoStock($u)
        Assert-Perm ($reportDal.Procedimiento -ceq 'sp_Reporte_BajoStock') "$role puede leer bajo stock"
    }
    Assert-Perm ([ForzaSuplementos.Negocio.Permisos]::Puede((Actor ' gerente '),[ForzaSuplementos.Negocio.Permiso]::Productos)) 'Normalizacion de perfil no cambia autorizacion'
    $flags=[Reflection.BindingFlags]'Instance,NonPublic,Public'
    $denied=@{ADMINISTRADOR=@('Ventas','Caja','Productos','Clientes');GERENTE=@('Usuarios','Backup','Ventas','Caja','Clientes');VENDEDOR=@('Usuarios','Productos','Backup')}
    foreach($role in @('ADMINISTRADOR','GERENTE','VENDEDOR')){
        $form=New-Object ForzaPruebasUI.PrincipalNavegacion($role)
        try{
            $form.ShowInTaskbar=$false;$form.StartPosition='Manual';$form.Location=New-Object Drawing.Point(-30000,-30000);$form.Show()
            foreach($module in @('Usuarios','Productos','Clientes','Ventas','Caja','Backup','Reportes')){
                $type=[ForzaSuplementos.Presentacion.FrmPrincipal].Assembly.GetType("ForzaSuplementos.Presentacion.Frm$module")
                if($denied[$role] -contains $module){
                    Reject "$role fabrica real rechaza $module" {$form.CrearReal($type)}
                }else{
                    $real=$form.CrearReal($type)
                    try{Assert-Perm ($real.UsuarioActual.IdUsuario -eq 1 -and $real.UsuarioActual.NombrePerfil -ceq $role) "$role fabrica real inyecta actor en $module"}finally{$real.Dispose()}
                }
            }
            foreach($module in $denied[$role]){
                $type=[ForzaSuplementos.Presentacion.FrmPrincipal].Assembly.GetType("ForzaSuplementos.Presentacion.Frm$module")
                $before=$form.Creaciones;$form.AbrirDirecto($type)
                Assert-Perm ($form.Creaciones -eq $before -and $form.MdiChildren.Count -eq 0) "$role apertura directa de $module rechazada antes de fabrica"
                $item=[ForzaSuplementos.Presentacion.FrmPrincipal].GetProperty("Menu$module",$flags).GetValue($form,$null)
                $item.Available=$true;$item.PerformClick()
                Assert-Perm ($form.Creaciones -eq $before) "$role menu $module forzado visible no evita autorizacion"
            }
        }finally{$form.Dispose()}
    }
    Write-Output "TOTAL PERMISOS: $script:checks comprobaciones aprobadas. Sin SQL; DAL de reportes interceptada antes de conectar."
}finally{$env:FORZA_ENTORNO=$old;$provider.Dispose()}
