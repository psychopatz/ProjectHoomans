-- Actor relationship, role, situation, and interaction projections.

return function(Core, Context, RelationshipConstants, RelationshipStates, RelationshipKinds)
    local Projections = {}

    function Projections.personality(context)
        local source = Core.personalitySource(context)
        local output = {}
        for index = 1, #Core.PERSONALITY_FIELDS do
            local field = Core.PERSONALITY_FIELDS[index]
            local value = source[field]
            if field == "socialStyle" then
                value = type(value) == "string" and value or nil
            else value = Core.boundedNumber(value, 0, 1) end
            if value ~= nil then output[field] = value end
        end
        output.revision = math.max(0, math.floor(Core.finite(source.revision) or 0))
        output.generationVersion = math.max(
            0, math.floor(Core.finite(source.generationVersion) or 0)
        )
        return output
    end

    function Projections.relationship(context)
        local source = type(context.relationship) == "table"
            and context.relationship or {}
        local approval = Core.boundedNumber(source.approval, -100, 100)
        local respect = Core.boundedNumber(source.respect, -100, 100)
        local familiarity = Core.boundedNumber(source.familiarity, 0, 100)
        local current = source.state or source.relationshipState
            or context.relationshipState
        local state = RelationshipConstants.STATE_UNKNOWN
        if RelationshipStates
            and type(RelationshipStates.ResolveState) == "function"
        then
            state = RelationshipStates.ResolveState({
                approval = approval,
                respect = respect,
                familiarity = familiarity,
                state = current,
            })
        elseif current ~= nil then
            state = Core.text(current, RelationshipConstants.STATE_UNKNOWN)
        end
        return {
            approval = approval,
            respect = respect,
            familiarity = familiarity,
            state = state,
            identityTrust = Core.text(source.identityTrust or context.identityTrust),
            revision = math.max(0, math.floor(Core.finite(source.revision) or 0)),
        }
    end

    local function startingRelationshipSource(context)
        local direct = Core.sourceValue(context, "startingRelationship")
        if type(direct) == "table" then return direct end
        local state = type(context) == "table" and context.npcState or nil
        if type(state) == "table" then
            if type(state.startingRelationship) == "table" then
                return state.startingRelationship
            end
            if type(state.generation) == "table" then
                return state.generation
            end
        end
        local record = type(context) == "table" and context.npcRecord or nil
        if type(record) == "table" then
            if type(record.startingRelationship) == "table" then
                return record.startingRelationship
            end
            if type(record.generation) == "table" then
                return record.generation
            end
        end
        return nil
    end

    function Projections.bond(context)
        local relationship = type(context.relationship) == "table"
            and context.relationship or {}
        local durable = type(relationship.bond) == "table"
            and relationship.bond or nil
        if durable and durable.class and durable.class ~= "none" then
            local durableKind = durable.kind or durable.class
            local durableDefinition = RelationshipKinds
                and RelationshipKinds.GetDefinition(durableKind) or nil
            return {
                class = durable.class,
                kind = durable.kind,
                establishedAt = durable.establishedAt,
                source = Core.text(durable.source, "relationship_record"),
                term = durableDefinition and {
                    referenceKey = durableDefinition.termKeys.reference,
                    addressKey = durableDefinition.termKeys.address,
                } or nil,
            }
        end
        local source = startingRelationshipSource(context)
        if type(source) ~= "table" then return nil end
        local kind = source.kind or source.relationshipKind
        local definition = RelationshipKinds
            and RelationshipKinds.GetDefinition(kind) or nil
        if not definition then return nil end
        return {
            class = definition.class,
            kind = definition.kind,
            source = Core.text(source.source, "starting_companion_trait"),
            term = {
                referenceKey = definition.termKeys.reference,
                addressKey = definition.termKeys.address,
            },
        }
    end

    function Projections.roles(context)
        local authority = type(context.actorAuthority) == "table"
            and context.actorAuthority or {}
        local role = context.role
        if role == nil and type(context.npcState) == "table" then
            role = context.npcState.role
        end
        if role == nil and type(context.npcRecord) == "table" then
            role = context.npcRecord.role
        end
        role = type(role) == "string" and role or nil
        local hostile = context.hostile == true
        local hostility = Core.sourceValue(context, "hostility")
        if type(hostility) == "table" and hostility.attackPlayers == true then
            hostile = true
        end
        local capabilities = Core.sortedIDs(
            context.capabilities or context.npcCapabilities,
            Context.MAX_CAPABILITIES
        )
        local hasCapability = {}
        for index = 1, #capabilities do hasCapability[capabilities[index]] = true end
        return {
            role = role,
            capabilities = capabilities,
            companion = authority.companion == true,
            owned = authority.owned == true,
            authorityEligible = authority.eligible == true,
            authorityStatus = Core.text(authority.status, "authority_unknown"),
            hostile = hostile,
            trader = role == "trader" or hasCapability.trader == true
                or hasCapability.trade == true,
        }
    end

    function Projections.situation(context)
        local situation = type(context.dialogueSituation) == "table"
            and context.dialogueSituation or {}
        local npc = type(situation.npc) == "table" and situation.npc or {}
        local state = type(context.semanticDialogueState) == "table"
            and context.semanticDialogueState or {}
        local needs = type(npc.needs) == "table" and npc.needs
            or Core.sourceValue(context, "needs")
        local activity = type(npc.activity) == "table" and npc.activity or nil
        return {
            healthState = Core.text(npc.healthState
                or Core.sourceValue(context, "healthState")),
            activeBehavior = Core.text(Core.sourceValue(context, "activeBehavior")),
            activity = Core.copy(activity),
            needs = Core.copy(needs),
            emotion = Core.copy(npc.emotion),
            inCombat = npc.inCombat == true or context.inCombat == true,
            currentTopic = Core.text(
                state.currentTopic or context.currentTopic
                    or context.conversationTopic
            ),
            previousTopic = Core.text(state.previousTopic or context.previousTopic),
            worldRevision = math.max(
                0, math.floor(Core.finite(context.worldRevision) or 0)
            ),
        }
    end

    function Projections.identity(context)
        local source = Core.identitySource(context)
        local gender = source.gender or source.sex
        if gender == nil and source.isFemale ~= nil then
            gender = source.isFemale == true and "female" or "male"
        end
        return {
            state = Core.text(context.identityState or source.identityState, "unknown"),
            gender = type(gender) == "string" and string.lower(gender) or nil,
            isFemale = type(source.isFemale) == "boolean"
                and source.isFemale or nil,
            source = Core.text(source.identitySource or source.source),
        }
    end

    function Projections.interaction(context)
        local source = type(context.interactionLifecycle) == "table"
            and context.interactionLifecycle or nil
        if not source then return nil end
        local beat = type(source.activeBeat) == "table"
            and source.activeBeat or nil
        return {
            status = Core.text(source.status, "ACTIVE"),
            topic = Core.text(source.topic),
            activeBeat = beat and Core.copy(beat) or nil,
            openQuestions = Core.copy(source.openQuestions or {}),
            commitments = Core.copy(source.openCommitments or source.commitments or {}),
            topicStack = Core.copy(source.topicStack or {}),
        }
    end

    function Projections.revisions(context, relationship, personality, roles, situation)
        local fingerprint = context.npcTraitFingerprint
        if fingerprint == nil and type(context.npcRecord) == "table" then
            fingerprint = context.npcRecord.npcTraitFingerprint
        end
        return {
            context = math.max(0, math.floor(Core.finite(
                context.contextRevision or context.revision
            ) or 0)),
            relationship = relationship.revision,
            personality = personality.revision,
            traits = Core.text(fingerprint, ""),
            roles = Core.text(roles.authorityStatus, "authority_unknown"),
            situation = situation.worldRevision,
        }
    end

    return Projections
end
