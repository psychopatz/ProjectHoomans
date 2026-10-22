-- Per-turn semantic context, view construction, and turn execution.

local Conversation = {}
local ActorConversationContext = require
    "PNC/Semantics/PNC_ActorConversationContext"
local SpeechStyleContext = require
    "PNC/Semantics/PNC_SpeechStyleContext"

local NEED_KEYS = { "hunger", "thirst", "fatigue" }
local CONDITION_KEYS = { "stress", "boredom", "panic" }

local function numbersFor(source, keys, number)
    local values = {}
    if type(source) ~= "table" then return values end
    for index = 1, #keys do
        local key = keys[index]
        local value = number(source[key], nil)
        if value ~= nil then values[key] = value end
    end
    return values
end

function Conversation.buildContext(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local number = Values.number
    local copy = Values.copy
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local world = scenario.world or {}
    local conversation = scenario.conversation or {}
    local player = scenario.player or {}
    local relationship = context.SemanticAdapters.relationshipFor(
        context, npc.npcID
    )
    local npcName = context.SemanticAdapters.identityName(context, npc)
    -- The world-level fields remain a legacy scenario fallback. An explicit
    -- npc.needs/conditionStats table is authoritative even when empty (unknown).
    local needSource = type(npc.needs) == "table" and npc.needs or world
    local conditionSource = type(npc.conditionStats) == "table"
        and npc.conditionStats or world
    local needs = numbersFor(needSource, NEED_KEYS, number)
    local conditions = numbersFor(conditionSource, CONDITION_KEYS, number)
    local bodyHealth = type(npc.bodyHealth) == "table"
        and copy(npc.bodyHealth) or nil
    local hpCurrent = number(npc.hpCurrent, nil)
    local hpMax = number(npc.hpMax, nil)
    local snapshotNeeds = copy(needs)
    -- Preserve the old snapshot.needs condition fields for worker consumers,
    -- while exposing conditionStats to the real production situation resolver.
    for index = 1, #CONDITION_KEYS do
        local key = CONDITION_KEYS[index]
        snapshotNeeds[key] = conditions[key]
    end
    local configuredAuthority = type(npc.actorAuthority) == "table"
        and npc.actorAuthority or {}
    local companion = configuredAuthority.companion
    if companion == nil then companion = npc.companion == true end
    local owned = configuredAuthority.owned
    if owned == nil then owned = npc.ownedByPlayer == true end
    local authorityEligible = configuredAuthority.eligible
    if authorityEligible == nil then
        authorityEligible = companion == true and owned == true
    end
    local authorityStatus = configuredAuthority.status
        or (authorityEligible and "eligible"
            or (companion == false and "not_companion"
                or owned == false and "not_owned" or "authority_unknown"))
    local priorContext = Runtime.view and Runtime.view.spec
        and Runtime.view.spec.context or nil
    local output = {
        npcID = npc.npcID,
        identityState = npc.identityState or "unknown",
        identity = copy(npc.identity),
        npcName = npcName,
        npcFullName = npcName,
        npcFirstName = npc.forename,
        npcState = {
            traits = copy(npc.traits or {}),
            identityState = npc.identityState or "unknown",
            healthState = npc.healthState,
            activeBehavior = npc.activeBehavior,
            followState = copy(npc.followState or { mode = "idle" }),
            hostility = copy(npc.hostility),
            role = npc.role,
            bodyHealth = bodyHealth,
            hpCurrent = hpCurrent,
            hpMax = hpMax,
            needs = copy(needs),
            conditionStats = copy(conditions),
        },
        relationshipState = relationship.relationshipState
            or npc.relationshipState or "unknown",
        identityTrust = relationship.identityTrust,
        relationship = copy(relationship),
        actorAuthority = {
            eligible = authorityEligible == true,
            companion = companion,
            owned = owned,
            status = authorityStatus,
        },
        npcTraits = copy(npc.traits or {}),
        npcTraitFingerprint = npc.npcTraitFingerprint,
        npcPersonality = copy(npc.personality or {}),
        semanticFactValues = copy(context.semanticFactValues or {}),
        player = nil,
        playerNameKnown = true,
        playerName = context.SemanticAdapters.playerName(context, player),
        characterUUID = player.characterUUID,
        conversationTopic = conversation.topic
            or priorContext and priorContext.conversationTopic
            or "greeting",
        conversationLifecycleState = { token = conversation.token or "harness-lease" },
        semanticAuthorization = copy(
            conversation.semanticAuthorization
                or npc.semanticAuthorization
        ),
        entry = {
            snapshot = {
                activeBehavior = npc.activeBehavior,
                followState = copy(npc.followState or { mode = "idle" }),
                hostility = copy(npc.hostility),
                role = npc.role,
                healthState = npc.healthState,
                bodyHealth = bodyHealth,
                residence = copy(npc.residence),
                knowledge = copy(npc.knowledge),
                inventorySummary = copy(npc.inventorySummary),
                hpCurrent = hpCurrent,
                hpMax = hpMax,
                needs = snapshotNeeds,
                conditionStats = copy(conditions),
            },
        },
    }
    -- Preserve the production composer projection across a worker context
    -- refresh. The registry/authority remains the state owner; this is only
    -- the public view projection consumed by semantic suggestions.
    if type(priorContext) == "table" then
        output.activeConversationBlockID =
            priorContext.activeConversationBlockID
        output.conversationBlockContext =
            priorContext.conversationBlockContext
        output.conversationBlock = Values.copy(priorContext.conversationBlock)
        output.conversationCategoryPreflight = Values.copy(
            priorContext.conversationCategoryPreflight
        )
        output.categoryDiagnostics = Values.copy(
            priorContext.categoryDiagnostics
        )
    end
    output.currentTopic = output.conversationTopic
    output.actorConversationContext = ActorConversationContext.Build(output)
    return output
end

function Conversation.refreshViewContext(context)
    local Runtime = context.Runtime
    if Runtime.view and Runtime.view.spec then
        Runtime.view.spec.context = Conversation.buildContext(context)
        local block = Conversation.blockProjection(Runtime.view)
        Runtime.view.spec.context.conversationBlock = block
        if block then
            Runtime.view.spec.context.conversationTopic = block.topic
            Runtime.view.spec.context.currentTopic = block.topic
            if type(Runtime.view.spec.context.conversationBlockContext)
                == "table"
            then
                Runtime.view.spec.context.conversationBlockContext.conversationTopic =
                    block.topic
            end
        end
        Runtime.view.spec.context.conversationCategoryPreflight =
            Conversation.categoryPreflight(
                Runtime.view.spec.context.conversationBlockContext
            )
        local composer = PNC.Conversation and PNC.Conversation.Composer
        if composer and type(composer.BuildCategoryDiagnostics) == "function"
            and type(Runtime.view.spec.context.conversationBlockContext) == "table"
        then
            local ok, diagnostics = pcall(
                composer.BuildCategoryDiagnostics,
                Runtime.view.spec.context.conversationBlockContext
            )
            if ok and type(diagnostics) == "table" then
                Runtime.view.spec.context.categoryDiagnostics = diagnostics
            end
        end
        if composer and type(composer.BuildRootNode) == "function"
            and type(Runtime.view.spec.context.conversationBlockContext)
                == "table"
        then
            local ok, root = pcall(
                composer.BuildRootNode,
                Runtime.view.spec.context.conversationBlockContext,
                Runtime.view.spec.context.conversationMenuOptions or {}
            )
            if ok and type(root) == "table" then
                Runtime.view.spec.nodes.menu = { choices = root.choices or {} }
                if composer
                    and type(composer.BuildSemanticRootProjection)
                        == "function"
                then
                    Runtime.view.spec.context.conversationRoot =
                        composer.BuildSemanticRootProjection(Runtime.view)
                end
                if Runtime.view.session.currentNodeID == "menu" then
                    Runtime.view.session.currentNode =
                        Runtime.view.spec.nodes.menu
                    Runtime.view.session:setChoices(
                        Runtime.view.session.currentNode.choices
                    )
                end
            end
        end
    end
end

local function resolvedPayload(value)
    if type(value) ~= "table" then return tostring(value or "") end
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    if text and type(text.Resolve) == "function" then
        local ok, resolved = pcall(text.Resolve, value)
        if ok and type(resolved) == "string" and resolved ~= "" then
            return resolved
        end
    end
    return tostring(value.text or value.fallback or "")
end

function Conversation.blockProjection(view)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    if composer and type(composer.BuildSemanticBlockProjection) == "function" then
        local projection = composer.BuildSemanticBlockProjection(view)
        if projection then return projection end
    end
    local spec = view and view.spec or nil
    local root = spec and spec.context or nil
    local nodes = spec and spec.nodes or nil
    local blockID = root and root.activeConversationBlockID or nil
    if not blockID or type(nodes) ~= "table" then return nil end
    local nodeID = view.session and view.session.currentNodeID or nil
    if not nodeID or string.sub(tostring(nodeID), 1, 6) == "block:" then
        nodeID = string.sub(tostring(nodeID or ""), 7)
    end
    if nodeID == "" then return nil end
    local node = nodes["block:" .. tostring(nodeID)]
    if type(node) ~= "table" then return nil end
    local block = PNC.Conversation and PNC.Conversation.Registry
        and PNC.Conversation.Registry.GetBlock
        and PNC.Conversation.Registry.GetBlock(blockID) or nil
    local topic = block and block.topic or nil
    if not topic and block
        and PNC.Semantics and PNC.Semantics.TopicCatalog
        and type(PNC.Semantics.TopicCatalog.AuthoredTopic) == "function"
    then
        topic = PNC.Semantics.TopicCatalog.AuthoredTopic(block)
    end
    if not topic and block and PNC.Semantics
        and PNC.Semantics.TopicCatalog
        and type(PNC.Semantics.TopicCatalog.AUTHORED_CATEGORY_TOPICS) == "table"
    then
        topic = PNC.Semantics.TopicCatalog.AUTHORED_CATEGORY_TOPICS[
            block.category
        ]
    end
    local choices = {}
    for _, choice in ipairs(node.choices or {}) do
        if type(choice) == "table" then
            choices[#choices + 1] = {
                id = choice.id,
                textKey = choice.textKey,
                text = resolvedPayload(choice.text),
                enabled = choice.enabled == true,
                lockedReasonKey = choice.lockedReasonKey,
            }
        end
    end
    return {
        categoryID = "projecthoomans:whats_up",
        blockID = blockID,
        nodeID = nodeID,
        topic = topic or root.conversationTopic,
        npcText = resolvedPayload(node.npc),
        choices = choices,
    }
end

function Conversation.categoryPreflight(blockContext)
    local categoryID = "projecthoomans:whats_up"
    if type(blockContext) ~= "table" then
        return { visible = false, reason = "context_unknown" }
    end
    local conversation = PNC.Conversation
    local registry = conversation and conversation.Registry or nil
    local selector = conversation and conversation.Selector or nil
    if not registry or not selector
        or type(registry.GetCategory) ~= "function"
        or type(selector.IsCategoryEligible) ~= "function"
        or type(selector.SelectBlock) ~= "function"
    then
        return { visible = false, reason = "registry_unavailable" }
    end
    local category = registry.GetCategory(categoryID)
    if not category then return { visible = false, reason = "category_not_found" } end
    local eligible, eligibilityReason = selector.IsCategoryEligible(
        categoryID, blockContext, false
    )
    local selected, selection = selector.SelectBlock(categoryID, blockContext)
    return {
        categoryID = categoryID,
        visible = eligible == true and selected ~= nil,
        eligible = eligible == true,
        reason = eligible ~= true and eligibilityReason
            or selected and "visible" or "no_eligible_block",
        selectedBlockID = selected and selected.id or nil,
        eligibleBlockCount = selection and selection.eligibleCount or 0,
    }
end

function Conversation.buildView(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local player = scenario.player or {}
    local session = {
        characterUUID = player.characterUUID,
        conversationID = "harness-conversation",
        queue = {},
        currentNodeID = "menu",
        currentNode = nil,
        spec = nil,
        view = nil,
        append = function(self, speaker, value, metadata)
            local message = {
                speaker = speaker,
                value = value,
                metadata = Values.copy(metadata),
            }
            self.lastAppend = message
            Runtime.transcript[#Runtime.transcript + 1] = message
            if speaker == "npc" then
                Runtime.queued[#Runtime.queued + 1] = {
                    speaker = speaker,
                    payload = Values.copy(value),
                    metadata = Values.copy(metadata),
                }
            end
            return { messageID = "harness-message-" .. tostring(#Runtime.transcript) }
        end,
        queueMessage = function(self, speaker, payload, metadata)
            local storedPayload = Values.copy(payload)
            if type(storedPayload) == "table"
                and storedPayload.text == nil
                and storedPayload.fallback == nil
            then
                local resolved = resolvedPayload(storedPayload)
                if resolved ~= "" then
                    storedPayload.text = resolved
                    storedPayload.fallback = resolved
                end
            end
            local message = {
                speaker = speaker,
                payload = storedPayload,
                metadata = Values.copy(metadata),
            }
            self.lastQueued = message
            Runtime.queued[#Runtime.queued + 1] = message
            Runtime.transcript[#Runtime.transcript + 1] = message
        end,
        setPresentedChoices = function(self, choices, metadata)
            self.choices = choices or {}
            metadata = type(metadata) == "table" and metadata or {}
            self.choicePresentationState = {
                source = metadata.source or "session",
                revision = metadata.revision,
                authoredCount = metadata.authoredCount,
                presentedCount = #self.choices,
                busy = self.busy == true,
                pending = self.pendingChoices ~= nil,
                presentationError = metadata.presentationError,
            }
            return true
        end,
        clearChoices = function(self, reason)
            return self:setPresentedChoices({}, { source = reason or "clear" })
        end,
        setChoices = function(self, choices)
            local authored = choices or {}
            local output = {}
            for index, choice in ipairs(authored) do
                local text = choice.text
                if text == nil and choice.textKey then
                    text = {
                        key = choice.textKey,
                        domain = choice.textDomain,
                        args = choice.textArgs,
                    }
                end
                output[#output + 1] = {
                    id = choice.id or tostring(index),
                    text = text,
                    response = choice.response,
                    next = choice.next,
                    close = choice.close,
                    closeReason = choice.closeReason,
                    action = choice.action or choice.onSelect,
                    log = choice.log ~= false,
                    enabled = choice.enabled ~= false,
                    tooltip = choice.tooltip,
                    source = choice,
                }
            end
            local presenter = self.view and self.view.spec
                and self.view.spec.choicePresentation or nil
            local presentedByCallback = false
            local presentationError
            if type(presenter) == "function" then
                local ok, presented = pcall(
                    presenter, self.view, output, authored, self
                )
                if ok and type(presented) == "table" then
                    output = presented
                    presentedByCallback = true
                elseif not ok then
                    presentationError = tostring(presented)
                end
            end
            return self:setPresentedChoices(output, {
                source = presentationError and "authored_fallback"
                    or presentedByCallback and "choice_presentation"
                    or "session",
                authoredCount = #output,
                presentationError = presentationError,
            })
        end,
        enterNode = function(self, nodeID)
            self.currentNodeID = tostring(nodeID or "")
            self.currentNode = self.spec
                and self.spec.nodes
                and self.spec.nodes[self.currentNodeID] or nil
            self:clearChoices("enter_node")
            self:setChoices(self.currentNode and self.currentNode.choices or {})
            local node = self.currentNode
            if node and node.npc then
                local text = resolvedPayload(node.npc)
                self:append("npc", {
                    key = "conversation.node." .. self.currentNodeID,
                    text = text,
                    fallback = text,
                    nodeID = self.currentNodeID,
                }, { conversationNode = true })
            end
            return self.currentNode ~= nil
        end,
        selectChoice = function(self, choice)
            if self.busy or not choice or choice.enabled == false then
                return false
            end
            self:clearChoices("select_choice")
            if choice.log ~= false then
                self:append("player", resolvedPayload(choice.text))
            end
            if type(choice.action) == "function" then
                choice.action(self.context, choice, self)
            end
            local response = choice.response
            if type(response) == "function" then
                response = response(self.context, choice, self)
            end
            if response then self:queueMessage("npc", response) end
            self.pendingNext = choice.next
            self.pendingClose = choice.close == true
            self.pendingCloseReason = choice.closeReason
            if #self.queue == 0 then self:finishPending() end
            return true
        end,
        finishPending = function(self)
            self.pendingFinished = true
            if self.pendingClose == true then
                self.lifecycleFinished = true
                self.pendingClose = nil
                self.pendingNext = nil
                self.pendingChoices = nil
                return true
            end
            if self.pendingNext then
                local nextNode = self.pendingNext
                self.pendingNext = nil
                self:enterNode(nextNode)
                return true
            end
            if self.pendingChoices then
                local choices = self.pendingChoices
                self.pendingChoices = nil
                self:setChoices(choices)
            end
            return true
        end,
    }
    local spec = {
        npcID = npc.npcID,
        context = Conversation.buildContext(context),
        nodes = { menu = { choices = {} } },
        choicePresentation = function(view, authoredChoices)
            local input = PNC.Semantics
                and PNC.Semantics.DialogueInput or nil
            local internal = input and input.Internal or nil
            if internal
                and type(internal.PresentSemanticChoices) == "function"
            then
                return internal.PresentSemanticChoices(
                    view, authoredChoices
                )
            end
            return nil
        end,
        choiceInteractionGuard = function(view)
            local context = view and view.spec and view.spec.context or nil
            return type(context) ~= "table"
                or context.pendingConversationRequest == nil
        end,
    }
    local authority = PNC.Conversation and PNC.Conversation.Authority
    if authority and type(authority.BuildContext) == "function" then
        local ok, blockContext = pcall(
            authority.BuildContext,
            context.player,
            npc,
            scenario.conversation and scenario.conversation.token
        )
        if ok and type(blockContext) == "table" then
            spec.context.conversationBlockContext = blockContext
        end
    end
    spec.context.conversationCategoryPreflight = Conversation.categoryPreflight(
        spec.context.conversationBlockContext
    )
    local composer = PNC.Conversation and PNC.Conversation.Composer
    if composer and type(composer.BuildCategoryDiagnostics) == "function"
        and type(spec.context.conversationBlockContext) == "table"
    then
        local ok, diagnostics = pcall(
            composer.BuildCategoryDiagnostics,
            spec.context.conversationBlockContext
        )
        if ok and type(diagnostics) == "table" then
            spec.context.categoryDiagnostics = diagnostics
        end
    end
    if composer and type(composer.BuildRootNode) == "function"
        and type(spec.context.conversationBlockContext) == "table"
    then
        local ok, root = pcall(
            composer.BuildRootNode,
            spec.context.conversationBlockContext,
            spec.context.conversationMenuOptions or {}
        )
        if ok and type(root) == "table" then
            spec.nodes.menu = { choices = root.choices or {} }
        end
    end
    local view = {
        headless = true,
        lifecycleFinished = false,
        spec = spec,
        session = session,
    }
    session.view = view
    session.spec = spec
    session.currentNode = spec.nodes.menu
    session:setChoices(session.currentNode.choices)
    view.spec.context.conversationBlock = Conversation.blockProjection(view)
    if composer and type(composer.BuildSemanticRootProjection) == "function" then
        view.spec.context.conversationRoot =
            composer.BuildSemanticRootProjection(view)
    end
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local internal = input and input.Internal or nil
    if internal and type(internal.RefreshRootSuggestions) == "function" then
        local projection = internal.RefreshRootSuggestions(view)
        if projection then
            Runtime.lastSuggestionRevision = tonumber(projection.revision)
                or Runtime.lastSuggestionRevision
        end
    end
    return view
end

function Conversation.relationshipSnapshot(context)
    local scenario = context.Runtime.scenario or {}
    local npc = scenario.npc or {}
    return context.SemanticAdapters.relationshipSnapshotFor(context, npc.npcID)
end

function Conversation.contextSnapshot(harnessContext, view)
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
        actorConversationContext = Values.copy(
            view and view.spec and view.spec.context
                and view.spec.context.actorConversationContext
        ),
        speechStyleContext = SpeechStyleContext.Resolve(
            view and view.spec and view.spec.context or {}
        ),
    }
end

function Conversation.turn(context, text)
    local Runtime = context.Runtime
    local Values = context.Values
    Runtime.turn = Runtime.turn + 1
    Runtime.now = Runtime.now + 1
    local view = Runtime.view
    local queuedBefore = #Runtime.queued
    local transcriptBefore = #Runtime.transcript
    local traceBefore = #Runtime.trace
    local transportBefore = #Runtime.transport
    local translationBefore = #Runtime.translationLookups
    local relationshipBefore = Conversation.relationshipSnapshot(context)
    local contextBefore = Conversation.contextSnapshot(context, view)
    local semanticClickFrame = Runtime.semanticClickFrame
    Runtime.semanticClickFrame = nil
    local accepted
    local reason
    if semanticClickFrame then
        accepted, reason = PNC.Semantics.DialogueInput.SubmitSemanticFrame(
            view, semanticClickFrame
        )
    else
        accepted, reason = PNC.Semantics.DialogueInput.Submit(view, text)
    end
    -- The harness transport is an authoritative fixture. Refresh the same
    -- production context projection after a command so the next suggestion
    -- set reflects follow/stay state rather than replaying stale affordances.
    Conversation.refreshViewContext(context)
    local result = view.lastSemanticDialogueResult
    -- Inspect the exact situation built by the production input router, not
    -- a separately re-created approximation in the Python test harness.
    local router = view.session and view.session.semanticDialogueRouter
    local routedContext = router and router.context
    local routedSituation = routedContext and routedContext.dialogueSituation
    local actorService = view.session
        and view.session.semanticActorConversationService
    local newMessages = {}
    local newTrace = {}
    local newTransport = {}
    local newTranslations = {}
    local index
    for index = queuedBefore + 1, #Runtime.queued do
        newMessages[#newMessages + 1] = Values.copy(Runtime.queued[index])
    end
    for index = transcriptBefore + 1, #Runtime.transcript do
        -- Transcript includes player input and queued NPC lines; preserve both.
    end
    for index = traceBefore + 1, #Runtime.trace do
        newTrace[#newTrace + 1] = Values.copy(Runtime.trace[index])
    end
    for index = transportBefore + 1, #Runtime.transport do
        newTransport[#newTransport + 1] = Values.copy(Runtime.transport[index])
    end
    for index = translationBefore + 1, #Runtime.translationLookups do
        newTranslations[#newTranslations + 1] = Values.copy(Runtime.translationLookups[index])
    end
    local actionResult = view.lastSemanticActionResult
    local toolCalls = context.OutputProjection.normalizedToolCalls(
        context, newTrace, newTransport, result, actionResult
    )
    local response = {
        ok = true,
        type = "turn",
        input = text,
        accepted = accepted == true,
        reason = reason,
        result = result and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = Values.copy(result.ir),
            decision = Values.copy(result.decision),
            flow = Values.copy(result.flow),
            actionResult = Values.copy(actionResult),
            compound = Values.copy(view.lastSemanticCompound),
            candidates = Values.copy(result.candidates),
            candidateDiagnostics = Values.copy(result.candidateDiagnostics),
        } or nil,
        messages = newMessages,
        trace = newTrace,
        transport = newTransport,
        toolCalls = toolCalls,
        translation = {
            language = context.Translations.currentLanguage(context),
            lookups = newTranslations,
        },
        relationshipBefore = relationshipBefore,
        relationshipAfter = Conversation.relationshipSnapshot(context),
        contextBefore = contextBefore,
        contextAfter = Conversation.contextSnapshot(context, view),
        routedSituation = Values.copy(routedSituation),
        actorConversation = actorService
            and actorService.Snapshot and actorService:Snapshot() or nil,
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
        choiceSurface = Values.copy(
            view.session and view.session.choicePresentationState
        ),
    }
    response.observation = context.OutputProjection.observation(
        context, response, view.spec and view.spec.context
    )
    -- Authoritative receipts can arrive synchronously through the worker's
    -- dual-role transport after the ordinary semantic result is planned.
    -- Preserve their exact final NPC payload in the Inspector trace even
    -- when no native UI composer is present to build a plan envelope.
    response.observation.authoritativeMessages = {}
    for _, message in ipairs(newMessages) do
        if type(message) == "table" and message.speaker == "npc" then
            response.observation.authoritativeMessages[#response.observation.authoritativeMessages + 1] =
                Values.copy(message.payload)
        end
    end
    response.observation.authoritativeMessageCount =
        #response.observation.authoritativeMessages
    if response.observation.suggestions then
        Runtime.lastSuggestionRevision = tonumber(
            response.observation.suggestions.revision
        )
    end
    return response
end

local function sliced(values, startIndex)
    local output = {}
    local start = tonumber(startIndex) or 1
    for index = start, #(values or {}) do
        output[#output + 1] = values[index]
    end
    return output
end

function Conversation.semanticClick(context, frame)
    local Runtime = context.Runtime
    local Values = context.Values
    local Input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local Suggestions = PNC.Semantics and PNC.Semantics.DialogueSuggestions
    local view = Runtime.view
    if not view or not view.session or not Input
        or type(Input.SubmitSemanticFrame) ~= "function"
    then
        return nil, "conversation_unavailable"
    end
    if type(frame) ~= "table" then return nil, "suggestion_frame_required" end
    local isCategory = Suggestions
        and Suggestions.IsConversationCategoryFrame
        and Suggestions.IsConversationCategoryFrame(frame)
    local isChoice = Suggestions
        and Suggestions.IsConversationChoiceFrame
        and Suggestions.IsConversationChoiceFrame(frame)
    local isRootChoice = Suggestions
        and Suggestions.IsConversationRootChoiceFrame
        and Suggestions.IsConversationRootChoiceFrame(frame)
    local isGroup = Suggestions
        and Suggestions.IsGroupFrame
        and Suggestions.IsGroupFrame(frame)
    if not isCategory and not isChoice and not isRootChoice and not isGroup then
        return nil, "unsupported_conversation_frame"
    end

    local revision = tonumber(frame.requestRevision)
    local currentRevision = tonumber(Runtime.lastSuggestionRevision)
    if revision == nil or currentRevision == nil
        or revision ~= currentRevision
    then
        return {
            ok = true,
            type = "semantic_click",
            input = tostring(frame.textFallback or frame.candidateID or ""),
            accepted = false,
            reason = "suggestion_click_stale",
            messages = {},
            trace = {},
            transport = {},
            toolCalls = {},
            observation = {
                suggestions = {
                    schemaVersion = 1,
                    kind = "semantic_dialogue_suggestions",
                    revision = currentRevision or 0,
                    candidates = {},
                    groups = {},
                    trace = {{
                        source = "suggestion_click",
                        status = "rejected",
                        reason = "suggestion_click_stale",
                        candidateCount = 0,
                    }},
                },
            },
        }
    end

    local receiptKey = table.concat({
        tostring(frame.candidateID or ""), tostring(revision),
    }, ":")
    Runtime.semanticClickReceipts = Runtime.semanticClickReceipts or {}
    if Runtime.semanticClickReceipts[receiptKey] then
        return {
            ok = true,
            type = "semantic_click",
            input = tostring(frame.textFallback or frame.candidateID or ""),
            accepted = false,
            reason = "suggestion_click_replayed",
            messages = {},
            trace = {},
            transport = {},
            toolCalls = {},
            observation = {
                suggestions = {
                    schemaVersion = 1,
                    kind = "semantic_dialogue_suggestions",
                    revision = currentRevision,
                    candidates = {},
                    groups = {},
                    trace = {{
                        source = "suggestion_click",
                        status = "rejected",
                        reason = "suggestion_click_replayed",
                        candidateCount = 0,
                    }},
                },
            },
        }
    end

    Runtime.turn = Runtime.turn + 1
    Runtime.now = Runtime.now + 1
    local transcriptBefore = #Runtime.transcript
    local queuedBefore = #Runtime.queued
    local traceBefore = #Runtime.trace
    local transportBefore = #Runtime.transport
    local translationBefore = #Runtime.translationLookups
    local blockBefore = view.spec.context.activeConversationBlockID
    local contextBefore = context.Conversation.contextSnapshot(
        context, view
    )
    local accepted, reason = Input.SubmitSemanticFrame(view, frame)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    local mode = Runtime.scenario and Runtime.scenario.runtime
        and Runtime.scenario.runtime.mode or "singleplayer"
    if accepted == true and mode ~= "multiplayer"
        and composer and type(composer.PumpLocalRequests) == "function"
    then
        composer.PumpLocalRequests()
    end
    Conversation.refreshViewContext(context)
    if isGroup and view.semanticSuggestions then
        local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
        local internal = input and input.Internal or nil
        if internal and type(internal.ApplySemanticChoices) == "function" then
            internal.ApplySemanticChoices(view, view.semanticSuggestions)
        end
    end
    local projectedBlock = Conversation.blockProjection(view)
    if isRootChoice then
        local internal = Input.Internal
        if isCategory and projectedBlock then
            -- The category request has crossed into an authored block. Let
            -- the normal block projection become the next suggestion set.
            local router = internal and type(internal.RouterFor) == "function"
                and internal.RouterFor(view) or nil
            local revision = router and router.state
                and tonumber(router.state.sequence) or currentRevision or 0
            if internal and type(internal.ShallowContext) == "function"
                and Suggestions and type(Suggestions.Build) == "function"
            then
                local semanticContext = internal.ShallowContext(view) or {}
                semanticContext.conversationBlock = projectedBlock
                view.semanticSuggestions = Suggestions.Build({
                    accepted = false,
                    sequence = revision,
                    state = { sequence = revision },
                    ir = {},
                    decision = {},
                }, semanticContext, nil)
            else
                view.semanticSuggestions = nil
            end
        else
            local refreshed = internal
                and type(internal.RefreshRootSuggestions) == "function"
                and internal.RefreshRootSuggestions(view) or nil
            if not refreshed then view.semanticSuggestions = nil end
        end
    end
    local projection = projectedBlock
    local blockAfter = view.spec.context.activeConversationBlockID
    local applied = accepted == true
    if isCategory then
        applied = applied and blockAfter ~= nil and blockAfter ~= blockBefore
    end
    if not applied and accepted == true then
        accepted = false
        reason = view.spec.context.lastConversationError
            or (isCategory and "conversation_block_unavailable"
                or "conversation_outcome_unavailable")
    end
    if accepted == true then
        Runtime.semanticClickReceipts[receiptKey] = true
    end

    local allMessages = sliced(Runtime.queued, queuedBefore + 1)
    local newTrace = sliced(Runtime.trace, traceBefore + 1)
    local newTransport = sliced(Runtime.transport, transportBefore + 1)
    local newTranslations = sliced(Runtime.translationLookups, translationBefore + 1)
    local response = {
        ok = true,
        type = "semantic_click",
        input = tostring(frame.textFallback or frame.candidateID or ""),
        accepted = accepted == true,
        reason = reason,
        -- This is a worker response envelope revision, not a parsed turn.
        -- The click has already crossed the typed-frame boundary above.
        result = {
            accepted = accepted == true,
            reason = reason,
            sequence = revision,
            ir = {
                kind = "semantic_click_frame",
                intent = "REQUEST",
                speechAct = "REQUEST",
                subject = "CONVERSATION_TOPIC",
            },
        },
        messages = allMessages,
        trace = newTrace,
        transport = newTransport,
        toolCalls = context.OutputProjection.normalizedToolCalls(
            context, newTrace, newTransport, nil, nil
        ),
        translation = {
            language = context.Translations.currentLanguage(context),
            lookups = newTranslations,
        },
        contextBefore = contextBefore,
        contextAfter = context.Conversation.contextSnapshot(
            context, view
        ),
        choiceSurface = Values.copy(
            view.session and view.session.choicePresentationState
        ),
        loadedModules = Runtime.loadedModules,
        conversationBlock = Values.copy(projection),
    }
    response.transcriptMessages = sliced(Runtime.transcript, transcriptBefore + 1)
    response.observation = context.OutputProjection.observation(
        context,
        response,
        view.spec and view.spec.context
    )
    if (isRootChoice or isGroup) and view.semanticSuggestions then
        response.observation.suggestions = Values.copy(
            view.semanticSuggestions
        )
        Runtime.lastSuggestionRevision = tonumber(
            view.semanticSuggestions.revision
        ) or Runtime.lastSuggestionRevision
    end
    response.observation.conversationBlock = Values.copy(projection)
    response.observation.authoritativeMessages = {}
    for _, message in ipairs(allMessages) do
        if type(message) == "table" and message.speaker == "npc" then
            response.observation.authoritativeMessages[#response.observation.authoritativeMessages + 1] =
                Values.copy(message.payload)
        end
    end
    response.observation.authoritativeMessageCount =
        #response.observation.authoritativeMessages
    if response.observation.suggestions then
        Runtime.lastSuggestionRevision = tonumber(
            response.observation.suggestions.revision
        ) or Runtime.lastSuggestionRevision
    end
    return response
end

function Conversation.preview(context, text)
    local Runtime = context.Runtime
    local Values = context.Values
    local view = Runtime.view
    local Input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local Internal = Input and Input.Internal or {}
    local router, routerReason
    if type(Internal.RouterFor) == "function" then
        router, routerReason = Internal.RouterFor(view)
    end
    if not router then
        return {
            ok = true,
            type = "preview",
            input = text,
            accepted = false,
            reason = routerReason or "conversation_unavailable",
            contextBefore = Conversation.contextSnapshot(context, view),
            contextAfter = Conversation.contextSnapshot(context, view),
            messages = {},
            trace = {},
            transport = {},
            toolCalls = {},
            llmCalls = Runtime.llmCalls,
        }
    end

    local value = tostring(text or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.sub(value, 1, Input.MAX_INPUT_LENGTH)
    local contextBefore = Conversation.contextSnapshot(context, view)
    local relationshipBefore = Conversation.relationshipSnapshot(context)
    local traceBefore = #Runtime.trace
    local transportBefore = #Runtime.transport
    local translationBefore = #Runtime.translationLookups
    local projection = type(Internal.ShallowContext) == "function"
        and Internal.ShallowContext(view) or {}
    local options = {
        timestamp = type(Internal.Now) == "function" and Internal.Now() or 0,
    }
    local result = router:Preview(value, projection, options)
    if result and result.accepted == true
        and result.ir and type(router.Decide) == "function"
    then
        -- Router:Preview intentionally does not commit a turn. Ask the same
        -- production policy for its pure flow preview so the lab can inspect
        -- generated gates/bindings without recording or dispatching anything.
        local decision = router:Decide(result.ir, projection, options)
        result.decision = decision
        result.flow = decision and decision.flow
    end
    local newTrace = {}
    local newTransport = {}
    local newTranslations = {}
    local index
    for index = traceBefore + 1, #Runtime.trace do
        newTrace[#newTrace + 1] = Values.copy(Runtime.trace[index])
    end
    for index = transportBefore + 1, #Runtime.transport do
        newTransport[#newTransport + 1] = Values.copy(Runtime.transport[index])
    end
    for index = translationBefore + 1, #Runtime.translationLookups do
        newTranslations[#newTranslations + 1] = Values.copy(Runtime.translationLookups[index])
    end
    local toolCalls = context.OutputProjection.normalizedToolCalls(
        context, newTrace, newTransport, result, nil
    )
    local response = {
        ok = true,
        type = "preview",
        input = value,
        accepted = result and result.accepted == true,
        reason = result and result.reason,
        result = result and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = Values.copy(result.ir),
            decision = Values.copy(result.decision),
            flow = Values.copy(result.flow),
            candidates = Values.copy(result.candidates),
            candidateDiagnostics = Values.copy(result.candidateDiagnostics),
        } or nil,
        messages = {},
        trace = newTrace,
        transport = newTransport,
        toolCalls = toolCalls,
        translation = {
            language = context.Translations.currentLanguage(context),
            lookups = newTranslations,
        },
        relationshipBefore = relationshipBefore,
        relationshipAfter = Conversation.relationshipSnapshot(context),
        contextBefore = contextBefore,
        contextAfter = Conversation.contextSnapshot(context, view),
        routedSituation = Values.copy(projection.dialogueSituation),
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
    }
    response.observation = context.OutputProjection.observation(
        context, response, view.spec and view.spec.context
    )
    return response
end

return Conversation
