-- Registered companion-command action contracts.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticCommandAdapter_Registry"
local Adapter = PNC.Semantics.CommandAdapter

-- This descriptor is the public, typed seam consumed by Semantic Lab. It
-- names the existing command registry and dispatcher; it does not contain a
-- callback or create a second execution path.
Adapter.RegisterAction("FOLLOW", {
    capabilityID = "pnc:companion.follow",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    commandID = "follow",
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "FOLLOW" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.follow",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            templateID = "semantic.command.follow.queued",
        },
        rejected = {
            templateID = "semantic.command.follow.rejected",
        },
        failed = {
            templateID = "semantic.command.follow.failed",
        },
    },
    arguments = {
        npcID = "actor_target",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_target",
    },
    result = {
        "requested",
        "rejected",
        "queued",
        "accepted",
        "completed",
    },
})
Adapter.RegisterAction("STAY", {
    capabilityID = "pnc:companion.stay",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    commandID = "stay",
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "STAY" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.stay",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            templateID = "semantic.command.stay.queued",
        },
        rejected = {
            templateID = "semantic.command.stay.rejected",
        },
        failed = {
            templateID = "semantic.command.stay.failed",
        },
    },
    arguments = {
        npcID = "actor_target",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_target",
    },
    result = {
        "requested",
        "rejected",
        "queued",
        "accepted",
        "completed",
    },
})
-- A direct stop is represented by the existing authoritative stay order. It
-- stops following at the current position without adding a second command
-- implementation.
Adapter.RegisterAction("STOP", {
    capabilityID = "pnc:companion.stop",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    commandID = "stay",
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "STOP" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.stop",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            templateID = "semantic.command.stop_following.queued",
        },
        rejected = {
            templateID = "semantic.command.stop_following.rejected",
        },
        failed = {
            templateID = "semantic.command.stop_following.failed",
        },
    },
    arguments = {
        npcID = "actor_target",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_target",
    },
    result = {
        "requested", "rejected", "queued", "accepted", "completed",
    },
})
Adapter.RegisterAction("GO", {
    capabilityID = "pnc:companion.go_home",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    destinations = {
        HOME = "return_home",
    },
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "GO" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
        destination = {
            type = "location",
            owner = "semantic_ir",
            source = "destination",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.go_home",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            templateID = "semantic.command.return_home.queued",
        },
        rejected = {
            templateID = "semantic.command.return_home.rejected",
        },
        failed = {
            templateID = "semantic.command.return_home.failed",
        },
    },
    arguments = {
        npcID = "actor_target",
        destination = "resolved_destination",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_destination",
    },
    result = {
        "requested", "rejected", "queued", "accepted", "completed",
    },
})
-- All CAMP scopes use the same authoritative command. Group admission still
-- batches nearby targets in the command registry, while a single recipient
-- receives the same durable camp order instead of entering a second semantic
-- action-plan path that can acknowledge without taking movement ownership.
Adapter.RegisterAction("CAMP", {
    capabilityID = "pnc:companion.camp",
    owner = "PNC.CompanionCommands",
    route = "existing_companion_command",
    workflowKind = "simple_command",
    templateVersion = 1,
    contractVersion = 1,
    commandID = "camp",
    handlerID = "PNC.Client.SendCompanionCommand",
    targetScope = "single_or_group",
    triggerFrames = {
        { intent = "REQUEST", speechAct = "REQUEST", action = "CAMP" },
    },
    requiredSlots = {
        npcID = {
            type = "entity",
            owner = "dialogue_context",
            source = "npcID",
        },
        target = {
            type = "location",
            owner = "semantic_ir",
            source = "target",
        },
    },
    permissionGate = {
        type = "pnc:semantic_context",
        capabilityID = "pnc:companion.camp",
        requiresTarget = true,
        requiresAuthority = true,
    },
    outcomeMapping = {
        queued = "queued",
        accepted = "queued",
        pending = "queued",
        network_queued = "queued",
        rejected = "rejected",
        failed = "failed",
    },
    responsePools = {
        queued = {
            templateID = "semantic.command.camp.queued",
        },
        rejected = {
            templateID = "semantic.command.camp.rejected",
        },
        failed = {
            templateID = "semantic.command.camp.failed",
        },
    },
    arguments = {
        npcID = "actor_target",
        target = "resolved_camp_site",
        scope = "single_or_group",
    },
    requires = {
        "conversation_or_companion_authority",
        "resolved_camp_site",
    },
    result = {
        "requested", "rejected", "queued", "accepted", "completed",
    },
})

local COMBAT_INTENT_RESPONSES = {
    combat_engage = {
        default = "semantic.combat.horde.ack.engage_default",
        variants = {
            {
                id = "eager",
                templateID = "semantic.combat.horde.ack.engage_eager",
                priority = 4,
                when = {
                    combatReactionStyle = { "aggressive", "brave" },
                },
            },
            {
                id = "hesitant",
                templateID = "semantic.combat.horde.ack.engage_hesitant",
                priority = 4,
                when = { combatReactionStyle = "shaken" },
            },
            {
                id = "reserved",
                templateID = "semantic.combat.horde.ack.engage_reserved",
                priority = 3,
                when = {
                    combatReactionStyle = { "reserved", "cold" },
                },
            },
        },
    },
    combat_avoid = {
        default = "semantic.combat.horde.ack.avoid_default",
        variants = {
            {
                id = "relief",
                templateID = "semantic.combat.horde.ack.avoid_relief",
                priority = 4,
                when = {
                    combatReactionStyle = { "shaken", "supportive" },
                },
            },
        },
    },
    combat_hold = {
        default = "semantic.combat.horde.ack.hold_default",
        variants = {
            {
                id = "eager",
                templateID = "semantic.combat.horde.ack.hold_eager",
                priority = 3,
                when = {
                    combatReactionStyle = { "aggressive", "brave" },
                },
            },
            {
                id = "hesitant",
                templateID = "semantic.combat.horde.ack.hold_hesitant",
                priority = 3,
                when = { combatReactionStyle = "shaken" },
            },
        },
    },
}

local function registerCombatIntentAction(action, commandID)
    local responses = COMBAT_INTENT_RESPONSES[commandID] or {}
    Adapter.RegisterAction(action, {
        capabilityID = "pnc:companion." .. string.lower(action),
        owner = "PNC.CompanionCommands",
        route = "existing_companion_command",
        workflowKind = "simple_command",
        templateVersion = 1,
        contractVersion = 1,
        commandID = commandID,
        handlerID = "PNC.Client.SendCompanionCommand",
        targetScope = "single",
        triggerFrames = {
            { intent = "REQUEST", speechAct = "REQUEST", action = action },
        },
        requiredSlots = {
            npcID = {
                type = "entity",
                owner = "dialogue_context",
                source = "npcID",
            },
        },
        permissionGate = {
            type = "pnc:semantic_context",
            capabilityID = "pnc:companion." .. string.lower(action),
            requiresTarget = true,
            requiresAuthority = true,
        },
        outcomeMapping = {
            queued = "queued",
            accepted = "queued",
            pending = "queued",
            network_queued = "queued",
            rejected = "rejected",
            failed = "failed",
        },
        responsePools = {
            queued = {
                templateID = responses.default
                    or "semantic.command.reply.generic_rejected",
                variants = responses.variants,
            },
            rejected = {
                templateID = "semantic.command.reply.generic_rejected",
            },
            failed = {
                templateID = "semantic.command.reply.generic_rejected",
            },
        },
        arguments = {
            npcID = "actor_target",
            encounterEpisodeID = "semantic_modifier",
        },
        requires = {
            "conversation_or_companion_authority",
            "active_combat_encounter",
        },
        result = {
            "requested", "rejected", "queued", "accepted", "completed",
        },
    })
end

registerCombatIntentAction("COMBAT_ENGAGE", "combat_engage")
registerCombatIntentAction("COMBAT_AVOID", "combat_avoid")
registerCombatIntentAction("COMBAT_HOLD", "combat_hold")

return Adapter
