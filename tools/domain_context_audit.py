#!/usr/bin/env python3
"""Bounded, repeatable context evidence from a freshly scanned architecture cache.

Run architecture-audit scan first. This report supplements MCP: literal Lua
imports cover PZ's statement-form require, while MCP supplies symbol/call traces.
Neither import closure nor whole-file bytes claim to be a semantic minimum.
"""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import sqlite3
import subprocess
import sys

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.domain_contracts import components, inspect, compare_debt, private_accesses


def collect(root, policy=None):
    cache = root / '.architecture-refactor/index.sqlite'
    with sqlite3.connect(f'file:{cache}?mode=ro', uri=True) as connection:
        rows = connection.execute('SELECT path,sha256,facts_json FROM files').fetchall()
        findings = [json.loads(row[0]) for row in
                    connection.execute('SELECT data_json FROM findings')]
        summary = json.loads(connection.execute(
            "SELECT value FROM meta WHERE key='project'").fetchone()[0])
    facts, stale = {}, []
    for path, digest, raw in rows:
        source = root / path
        if not source.is_file() or hashlib.sha256(source.read_bytes()).hexdigest() != digest:
            stale.append(path)
        facts[path] = json.loads(raw)
    if stale:
        raise SystemExit('Rescan architecture-audit; stale paths: ' + ', '.join(stale[:10]))
    packaged = root / 'Contents/mods/ProjectHoomans'
    versions = [p.name for p in packaged.iterdir()
                if p.is_dir() and all(part.isdigit() for part in p.name.split('.'))]
    version = max(versions, key=lambda v: tuple(map(int, v.split('.'))))
    prefix = f'Contents/mods/ProjectHoomans/{version}/media/lua/'
    runtime = {p: f for p, f in facts.items()
               if p.startswith(prefix) and p.endswith('.lua') and f['role'] == 'production'}
    graph = {p: sorted(t for t in f['deps'] if t in runtime) for p, f in runtime.items()}
    domains = defaultdict(set)
    for source, targets in graph.items():
        for target in targets:
            a, b = runtime[source]['subsystem'], runtime[target]['subsystem']
            if a != b:
                domains[a].add(b)
    manifestations = Counter(f['message'].split(': ', 1)[1] for f in findings
                             if f['rule'] == 'DEPENDENCY_CYCLE')
    composition = []
    for path, fact in sorted(runtime.items()):
        if '/Composition/' not in path:
            continue
        targets = graph[path]
        composition.append({
            'path': path, 'literal_requires': len(fact['import_records']),
            'resolved_runtime_targets': len(targets),
            'analyzer_domain_count': len({runtime[t]['subsystem'] for t in targets}),
            'analyzer_domains': sorted({runtime[t]['subsystem'] for t in targets}),
            'leaf_targets_without_runtime_imports': sum(not graph[t] for t in targets),
            'targets': targets,
        })
    result = {
        'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
        'scope': prefix,
        'limitations': [
            'Literal import graph excludes lazy global-table calls and callback wiring.',
            'Folder-level SCCs may join unrelated files; inspect file edges before classifying architectural cycles.',
            'A leaf target has no resolved maintained-runtime imports; this is not a judgment about semantic value.',
            'Cache freshness checks indexed files, not unindexed additions; rerun scan before every report.',
        ],
        'analyzer_summary': summary,
        'roles': dict(Counter(f['role'] for f in facts.values())),
        'common_lua_roles': dict(Counter(f['role'] for p, f in facts.items()
                                       if '/common/media/lua/' in p)),
        'runtime_layers': dict(Counter(f['runtime_layer'] for f in runtime.values())),
        'maintained_runtime_files': len(runtime),
        'literal_runtime_import_edges': sum(map(len, graph.values())),
        'cycle_manifestations': dict(sorted(manifestations.items())),
        'folder_domain_sccs': components(domains),
        'file_import_sccs': components(graph),
        'composition': composition,
        'domain_edges': {k: sorted(v) for k, v in sorted(domains.items())},
        'cycle_edge_evidence': [
            {'path': p, 'line': edge['line'], 'target': edge['target'],
             'from': f['subsystem'], 'to': runtime[edge['target']]['subsystem']}
            for p, f in sorted(runtime.items()) for edge in f['resolved_imports']
            if edge['target'] in runtime and f['subsystem'] != runtime[edge['target']]['subsystem']
            and any(f['subsystem'] in group and runtime[edge['target']]['subsystem'] in group
                    for group in components(domains))
        ],
    }
    if policy:
        relative = {p: p.removeprefix(prefix) for p in runtime}
        result['contracts'] = inspect(
            {relative[p]: f['subsystem'] for p, f in runtime.items()},
            [{'source': relative[p], 'target': relative[e['target']], 'line': e['line']}
             for p, f in runtime.items() for e in f['resolved_imports']
             if e['target'] in runtime], policy)
        for path in runtime:
            relative_path = relative[path]
            source_owner = result['contracts']['path_owners'][relative_path]
            for access in private_accesses((root / path).read_text(), source_owner, policy):
                result['contracts']['issues'].append({'source': relative_path, **access})
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path)
    parser.add_argument('--probes', type=Path,
                        help='Fixed reviewed probe definitions; report their current source footprint')
    parser.add_argument('--compare', type=Path, help='Compare probe metrics with a saved baseline')
    parser.add_argument('--contracts', type=Path, help='Explicit ownership/public-boundary policy')
    parser.add_argument('--check-debt', type=Path,
                        help='Fail for new boundary violations beyond this reviewed migration debt')
    args = parser.parse_args()
    policy = json.loads(args.contracts.read_text()) if args.contracts else None
    if args.check_debt and not policy:
        parser.error('--check-debt requires --contracts')
    result = collect(args.root, policy)
    failed = False
    if args.check_debt:
        debt = json.loads(args.check_debt.read_text())
        comparison = compare_debt(result['contracts']['issues'], debt['issues'])
        result['contracts']['debt_comparison'] = comparison
        failed = bool(comparison['new'])
    if args.probes:
        definitions = json.loads(args.probes.read_text())
        source_root = args.root / result['scope']
        unique = set()
        probes = []
        for definition in definitions['probes']:
            files = []
            for relative in definition['files']:
                path = source_root / relative
                data = path.read_bytes()
                unique.add(path)
                files.append({'path': relative, 'bytes': len(data),
                              'lines': len(data.splitlines()),
                              'sha256': hashlib.sha256(data).hexdigest()})
            for test in definition['tests']:
                if not (args.root / test).is_file():
                    raise SystemExit('Missing probe test: ' + test)
            probes.append({**definition, 'source': files,
                           'file_count': len(files),
                           'source_bytes': sum(f['bytes'] for f in files),
                           'source_lines': sum(f['lines'] for f in files)})
        result = {'revision': result['revision'], 'scope': result['scope'],
                  'metric': definitions['metric'], 'probes': probes,
                  'aggregate_unique': {'files': len(unique),
                                       'bytes': sum(p.stat().st_size for p in unique),
                                       'lines': sum(len(p.read_bytes().splitlines()) for p in unique)}}
        if args.compare:
            baseline = json.loads(args.compare.read_text())
            previous = {p['id']: p for p in baseline['probes']}
            if set(previous) != {p['id'] for p in probes}:
                raise SystemExit('Probe IDs changed; comparisons require the fixed behavior set')
            result['delta'] = {
                p['id']: {k: p[k] - previous[p['id']][k]
                          for k in ('file_count', 'source_bytes', 'source_lines', 'hops')}
                for p in probes}
            result['aggregate_delta'] = {
                k: result['aggregate_unique'][k] - baseline['aggregate_unique'][k]
                for k in result['aggregate_unique']}
    rendered = json.dumps(result, indent=2) + '\n'
    if args.output:
        args.output.write_text(rendered)
    else:
        print(rendered, end='')
    if failed:
        raise SystemExit('New domain boundary violations; inspect report before accepting migration debt')


if __name__ == '__main__':
    main()
