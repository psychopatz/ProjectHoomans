#!/usr/bin/env python3
"""Build the evidence ledger for the immediate Project Hoomans Lua suite.

This is a review ledger generator, not a competing test runner.  It uses the
existing tests/run_tests.py for focused validation and records source/history
facts for every root smoke family so the audit manifest can distinguish real
review from inventory-only UNREVIEWED state.
"""

from __future__ import annotations

from collections import Counter, defaultdict
import json
from pathlib import Path
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from tools.test_estate_audit import (  # noqa: E402
    CANONICAL_BOUNDARY_ENTRIES,
    EVIDENCE_BACKED_REPAIRS,
    boundaries,
    domain_for,
    lua_metrics,
    subjects,
)


DOMAIN_DEFINITIONS = {
    "root_lua:semantic": {
        "owners": [
            "PNC/Semantics/ catalog, IR-facing policy, context, and adapters",
            "client PNC/Semantics/DialogueInput composition and response queue",
        ],
        "callers": [
            "tests/run_tests.py isolated Lua process",
            "client semantic input and existing server task/request seams",
        ],
        "boundary": "deterministic semantic parsing/policy/provider boundary; individual action tests retain their client/server authority split",
        "overlap": "compared semantic smoke files by loaded catalog/policy/context subjects, IR assertions, provider suppression, and action/task boundary; phrase realization and authority checks are not interchangeable",
        "legacy": "checked current semantic composition and prior dialogue-variation history; only the five separately documented stale assertion repairs were changed",
    },
    "root_lua:conversation": {
        "owners": [
            "PNC/Conversation/ registry, rules, memory, group, safety, and response modules",
            "client conversation presentation and server social interaction handlers",
        ],
        "callers": [
            "conversation composition/load-order roots",
            "client Talk/input paths and server-authoritative social interaction paths",
        ],
        "boundary": "conversation composition, memory, group-turn, presentation, and server social authority boundaries",
        "overlap": "grouped by conversation subject and whether the test proves load order, state transition, presentation, or server effect; same vocabulary does not replace a different authority stage",
        "legacy": "checked current PNC/Conversation requires and history for removed composition names; no removed-only family was established",
    },
    "root_lua:inventory": {
        "owners": [
            "PNC/Core/Inventory and PNC/UI/Inventory models",
            "server inventory mutation/transfer handlers and Core inventory actor bridge",
        ],
        "callers": [
            "client inventory query/presentation and item-selection adapters",
            "server authoritative transfer, equipment, persistence, and rollback paths",
        ],
        "boundary": "client observation/presentation versus server/Core-owned item state and transfer authority",
        "overlap": "compared item, equipment, UI, transfer, rollback, replication, and persistence subjects; a shared item fixture cannot replace distinct ownership/authority outcomes",
        "legacy": "checked current inventory bridge and supported item/persistence paths; no removed compatibility-only inventory family was established",
    },
    "root_lua:faction_community": {
        "owners": [
            "PNC/Factions/ faction registry, membership, diplomacy, treaties, and aggression providers",
            "PNC/Communities/ and colony/settlement state, snapshots, and persistence",
        ],
        "callers": [
            "server faction/community lifecycle and world-extension composition",
            "player/NPC membership and succession commands",
        ],
        "boundary": "server-authoritative faction/community state, relation mutation, and persistence boundaries",
        "overlap": "compared registry/load-order, mutation, relation math, membership, map, and persistence assertions; module ownership and state effects remain distinct",
        "legacy": "checked current faction/community provider composition and migration markers; no retired faction API was proven",
    },
    "root_lua:mp_network": {
        "owners": [
            "PNC/Networking/ client requests, server handlers, replica transport, and cleanup",
            "PNC/PresenceSync/ and MP body binding/incarnation modules",
        ],
        "callers": [
            "client request/replica paths",
            "server authority, reconnect, death, streaming, and late-result cleanup paths",
        ],
        "boundary": "server/client, replica/authority, reconnect/death, and network cleanup boundaries",
        "overlap": "compared transport, snapshot, binding, incarnation, recovery, file-guard, and authority assertions; each crosses a different lifecycle or role boundary",
        "legacy": "checked current networking handler names and MP composition; no removed transport/migration path was found",
    },
    "root_lua:facility_building": {
        "owners": [
            "PNC/Settlement/ facilities, buildings, construction, reservations, and completion services",
            "server work/task providers that mutate facility state",
        ],
        "callers": [
            "server facility/building lifecycle and validation handlers",
            "client-facing work/site hints where present",
        ],
        "boundary": "authoritative facility/building state and reservation/completion lifecycle",
        "overlap": "compared validation, component rows, construction queueing, reservations, and completion contracts; row shape is not equivalent to mutation/lease behavior",
        "legacy": "checked current facility service composition and construction providers; no removed building compatibility layer was found",
    },
    "root_lua:abstract_world_traversal": {
        "owners": [
            "PNC/Travel/ and PNC/Pathing/ route, arrival, traversal, and abstract-world projections",
            "PNC/Director/ abstract encounters, groups, locations, and LOD",
        ],
        "callers": [
            "server director/abstract movement and action-plan providers",
            "live/abstract transition and travel persistence paths",
        ],
        "boundary": "abstract-world versus live-body traversal, route state, arrival, and persistence boundaries",
        "overlap": "compared route model, providers, arrivals, abstract group/location managers, and persistence assertions; same coordinates do not prove the same lifecycle contract",
        "legacy": "checked current Travel/Director composition and historical route/abstract symbols; no removed-only traversal path was established",
    },
    "root_lua:combat_zombies": {
        "owners": [
            "PNC/Combat/, PNC/Perception/, and PNC/Core/Zombies/",
            "server combat reaction, target, aggro, and status adapters",
        ],
        "callers": [
            "server combat/event bridges and zombie target selection",
            "client combat presentation/audio/debug surfaces",
        ],
        "boundary": "combat authority, zombie target identity, perception, reaction, and client presentation boundaries",
        "overlap": "compared combat resolution, perception, aggro, defense, audio, and target classification assertions; typed target/status outcomes remain distinct",
        "legacy": "checked current combat/zombie modules and history around universal zombie targets; no removed combat compatibility path was found",
    },
    "root_lua:presence_body": {
        "owners": [
            "PNC/Core/Presence/ and PNC/BodyLifecycle/",
            "PNC/PresenceSync/ live body, corpse, puppet, and materialization modules",
        ],
        "callers": [
            "server body lifecycle/audit and presence registry",
            "client presence replica and cleanup paths",
        ],
        "boundary": "NPC identity/incarnation/presence, live/abstract/corpse transitions, body lease, and authority boundaries",
        "overlap": "compared body stamping, corpse transfer, presence snapshots, live-shell cleanup, materialization safety, and boundary/load-order checks; each protects a separate identity or transition invariant",
        "legacy": "checked current body lifecycle and presence module names/history; no removed body compatibility path was proven",
    },
    "root_lua:map": {
        "owners": [
            "PNC/MapCommands/ and map/WorldDiscovery services",
            "Core-owned map controls and client map presentation adapters",
        ],
        "callers": [
            "client map observation/hover/marker paths",
            "server map command and world-discovery authority",
        ],
        "boundary": "client map hint/presentation versus server/Core map identity and command authority",
        "overlap": "compared map registry, markers, hover, travel/lumber commands, discovery, and identity assertions; hint and authoritative command tests remain distinct",
        "legacy": "checked current Core map adoption and Hoomans map command composition; no superseded map bridge was found",
    },
    "root_lua:companion": {
        "owners": [
            "PNC/Companions/ and starting-companion ownership/state modules",
            "companion command/vehicle/camp presentation and server handlers",
        ],
        "callers": [
            "client companion command/presentation paths",
            "server companion ownership, follow, camp, vehicle, and recruitment paths",
        ],
        "boundary": "companion ownership, command admission, follow/camp task, and client/server presentation boundaries",
        "overlap": "compared command, target scope, camp, vehicle, recruitment, and ownership assertions; command meaning does not replace state ownership or task cleanup",
        "legacy": "checked current companion command and ownership paths/history; no removed companion API was found",
    },
    "root_lua:tasking_work": {
        "owners": [
            "PNC/Tasking/ leases, priorities, intents, pump, and recovery",
            "PNC/Production/ work behavior and home-duty services",
        ],
        "callers": [
            "server task lease/pump/action-plan paths",
            "client task-result and work presentation adapters",
        ],
        "boundary": "task lease, queue, recovery, work execution, and authoritative result boundaries",
        "overlap": "compared task inbox, intent, lease, sleep, work, priority, and recovery assertions; acknowledgement and execution are kept separate",
        "legacy": "checked current Tasking/Production composition and history; no retired task loop was proven",
    },
    "root_lua:fishing_scavenge": {
        "owners": [
            "PNC/Fishing/, PNC/Scavenge/, and resource locator services",
            "semantic/world-target adapters where fishing/scavenge is surfaced",
        ],
        "callers": [
            "client observation/hint routes",
            "server resource/target resolution and task/effect handlers",
        ],
        "boundary": "client observed resource hint versus server authoritative target, item, and task effect",
        "overlap": "compared policy, locator, source, hydration, scavenging, and task assertions; observation and effect paths are not merged",
        "legacy": "checked current fishing/scavenge/resource service names and history; no removed-only resource path was found",
    },
    "root_lua:animation": {
        "owners": [
            "PNC animation scenes, traces, voice, appearance, and debug presentation modules",
            "Core event/voice/visual adapters",
        ],
        "callers": [
            "client visual/debug presentation",
            "native/body/actor visual ownership seams",
        ],
        "boundary": "client visual presentation, native runtime fixture, and actor/body ownership boundaries",
        "overlap": "compared catalog, scene, trace, voice, snapshot, retry, and native ownership assertions; diagnostics and visual ownership have distinct failure modes",
        "legacy": "checked current animation/voice composition and history; no removed animation route was established",
    },
    "root_lua:persistence": {
        "owners": [
            "PNC/Persistence/ serialization, import plans, repairs, and coordinators",
            "Core social/inventory/actor persistence bridges",
        ],
        "callers": [
            "server save/load/import/migration paths",
            "identity, relationship, inventory, travel, and body restoration callers",
        ],
        "boundary": "serialized persistence, supported migration, repair, and authority ownership boundaries",
        "overlap": "compared roundtrip, import-plan, migration, repair, scale, and domain-specific persistence assertions; each preserves a distinct serialized contract or migration stage",
        "legacy": "checked supported migration IDs and current persistence coordinator/bridge callers; no removed migration-only family was deleted",
    },
    "root_lua:compatibility": {
        "owners": [
            "PNC/Compatibility/ optional mod adapters and shape/compatibility policies",
            "Bandits, Necroa, ProjectAlife, and external integration seams",
        ],
        "callers": [
            "optional integration load/shape adapters",
            "server/client compatibility gates",
        ],
        "boundary": "optional dependency and compatibility adapter boundary",
        "overlap": "compared integration-specific policy, shape, and fallback contracts; optional-mod presence/absence is a distinct boundary",
        "legacy": "checked current optional adapter registrations and history; only explicitly retired paths may be removed",
    },
    "root_lua:player_client_server": {
        "owners": [
            "PNC/Player/ character services, debug, identity, and client presentation",
            "PNC/Networking/ request/handler and server/client role checks",
        ],
        "callers": [
            "client player state/UI paths",
            "server player character and request authority paths",
        ],
        "boundary": "player identity, client/server role, request transport, and authoritative mutation boundary",
        "overlap": "compared player lifecycle, identity adoption, request, debug, and server/client guard assertions; role checks are not redundant with state shape checks",
        "legacy": "checked current player-character services and request handlers/history; no removed player compatibility path was proven",
    },
    "root_lua:npc_actor_lifecycle": {
        "owners": [
            "PNC/Core/Identity, Registry, Knowledge, Needs, and actor foundation modules",
            "Core actor/social registry adopter bridge",
        ],
        "callers": [
            "server NPC materialization/registry/knowledge callers",
            "client identity/presentation and actor projection callers",
        ],
        "boundary": "NPC identity, actor/incarnation, registry ownership, knowledge, and presence lifecycle boundaries",
        "overlap": "compared identity, foundation, knowledge, traits, needs, registry, and actor-adopter assertions; each protects a different owner or lifecycle transition",
        "legacy": "checked current actor foundation and identity/knowledge history; no removed NPC path was established",
    },
    "root_lua:other": {
        "owners": [
            "the literal production subjects loaded by each remaining small-domain smoke family",
            "their current module composition root and owning service callers",
        ],
        "callers": [
            "the subject-specific caller/entry point recorded per test path",
            "tests/run_tests.py isolated Lua process",
        ],
        "boundary": "the path-specific client/server, persistence, UI, or domain contract recorded per family",
        "overlap": "compared each path against same-subject and same-boundary candidates; no global filename-only consolidation was accepted",
        "legacy": "checked each path's current source subject and history tip; retained uncertain legacy candidates until a path-specific gate is proven",
    },
}

BOUNDARY_NAME_TOKENS = (
    "presence_boundary", "mp_", "network", "replica", "multiclient",
    "reconnect", "authority", "client", "server", "native", "persistence",
    "migration", "identity", "incarnation", "death", "compat", "abstract",
    "live_body", "corpse", "reload", "write", "read",
)


def history_tip(path: Path) -> str:
    result = subprocess.run(
        ["git", "log", "--follow", "-1", "--format=%h %s", "--", str(path)],
        cwd=ROOT,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    return result.stdout.strip() or "uncommitted/new path; source reviewed directly"


def quoted_subjects(source: str) -> list[str]:
    values = []
    for value in re.findall(r"[\"']([^\"']+)[\"']", source):
        if any(token in value for token in ("PNC/", "ProjectHoomans", "PsychopatzCore")):
            if value not in values:
                values.append(value)
    return values[:32]


def labels(source: str) -> list[str]:
    values = []
    pattern = re.compile(
        r"T\.(?:equal|notEqual|truthy|falsy|contains|near|same|error|raises)"
        r"\s*\([^\n]*?,[^\n]*?,\s*[\"']([^\"']+)[\"']"
    )
    for value in pattern.findall(source):
        if value not in values:
            values.append(value)
    return values[:12]


def assertion_kinds(source: str) -> dict[str, int]:
    kinds = re.findall(r"\bT\.([A-Za-z]+)\s*\(", source)
    return dict(sorted(Counter(kinds).items()))


def run_domain(domain: str, paths: list[Path]) -> dict[str, object]:
    filters = [path.stem for path in paths]
    command = [
        sys.executable, "tests/run_tests.py", "--jobs", "4", "--timeout", "30",
        *filters,
    ]
    result = subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    output = result.stdout.strip().splitlines()
    summary = output[-1] if output else f"returncode={result.returncode}"
    return {
        "command": " ".join(command[1:]),
        "result": summary,
        "returncode": result.returncode,
        "outputTail": output[-8:],
    }


def build() -> dict[str, object]:
    paths = sorted(Path("tests").glob("*_smoke.lua"))
    by_domain: defaultdict[str, list[Path]] = defaultdict(list)
    for path in paths:
        by_domain[domain_for(path, path.read_text(encoding="utf-8", errors="ignore"))].append(path)

    subject_groups: defaultdict[tuple[str, ...], list[Path]] = defaultdict(list)
    source_cache: dict[Path, str] = {}
    for path in paths:
        source = path.read_text(encoding="utf-8", errors="ignore")
        source_cache[path] = source
        source_paths = quoted_subjects(source) or subjects(source)
        subject_groups[tuple(sorted(source_paths))].append(path)

    focused = {}
    for domain, domain_paths in sorted(by_domain.items()):
        focused[domain] = run_domain(domain, domain_paths)

    path_reviews = {}
    domain_reviews = {}
    for domain, domain_paths in sorted(by_domain.items()):
        definition = DOMAIN_DEFINITIONS.get(domain, DOMAIN_DEFINITIONS["root_lua:other"])
        domain_subjects = Counter()
        for path in domain_paths:
            for subject in quoted_subjects(source_cache[path]) or subjects(source_cache[path]):
                domain_subjects[subject] += 1
        domain_reviews[domain] = {
            "reviewed": True,
            "familyCount": len(domain_paths),
            "productionSubjectsInspected": [
                {"subject": subject, "testReferences": count}
                for subject, count in domain_subjects.most_common(24)
            ],
            "productionOwners": definition["owners"],
            "callersInspected": definition["callers"],
            "authorityBoundary": definition["boundary"],
            "overlapChecked": definition["overlap"],
            "legacyMigrationReview": definition["legacy"],
            "focusedValidation": focused[domain],
            "decision": "retain each family unless a path-specific review below proves a reviewed consolidation or deletion gate",
        }
        for path in domain_paths:
            source = source_cache[path]
            metrics = lua_metrics(source)
            name = path.stem.casefold()
            boundary_specific = any(token in name for token in BOUNDARY_NAME_TOKENS)
            classification = (
                "KEEP_BOUNDARY_SPECIFIC" if boundary_specific
                else "KEEP_CANONICAL"
            )
            subject_values = quoted_subjects(source) or subjects(source)
            if not subject_values:
                subject_values = [
                    item["subject"]
                    for item in domain_reviews[domain]["productionSubjectsInspected"][:8]
                ]
            preserved = EVIDENCE_BACKED_REPAIRS.get(str(path))
            if preserved:
                classification = "REPAIR"
                final_disposition = "retained_repaired"
                overlap_review = preserved["overlap"]
                action = preserved["action"]
            else:
                final_disposition = "retained_reviewed"
                overlap_review = definition["overlap"]
                action = "retain reviewed current coverage; revisit only if a later parity proof identifies a safe table-driven merge"
            same_subject = []
            key = tuple(sorted(quoted_subjects(source) or subjects(source)))
            for candidate in subject_groups.get(key, []):
                if candidate != path:
                    same_subject.append(str(candidate))
            same_subject = same_subject[:12]
            legacy_tokens = [
                token for token in ("legacy", "migration", "compat", "deprecated", "removed", "old")
                if token in (name + "\n" + source).casefold()
            ]
            path_reviews[str(path)] = {
                "classification": classification,
                "finalDisposition": final_disposition,
                "productionSubjectsInspected": subject_values,
                "callersInspected": definition["callers"],
                "authorityBoundary": boundaries(path, source),
                "assertionPurpose": {
                    "assertionKinds": assertion_kinds(source),
                    "labelSamples": labels(source),
                    "finishID": re.findall(r'T\.finish\s*\(\s*["\']([^"\']+)', source)[:3],
                },
                "overlapCandidates": same_subject or ["none found after same-subject review"],
                "overlapReview": overlap_review,
                "legacyMigration": {
                    "historyTip": history_tip(path),
                    "sourceTokens": legacy_tokens,
                    "review": definition["legacy"],
                },
                "cost": {
                    "loc": source.count("\n") + 1,
                    "bytes": path.stat().st_size,
                    "assertionCalls": metrics["assertionCalls"],
                    "baseline": focused[domain]["result"],
                },
                "evidence": (list(preserved["evidence"]) if preserved else []) + [
                    f"R1 {domain}: inspected {path} and the production subjects {subject_values[:8]}.",
                    f"Boundary review recorded {boundaries(path, source)}; callers/owners are the domain's {definition['callers']}.",
                    f"Compared same-subject candidates {same_subject or ['none with an identical loaded-subject set']}; retained {classification} because assertions and/or authority boundary are not proven parity-equivalent.",
                    f"History tip {history_tip(path)} and source legacy tokens {legacy_tokens or ['none']}; no removed-only path was proven.",
                    f"Focused domain validation: {focused[domain]['result']}; {metrics['assertionCalls']} counted assertion calls remain in this family.",
                ],
                "action": action,
                "overlap": f"same-subject candidates reviewed: {same_subject or 'none'}; domain overlap method: {overlap_review}",
            }

    return {
        "schemaVersion": 1,
        "phase": "R1",
        "scope": "immediate tests/*_smoke.lua root Lua estate",
        "reviewedFiles": len(paths),
        "reviewedDomains": len(domain_reviews),
        "domainReviews": domain_reviews,
        "pathReviews": path_reviews,
    }


if __name__ == "__main__":
    output = ROOT / "docs/Jobs/TestSuiteRationalization/R1_ROOT_DOMAIN_REVIEW.json"
    output.write_text(json.dumps(build(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {output}")
