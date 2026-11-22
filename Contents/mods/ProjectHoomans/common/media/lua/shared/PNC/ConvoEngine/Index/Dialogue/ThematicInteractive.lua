-- Generated Conversation discovery index; do not edit by hand.
return {
    ["colony.work.status_exchange"] = {
        ["dependents"] = {
            "combat.aftermath.debrief_exchange",
            "knowledge.gossip.exchange",
            "social.conflict.mediate_exchange",
            "social.identity.personal_history",
            "travel.excursion.plan_exchange",
            "wellbeing.needs.checkin",
        },
        ["domain"] = "thematic_interactive",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ThematicInteractive/ColonyWorkStatusExchangeToCombatAftermathDebriefExchange",
        },
        ["id"] = "colony.work.status_exchange",
        ["kind"] = "dialogue",
        ["related"] = {
            "knowledge.gossip.exchange",
            "social.conflict.mediate_exchange",
            "wellbeing.needs.checkin",
        },
        ["source"] = "dialogue/thematic_interactive/colony_work_exchange.json",
    },
    ["combat.aftermath.debrief_exchange"] = {
        ["dependents"] = {
            "knowledge.gossip.exchange",
            "travel.excursion.plan_exchange",
        },
        ["domain"] = "thematic_interactive",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ThematicInteractive/ColonyWorkStatusExchangeToCombatAftermathDebriefExchange",
        },
        ["id"] = "combat.aftermath.debrief_exchange",
        ["kind"] = "dialogue",
        ["related"] = {
            "colony.work.status_exchange",
            "travel.excursion.plan_exchange",
            "wellbeing.needs.checkin",
        },
        ["source"] = "dialogue/thematic_interactive/combat_aftermath_exchange.json",
    },
    ["knowledge.gossip.exchange"] = {
        ["dependents"] = {
            "colony.work.status_exchange",
            "social.greeting.first_contact",
            "social.identity.personal_history",
            "travel.excursion.plan_exchange",
            "wellbeing.needs.checkin",
        },
        ["domain"] = "thematic_interactive",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ThematicInteractive/KnowledgeGossipExchangeToSocialConflictMediateExchange",
        },
        ["id"] = "knowledge.gossip.exchange",
        ["kind"] = "dialogue",
        ["related"] = {
            "colony.work.status_exchange",
            "combat.aftermath.debrief_exchange",
            "social.conflict.mediate_exchange",
            "social.identity.personal_history",
            "travel.excursion.plan_exchange",
        },
        ["source"] = "dialogue/thematic_interactive/knowledge_gossip_exchange.json",
    },
    ["social.conflict.mediate_exchange"] = {
        ["dependents"] = {
            "colony.work.status_exchange",
            "knowledge.gossip.exchange",
        },
        ["domain"] = "thematic_interactive",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ThematicInteractive/KnowledgeGossipExchangeToSocialConflictMediateExchange",
        },
        ["id"] = "social.conflict.mediate_exchange",
        ["kind"] = "dialogue",
        ["related"] = {
            "colony.work.status_exchange",
            "wellbeing.needs.checkin",
        },
        ["source"] = "dialogue/thematic_interactive/relationship_conflict_exchange.json",
    },
    ["social.greeting.first_contact"] = {
        ["domain"] = "thematic_interactive",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ThematicInteractive/GreetingFirstContactToIdentityPersonalHistory",
        },
        ["id"] = "social.greeting.first_contact",
        ["kind"] = "dialogue",
        ["related"] = {
            "greeting",
            "knowledge.gossip.exchange",
            "social.identity.personal_history",
        },
        ["source"] = "dialogue/thematic_interactive/social_greeting_first_contact.json",
    },
    ["social.identity.personal_history"] = {
        ["dependents"] = {
            "knowledge.gossip.exchange",
            "social.greeting.first_contact",
        },
        ["domain"] = "thematic_interactive",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ThematicInteractive/GreetingFirstContactToIdentityPersonalHistory",
        },
        ["id"] = "social.identity.personal_history",
        ["kind"] = "dialogue",
        ["related"] = {
            "colony.work.status_exchange",
            "knowledge.gossip.exchange",
            "wellbeing.needs.checkin",
        },
        ["source"] = "dialogue/thematic_interactive/identity_history_exchange.json",
    },
    ["travel.excursion.plan_exchange"] = {
        ["dependents"] = {
            "combat.aftermath.debrief_exchange",
            "knowledge.gossip.exchange",
            "wellbeing.needs.checkin",
        },
        ["domain"] = "thematic_interactive",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ThematicInteractive/TravelExcursionPlanExchangeToWellbeingNeedsCheckin",
        },
        ["id"] = "travel.excursion.plan_exchange",
        ["kind"] = "dialogue",
        ["related"] = {
            "colony.work.status_exchange",
            "combat.aftermath.debrief_exchange",
            "knowledge.gossip.exchange",
            "wellbeing.needs.checkin",
        },
        ["source"] = "dialogue/thematic_interactive/travel_excursion_exchange.json",
    },
    ["wellbeing.needs.checkin"] = {
        ["dependents"] = {
            "colony.work.status_exchange",
            "combat.aftermath.debrief_exchange",
            "social.conflict.mediate_exchange",
            "social.identity.personal_history",
            "travel.excursion.plan_exchange",
        },
        ["domain"] = "thematic_interactive",
        ["generated"] = {
            "PNC/ConvoEngine/Dialogue/ThematicInteractive/TravelExcursionPlanExchangeToWellbeingNeedsCheckin",
        },
        ["id"] = "wellbeing.needs.checkin",
        ["kind"] = "dialogue",
        ["related"] = {
            "colony.work.status_exchange",
            "knowledge.gossip.exchange",
            "travel.excursion.plan_exchange",
        },
        ["source"] = "dialogue/thematic_interactive/wellbeing_needs_checkin.json",
    },
}
