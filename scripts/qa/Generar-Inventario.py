"""Genera documentación solo desde metadatos; nunca conecta ni exporta filas."""
import argparse,json,re
from pathlib import Path
from collections import defaultdict
p=argparse.ArgumentParser();p.add_argument('--fecha',required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[2]
m=json.loads((root/'private/inventario-esquema-qa.json').read_text(encoding='utf-8-sig'))
groups=defaultdict(list)
for c in m['tablas']:groups[(c['esquema'],c['tabla'])].append(c)
def typename(c):
 t=c['tipo']
 if t in ('varchar','char','varbinary','binary','nvarchar','nchar'):
  n=c['longitud'];n=n//2 if t in ('nvarchar','nchar') and n>0 else n
  return f"{t}({'max' if n==-1 else n})"
 if t in ('decimal','numeric'):return f"{t}({c['precision']},{c['escala']})"
 return t
idx=defaultdict(list)
for i in m['indices']:idx[(i['tabla'],i['indice'])].append(i)
fks=defaultdict(list)
for f in m['fks']:fks[f['nombre']].append(f)
sp=defaultdict(list)
for s in m['procedimientos']:sp[s['procedimiento']].append(s)
lines=['# Inventario real de ForzaSuplementosDB_QA','',f'Fecha: {a.fecha}. Extracción exclusivamente de sys.* mediante conexión QA validada. No se ejecutó DDL/DML ni se exportaron filas, credenciales, rutas de backups o identificadores de equipo.','',f'**{len(groups)} tablas**: {sum(1 for schema,table in groups if schema=="dbo")} tablas en dbo y {sum(1 for schema,table in groups if schema!="dbo")} tabla(s) auxiliar(es). **{len(fks)} claves foráneas, {len(idx)} índices, {len(m["checks"])} restricciones CHECK y {len(sp)} procedimientos.** La tabla de fixtures no forma parte del modelo comercial.','']
for (schema,table),cols in groups.items():
 lines+=['## '+schema+'.'+table,'']
 for c in cols:
  flags=('NULL' if c['nullable'] else 'NOT NULL')+(' IDENTITY' if c['identidad'] else '')
  default=('; DEFAULT `'+str(c.get('nombreDefecto',''))+'` '+c['defecto']) if c['defecto'] else ''
  lines.append(f"- `{c['columna']}`: `{typename(c)}`, {flags}{default}.")
 lines+=['','Índices y claves:','']
 entries=[(k,v) for k,v in idx.items() if k[0]==table]
 if not entries:lines.append('- Sin índices declarados.')
 for (_,name),items in entries:
  keys=', '.join(i['columna']+(' DESC' if i.get('descendente') else ' ASC') for i in items if not i['incluida']);inc=', '.join(i['columna'] for i in items if i['incluida'])
  first=items[0];lines.append(f"- `{name}`: {first['tipo']}; PK={bool(first['pk'])}, UNIQUE={bool(first['unico'])}, deshabilitado={bool(first.get('deshabilitado'))}; columnas ({keys})"+(f'; INCLUDE ({inc})' if inc else '')+(f"; filtro `{first['filtro']}`" if first['filtro'] else '')+'.')
 for row in m['checks']:
  if row['tabla']==table:lines.append(f"- CHECK `{row['nombre']}`: `{row['definicion']}`; deshabilitada={bool(row['deshabilitada'])}, no confiable={bool(row['noConfiable'])}.")
 lines.append('')
lines+=['## Relaciones reales','']
for name,rows in fks.items():
 f=rows[0];lhs=', '.join(r['columna'] for r in rows);rhs=', '.join(r['referenciada'] for r in rows)
 lines.append(f"- `{name}`: `{f['hija']}({lhs})` → `{f['padre']}({rhs})`; DELETE {f['alBorrar']}, UPDATE {f['alActualizar']}; deshabilitada={bool(f['deshabilitada'])}, no confiable={bool(f['noConfiable'])}.")
lines+=['','## Procedimientos existentes y parámetros','']
for name,rows in sp.items():
 params=[]
 for c in rows:
  if c['parametro']:params.append(c['parametro']+' '+typename(c)+(' OUTPUT' if c['salida'] else ''))
 lines.append('- `'+name+'`: '+('; '.join('`'+x+'`' for x in params) if params else 'sin parámetros')+'.')
lines+=['','## Vistas y triggers','']
for v in m.get('vistas',[]):lines.append('- Vista `'+v['esquema']+'.'+v['vista']+'`.')
for t in m.get('triggers',[]):lines.append('- Trigger `'+t['triggerNombre']+'` en `'+t['esquema']+'.'+t['tabla']+'`; deshabilitado='+str(t['deshabilitado'])+'.')
if not m.get('triggers'):lines.append('- No se encontraron triggers de usuario en tablas.')
lines+=['','## Indicadores posibles y datos faltantes','',
'- Ventas.total y fecha permiten facturación, operaciones y evolución por fecha. Ventas.idUsuario permite alcance propio y comparación de vendedores identificados, evitando mezclar homónimos.',
'- DetalleVentas.cantidad/subtotal permiten unidades y ranking por producto. Productos.idCategoria permite ranking por categoría actual; no existe una instantánea histórica de categoría/nombre del producto.',
'- PagosVenta registra medio e importe: es posible separar efectivo, transferencia y tarjeta donde existe el pago. Las ventas históricas sin pago/sesión no deben convertirse automáticamente en efectivo.',
'- AuditoriaBackups registra idBackup, idUsuario, fecha y rutaArchivo. Permite historial y cantidad por período; no registra estado de intento, fallo, motivo, tamaño, hash o verificación de restauración. No es válido dibujar un gráfico de exitosos/fallidos inventando esos datos.',
'- No hay costo histórico, margen, descuento separado, devoluciones/cancelaciones o retiros/aportes de caja: no pueden calcularse indicadores confiables de ganancia neta, devoluciones o flujo completo de caja.',
'- El total de cabecera se deduplica por idVenta; no se suma después de un JOIN a detalle que lo multiplique. Ventas sin detalle se informan como tales; unidades son las registradas, no una estimación.',
'- Los SP heredados de historial y mis ventas alcanzan para resumen temporal básico; no devuelven detalle/IDs suficientes para rankings completos. Los SP nuevos de dashboard se preparan aparte y no forman parte del conteo existente hasta que se apliquen.',
'- Metadatos no equivalen a verificar contenido ni permisos efectivos de SQL. No se afirmaron resultados de SP todavía no desplegados.','',
'Extracción reproducible: `powershell -NoProfile -ExecutionPolicy RemoteSigned -File scripts/qa/Inventariar-Base-Lectura.ps1`; generación: `python scripts/qa/Generar-Inventario.py --fecha AAAA-MM-DD`. La instantánea intermedia se guarda en private, ignorada. El inventario no contiene definiciones de SP ni rutas físicas.','']
(root/'docs/INVENTARIO_BASE_DATOS.md').write_text('\n'.join(lines),encoding='utf-8')
er=['# Diagrama entidad-relación auditado','',f'Fecha: {a.fecha}. Basado en las {len(fks)} FK reales de QA; no se deducen relaciones por semejanza de nombres. qa.Fixtures es auxiliar de pruebas y no tiene FK. Ver INVENTARIO_BASE_DATOS.md para tipos completos y restricciones.','','```mermaid','erDiagram']
for (schema,table),cols in groups.items():
 entity=schema+'_'+table;er.append('    '+entity+' {')
 for c in cols:
  tags=[]
  if any(i['tabla']==table and i['columna']==c['columna'] and i['pk'] for i in m['indices']):tags.append('PK')
  if any(f['hija']==table and f['columna']==c['columna'] for f in m['fks']):tags.append('FK')
  er.append('        '+c['tipo']+' '+c['columna']+(' '+','.join(tags) if tags else '')+' "'+typename(c)+(' nullable' if c['nullable'] else ' required')+'"')
 er.append('    }')
for name,rows in fks.items():
 f=rows[0];childcols={r['columna'] for r in rows}
 unique=any(k[0]==f['hija'] and v[0]['unico'] and {i['columna'] for i in v if not i['incluida']}==childcols for k,v in idx.items())
 left='o|' if any(r['nullable'] for r in rows) else '||';right='o|' if unique else 'o{'
 er.append(f"    dbo_{f['padre']} {left}--{right} dbo_{f['hija']} : {name}")
er+=['```','','La opcionalidad se obtiene de NULL en la FK; la cardinalidad uno a uno solo se usa cuando las columnas FK tienen unicidad real. Las dos relaciones Usuario/SesionCaja (apertura/cierre) se conservan por separado. No se dibuja qa.Fixtures como FK comercial.','']
(root/'docs/DIAGRAMA_ER.md').write_text('\n'.join(er),encoding='utf-8')
print('Inventario y Mermaid generados: sin datos de filas.')
