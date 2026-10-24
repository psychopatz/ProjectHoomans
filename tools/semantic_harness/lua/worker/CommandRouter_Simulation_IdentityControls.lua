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
    add("npc.healthState", "npc.healthState", "Actors", "NPC", "Health", "combobox", "enum", {
        options = { "unknown", "healthy", "injured", "wounded", "critical", "dead" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("npc.activeBehavior", "npc.activeBehavior", "Actors", "NPC", "Activity", "combobox", "enum", {
        options = { "idle", "following", "staying", "busy", "searching", "fleeing", "hostile", "combat" },
        optionsSource = "semantic_lab.harness",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
end

return IdentityControls

