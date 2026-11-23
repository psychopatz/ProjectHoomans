-- Generated Conversation discovery index; do not edit by hand.
return {
    ["combat.fighting.injured_callout"] = {
        ["domain"] = "combat_wound_callouts",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/FightingInjuredCalloutToInjuryTriageExchange",
        },
        ["id"] = "combat.fighting.injured_callout",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/combat_wound_callouts/combat_fighting_injured_callout.json",
    },
    ["combat.injury.pain_reaction"] = {
        ["domain"] = "combat_wound_callouts",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/FightingInjuredCalloutToInjuryTriageExchange",
        },
        ["id"] = "combat.injury.pain_reaction",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/combat_wound_callouts/combat_injury_pain_reaction.json",
    },
    ["combat.injury.triage_exchange"] = {
        ["domain"] = "combat_wound_callouts",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/FightingInjuredCalloutToInjuryTriageExchange",
        },
        ["id"] = "combat.injury.triage_exchange",
        ["kind"] = "dialogue",
        ["related"] = {
            "combat.aftermath.debrief_exchange",
            "social.conflict.mediate_exchange",
            "wellbeing.needs.checkin",
        },
        ["source"] = "dialogue/combat_wound_callouts/combat_injury_interactive_exchange.json",
    },
    ["combat.injury.visible_observation"] = {
        ["domain"] = "combat_wound_callouts",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/InjuryVisibleObservationToWoundReceivedBeat",
        },
        ["id"] = "combat.injury.visible_observation",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/combat_wound_callouts/combat_injury_visible_observation.json",
    },
    ["combat.wound.ally_reaction"] = {
        ["domain"] = "combat_wound_callouts",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/InjuryVisibleObservationToWoundReceivedBeat",
        },
        ["id"] = "combat.wound.ally_reaction",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/combat_wound_callouts/combat_wound_ally_reaction.json",
    },
    ["combat.wound.received_beat"] = {
        ["domain"] = "combat_wound_callouts",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/CombatWoundCallouts/InjuryVisibleObservationToWoundReceivedBeat",
        },
        ["id"] = "combat.wound.received_beat",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/combat_wound_callouts/combat_wound_received_beat.json",
    },
}
