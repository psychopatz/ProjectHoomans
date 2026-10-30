"""Verify ordered domain registrations against the reviewed pre-migration trace.

Registration files contain literal requires and the standard server-role guard
only. Roots may contain executable barriers; those lines stay in the trace.
This checks assembly, not Lua's module-cache behavior or engine side effects.
"""
import argparse
import json
from pathlib import Path
import re

REQUIRE = re.compile(r'require "([^"]+)"')
SERVER_GUARD = ('if PsychopatzCore and PsychopatzCore.RuntimeRole and not '
                'PsychopatzCore.RuntimeRole.AllowsServerCode() then return end')


def code_lines(path):
    return [line.strip() for line in path.read_text().splitlines()
            if line.strip() and not line.lstrip().startswith('--')]


def trace(base, path, registrations, stack=()):
    if path in stack:
        raise ValueError('Registration cycle: ' + ' -> '.join((*stack, path)))
    layer = path.split('/', 1)[0]
    result = []
    for line in code_lines(base / path):
        match = REQUIRE.fullmatch(line)
        registration = registrations.get((layer, match[1])) if match else None
        if registration:
            expanded = trace(base, registration['path'], registrations, (*stack, path))
            # Nested role checks introduce no work. Root retains the same guard;
            # runtime tests separately verify pure-client early return.
            result.extend(event for event in expanded if event != SERVER_GUARD)
        else:
            result.append(line)
    return result


def verify(base, manifest, baseline):
    registrations = {}
    for registration in manifest['registrations']:
        path = registration['path']
        layer = path.split('/', 1)[0]
        key = (layer, registration['module'])
        if key in registrations:
            raise ValueError('Duplicate registration: ' + path)
        registrations[key] = registration
        expected = [f'require "{p}"' for p in registration['providers']]
        if layer == 'server':
            expected.insert(0, SERVER_GUARD)
        if code_lines(base / path) != expected:
            raise ValueError('Registration contains policy or changed providers: ' + path)
    results = []
    for path, before in baseline['roots'].items():
        after = trace(base, path, registrations)
        if after != before['trace']:
            raise ValueError('Expanded bootstrap changed: ' + path)
        data = (base / path).read_bytes()
        results.append({'path': path, 'expanded_order_equal': True,
                        'before': {k: before[k] for k in ('bytes', 'lines', 'requires')},
                        'after': {'bytes': len(data), 'lines': len(data.splitlines()),
                                  'requires': sum(bool(REQUIRE.fullmatch(l))
                                                  for l in code_lines(base / path))}})
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    job = args.root / 'docs/Jobs/DomainContextArchitectureRefactor'
    manifest = json.loads((job / 'REGISTRATIONS.json').read_text())
    baseline = json.loads((job / 'P3_BOOTSTRAP_BASELINE.json').read_text())
    results = verify(args.root / baseline['scope'], manifest, baseline)
    report = {'registrations': len(manifest['registrations']), 'roots': results}
    rendered = json.dumps(report, indent=2) + '\n'
    if args.output:
        args.output.write_text(rendered)
    else:
        print(rendered, end='')


if __name__ == '__main__':
    main()
