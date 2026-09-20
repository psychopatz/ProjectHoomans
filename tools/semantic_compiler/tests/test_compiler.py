from __future__ import annotations

import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

from tools.semantic_compiler.compiler import (
    CompileError,
    compile_wordnet,
    load_allowlist,
    render_lua,
)


REPOSITORY = Path(__file__).resolve().parents[3]
PRODUCTION_ALLOWLIST = REPOSITORY / "tools/semantic_compiler/wordnet_concepts.json"


def index_row(lemma: str, offsets: list[str]) -> str:
    return f"{lemma} v {len(offsets)} 0 {len(offsets)} 0 {' '.join(offsets)}"


class SemanticCompilerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.home = Path(self.temporary.name) / "WordNet-3.0"
        dictionary = self.home / "dict"
        dictionary.mkdir(parents=True)
        (self.home / "LICENSE").write_text(
            "WordNet Release 3.0\nCopyright (fixture)\n", encoding="utf-8")
        data = [
            "01433294 35 v 03 bring 00 get 00 fetch 00 0 | bring or fetch",
            "01433991 35 v 01 retrieve 00 0 | go for and bring back",
            "01439190 35 v 02 grab 00 take_hold_of 00 0 | take hold of",
            "02305586 40 v 01 pick_up 00 0 | pick up and collect",
            "01998432 35 v 01 follow 00 0 | travel behind",
        ]
        (dictionary / "data.verb").write_text("\n".join(data) + "\n", encoding="ascii")
        index = [
            index_row("bring", ["01433294"]),
            index_row("get", ["01433294"]),
            index_row("fetch", ["01433294"]),
            index_row("retrieve", ["01433991"]),
            index_row("grab", ["01439190"]),
            index_row("take_hold_of", ["01439190"]),
            index_row("take", ["00000001"]),
            index_row("pick_up", ["02305586"]),
            index_row("pick", ["00000002"]),
            index_row("follow", ["01998432"]),
        ]
        (dictionary / "index.verb").write_text("\n".join(index) + "\n", encoding="ascii")
        (dictionary / "verb.exc").write_text(
            "brought bring\n"
            "got get\n"
            "gotten get\n"
            "grabbed grab\n"
            "grabbing grab\n"
            "took take\n"
            "taken take\n",
            encoding="ascii",
        )
        self.allowlist = load_allowlist(PRODUCTION_ALLOWLIST)
        self.allowlist["source"]["expected_sha256"] = {
            name: hashlib.sha256((dictionary / name).read_bytes()).hexdigest()
            for name in ("index.verb", "data.verb", "verb.exc")
        }
        self.allowlist["source"]["expected_sha256"]["LICENSE"] = hashlib.sha256(
            (self.home / "LICENSE").read_bytes()).hexdigest()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_only_lemmas_are_emitted_as_aliases(self) -> None:
        compiled = compile_wordnet(self.home, self.allowlist)
        aliases = set(compiled.aliases_by_concept["FETCH"])

        for expected in (
            "bring", "fetch", "get", "retrieve", "grab", "take hold of",
            "pick up",
        ):
            self.assertIn(expected, aliases)
        for inflected in (
            "takes hold of", "took hold of", "taken hold of", "picked up",
            "picking up", "grabbed", "grabbing", "grabs", "brought",
            "bringing", "retrieved", "retrieving", "fetches", "fetched",
            "fetching",
        ):
            self.assertNotIn(inflected, aliases)
        self.assertNotIn("got", aliases)
        self.assertNotIn("gotten", aliases)
        self.assertNotIn("catch", aliases)
        self.assertEqual(set(compiled.aliases_by_concept["FOLLOW"]), {"follow"})
        self.assertNotIn("following", compiled.aliases_by_concept["FOLLOW"])

    def test_inflections_keep_lemma_and_form_without_becoming_aliases(self) -> None:
        compiled = compile_wordnet(self.home, self.allowlist)
        forms = compiled.verb_forms_by_surface

        self.assertEqual(forms["grabs"], ("FETCH", "grab", "THIRD_PERSON"))
        self.assertEqual(forms["grabbed"], ("FETCH", "grab", "PAST"))
        self.assertEqual(forms["grabbing"], ("FETCH", "grab", "PROGRESSIVE"))
        self.assertEqual(forms["picked up"], ("FETCH", "pick up", "PAST"))
        self.assertEqual(forms["picking up"], ("FETCH", "pick up", "PROGRESSIVE"))
        self.assertEqual(forms["following"], ("FOLLOW", "follow", "PROGRESSIVE"))
        self.assertEqual(forms["followed"], ("FOLLOW", "follow", "PAST"))
        self.assertEqual(forms["follows"], ("FOLLOW", "follow", "THIRD_PERSON"))
        self.assertNotIn("got", forms)
        self.assertNotIn("gotten", forms)

    def test_synset_membership_is_required(self) -> None:
        invalid = copy.deepcopy(self.allowlist)
        invalid["concepts"]["FETCH"]["synsets"][0]["lemmas"].append("convey")
        with self.assertRaisesRegex(CompileError, "not a member"):
            compile_wordnet(self.home, invalid)

    def test_alias_collisions_across_concepts_fail_closed(self) -> None:
        conflicting = copy.deepcopy(self.allowlist)
        conflicting["concepts"]["OTHER"] = {
            "synsets": [
                {"pos": "v", "offset": "01439190", "lemmas": ["grab"]}
            ]
        }
        with self.assertRaisesRegex(CompileError, "maps to both"):
            compile_wordnet(self.home, conflicting)

    def test_output_is_deterministic_and_carries_provenance(self) -> None:
        first = render_lua(compile_wordnet(self.home, self.allowlist))
        second = render_lua(compile_wordnet(self.home, self.allowlist))
        self.assertEqual(first, second)
        self.assertIn("WordNet 3.0 license notice", first)
        self.assertIn("version = \"3.0\"", first)
        self.assertIn("SHA256 data.verb:", first)
        self.assertIn("verbFormsBySurface = {", first)
        self.assertIn('["grabbing"]', first)
        self.assertIn('["following"]', first)

    def test_unknown_offset_fails_instead_of_emitting_partial_data(self) -> None:
        invalid = copy.deepcopy(self.allowlist)
        invalid["concepts"]["FETCH"]["synsets"][0]["offset"] = "99999999"
        with self.assertRaisesRegex(CompileError, "was not found"):
            compile_wordnet(self.home, invalid)

    def test_source_hashes_are_pinned(self) -> None:
        invalid = copy.deepcopy(self.allowlist)
        invalid["source"]["expected_sha256"]["data.verb"] = "0" * 64
        with self.assertRaisesRegex(CompileError, "source hash mismatch"):
            compile_wordnet(self.home, invalid)


if __name__ == "__main__":
    unittest.main()
