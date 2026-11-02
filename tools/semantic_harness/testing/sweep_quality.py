"""Deterministic dialogue quality analyzer with confidence classes and negative controls.

Evaluates compact evidence rows against QUALITY_RUBRIC rules:
- Empty, fragment, and one-word detection (with negative controls for valid short words)
- Placeholder leaks ({0}, %s, nil, NaN) and translation key leaks (IGUI_, UI_)
- Unsupported family references (e.g. 'family' without a family bond)
- Relationship and intimacy terms without supporting bond
- Identity and private name leaks without sufficient familiarity/trust
- Perspective and agency suspicions
- Generic acknowledgement overuse
"""

from __future__ import annotations

import re
from typing import Any, Mapping

from .sweep_evidence import QualityFlag

# Words that are legitimately valid short responses (negative controls)
ALLOWED_SHORT_WORDS = frozenset({
    "yeah",
    "yeah.",
    "yes",
    "yes.",
    "no",
    "no.",
    "sure",
    "sure.",
    "right",
    "right.",
    "okay",
    "okay.",
    "thanks",
    "thanks.",
    "fine",
    "fine.",
    "nevermind",
    "nevermind.",
    "sige",
    "sige.",
    "oo",
    "oo.",
    "hindi",
    "hindi.",
    "ayos",
    "ayos.",
    "salamat",
    "salamat.",
})

FAMILY_TERMS_PATTERN = re.compile(
    r"\b(family|mother|father|sister|brother|mom|dad|sis|bro|nanay|tatay|ate|kuya)\b",
    re.IGNORECASE,
)

ROMANTIC_TERMS_PATTERN = re.compile(
    r"\b(darling|sweetheart|sweetie|babe|baby|honey|mahal|irog)\b",
    re.IGNORECASE,
)

PLACEHOLDER_LEAK_PATTERN = re.compile(
    r"(\{[0-9a-zA-Z_]+\}|%[0-9]*[sdif]|<[0-9a-zA-Z_]+>|\bNaN\b|\bnil\b|\bundefined\b)",
)

TRANSLATION_KEY_PATTERN = re.compile(
    r"\b(IGUI_[a-zA-Z0-9_]+|UI_[a-zA-Z0-9_]+|ContextMenu_[a-zA-Z0-9_]+)\b",
)

VALID_FAMILY_BONDS = frozenset({"mother", "father", "sister", "brother"})


class QualityAnalyzer:
    """Evaluates evidence rows and attaches deterministic quality flags."""

    def analyze_row(self, row: dict[str, Any]) -> list[QualityFlag]:
        """Analyze a single evidence row and return any discovered QualityFlags."""
        flags: list[QualityFlag] = []

        final_text = str(row.get("output", {}).get("finalText") or "").strip()
        semantic_path = row.get("semanticPath", {})
        trigger = row.get("trigger", {})
        rel_summary = trigger.get("relationshipSummary", {})
        bond_kind = str(rel_summary.get("bondKind") or "none").lower()
        bond_class = str(rel_summary.get("bondClass") or "").lower()
        familiarity = float(rel_summary.get("familiarity") or 0.0)
        identity_trust = float(rel_summary.get("identityTrust") or 0.0)

        # 1. EMPTY_RESPONSE
        if not final_text:
            flags.append(
                QualityFlag(
                    name="EMPTY_RESPONSE",
                    severity="CRITICAL",
                    confidence="DEFINITE",
                    detail="Rendered NPC response is completely empty or blank.",
                )
            )
            return flags

        # 2. PLACEHOLDER_LEAK
        placeholder_match = PLACEHOLDER_LEAK_PATTERN.search(final_text)
        if placeholder_match:
            flags.append(
                QualityFlag(
                    name="PLACEHOLDER_LEAK",
                    severity="CRITICAL",
                    confidence="DEFINITE",
                    detail=f"Unreplaced template placeholder found in text: '{placeholder_match.group(1)}'",
                )
            )

        # 3. TRANSLATION_KEY_LEAK
        key_match = TRANSLATION_KEY_PATTERN.search(final_text)
        if key_match:
            flags.append(
                QualityFlag(
                    name="TRANSLATION_KEY_LEAK",
                    severity="CRITICAL",
                    confidence="DEFINITE",
                    detail=f"Raw translation key leaked into final text: '{key_match.group(1)}'",
                )
            )

        # 4. ONE_WORD_RESPONSE / VERY_SHORT_FRAGMENT
        words = final_text.split()
        if len(words) == 1:
            clean_word = words[0].lower().rstrip(".!?,")
            # Negative control check: allowed conversational words pass cleanly
            if clean_word not in ALLOWED_SHORT_WORDS and words[0].lower() not in ALLOWED_SHORT_WORDS:
                flags.append(
                    QualityFlag(
                        name="ONE_WORD_RESPONSE",
                        severity="HIGH",
                        confidence="SUSPECT",
                        detail=f"Single-word response '{final_text}' is not an approved conversational short response.",
                    )
                )

        # 5. UNSUPPORTED_FAMILY_REFERENCE
        # Required user-observed defect class:
        # Detects family wording or familyAddress when relationship context is NOT a family bond
        family_match = FAMILY_TERMS_PATTERN.search(final_text)
        has_family_address = bool(semantic_path.get("familyAddress"))
        is_family_bond = bond_kind in VALID_FAMILY_BONDS or bond_class == "family"

        if (family_match or has_family_address) and not is_family_bond:
            term = family_match.group(1) if family_match else "familyAddress"
            flags.append(
                QualityFlag(
                    name="UNSUPPORTED_FAMILY_REFERENCE",
                    severity="CRITICAL",
                    confidence="DEFINITE",
                    detail=(
                        f"Family reference '{term}' used but relationship bond is '{bond_kind}' "
                        f"(bondClass: '{bond_class or 'none'}'). Unsupported by context."
                    ),
                )
            )

        # 6. RELATIONSHIP_TERM_WITHOUT_BOND
        romantic_match = ROMANTIC_TERMS_PATTERN.search(final_text)
        if romantic_match and bond_kind != "lover":
            flags.append(
                QualityFlag(
                    name="RELATIONSHIP_TERM_WITHOUT_BOND",
                    severity="HIGH",
                    confidence="DEFINITE",
                    detail=f"Intimate address '{romantic_match.group(1)}' used when bondKind is '{bond_kind}' (expected 'lover').",
                )
            )

        # 7. IDENTITY_TERM_WITHOUT_KNOWLEDGE
        # Check if NPC uses player name when stranger / low trust
        player_id = trigger.get("actorSummary", {}).get("listenerID") or ""
        if player_id and len(player_id) > 2 and player_id.lower() in final_text.lower():
            if familiarity < 5.0 or identity_trust < 50.0:
                flags.append(
                    QualityFlag(
                        name="IDENTITY_TERM_WITHOUT_KNOWLEDGE",
                        severity="HIGH",
                        confidence="SUSPECT",
                        detail=(
                            f"Name '{player_id}' used with low familiarity ({familiarity:.1f} < 5) "
                            f"or low identity trust ({identity_trust:.1f} < 50)."
                        ),
                    )
                )

        # 8. PERSPECTIVE_SUSPECT
        intent = str(semantic_path.get("intent") or "").lower()
        if "wellbeing" in intent and final_text.lower().startswith("you are "):
            flags.append(
                QualityFlag(
                    name="PERSPECTIVE_SUSPECT",
                    severity="MEDIUM",
                    confidence="REVIEW",
                    detail="Wellbeing reply appears to describe listener ('You are...') instead of speaker.",
                )
            )

        # 9. GENERIC_ACKNOWLEDGEMENT_SUSPECT
        if final_text.lower() in ("i understand.", "i see.", "acknowledged.", "that is good."):
            flags.append(
                QualityFlag(
                    name="GENERIC_ACKNOWLEDGEMENT_SUSPECT",
                    severity="LOW",
                    confidence="REVIEW",
                    detail=f"Canned generic acknowledgement '{final_text}' may lack situational specificity.",
                )
            )

        return flags

    def tag_row(self, row: dict[str, Any]) -> dict[str, Any]:
        """Analyze row, append flags and cluster keys, and update review state."""
        flags = self.analyze_row(row)
        flag_dicts = [f.to_dict() for f in flags]
        row.setdefault("quality", {})["flags"] = flag_dicts

        # Build cluster keys
        cluster_keys: list[str] = []
        sem_path = row.get("semanticPath", {})
        canonical_source = row.get("selectionProvenance", {}).get("canonicalSourceOwner") or "UNKNOWN"
        phrase_id = sem_path.get("phraseID") or sem_path.get("semanticVariantID")
        pool_id = sem_path.get("semanticTemplateID")

        for f in flags:
            cluster_keys.append(f"flag:{f.name}")
            if canonical_source != "UNKNOWN":
                cluster_keys.append(f"source:{canonical_source}:{f.name}")
            if phrase_id:
                cluster_keys.append(f"phrase:{phrase_id}:{f.name}")
            elif pool_id:
                cluster_keys.append(f"pool:{pool_id}:{f.name}")

        row["quality"]["clusterKeys"] = cluster_keys
        if flags:
            row["quality"]["reviewState"] = "FLAGGED"
        else:
            row["quality"]["reviewState"] = "UNREVIEWED"

        return row
