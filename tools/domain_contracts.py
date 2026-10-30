"""Explicit ownership and literal-import boundary checks, independent of PZ.

This cannot prove the absence of foreign writes through Lua namespace aliases.
Domain migrations must also review source and MCP call/data relationships.
"""
from collections import Counter, defaultdict
from fnmatch import fnmatchcase
from pathlib import PurePosixPath
import re

def components(graph):
    """Iterative Kosaraju, including target-only vertices."""
    reverse = defaultdict(set)
    for source, targets in graph.items():
        for target in targets:
            reverse[target].add(source)
    nodes = set(graph) | set(reverse)
    seen, order = set(), []
    for node in sorted(nodes):
        stack = [(node, False)]
        while stack:
            current, done = stack.pop()
            if done:
                order.append(current)
            elif current not in seen:
                seen.add(current)
                stack.append((current, True))
                stack.extend((n, False) for n in sorted(graph.get(current, ()))
                             if n not in seen)
    seen, result = set(), []
    for node in reversed(order):
        if node in seen:
            continue
        group, stack = [], [node]
        while stack:
            current = stack.pop()
            if current in seen:
                continue
            seen.add(current)
            group.append(current)
            stack.extend(reverse[current] - seen)
        if len(group) > 1:
            result.append(sorted(group))
    return sorted(result)



def owner(path, folder, policy):
    for rule in policy['path_owners']:
        if fnmatchcase(path, rule['pattern']):
            return rule['owner']
    return policy['folder_owners'].get(folder)


def is_private(path):
    return any(part == 'Internal' or part.endswith('_Internal')
               or '_Internal_' in part
               for part in PurePosixPath(path).with_suffix('').parts)


def private_accesses(source, source_owner, policy):
    """Bounded lexical supplement for declared private roots and direct aliases.

    This deliberately does not pretend to resolve arbitrary Lua data flow.
    """
    def blank(match):
        return '\n' * match.group().count('\n')

    code = re.sub(r'--\[(=*)\[.*?\]\1\]', blank, source, flags=re.S)
    code = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', blank, code, flags=re.S)
    code = re.sub(r'\[(=*)\[.*?\]\1\]', blank, code, flags=re.S)
    code = re.sub(r'--[^\n]*', '', code)
    result = []
    for private, target_owner in policy.get('private_roots', {}).items():
        if target_owner == source_owner:
            continue
        parent, member = private.rsplit('.', 1)
        names = {private}
        aliases = re.findall(r'\blocal\s+(\w+)\s*=\s*' + re.escape(parent)
                             + r'(?![\w.])', code)
        names.update(alias + '.' + member for alias in aliases)
        pattern = r'(?<![\w.])(?:' + '|'.join(re.escape(n) for n in names) + r')\b'
        for line, text in enumerate(code.splitlines(), 1):
            if re.search(pattern, text):
                result.append({'rule': 'FOREIGN_PRIVATE_NAMESPACE', 'target': private,
                               'line': line, 'detail': f'{source_owner} -> {target_owner}'})
    return result


def inspect(paths, edges, policy):
    """paths maps runtime-relative path -> analyzer folder; edges have line evidence."""
    ownership = {p: owner(p, folder, policy) for p, folder in paths.items()}
    issues = []

    def issue(rule, source, target='', line=0, detail=''):
        issues.append({'rule': rule, 'source': source, 'target': target,
                       'line': line, 'detail': detail})

    entries = {name: set(domain['entries'])
               for name, domain in policy['domains'].items()}
    for name, public in entries.items():
        for path in public:
            if path not in paths:
                issue('MISSING_ENTRY', path, detail=name)
            elif ownership[path] != name:
                issue('COMPETING_AUTHORITY', path, detail=f'{name} entry owned by {ownership[path]}')
    namespaces = {}
    for name, domain in policy['domains'].items():
        namespace = domain.get('namespace')
        if namespace and namespace in namespaces:
            issue('COMPETING_AUTHORITY', name, detail=f'{namespace}: {namespaces[namespace]} and {name}')
        namespaces[namespace] = name
    for path, name in ownership.items():
        if name is None:
            issue('UNMAPPED_OWNER', path, detail=paths[path])
    graph = defaultdict(set)
    for edge in edges:
        source, target = edge['source'], edge['target']
        a, b = ownership[source], ownership[target]
        if a and b and a != b:
            graph[a].add(b)
    groups = components(graph)
    cycle_pairs = {(a, b) for group in groups for a in group
                   for b in graph[a] if b in group}
    for edge in edges:
        source, target = edge['source'], edge['target']
        a, b = ownership[source], ownership[target]
        if not a or not b or a == b:
            continue
        line = edge['line']
        if is_private(target):
            issue('FOREIGN_INTERNAL', source, target, line)
        if b == 'UI' and a not in policy['permitted_presentation_consumers']:
            issue('DOMAIN_TO_UI', source, target, line)
        if a == 'UI' and b == 'Persistence' and target not in entries.get(b, ()):
            issue('UI_TO_PERSISTENCE_INTERNAL', source, target, line)
        # A server entry cannot replace a shared/client provider at bootstrap.
        layer = target.split('/', 1)[0]
        compatible_entries = [p for p in entries.get(b, ()) if p.startswith(layer + '/')]
        if a == 'Composition' and compatible_entries and target not in entries[b]:
            issue('COMPOSITION_TO_PROVIDER', source, target, line)
        if (a != 'Composition' and b in policy['enforced_public_domains']
                and target not in entries.get(b, ())):
            issue('FOREIGN_IMPLEMENTATION', source, target, line)
        if (a, b) in cycle_pairs:
            issue('CROSS_DOMAIN_CYCLE_EDGE', source, target, line, f'{a} -> {b}')
    return {'owners': dict(sorted(Counter(ownership.values()).items(), key=lambda x: str(x[0]))),
            'path_owners': ownership, 'domain_sccs': groups,
            'domain_edges': {a: sorted(b) for a, b in sorted(graph.items())},
            'issues': sorted(issues, key=issue_key)}


def issue_key(issue):
    # Line movement is not new debt. Exact endpoints/rule remain reviewable.
    return (issue['rule'], issue['source'], issue['target'], issue['detail'])


def compare_debt(current, accepted):
    previous = {issue_key(v) for v in accepted}
    actual = {issue_key(v) for v in current}
    return {'new': [v for v in current if issue_key(v) not in previous],
            'resolved': [v for v in accepted if issue_key(v) not in actual]}
