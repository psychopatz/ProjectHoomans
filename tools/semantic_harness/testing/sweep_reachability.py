"""Production-backed variant reachability frontier and selection provenance analyzer.

Analyzes registered response pools and variants against executed sweep evidence,
truthfully classifying each variant into:
- UNTESTED
- TESTED_INELIGIBLE
- ELIGIBLE_NOT_SELECTED (dominated in tested contexts)
- SELECTED
- SELECTED_UNDER_SUSPICIOUS_CONTEXT

Crucial rule: Finite non-selection is NEVER claimed to be globally impossible or unreachable.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Mapping, Sequence

REACHABILITY_SCHEMA_V1 = "pnc.semantic-reachability-report.v1"
ALLOWED_REACHABILITY_SCHEMAS = frozenset({REACHABILITY_SCHEMA_V1})


class VariantReachabilityState:
    UNTESTED = "UNTESTED"
    TESTED_INELIGIBLE = "TESTED_INELIGIBLE"
    ELIGIBLE_NOT_SELECTED = "ELIGIBLE_NOT_SELECTED"
    SELECTED = "SELECTED"
    SELECTED_UNDER_SUSPICIOUS_CONTEXT = "SELECTED_UNDER_SUSPICIOUS_CONTEXT"


@dataclass
class VariantReachabilityRecord:
    """Reachability status and production evidence for a single response variant."""

    pool_id: str
    variant_id: str
    status: str  # VariantReachabilityState
    tested_contexts_count: int = 0
    eligible_contexts_count: int = 0
    selected_contexts_count: int = 0
    selected_case_ids: list[str] = field(default_factory=list)
    rejection_reasons: list[str] = field(default_factory=list)
    failed_checks: list[str] = field(default_factory=list)
    canonical_source_owner: str = "UNKNOWN"
    global_unreachable_claim: bool = False  # Mandatory: never claim global unreachability

    def to_dict(self) -> dict[str, Any]:
        return {
            "poolID": self.pool_id,
            "variantID": self.variant_id,
            "status": self.status,
            "testedContextsCount": self.tested_contexts_count,
            "eligibleContextsCount": self.eligible_contexts_count,
            "selectedContextsCount": self.selected_contexts_count,
            "selectedCaseIDs": self.selected_case_ids,
            "rejectionReasons": self.rejection_reasons,
            "failedChecks": self.failed_checks,
            "canonicalSourceOwner": self.canonical_source_owner,
            "globalUnreachableClaim": False,
        }


@dataclass
class ReachabilityReport:
    """Comprehensive reachability report across registered response pools."""

    sweep_id: str
    total_pools: int
    total_variants: int
    status_counts: dict[str, int]
    pool_records: dict[str, list[VariantReachabilityRecord]]
    frontier_candidates: list[dict[str, Any]] = field(default_factory=list)
    global_unreachable_warning: str = (
        "Finite non-selection in tested matrices does not prove global unreachability."
    )
    schema: str = REACHABILITY_SCHEMA_V1
    schema_version: int = 1

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": self.schema,
            "schemaVersion": self.schema_version,
            "sweepID": self.sweep_id,
            "totalPools": self.total_pools,
            "totalVariants": self.total_variants,
            "statusCounts": self.status_counts,
            "globalUnreachableWarning": self.global_unreachable_warning,
            "pools": {
                p: [v.to_dict() for v in vars_list]
                for p, vars_list in self.pool_records.items()
            },
            "frontierCandidates": self.frontier_candidates,
        }


class ReachabilityAnalyzer:
    """Analyzes response variant reachability using production worker evidence."""

    def __init__(self, worker: Any | None = None) -> None:
        self.worker = worker

    def analyze_reachability(
        self,
        evidence_rows: Sequence[Mapping[str, Any]],
        *,
        worker: Any | None = None,
        sweep_id: str = "reachability_analysis",
        target_pools: Sequence[str] | None = None,
        lineage_cache: Mapping[str, str] | None = None,
    ) -> ReachabilityReport:
        """Analyze reachability of registered response variants against executed evidence rows."""
        active_worker = worker or self.worker
        if active_worker is None:
            raise ValueError("A LuaSemanticWorker is required to discover registered pools and explain selection")

        # Discover registered pools
        if target_pools:
            pool_ids = list(target_pools)
        else:
            pools_listing = active_worker.response_pool_list(limit=64)
            pool_ids = [
                p["id"]
                for p in pools_listing.get("pools", [])
                if isinstance(p, dict) and p.get("id")
            ]

        # Map executed evidence rows by selected variant and template
        selected_variant_counts: dict[str, int] = {}
        selected_variant_cases: dict[str, list[str]] = {}
        selected_variant_suspicious: dict[str, bool] = {}

        for row in evidence_rows:
            case_id = row.get("identity", {}).get("caseID") or "unknown"
            sel_provenance = row.get("selectionProvenance", {})
            sem_path = row.get("semanticPath", {})
            out = row.get("output", {})
            quality = row.get("quality", {})
            flags = quality.get("flags", [])

            is_suspicious = any(
                f.get("name") in (
                    "UNSUPPORTED_FAMILY_REFERENCE",
                    "RELATIONSHIP_TERM_WITHOUT_BOND",
                    "PERSPECTIVE_SUSPECT",
                    "EXECUTION_ERROR",
                )
                for f in flags
            )

            # Check selectedVariantID or semanticVariantID
            var_id = (
                sel_provenance.get("selectedVariantID")
                or sem_path.get("semanticVariantID")
            )
            if var_id:
                selected_variant_counts[var_id] = selected_variant_counts.get(var_id, 0) + 1
                selected_variant_cases.setdefault(var_id, []).append(case_id)
                if is_suspicious:
                    selected_variant_suspicious[var_id] = True

        total_variants_count = 0
        pool_records: dict[str, list[VariantReachabilityRecord]] = {}
        status_counts: dict[str, int] = {
            VariantReachabilityState.UNTESTED: 0,
            VariantReachabilityState.TESTED_INELIGIBLE: 0,
            VariantReachabilityState.ELIGIBLE_NOT_SELECTED: 0,
            VariantReachabilityState.SELECTED: 0,
            VariantReachabilityState.SELECTED_UNDER_SUSPICIOUS_CONTEXT: 0,
        }
        frontier_candidates: list[dict[str, Any]] = []

        # Analyze each pool
        for pool_id in pool_ids:
            try:
                detail = active_worker.response_pool_detail(pool_id)
            except Exception:
                continue

            variants = detail.get("variants", [])
            total_variants_count += len(variants)
            records: list[VariantReachabilityRecord] = []

            # Sample 1 baseline context to test eligibility explanation if not already selected
            explanation = None
            try:
                explanation = active_worker.explain_response_selection(pool_id, {}, "")
            except Exception:
                explanation = {}

            cand_by_id = {
                c["id"]: c
                for c in explanation.get("candidates", [])
                if isinstance(c, dict) and c.get("id")
            }

            for v in variants:
                var_id = v.get("id")
                if not var_id:
                    continue

                source_owner = "UNKNOWN"
                if lineage_cache and var_id in lineage_cache:
                    source_owner = lineage_cache[var_id]

                sel_count = selected_variant_counts.get(var_id, 0)
                cases = selected_variant_cases.get(var_id, [])

                if sel_count > 0:
                    if selected_variant_suspicious.get(var_id):
                        status = VariantReachabilityState.SELECTED_UNDER_SUSPICIOUS_CONTEXT
                    else:
                        status = VariantReachabilityState.SELECTED
                    rec = VariantReachabilityRecord(
                        pool_id=pool_id,
                        variant_id=var_id,
                        status=status,
                        tested_contexts_count=sel_count,
                        eligible_contexts_count=sel_count,
                        selected_contexts_count=sel_count,
                        selected_case_ids=cases[:10],
                        canonical_source_owner=source_owner,
                        global_unreachable_claim=False,
                    )
                else:
                    # Check candidate explanation in tested baseline
                    cand = cand_by_id.get(var_id)
                    if cand is not None:
                        eligible = cand.get("eligible", False)
                        reason = cand.get("reason", "unknown")
                        failed_checks = [
                            chk["field"]
                            for chk in cand.get("checks", [])
                            if not chk.get("matched")
                        ]
                        if eligible:
                            status = VariantReachabilityState.ELIGIBLE_NOT_SELECTED
                            reasons = [reason] if reason else ["lower_score"]
                            status_counts[status] += 1
                            rec = VariantReachabilityRecord(
                                pool_id=pool_id,
                                variant_id=var_id,
                                status=status,
                                tested_contexts_count=1,
                                eligible_contexts_count=1,
                                selected_contexts_count=0,
                                rejection_reasons=reasons,
                                canonical_source_owner=source_owner,
                                global_unreachable_claim=False,
                            )
                            frontier_candidates.append({
                                "poolID": pool_id,
                                "variantID": var_id,
                                "status": status,
                                "reason": reason,
                            })
                        else:
                            status = VariantReachabilityState.TESTED_INELIGIBLE
                            status_counts[status] += 1
                            rec = VariantReachabilityRecord(
                                pool_id=pool_id,
                                variant_id=var_id,
                                status=status,
                                tested_contexts_count=1,
                                eligible_contexts_count=0,
                                selected_contexts_count=0,
                                rejection_reasons=[reason],
                                failed_checks=failed_checks,
                                canonical_source_owner=source_owner,
                                global_unreachable_claim=False,
                            )
                            frontier_candidates.append({
                                "poolID": pool_id,
                                "variantID": var_id,
                                "status": status,
                                "failedChecks": failed_checks,
                            })
                    else:
                        status = VariantReachabilityState.UNTESTED
                        status_counts[status] += 1
                        rec = VariantReachabilityRecord(
                            pool_id=pool_id,
                            variant_id=var_id,
                            status=status,
                            canonical_source_owner=source_owner,
                            global_unreachable_claim=False,
                        )

                if rec.status in (
                    VariantReachabilityState.SELECTED,
                    VariantReachabilityState.SELECTED_UNDER_SUSPICIOUS_CONTEXT,
                ):
                    status_counts[rec.status] += 1

                records.append(rec)

            pool_records[pool_id] = records

        return ReachabilityReport(
            sweep_id=sweep_id,
            total_pools=len(pool_records),
            total_variants=total_variants_count,
            status_counts=status_counts,
            pool_records=pool_records,
            frontier_candidates=frontier_candidates,
        )
