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
            key = "UI_PNC_Conversation_Semantic_GeneratedFollowQueued",
            en = "Okay, I'll follow you.",
            tl = "Sige, susundan kita.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedFollowRejected",
            en = "I can't follow you right now.",
            tl = "Hindi kita masusundan ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedFollowFailed",
            en = "I couldn't start following you.",
            tl = "Hindi ko masimulan ang pagsunod sa iyo.",
        },
    },
    translationOwner = "ProjectHoomans",
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
            key = "UI_PNC_Conversation_Semantic_GeneratedStayQueued",
            en = "Okay, I'll stay here.",
            tl = "Sige, mananatili ako rito.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStayRejected",
            en = "I can't stay here right now.",
            tl = "Hindi ako makapananatili rito ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStayFailed",
            en = "I couldn't start the stay order.",
            tl = "Hindi ko masimulan ang utos na manatili.",
        },
    },
    translationOwner = "ProjectHoomans",
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
            key = "UI_PNC_Conversation_Semantic_GeneratedStopQueued",
            en = "Okay, I'll stop following.",
            tl = "Sige, titigil ako sa pagsunod.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStopRejected",
            en = "I can't stop following right now.",
            tl = "Hindi ako makapaghinto sa pagsunod ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedStopFailed",
            en = "I couldn't stop following.",
            tl = "Hindi ako nakahinto sa pagsunod.",
        },
    },
    translationOwner = "ProjectHoomans",
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
            key = "UI_PNC_Conversation_Semantic_GeneratedGoQueued",
            en = "Okay, I'll head home.",
            tl = "Sige, uuwi ako.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGoRejected",
            en = "I can't head home right now.",
            tl = "Hindi ako makauuwi ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGoFailed",
            en = "I couldn't head home.",
            tl = "Hindi ako nakauwi.",
        },
    },
    translationOwner = "ProjectHoomans",
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
            key = "UI_PNC_Conversation_Semantic_GeneratedCampQueued",
            en = "Okay, I'll set up camp there.",
            tl = "Sige, magse-set up ako ng kampo roon.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedCampRejected",
            en = "I can't set up camp there right now.",
            tl = "Hindi ako makapag-set up ng kampo roon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedCampFailed",
            en = "I couldn't set up camp there.",
            tl = "Hindi ako nakapag-set up ng kampo roon.",
        },
    },
    translationOwner = "ProjectHoomans",
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

return Adapter
