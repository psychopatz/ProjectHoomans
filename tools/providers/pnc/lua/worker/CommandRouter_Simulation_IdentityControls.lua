-- Player and NPC identity controls for the Semantic Lab.

local IdentityControls = {}

function IdentityControls.append(add, context, persona, roles, traits, playerTraitOptions)
    add("player.characterUUID", "player.characterUUID", "Actors", "Player", "Player ID", "text", "text", {
        derivedFrom = { "player.forename", "player.surname" },
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview", workbenchVisible = false, settingsVisible = false,
    })
    add("player.forename", "player.forename", "Actors", "Player", "Player first name", "text", "text", {
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("player.surname", "player.surname", "Actors", "Player", "Player surname", "text", "text", {
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("player.displayName", "player.displayName", "Actors", "Player", "Player display name", "text", "text", {
        derivedFrom = { "player.forename", "player.surname" },
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview", workbenchVisible = false, settingsVisible = false,
    })
    add("player.gender", "player.gender", "Actors", "Player", "Gender", "combobox", "enum", {
        options = persona.identity.genders,
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "Player", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("player.traits", "player.traits", "Actors", "Player", "Registered player traits", "multi_select", "array", {
        options = playerTraitOptions,
        optionsSource = "PsychopatzCore.Traits / PNC.SocialTraits",
        workbench = true, workbenchPanel = "Player", workbenchTab = "Personality & Traits",
        workbenchSection = "Traits",
    })
    for _, key in ipairs({ "orientation", "romanceStyle", "jealousyStyle", "socialStyle", "foodPreference" }) do
        add("player.socialProfile." .. key, nil, "Actors", "Player", key, "read_only", "text", {
            currentValue = context.playerSocialProfile
                and context.playerSocialProfile[key] or "unknown",
            source = "production.player_social_profile",
            workbench = true, workbenchPanel = "Player",
            workbenchTab = "Personality & Traits", workbenchSection = "Derived social profile",
        })
    end
    add("npc.identitySeed", "npc.identitySeed", "Actors", "NPC", "Identity seed", "text", "text", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.archetype", "npc.archetype", "Actors", "NPC", "Archetype", "combobox", "enum", {
        options = persona.archetypes,
        optionsSource = "PNC.SocialProfileConstants.ARCHETYPE_MODIFIERS",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.npcID", "npc.npcID", "Actors", "NPC", "NPC ID", "text", "text", {
        derivedFrom = { "npc.forename", "npc.surname" },
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview", workbenchVisible = false, settingsVisible = false,
    })
    add("npc.forename", "npc.forename", "Actors", "NPC", "First name", "text", "text", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.surname", "npc.surname", "Actors", "NPC", "Surname", "text", "text", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.identityState", "npc.identityState", "Actors", "NPC", "Identity state", "text", "text", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.gender", "npc.gender", "Actors", "NPC", "Gender", "combobox", "enum", {
        options = persona.identity.genders,
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Overview",
    })
    add("npc.role", "npc.role", "Actors", "NPC", "Role / capability", "combobox", "enum", {
        options = roles,
        optionsSource = "PNC.FactionConstants.ROLES",
        noneValue = "none",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("npc.health.state", "npc.health.state", "Actors", "NPC", "Health state", "combobox", "enum", {
        options = { "normal", "incapacitated", "dead" },
        optionsSource = "PNC.Health",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Health",
    })
    add("npc.health.current", "npc.health.current", "Actors", "NPC", "Current HP", "spinbox", "integer", {
        min = 0, max = 1000, step = 1,
        optionsSource = "PNC.Health",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Health",
    })
    add("npc.health.max", "npc.health.max", "Actors", "NPC", "Maximum HP", "spinbox", "integer", {
        min = 1, max = 1000, step = 1,
        optionsSource = "PNC.Health",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Health",
    })
    add("npc.health.body.overallPercent", "npc.health.body.overallPercent", "Actors", "NPC", "Body health %", "slider", "number", {
        min = 0, max = 100, step = 1, format = "%.0f",
        optionsSource = "PNC.NPCWounds.BuildSnapshot",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Health",
    })
    add("npc.health.body.openWoundCount", "npc.health.body.openWoundCount", "Actors", "NPC", "Open wounds", "integer", "integer", {
        min = 0, max = 64, step = 1,
        optionsSource = "PNC.NPCWounds.BuildSnapshot",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Health",
    })
    add("npc.health.body.bandagedWoundCount", "npc.health.body.bandagedWoundCount", "Actors", "NPC", "Bandaged wounds", "integer", "integer", {
        min = 0, max = 64, step = 1,
        optionsSource = "PNC.NPCWounds.BuildSnapshot",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Health",
    })
    add("npc.health.body.bleedingRate", "npc.health.body.bleedingRate", "Actors", "NPC", "Bleeding rate", "spinbox", "number", {
        min = 0, max = 100, step = 0.1, format = "%.1f",
        optionsSource = "PNC.NPCWounds.BuildSnapshot",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Health",
    })
    add("npc.health.body.infected", "npc.health.body.infected", "Actors", "NPC", "Active infection", "boolean", "boolean", {
        optionsSource = "PNC.NPCWounds.BuildSnapshot",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Health",
    })
    add("npc.activeBehavior", "npc.activeBehavior", "Actors", "NPC", "Activity", "combobox", "enum", {
        options = { "idle", "following", "staying", "busy", "searching", "fleeing", "hostile", "combat" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
end

return IdentityControls

