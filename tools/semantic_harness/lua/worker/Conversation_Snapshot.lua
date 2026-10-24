-- Relationship and inspector context snapshots.

local Snapshot = {}
local SpeechStyleContext = require
    "PNC/Semantics/PNC_SpeechStyleContext"

function Snapshot.relationship(context)
    local scenario = context.Runtime.scenario or {}
    local npc = scenario.npc or {}
    return context.SemanticAdapters.relationshipSnapshotFor(context, npc.npcID)
end

function Snapshot.context(harnessContext, view)
    local Values = harnessContext.Values
    local session = view and view.session
    local dialogueContext = session and session.semanticDialogueContext
    local semanticState = session and session.semanticDialogueState
    local null = harnessContext.Protocol.NULL
    local worldContext = PNC.Semantics.WorldContext
        and PNC.Semantics.WorldContext.Get
        and PNC.Semantics.WorldContext.Get({ player = harnessContext.player })
        or nil
    local npcID = view and view.spec and view.spec.npcID
    local knowledge = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.npcKnowledge
        and PNC.Network.ClientState.npcKnowledge[tostring(npcID or "")]
        or nil
    local memory = PNC.Conversation and PNC.Conversation.Memory
    local pbrainzFacts
    local npcRecord = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if type(knowledge) == "table"
        and type(memory) == "table"
        and type(memory.BuildAuthorizedBackstoryFacts) == "function"
    then
        local ok, facts = pcall(
            memory.BuildAuthorizedBackstoryFacts,
            npcRecord,
            knowledge,
            10,
            harnessContext.Translations.scenarioLanguage(harnessContext)
        )
        if ok and type(facts) == "table" then pbrainzFacts = facts end
    end
    local engineFacts = {}
    local factCatalog = harnessContext.EngineFacts
        and harnessContext.EngineFacts.List
        and harnessContext.EngineFacts.List() or {}
    local factIndex
    for factIndex = 1, #factCatalog do
        local factID = factCatalog[factIndex].id
        local record = harnessContext.EngineFacts.Resolve(factID, {
            worldContext = worldContext,
            semanticFactValues = harnessContext.semanticFactValues,
            engineFacts = harnessContext.engineFacts,
            player = harnessContext.player,
        })
        engineFacts[factID] = Values.copy(record)
    end
    local speechStyle = SpeechStyleContext.Resolve(
        view and view.spec and view.spec.context or {}
    )
    local actorContext = Values.copy(
        view and view.spec and view.spec.context
            and view.spec.context.actorConversationContext
    ) or {}
    local socialContext = {
        schema = "semantic.social.context.v1",
        personalRelationship = Values.copy(
            actorContext.personalRelationship or actorContext.relationship
        ),
        factionRelationship = Values.copy(actorContext.factionRelationship)
            or {
                status = "absent",
                source = "MISSING",
                reason = "no production faction/community registry",
                missingClass = "LEGITIMATE_ABSENCE",
            },
        tacticalHostility = Values.copy(actorContext.tacticalHostility),
        conversationAudience = Values.copy(
            actorContext.conversationAudience
        ),
        durableBond = Values.copy(actorContext.bond) or {
            status = "absent",
            class = "none",
            source = "MISSING",
            reason = "no persisted durable bond",
            missingClass = "LEGITIMATE_ABSENCE",
        },
        speechStyle = Values.copy(speechStyle),
        provenance = {
            personalRelationship = actorContext.provenance
                and actorContext.provenance.relationship,
            factionRelationship = actorContext.factionRelationship
                and actorContext.factionRelationship.source,
            tacticalHostility = actorContext.tacticalHostility
                and actorContext.tacticalHostility.owner,
            conversationAudience = actorContext.conversationAudience
                and actorContext.conversationAudience.source,
            durableBond = actorContext.provenance
                and actorContext.provenance.bond,
            speechStyle = speechStyle.provenance,
        },
    }
    return {
        -- This is the filtered player-character projection, suitable for the
        -- Inspector and Dossier preview. It is never reconstructed from the
        -- NPC record or the identity-seeded backstory generator.
        knowledge = Values.copy(knowledge),
        dossier = Values.copy(knowledge),
        pbrainz = {
            enabled = harnessContext.runtime.llmEnabled == true,
            providerAvailable = harnessContext.runtime.providerAvailable == true,
            disclosureFiltered = true,
            backstoryFacts = Values.copy(pbrainzFacts),
        },
        dialogue = dialogueContext and dialogueContext.ToContext
            and dialogueContext:ToContext() or null,
        state = semanticState and semanticState.Snapshot
            and semanticState:Snapshot() or null,
        engineFacts = engineFacts,
        engineEvents = harnessContext.EngineEvents
            and harnessContext.EngineEvents.Recent
            and Values.copy(harnessContext.EngineEvents.Recent()) or {},
        categoryDiagnostics = Values.copy(
            view and view.spec and view.spec.context
                and view.spec.context.categoryDiagnostics
        ),
        conversationRoot = Values.copy(
            view and view.spec and view.spec.context
                and view.spec.context.conversationRoot
        ),
        conversationBlock = Values.copy(
            view and view.spec and view.spec.context
                and view.spec.context.conversationBlock
        ),
        actorConversationContext = actorContext,
        speechStyleContext = speechStyle,
        socialContext = socialContext,
    }
end

return Snapshot

