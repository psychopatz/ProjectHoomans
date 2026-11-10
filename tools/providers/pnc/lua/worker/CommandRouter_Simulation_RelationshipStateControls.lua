-- Derived relationship and proposal controls for the Semantic Lab.

local RelationshipStateControls = {}

function RelationshipStateControls.append(add, context, persona)
    add("relationship.approval", "npc.relationship.approval", "Persona", "Relationship", "Approval", "slider", "number", {
        min = -100, max = 100, step = 0.01, format = "%.2f",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("relationship.respect", "npc.relationship.respect", "Persona", "Relationship", "Respect", "slider", "number", {
        min = -100, max = 100, step = 0.01, format = "%.2f",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    add("relationship.familiarity", "npc.relationship.familiarity", "Persona", "Relationship", "Familiarity", "slider", "number", {
        min = 0, max = 100, step = 0.01, format = "%.2f",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    for _, key in ipairs(persona.personality.dimensions or {}) do
        add("persona.personality." .. key, "npc.personality." .. key, "Persona", "Personality", key, "slider", "number", {
            min = 0, max = 1, step = 0.05, format = "%.2f",
            optionsSource = "PNC.SocialProfileConstants.NUMERIC_DIMENSIONS",
            currentValue = context.npcPersonality and context.npcPersonality[key],
            requiresOverride = "npc.personalityOverride",
            workbench = true, workbenchPanel = "NPC Target", workbenchTab = "Personality & Traits",
            workbenchSection = "Generated personality",
        })
    end
    for _, key in ipairs({ "companion", "owned", "eligible" }) do
        add("persona.authority." .. key, "npc.actorAuthority." .. key, "Persona", "Authority", key, "boolean", "boolean")
    end
    add("relationship.state", nil, "Persona", "Relationship", "Derived relationship state", "read_only", "text", {
        source = "production.relationship.state",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    local durableBond = context.npcData and context.npcData.relationship
        and context.npcData.relationship.bond or nil
    local durableBondLabel = durableBond
        and (durableBond.kind or durableBond.class) or "none"
    local proposal = context.ScenarioSession
        and context.ScenarioSession.relationshipProposalProjection
        and context.ScenarioSession.relationshipProposalProjection(context)
        or {}
    add("relationship.bond", nil, "Persona", "Relationship", "Durable bond", "read_only", "text", {
        currentValue = durableBondLabel,
        source = "production.relationship.bond",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Context",
    })
    local approval = context.npcData and context.npcData.relationship
        and context.npcData.relationship.approval or 0
    local respect = context.npcData and context.npcData.relationship
        and context.npcData.relationship.respect or 0
    local familiarity = context.npcData and context.npcData.relationship
        and context.npcData.relationship.familiarity or 0
    add("relationship.friendBondProgress", nil, "Persona", "Relationship", "Friend bond progress", "read_only", "text", {
        currentValue = string.format(
            "Approval %s / 80 · Respect %s / 50 · Familiarity %s / 60",
            tostring(approval), tostring(respect), tostring(familiarity)
        ),
        source = "PNC.RelationshipConstants",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Friend bond",
    })
    add("relationship.romanceCompatibility", nil, "Persona", "Relationship", "Romance compatibility", "read_only", "text", {
        currentValue = proposal.compatible == true and "compatible" or "incompatible",
        source = "production.social_profile_math",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Romance proposal",
    })
    add("relationship.proposalThreshold", nil, "Persona", "Relationship", "Proposal threshold", "read_only", "text", {
        currentValue = "Approval 85 · Respect 60 · Familiarity 80",
        source = "PNC.RelationshipConstants",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Romance proposal",
    })
    add("relationship.proposalCooldown", nil, "Persona", "Relationship", "Proposal cooldown", "read_only", "text", {
        currentValue = proposal.cooldownRemaining or 0,
        source = "production.relationship.bond",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Romance proposal",
    })
    add("relationship.proposalAvailable", nil, "Persona", "Relationship", "Proposal available", "read_only", "text", {
        currentValue = proposal.eligible == true and "yes" or "no",
        source = "production.relationship.proposal_policy",
        workbench = true, workbenchPanel = "Relationship", workbenchTab = "Overview",
        workbenchSection = "Romance proposal",
    })
end

return RelationshipStateControls

