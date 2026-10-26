"""Auditoria local de todos los blobs Git, refs/reflogs y arbol actual.

No publica, no cambia refs y no imprime valores detectados. Solo biblioteca estandar.
Uso: python scripts/auditar_git.py --output private/auditoria-git.json
"""
import argparse
import collections
import json
import pathlib
import re
import subprocess


def git(*args):
    return subprocess.check_output(["git", *args])


PATTERNS = {
    "token_github": re.compile(r"(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,})"),
    "clave_privada": re.compile(r"-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----"),
    "clave_aws": re.compile(r"(?:AKIA|ASIA)[A-Z0-9]{16}"),
    "secreto_literal_candidato": re.compile(r'''(?im)(?:password|pwd|access_token|api_key|client_secret)\s*[=:]\s*["']?([^\s;"'<>]{6,})'''),
    "contrasena_literal_candidata": re.compile(r'''(?im)(?:contrasena|contraseña)\s*[=:]\s*["']([^"'\r\n]{4,})["']'''),
    "credencial_en_url": re.compile(r'''[a-z]+://[^\s/:@]+:[^\s/@]+@''',re.I),
    "jwt_candidato": re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b"),
    "perfil_windows": re.compile(r'''(?i)[A-Z]:[\\/]+Users[\\/]+[^\\/\r\n<>"']+'''),
    "identificador_equipo": re.compile(r"\b(?:DESKTOP|LAPTOP)-[A-Z0-9]{4,}\b", re.I),
    "correo_candidato": re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"),
}
PRIVATE_SUFFIXES = {".bak", ".mdf", ".ldf", ".ndf", ".trn", ".bacpac", ".dacpac", ".zip", ".7z", ".rar", ".pfx", ".p12", ".key", ".bundle", ".db", ".sqlite"}
PLACEHOLDERS = {"true", "false", "nothing", "dbnull.value", "$secure", "@clave"}


def inspect_text(value):
    findings = []
    for category, pattern in PATTERNS.items():
        for match in pattern.finditer(value):
            if category == "correo_candidato":
                domain = match.group().rsplit("@", 1)[-1].lower()
                if domain.endswith(".invalid") or domain in {"correo.com", "example.com", "ejemplo.com"}:
                    continue
            if category == "secreto_literal_candidato":
                candidate = match.group(1).lower()
                if candidate in PLACEHOLDERS or candidate.startswith(("$", "@", "[", "\\", "*", "?")):
                    continue
            findings.append({"category": category, "line": value.count("\n", 0, match.start()) + 1})
    return findings


def decode(blob):
    if blob.startswith((b"\xff\xfe", b"\xfe\xff")):
        return blob.decode("utf-16"), False
    if b"\0" in blob:
        return "", True
    return blob.decode("utf-8-sig", errors="replace"), False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="private/auditoria-git.json")
    args = parser.parse_args()
    root = pathlib.Path(git("rev-parse", "--show-toplevel").decode().strip()).resolve()
    target = (root / args.output).resolve()
    if not target.is_relative_to(root):
        raise SystemExit("El resultado debe permanecer dentro del proyecto.")
    commits = git("rev-list", "--all", "--reflog").decode().splitlines()
    reachable = set(git("rev-list", "--all").decode().splitlines())
    locations = collections.defaultdict(set)
    commit_metadata = []
    forbidden_paths = set()
    for commit in commits:
        for entry in git("ls-tree", "-r", "-z", commit).split(b"\0"):
            if not entry:
                continue
            info, path = entry.split(b"\t", 1)
            mode, kind, oid = info.decode().split()
            name = path.decode("utf-8", errors="replace")
            if kind == "blob":
                locations[oid].add((commit, name))
            if pathlib.PurePosixPath(name).suffix.lower() in PRIVATE_SUFFIXES:
                forbidden_paths.add((commit[:12], name))
        metadata = git("show", "-s", "--format=%an%n%ae%n%cn%n%ce%n%B", commit).decode("utf-8", errors="replace")
        found = inspect_text(metadata)
        if found:
            commit_metadata.append({"commit": commit, "findings": found})
    head_paths = {}
    for ref in git("for-each-ref", "--format=%(objectname) %(objecttype) %(refname)").decode().splitlines():
        oid, kind, name = ref.split(" ", 2)
        if kind == "tree":
            for entry in git("ls-tree", "-r", "-z", oid).split(b"\0"):
                if entry:
                    info, path = entry.split(b"\t", 1)
                    _, item_kind, blob_oid = info.decode().split()
                    if item_kind == "blob":
                        locations[blob_oid].add((name, path.decode("utf-8", errors="replace")))
    for entry in git("ls-files", "--stage", "-z").split(b"\0"):
        if entry:
            info, path = entry.split(b"\t", 1)
            oid = info.decode().split()[1]
            head_paths[path.decode("utf-8")] = oid
    objects = git("cat-file", "--batch-all-objects", "--batch-check=%(objectname) %(objecttype) %(objectsize)").decode().splitlines()
    reader = subprocess.Popen(["git", "cat-file", "--batch"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    blobs = 0
    commit_objects = 0
    binary = []
    historical = []
    categories = collections.Counter()
    try:
        for entry in objects:
            oid, kind, size = entry.split()
            if kind not in {"blob", "commit"}:
                continue
            reader.stdin.write((oid + "\n").encode())
            reader.stdin.flush()
            header = reader.stdout.readline().decode().split()
            payload = reader.stdout.read(int(header[2]))
            if reader.stdout.read(1) != b"\n":
                raise RuntimeError("Respuesta Git incompleta.")
            content, is_binary = decode(payload)
            if kind == "commit":
                commit_objects += 1
                found = inspect_text(content)
                if found and not any(item["commit"] == oid for item in commit_metadata):
                    commit_metadata.append({"commit": oid, "findings": found})
                continue
            blobs += 1
            refs = sorted(locations.get(oid, set()))
            if is_binary:
                binary.append({"blob": oid, "bytes": int(size), "paths": sorted({p for _, p in refs})})
                continue
            findings = inspect_text(content)
            if findings:
                for item in findings:
                    categories[item["category"]] += 1
                historical.append({"blob": oid, "reachable": any(c in reachable for c, _ in refs), "paths": sorted({p for _, p in refs}), "commits": sorted({c for c, _ in refs}), "findings": findings})
    finally:
        reader.stdin.close()
        reader.wait()
    working = []
    files = git("ls-files", "--cached", "--others", "--exclude-standard", "-z").split(b"\0")
    for entry in files:
        if not entry:
            continue
        name = entry.decode("utf-8")
        path = root / name
        if not path.is_file():
            continue
        content, is_binary = decode(path.read_bytes())
        findings = inspect_text(content) if not is_binary else []
        if findings or is_binary or path.suffix.lower() in PRIVATE_SUFFIXES:
            working.append({"path": name, "binary": is_binary, "findings": findings})
    result = {
        "head": git("rev-parse", "HEAD").decode().strip(),
        "commits_reachable": len(reachable), "commits_including_reflogs": len(commits),
        "tracked_paths": len(head_paths), "objects_total": len(objects), "blobs_scanned": blobs,
        "commit_objects_scanned": commit_objects,
        "binary_blobs_to_review": binary, "historical_findings": historical,
        "commit_metadata_findings": commit_metadata,
        "forbidden_historical_paths": [{"commit": c, "path": p} for c, p in sorted(forbidden_paths)],
        "current_findings": working, "historical_categories": dict(categories),
        "limits": "Revision completa de blobs existentes y arboles de commits; deteccion por patrones, no prueba matematica de ausencia de secretos. Los candidatos requieren revision contextual. No muestra valores detectados.",
    }
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({k: result[k] for k in ("commits_reachable", "tracked_paths", "objects_total", "blobs_scanned", "historical_categories")}, ensure_ascii=False))
    print("Hallazgos guardados localmente sin valores; no se modificaron referencias Git.")


if __name__ == "__main__":
    main()
