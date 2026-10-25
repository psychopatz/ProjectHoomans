-- Full bounded actor context composition.

return function(Context, Core, Projections)
    function Context.Build(source)
        local context = type(source) == "table" and source or {}
        local relationship = Projections.relationship(context)
        local personalRelationship = type(context.personalRelationship) == "table"
            and Core.copy(context.personalRelationship)
            or Core.copy(relationship)
        local factionRelationship = type(context.factionRelationship) == "table"
            and Core.copy(context.factionRelationship)
            or nil
        local tacticalHostility = type(context.tacticalHostility) == "table"
            and Core.copy(context.tacticalHostility)
            or nil
        local conversationAudience = type(context.conversationAudience) == "table"
            and Core.copy(context.conversationAudience)
            or nil
        local personality = Projections.personality(context)
        local roles = Projections.roles(context)
        local situation = Projections.situation(context)
        local identity = Projections.identity(context)
        local traits = Core.sortedIDs(context.npcTraits, Context.MAX_TRAITS)
        local bond = Projections.bond(context)
        local interaction = Projections.interaction(context)
        return {
            schemaVersion = Context.VERSION,
            schema = Context.SCHEMA,
            actorID = Core.text(context.npcID or context.actorID),
            identity = identity,
            traits = traits,
            personality = personality,
            relationship = relationship,
            personalRelationship = personalRelationship,
            factionRelationship = factionRelationship,
            tacticalHostility = tacticalHostility,
            conversationAudience = conversationAudience,
            bond = bond,
            interactionLifecycle = interaction,
            roles = roles,
            situation = situation,
            revisions = Projections.revisions(
                context, relationship, personality, roles, situation
            ),
            provenance = {
                identity = context.identity and "identity_projection"
                    or "context.identityState",
                traits = context.npcTraits and "registered_npc_traits"
                    or "traits_unavailable",
                personality = context.npcPersonality and "social_profile_projection"
                    or "personality_unavailable",
                relationship = context.relationship and "directed_relationship",
                personalRelationship = personalRelationship
                    and personalRelationship.source or "MISSING",
                factionRelationship = factionRelationship
                    and factionRelationship.source,
                tacticalHostility = tacticalHostility
                    and tacticalHostility.owner,
                conversationAudience = conversationAudience
                    and conversationAudience.source,
                bond = bond and "starting_companion_relationship_kind"
                    or "bond_unavailable",
                roles = context.actorAuthority and "actor_authority",
                situation = context.dialogueSituation and "dialogue_situation"
                    or "actor_state_projection",
                interactionLifecycle = interaction
                    and "semantic_interaction_lifecycle"
                    or "interaction_lifecycle_unavailable",
            },
            privacy = {
                privateFieldsOmitted = {
                    "orientation", "romanceStyle", "jealousyStyle",
                },
                undiscoveredFactsExcluded = true,
                playerVisible = false,
            },
        }
    end
end
