"""Unit tests for the compact .convo DSL compiler, lexicon, and static validation."""

from __future__ import annotations

import unittest

from tools.providers.pnc.codebuilder.convo_dsl.cli import compile_all
from tools.providers.pnc.codebuilder.convo_dsl.emitter import emit_lua
from tools.providers.pnc.codebuilder.convo_dsl.parser import (
    parse_convo_text,
    validate_language_pack,
)


class ConvoDSLTests(unittest.TestCase):
    def test_valid_lex_and_flow_emit_modular_lua(self) -> None:
        src = """
lang EN
namespace hoomans

lex noun.zombie
  [actor.style=tactical] (pri 8): "hostile" | "infected"
  [default]: "walker" | "dead"

lex clause.night_note
  [env.night_or_dusk] (pri 8): "Hard spotting {noun.zombie|s} in the dark."

flow semantic.demo.greet
  say [rel.tier=wary, env.night_or_dusk] (pri 8) as night_wary:
    "Watch those {noun.zombie|s}. {?clause.night_note}"
  offer demo.reply_ok:
    label: "All good"
    say: "Easy, I'm {speaker.name}."
    utility: openness
    intent: INFORM
    subject: GREETING
"""
        script = parse_convo_text(src, "demo.convo")
        validate_language_pack([script])
        lua = emit_lua(script, "demo.convo")

        self.assertIn('Lexicon.Register("EN", "noun.zombie"', lua)
        self.assertIn('Lexicon.Register("EN", "clause.night_note"', lua)
        self.assertIn('Catalog.Register("semantic.demo.greet"', lua)
        self.assertIn('"hoomans.demo.greet.night_wary"', lua)
        self.assertIn('utility = "openness"', lua)

    def test_unknown_predicate_fails_at_compile_time(self) -> None:
        src = """
beat semantic.demo.bad
  say [typo.flag=true]:
    "Should fail."
"""
        with self.assertRaisesRegex(ValueError, "unknown context predicate 'typo.flag'"):
            parse_convo_text(src, "bad.convo")

    def test_unknown_lex_reference_fails_at_compile_time(self) -> None:
        src = """
beat semantic.demo.bad_ref
  say [default]:
    "Watch out for {noun.zombe|s}!"
"""
        script = parse_convo_text(src, "bad_ref.convo")
        with self.assertRaisesRegex(ValueError, "unknown lex/token reference '\\{noun.zombe\\}'"):
            validate_language_pack([script])

    def test_cyclic_lex_reference_fails_at_compile_time(self) -> None:
        src = """
lex clause.a
  [default]: "{clause.b}"
lex clause.b
  [default]: "{clause.a}"
"""
        script = parse_convo_text(src, "cycle.convo")
        with self.assertRaisesRegex(ValueError, "cyclic lex reference detected"):
            validate_language_pack([script])

    def test_production_language_packs_validate_cleanly(self) -> None:
        validated = compile_all(check_only=True)
        self.assertGreaterEqual(len(validated), 3)


if __name__ == "__main__":
    unittest.main()
