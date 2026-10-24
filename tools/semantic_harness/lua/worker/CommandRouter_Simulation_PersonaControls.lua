-- Persona and relationship-input controls for the Semantic Lab.

local PersonaControls = {}

local function withNone(values)
    local result = { "none" }
    for index = 1, math.min(#(values or {}), 64) do
        if values[index] ~= "none" then
            result[#result + 1] = values[index]
        end
    end
    return result
end

function PersonaControls.append(add, context, persona, traits, bondKinds)
    add("relationship.identityTrust", "npc.relationship.identityTrust", "Persona", "Relationship", "Identity trust", "combobox", "enum", {
        options = { "unknown", "trusted", "untrustworthy" },
        optionsSource = "semantic_lab.harness",
    })
    add("persona.bondKind", "npc.startingRelationship.kind", "Persona", "Relationship", "Bond kind", "combobox", "enum", {
        options = withNone(bondKinds),
        optionsSource = "PNC.RelationshipKinds",
        noneValue = "none",
        clearPath = "npc.startingRelationship",
        advanced = true,
    })
    add("persona.traits", "npc.traits", "Persona", "Traits", "Registered traits", "multi_select", "array", {
        options = traits,
        optionsSource = "PNC.NPCTraits",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
        workbenchSection = "Registered traits",
    })
    add("npc.personalityOverride", "npc.personalityOverride", "Persona", "Personality", "Override generated personality", "boolean", "boolean", {
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
        workbenchSection = "Personality source",
    })
    add("npc.personalityMode", nil, "Persona", "Personality", "Personality mode", "read_only", "text", {
        currentValue = context.npcPersonalityMode or "generated",
        source = "production.social_profile_generator",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
        workbenchSection = "Personality source",
    })
    add("persona.socialStyle", "npc.personality.socialStyle", "Persona", "Personality", "Social style", "combobox", "enum", {
        options = persona.personality.enums.socialStyle,
        optionsSource = "PNC.SocialProfileConstants.VALID_SOCIAL_STYLES",
        currentValue = context.npcPersonality and context.npcPersonality.socialStyle,
        requiresOverride = "npc.personalityOverride",
        workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
        workbenchSection = "Generated personality",
    })
end

return PersonaControls

