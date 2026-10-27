$ErrorActionPreference='Stop'
function Assert-QaExecutable([string]$Path){
    if(!(Test-Path -LiteralPath $Path -PathType Leaf)){throw 'Falta el ejecutable. Compilar antes de iniciar QA.'}
    $assembly=[Reflection.Assembly]::LoadFrom($Path)
    if($assembly.GetName().Name -cne 'ForzaSuplementos.Presentacion'){throw 'Ejecutable de otra aplicacion rechazado.'}
    $sales=$assembly.GetType('ForzaSuplementos.Presentacion.FrmVentas')
    if(!$sales -or !$assembly.GetType('ForzaSuplementos.Presentacion.FrmBuscador')){throw 'Compilacion antigua: faltan los buscadores. No se iniciara QA.'}
    $flags=[Reflection.BindingFlags]'Instance,Public,NonPublic'
    foreach($name in @('btnBuscarCliente','btnBuscarProducto','txtClienteSeleccionado','txtProductoSeleccionado')){
        if(!$sales.GetProperty($name,$flags) -and !$sales.GetField($name,$flags)){throw 'Compilacion incompatible: faltan los controles de busqueda.'}
    }
    foreach($name in @('cboCliente','cboProducto')){
        if($sales.GetProperty($name,$flags) -or $sales.GetField($name,$flags)){throw 'Compilacion antigua con ComboBox de clientes/productos rechazada.'}
    }
    return $sales.Module.ModuleVersionId.ToString()
}
Export-ModuleMember -Function Assert-QaExecutable
