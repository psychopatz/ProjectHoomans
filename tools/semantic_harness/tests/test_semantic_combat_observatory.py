from __future__ import annotations

from copy import deepcopy
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def tactical_fixture() -> dict:
    event_ref = "horde:observatory"
    return {
        "record": {
            "id": "npc-observatory",
            "alive": True,
            "activeJob": "FollowOwner",
            "ownerOnlineID": 7,
            "runtime": {
                "zombieHordeAwareness": {
                    "active": True,
                    "sequence": 1,
                    "lastPhase": "started",
                    "episodeID": event_ref,
                    "lastBand": "horde",
                    "lastCount": 9,
                    "startedAt": 1000,
                    "lastObservedAt": 1000,
                }
            },
        },
        "encounterTransitions": [
            {"phase": "started", "episodeID": event_ref, "now": 1000},
        ],
        "moments": {
            "prompt": {
                "kind": "tactical_prompt",
                "eventType": "zombie_horde_encounter",
                "actorKind": "npc",
                "actorID": "npc-observatory",
                "targetKind": "zombie_group",
                "pressureBand": "horde",
                "nearbyCount": 9,
                "encounterID": event_ref,
                "encounterIntent": "undecided",
                "presentationClass": "TACTICAL_PROMPT",
                "occurredAt": 1000,
            }
        },
        "operations": [
            {
                "kind": "reserve",
                "momentID": "prompt",
                "spec": {
                    "streamKey": "awareness:player:p1:horde_tactical_prompt",
                    "now": 1000,
                    "cooldownMs": 12000,
                    "maxSpeakers": 1,
                    "speakerID": "npc-observatory",
                    "audienceKey": "player:p1",
                    "family": "horde_tactical_prompt",
                    "familyCooldownMs": 12000,
                    "priority": 100,
                },
            },
            {
                "kind": "presentation",
                "momentID": "prompt",
                "spec": {
                    "accepted": True,
                    "reason": "presentation_sent",
                    "at": 1001,
                    "speakerID": "npc-observatory",
                    "audienceKey": "player:p1",
                    "family": "horde_tactical_prompt",
                    "eventRef": event_ref,
                    "responsePlanID": "semantic.combat.horde.prompt",
                    "realizationID": "semantic.combat.horde.prompt.default",
                    "presentationClass": "TACTICAL_PROMPT",
                    "tacticalSpatial": {
                        "targetKind": "zombie_group",
                        "targetRef": event_ref,
                        "targetPositionSource": "combat_centroid",
                        "headingSource": "live_body",
                        "clockToken": "CLOCK_08",
                        "relativeSector8": "REAR_LEFT",
                        "distanceBand": "NEAR",
                        "freshnessMs": 0,
                        "presentationMode": "clock",
                        "presentationReason": "tactical_role:guard",
                    },
                    "tacticalPresentation": {
                        "mode": "clock",
                        "clockToken": "CLOCK_08",
                        "relativeSector8": "REAR_LEFT",
                        "templateID":
                            "semantic.combat.tactical_spatial.zombie.clock",
                        "translationKey":
                            "UI_PNC_Conversation_Content_SemanticCombatTacticalSpatialZombieClockNeutral01",
                    },
                    "offerIDs": [
                        "semantic.combat.horde.choice.engage",
                        "semantic.combat.horde.choice.avoid",
                        "semantic.combat.horde.choice.hold",
                    ],
                },
            },
        ],
        "inspect": {"eventRef": event_ref, "limit": 4},
    }


def silence_fixture() -> dict:
    return {
        "record": {
            "id": "npc-silent",
            "alive": True,
            "runtime": {},
        },
        "moments": {
            "urgent": {
                "kind": "tactical_prompt",
                "eventType": "zombie_horde_encounter",
                "actorKind": "npc",
                "actorID": "npc-urgent",
                "targetKind": "zombie_group",
                "presentationClass": "TACTICAL_PROMPT",
                "occurredAt": 2000,
            },
            "kill": {
                "kind": "kill",
                "eventType": "zombie_kill_witnessed",
                "actorKind": "player",
                "actorID": "player:p1",
                "targetKind": "zombie",
                "outcome": "killed",
                "attackType": "ranged",
                "attackKind": "firearm",
                "weaponDisplayName": "M9 Pistol",
                "weaponFamily": "firearm",
                "weaponSkill": "Aiming",
                "weaponSkillLevel": 8,
                "weaponSkillBand": "high",
                "weaponNameEligible": True,
                "hitZone": "head_neck",
                "woundType": "gunshot",
                "presentationClass": "BARK",
                "occurredAt": 2100,
            },
        },
        "operations": [
            {
                "kind": "reserve",
                "momentID": "urgent",
                "spec": {
                    "streamKey": "awareness:player:p1:horde",
                    "now": 2000,
                    "cooldownMs": 12000,
                    "maxSpeakers": 1,
                    "speakerID": "npc-urgent",
                    "audienceKey": "player:p1",
                    "family": "horde_tactical_prompt",
                    "familyCooldownMs": 12000,
                    "priorityHoldMs": 5000,
                    "priority": 100,
                },
            },
            {
                "kind": "begin",
                "momentID": "kill",
                "gateID": "kill-gate",
                "spec": {
                    "streamKey": "player_kill:player:p1",
                    "now": 2100,
                    "cooldownMs": 5000,
                    "maxSpeakers": 2,
                    "priority": 10,
                },
            },
            {
                "kind": "consider",
                "momentID": "kill",
                "gateID": "kill-gate",
                "spec": {
                    "now": 2100,
                    "speakerID": "npc-silent",
                    "audienceKey": "player:p1",
                    "family": "combat_kill_witness",
                    "priority": 10,
                },
            },
        ],
        "inspect": {"npcID": "npc-silent", "limit": 4},
    }


class SemanticCombatObservatoryTests(unittest.TestCase):
    def test_worker_explains_tactical_prompt_from_production_lua(self) -> None:
        fixture = tactical_fixture()
        event_ref = fixture["inspect"]["eventRef"]
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            first = worker.combat_observatory_fixture(fixture)
            again = worker.combat_observatory_inspect(
                npc_id="npc-observatory",
                event_ref=event_ref,
                limit=4,
            )

        self.assertTrue(first["ok"])
        self.assertEqual(first["workerKind"], "production_lua")
        self.assertEqual(first["schema"], "semantic.combat.observatory.v1")
        self.assertEqual(first["hordeEpisode"]["phase"], "started")
        self.assertEqual(first["encounterIntent"]["intent"], "undecided")
        self.assertEqual(first["combatMoment"]["kind"], "tactical_prompt")
        self.assertEqual(first["presentation"]["class"], "TACTICAL_PROMPT")
        self.assertEqual(first["presentation"]["offerCount"], 3)
        self.assertEqual(
            {row["action"] for row in first["presentation"]["offers"]},
            {"COMBAT_ENGAGE", "COMBAT_AVOID", "COMBAT_HOLD"},
        )
        self.assertEqual(first["explanation"]["outcome"], "asked")
        self.assertEqual(first["explanation"]["reason"], "presentation_sent")
        self.assertTrue(first["tacticalSpatial"]["available"])
        self.assertEqual(first["tacticalSpatial"]["clockToken"], "CLOCK_08")
        self.assertEqual(
            first["tacticalSpatial"]["relativeSector8"], "REAR_LEFT"
        )
        self.assertEqual(
            first["tacticalSpatial"]["targetPositionSource"], "combat_centroid"
        )
        self.assertEqual(
            first["tacticalSpatial"]["headingSource"], "live_body"
        )
        self.assertEqual(
            first["tacticalSpatial"]["presentationMode"], "clock"
        )
        self.assertIsNone(
            first["tacticalSpatial"].get("suppressionReason")
        )
        self.assertNotIn("fallback", first["tacticalSpatial"])
        self.assertLessEqual(len(first["arbiter"]["decisions"]), 4)

        # Inspection is read-only over the same bounded production owners.
        for key in (
            "hordeEpisode",
            "encounterIntent",
            "combatMoment",
            "presentation",
            "weapon",
            "tacticalSpatial",
            "explanation",
        ):
            self.assertEqual(first[key], again[key], key)
        self.assertEqual(
            first["arbiter"]["decisionSequence"],
            again["arbiter"]["decisionSequence"],
        )

    def test_worker_explains_silence_and_weapon_predicates(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            view = worker.combat_observatory_fixture(silence_fixture())

        self.assertTrue(view["ok"])
        self.assertEqual(view["explanation"]["outcome"], "silent")
        self.assertEqual(view["explanation"]["reason"], "higher_priority_active")
        self.assertEqual(view["weapon"]["family"], "firearm")
        self.assertEqual(view["weapon"]["skill"], "Aiming")
        self.assertTrue(view["weapon"]["highSkill"])
        self.assertTrue(view["weapon"]["nameEligible"])
        self.assertTrue(view["weapon"]["nameAvailable"])
        self.assertEqual(view["weapon"]["displayName"], "M9 Pistol")
        self.assertTrue(view["weapon"]["headNeckResult"])
        self.assertEqual(view["weapon"]["woundType"], "gunshot")
        self.assertLessEqual(len(view["arbiter"]["decisions"]), 4)

    def test_worker_api_enforces_bounded_inspection(self) -> None:
        with LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO)) as worker:
            worker.combat_observatory_fixture(tactical_fixture())
            with self.assertRaisesRegex(ValueError, "1 to 8"):
                worker.combat_observatory_inspect(limit=0)
            with self.assertRaisesRegex(ValueError, "1 to 8"):
                worker.combat_observatory_inspect(limit=9)


if __name__ == "__main__":
    unittest.main()
