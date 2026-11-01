# Analisis semantico offline adicional: importar no conecta a SQL Server.
$ErrorActionPreference='Stop'
function Assert-ForzaColumnChecks([string]$Source){
 if(!('Forza.SqlReview.ColumnChecks' -as [type])){
  . (Join-Path (Split-Path $PSScriptRoot -Parent) 'Resolver-ScriptDom.ps1')
  $dom=Resolve-ForzaScriptDom
  Add-Type -Path $dom
  $code=@"
using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.SqlServer.TransactSql.ScriptDom;
namespace Forza.SqlReview {
 public sealed class References : TSqlFragmentVisitor {
  public readonly List<string> Names = new List<string>();
  public override void ExplicitVisit(ColumnReferenceExpression node) {
   if(node.MultiPartIdentifier != null && node.MultiPartIdentifier.Identifiers.Count > 0)
    Names.Add(node.MultiPartIdentifier.Identifiers[node.MultiPartIdentifier.Identifiers.Count-1].Value);
   base.ExplicitVisit(node);
  }
 }
 public sealed class ColumnChecks : TSqlFragmentVisitor {
  public readonly List<string> Problems = new List<string>();
  public override void ExplicitVisit(ColumnDefinition column) {
   foreach(ConstraintDefinition constraint in column.Constraints) {
    var check = constraint as CheckConstraintDefinition;
    if(check == null) continue;
    var refs = new References(); check.CheckCondition.Accept(refs);
    foreach(var name in refs.Names)
     if(!String.Equals(name,column.ColumnIdentifier.Value,StringComparison.OrdinalIgnoreCase))
      Problems.Add("CHECK de columna " + column.ColumnIdentifier.Value + " referencia " + name + " (linea " + check.StartLine + "). Declarar a nivel de tabla.");
   }
   base.ExplicitVisit(column);
  }
  public static void Validate(string sql) {
   IList<ParseError> errors;
   TSqlFragment fragment = new TSql160Parser(true).Parse(new StringReader(sql),out errors);
   if(errors.Count != 0) throw new InvalidOperationException("SQL no parseable: " + errors[0].Message);
   var visitor = new ColumnChecks(); fragment.Accept(visitor);
   if(visitor.Problems.Count != 0) throw new InvalidOperationException(String.Join("; ",visitor.Problems));
  }
 }
}
"@
  Add-Type -TypeDefinition $code -ReferencedAssemblies @('System.dll','System.Core.dll',$dom)
 }
 $text=$Source -replace '(?m)^:on error exit\s*',''
 [Forza.SqlReview.ColumnChecks]::Validate($text)
 foreach($m in [regex]::Matches($text,"(?s)EXEC sys.sp_executesql N'((?:[^']|'')*)';")){
  [Forza.SqlReview.ColumnChecks]::Validate($m.Groups[1].Value.Replace("''","'"))
 }
}
Export-ModuleMember -Function Assert-ForzaColumnChecks
