-- Privacy-bounded public actor context view.

return function(Context, Core)
    function Context.PublicView(value)
        value = type(value) == "table" and value or {}
        local identity = type(value.identity) == "table" and value.identity or {}
        local roles = type(value.roles) == "table" and value.roles or {}
        local situation = type(value.situation) == "table" and value.situation or {}
        local bond = type(value.bond) == "table" and value.bond or nil
        local personalRelationship = type(value.personalRelationship) == "table"
            and value.personalRelationship or value.relationship
        local factionRelationship = type(value.factionRelationship) == "table"
            and value.factionRelationship or nil
        local tacticalHostility = type(value.tacticalHostility) == "table"
            and value.tacticalHostility or nil
        local conversationAudience = type(value.conversationAudience) == "table"
            and value.conversationAudience or nil
        local interaction = type(value.interactionLifecycle) == "table"
            and value.interactionLifecycle or nil
        return {
            schemaVersion = value.schemaVersion,
            actorID = value.actorID,
            identity = { state = identity.state },
            personalRelationship = Core.copy(personalRelationship),
            factionRelationship = Core.copy(factionRelationship),
            tacticalHostility = Core.copy(tacticalHostility),
            conversationAudience = Core.copy(conversationAudience),
            roles = {
                role = roles.role,
                companion = roles.companion == true,
                owned = roles.owned == true,
                authorityEligible = roles.authorityEligible == true,
                hostile = roles.hostile == true,
                trader = roles.trader == true,
            },
            bond = bond and {
                class = bond.class,
                kind = bond.kind,
            } or nil,
            situation = {
                healthState = situation.healthState,
                activeBehavior = situation.activeBehavior,
                currentTopic = situation.currentTopic,
                inCombat = situation.inCombat == true,
            },
            interactionLifecycle = interaction and {
                status = interaction.status,
                topic = interaction.topic,
                activeBeat = Core.copy(interaction.activeBeat),
                openQuestions = Core.copy(interaction.openQuestions),
                commitments = Core.copy(interaction.commitments),
                topicStack = Core.copy(interaction.topicStack),
            } or nil,
            revisions = Core.copy(value.revisions),
            privacy = {
                privateFieldsOmitted = true,
                undiscoveredFactsExcluded = true,
                playerVisible = true,
            },
        }
    end
end
