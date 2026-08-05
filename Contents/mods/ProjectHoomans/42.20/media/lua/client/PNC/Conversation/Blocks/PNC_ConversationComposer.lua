require "PNC/Conversation/Blocks/PNC_ConversationTextLoader"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Composer = Conversation.Composer or {}
Conversation.Composer = Composer
local Registry = Conversation.Registry
local Selector = Conversation.Selector
local Rules = Conversation.Rules
local Loader = Conversation.TextLoader
Composer.requestSerial = tonumber(Composer.requestSerial) or 0
Composer.localRequests = Composer.localRequests or {}

local SYSTEM_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/categories.json",
    domain = "pnc.system.shared.categories",
}

local RECRUIT_SYSTEM_KEYS = {
    "choice.recruit",
    "response.recruit.admire.1",
    "response.recruit.admire.2",
    "response.recruit.admire.3",
    "response.recruit.fear.1",
    "response.recruit.fear.2",
    "response.recruit.fear.3",
    "response.recruit.reject.relationship.1",
    "response.recruit.reject.relationship.2",
    "response.recruit.reject.relationship.3",
    "response.recruit.reject.leader.1",
    "response.recruit.reject.leader.2",
    "response.recruit.reject.cooldown.1",
    "response.recruit.reject.cooldown.2",
    "response.recruit.reject.general.1",
    "response.recruit.reject.general.2",
    "response.recruit.reject.general.3",
}

local GOODBYE_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/goodbye/shared/{language}/goodbye.json",
    domain = "pnc.goodbye.shared.goodbye",
}

local TIME_HOURS = {
    dawn = 5.5,
    sunrise = 8,
    sunset = 15,
    dusk = 19,
    twilight = 22,
}

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function activeView(npcID)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if view and tostring(view.spec and view.spec.npcID or "")
        == tostring(npcID or "")
    then return view end
    return nil
end

local function audienceMap(entry, relationshipID)
    local snapshot = entry and entry.snapshot or {}
    local record = entry and entry.record or {}
    local faction = tostring(snapshot.faction or record.faction or "")
    local hostility = snapshot.hostility or record.hostility or {}
    local hostile = faction == "hostile" and hostility.attackPlayers ~= false
    return {
        hostile = hostile,
        neutral = not hostile and relationshipID ~= "Member"
            and relationshipID ~= "Lover",
        member = not hostile and relationshipID == "Member",
        special = not hostile and relationshipID == "Lover",
        shared = true,
    }
end

function Composer.BuildContext(entry, player, timeID, relationshipID)
    local state = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = state.playerContext or {}
    local record = entry and entry.record or {}
    local npcID = tostring(entry and entry.id or "debug-npc")
    local relationship = Conversation.Relationship
        and Conversation.Relationship.GetPresentation(npcID) or {}
    local at = worldAgeHours()
    local context = {
        entry = entry,
        player = player,
        npcRecord = record,
        npcID = npcID,
        characterUUID = playerContext.characterUUID or "unbound",
        relationship = relationship or {},
        relationshipState = relationshipID,
        playerSocialProfile = playerContext.socialProfile,
        playerPersonality = playerContext.socialProfile,
        npcPersonality = record.personality or record.socialProfile,
        npcTraits = record.traits or record.socialTraits,
        audiences = audienceMap(entry, relationshipID),
        allowHostileParley = audienceMap(entry, relationshipID).hostile,
        worldAgeHours = at,
        hour = TIME_HOURS[timeID] or at % 24,
        worldID = "world",
    }
    context.blockValidator = function(block)
        return Loader.EnsureSource(
            block.textSource,
            Registry.CollectTextKeys(block)
        )
    end
    context.categoryValidator = function(category)
        return Loader.EnsureSource(
            category.textSource,
            { category.labelKey }
        )
    end
    state.conversationHistory = state.conversationHistory or {}
    state.conversationHistory[npcID] = state.conversationHistory[npcID] or {}
    context.historyLookup = function(subjectID)
        return state.conversationHistory[npcID][tostring(subjectID or "")]
    end
    return context
end

local function payload(source, key, args)
    return Loader.Payload(source, key, args)
end

local function dialoguePayload(source, key, context, args)
    local merged = {}
    for name, value in pairs(context and context.textArgs or {}) do
        merged[name] = value
    end
    for name, value in pairs(type(args) == "table" and args or {}) do
        merged[name] = value
    end
    return payload(source, key, merged)
end

function Composer.SetIdentityArguments(context, values)
    if type(context) ~= "table" then return false end
    context.textArgs = {}
    for name, value in pairs(type(values) == "table" and values or {}) do
        context.textArgs[name] = value
        context[name] = value
    end
    return true
end

local function ensureBlockText(block)
    return Loader.EnsureSource(
        block.textSource,
        Registry.CollectTextKeys(block)
    )
end

local function selectedTextKey(block, nodeID, node, context)
    if node.textKey then return node.textKey end
    local values = node.textKeys or {}
    if #values == 0 then return nil end
    local seed = Selector.Seed(
        context,
        table.concat({ "node_text", block.id, nodeID }, ":")
    )
    return values[seed % #values + 1]
end

local function requestID(prefix)
    Composer.requestSerial = Composer.requestSerial + 1
    return table.concat({ prefix, Composer.requestSerial,
        getTimeInMillis and getTimeInMillis() or 0 }, ":")
end

local function lifecycleState(view)
    return view and view.spec and view.spec.context
        and view.spec.context.conversationLifecycleState or nil
end

local function sendRequest(command, payloadValue)
    if isClient and isClient() == true then
        if not sendClientCommand then return false, "transport_unavailable" end
        sendClientCommand(PNC.Const.MODULE, command, payloadValue)
        return true
    end
    local authority = Conversation.Authority
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if authority then
        Composer.localRequests[#Composer.localRequests + 1] = {
            command = command,
            payload = payloadValue,
            player = player,
        }
        return true
    end
    return false, "authority_unavailable"
end

local function restoreCurrentChoices(view)
    local session = view and view.session
    if session and session.currentNode then
        session:setChoices(session.currentNode.choices or {})
    end
end

local function notifyFailure(view, key, reason)
    if view and view.spec and view.spec.context then
        view.spec.context.lastConversationError = tostring(reason or "unavailable")
    end
    local value = PsychopatzCore.Conversation.Text.Resolve(payload(
        SYSTEM_SOURCE,
        key,
        { reason = tostring(reason or "unavailable") }
    ))
    -- A rejected authoritative request is part of the conversation.  Keep it
    -- in the log as well as the transient halo so a failed recruit, stale
    -- lease, or inventory action is never indistinguishable from a blank UI.
    local session = view and view.session
    if session and session.append then
        session:append("npc", payload(
            SYSTEM_SOURCE,
            key,
            { reason = tostring(reason or "unavailable") }
        ))
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, value)
    end
    if PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("Conversation request rejected: "
            .. tostring(reason or "unavailable"))
    end
    restoreCurrentChoices(view)
end

local function rememberCategoryUse(context, categoryID, outcomeID)
    if type(context) ~= "table" or not categoryID then return false end
    local history = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.conversationHistory or nil
    if type(history) ~= "table" then return false end
    local npcID = tostring(context.npcID or "")
    local subject = "category:" .. tostring(categoryID)
    history[npcID] = history[npcID] or {}
    local previous = history[npcID][subject] or { useCount = 0 }
    previous.useCount = (tonumber(previous.useCount) or 0) + 1
    previous.lastUsedWorldHour = context.worldAgeHours
    previous.lastOutcomeID = outcomeID
    history[npcID][subject] = previous
    return true
end

function Composer.PumpLocalRequests()
    local requests = Composer.localRequests
    Composer.localRequests = {}
    for _, request in ipairs(requests) do
        if request.command == PNC.Const.CMD_CONVERSATION_CATEGORY_REQUEST
            and Conversation.Authority.HandleCategory
        then
            Conversation.Authority.HandleCategory(request.player, request.payload)
        elseif request.command == PNC.Const.CMD_CONVERSATION_CHOICE_REQUEST
            and Conversation.Authority.HandleChoice
        then
            Conversation.Authority.HandleChoice(request.player, request.payload)
        elseif request.command == PNC.Const.CMD_CONVERSATION_RECRUIT_REQUEST
            and Conversation.Authority.HandleRecruit
        then
            Conversation.Authority.HandleRecruit(request.player, request.payload)
        end
    end
end

function Composer.RequestCategory(npcID, categoryID, autoChoiceID)
    local view = activeView(npcID)
    local lifecycle = lifecycleState(view)
    if not view then return false, "conversation_not_ready" end
    if not lifecycle then
        notifyFailure(view, "status.block_unavailable", "conversation_not_ready")
        return false, "conversation_not_ready"
    end
    local id = requestID("category")
    view.spec.context.pendingConversationRequest = id
    view.spec.context.pendingConversationAutoChoice = autoChoiceID and {
        categoryID = categoryID,
        choiceID = autoChoiceID,
    } or nil
    local sent, reason = sendRequest(PNC.Const.CMD_CONVERSATION_CATEGORY_REQUEST, {
        requestID = id,
        npcID = tostring(npcID),
        token = lifecycle.token,
        categoryID = categoryID,
        registryFingerprint = Registry.GetFingerprint(),
    })
    if not sent then
        view.spec.context.pendingConversationRequest = nil
        view.spec.context.pendingConversationAutoChoice = nil
        notifyFailure(view, "status.block_unavailable", reason)
    end
    return sent, reason
end

function Composer.RequestChoice(npcID, blockID, nodeID, choiceID)
    local view = activeView(npcID)
    local lifecycle = lifecycleState(view)
    if not view then return false, "conversation_not_ready" end
    if not lifecycle then
        notifyFailure(view, "status.choice_rejected", "conversation_not_ready")
        return false, "conversation_not_ready"
    end
    local id = requestID("choice")
    view.spec.context.pendingConversationRequest = id
    local sent, reason = sendRequest(PNC.Const.CMD_CONVERSATION_CHOICE_REQUEST, {
        requestID = id,
        npcID = tostring(npcID),
        token = lifecycle.token,
        blockID = blockID,
        nodeID = nodeID,
        choiceID = choiceID,
        registryFingerprint = Registry.GetFingerprint(),
    })
    if not sent then
        view.spec.context.pendingConversationRequest = nil
        notifyFailure(view, "status.choice_rejected", reason)
    end
    return sent, reason
end

function Composer.RequestRecruit(npcID)
    local view = activeView(npcID)
    local lifecycle = lifecycleState(view)
    if not view then return false, "conversation_not_ready" end
    if not lifecycle then
        notifyFailure(view, "status.choice_rejected", "conversation_not_ready")
        return false, "conversation_not_ready"
    end
    local id = requestID("recruit")
    view.spec.context.pendingConversationRequest = id
    local sent, reason = sendRequest(
        PNC.Const.CMD_CONVERSATION_RECRUIT_REQUEST,
        {
            requestID = id,
            npcID = tostring(npcID),
            token = lifecycle.token,
            registryFingerprint = Registry.GetFingerprint(),
        }
    )
    if not sent then
        view.spec.context.pendingConversationRequest = nil
        notifyFailure(view, "status.choice_rejected", reason)
    end
    return sent, reason
end

local function lockedText(block, choice, reason, context)
    local key = choice.lockedReasonKey or reason
    if not key then
        return dialoguePayload(block.textSource, choice.textKey, context)
    end
    local text = PsychopatzCore.Conversation.Text
    local label = text.Resolve(dialoguePayload(
        block.textSource, choice.textKey, context
    ))
    local explanation = text.Resolve(dialoguePayload(
        block.textSource, key, context
    ))
    return { text = label .. " (" .. explanation .. ")" }
end

function Composer.BuildBlockNode(block, nodeID, context)
    local node = block.nodes[nodeID]
    if not node then return nil end
    local choices = {}
    for _, choice in ipairs(node.choices or {}) do
        local passed, reason = Selector.IsChoiceEligible(
            block, nodeID, choice, context
        )
        local mode = choice.lockedMode or "hidden"
        if passed or mode == "disabled" then
            local selectedChoice = choice
            choices[#choices + 1] = {
                id = selectedChoice.id,
                text = passed
                    and dialoguePayload(
                        block.textSource,
                        selectedChoice.textKey,
                        context
                    )
                    or lockedText(block, selectedChoice, reason, context),
                enabled = passed,
                action = passed and function()
                    Composer.RequestChoice(
                        context.npcID,
                        block.id,
                        nodeID,
                        selectedChoice.id
                    )
                end or nil,
            }
        end
    end
    return {
        npc = dialoguePayload(
            block.textSource,
            selectedTextKey(block, nodeID, node, context),
            context
        ),
        choices = choices,
    }
end

function Composer.AttachBlock(spec, block, context)
    local valid, errors = ensureBlockText(block)
    if not valid then return false, errors end
    spec.context.activeConversationBlockID = block.id
    for nodeID in pairs(block.nodes) do
        spec.nodes["block:" .. nodeID] = Composer.BuildBlockNode(
            block, nodeID, context
        )
    end
    return true, "block:" .. block.entryNode
end

function Composer.ReceiveBlock(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    if args.success ~= true then
        if args.reason == "once_per_day_used" and args.categoryID then
            local context = view.spec.context.conversationBlockContext
            rememberCategoryUse(context, args.categoryID)
            view.spec.nodes.menu = Composer.BuildMenuNode(
                context,
                context and context.conversationMenuOptions
            )
            if view.session and view.session.currentNodeID == "menu" then
                view.session.currentNode = view.spec.nodes.menu
            end
        end
        notifyFailure(view, "status.block_unavailable", args.reason)
        return false, args.reason
    end
    local block = Registry.GetBlock(args.blockID)
    local context = view.spec.context.conversationBlockContext
    if not block or not context then
        notifyFailure(view, "status.block_unavailable", "block_unavailable")
        return false, "block_unavailable"
    end
    local attached, nodeID = Composer.AttachBlock(view.spec, block, context)
    if not attached then
        notifyFailure(view, "status.block_unavailable", nodeID)
        return false, nodeID
    end
    local automatic = view.spec.context.pendingConversationAutoChoice
    view.spec.context.pendingConversationAutoChoice = nil
    if automatic and automatic.categoryID == args.categoryID then
        return Composer.RequestChoice(
            args.npcID,
            block.id,
            args.nodeID or block.entryNode,
            automatic.choiceID
        )
    end
    view.session.spec = view.spec
    view.session:enterNode("block:" .. tostring(args.nodeID or block.entryNode))
    return true
end

function Composer.ReceiveOutcome(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    local session = view.session
    if args.success ~= true then
        notifyFailure(view, "status.choice_rejected", args.reason)
        return false, args.reason
    end
    local block = Registry.GetBlock(args.blockID)
    if not block or not session then
        notifyFailure(view, "status.choice_rejected", "block_unavailable")
        return false, "block_unavailable"
    end
    local context = view.spec.context.conversationBlockContext
    rememberCategoryUse(context, block.category, args.outcomeID)
    local clientState = PNC.Network and PNC.Network.ClientState
    if args.relationshipDelta and clientState then
        clientState.lastConversationDelta = {
            npcID = args.npcID,
            source = "conversation",
            blockID = args.blockID,
            choiceID = args.choiceID,
            outcomeID = args.outcomeID,
            delta = args.relationshipDelta,
            before = args.relationshipBefore,
            after = args.relationshipAfter,
            effects = args.effectResults,
            at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        }
    end
    if args.responseKey then
        session:queueMessage("npc", dialoguePayload(
            block.textSource,
            args.responseKey,
            context
        ))
    end
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(table.concat({
            "Conversation outcome",
            "npc=" .. tostring(args.npcID or "unknown"),
            "block=" .. tostring(args.blockID or "unknown"),
            "choice=" .. tostring(args.choiceID or "unknown"),
            "outcome=" .. tostring(args.outcomeID or "unknown"),
            "next=" .. tostring(args.nextNodeID or "none"),
            "close=" .. tostring(args.close == true),
            "reason=" .. tostring(args.closeReason or "continued"),
        }, " "))
    end
    session.pendingClose = args.close == true
    session.pendingCloseReason = args.closeReason
    if args.nextNodeID == "$root" then
        if context.giftConversationActive
            and PNC.InventoryWindow
            and PNC.InventoryWindow.Close
        then
            PNC.InventoryWindow.Close()
            context.giftConversationActive = nil
        end
        view.spec.nodes.menu = Composer.BuildMenuNode(
            context,
            context.conversationMenuOptions
        )
        session.pendingNext = "menu"
    else
        session.pendingNext = args.nextNodeID
            and "block:" .. tostring(args.nextNodeID) or nil
        if args.nextNodeID == "gift"
            and PNC.InventoryWindow
            and PNC.InventoryWindow.Open
        then
            local lifecycle = lifecycleState(view)
            context.giftConversationActive = true
            PNC.InventoryWindow.Open(args.npcID, {
                mode = "gift",
                token = lifecycle and lifecycle.token,
            })
        end
    end
    if #session.queue == 0 then session:finishPending() end
    return true
end

function Composer.ReceiveRecruitOutcome(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    if args.success ~= true then
        local state = PNC.Network and PNC.Network.ClientState
        if state and args.relationshipDelta then
            state.lastConversationDelta = {
                npcID = args.npcID,
                source = "recruitment_rejected",
                delta = args.relationshipDelta,
                before = args.relationshipBefore,
                after = args.relationshipAfter,
                at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
            }
        end
        view.spec.context.lastConversationError = tostring(
            args.reason or "recruitment_rejected"
        )
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("Conversation recruitment rejected npc="
                .. tostring(args.npcID or "unknown") .. " reason="
                .. tostring(args.reason or "unknown"))
        end
        local session = view.session
        local context = view.spec.context.conversationBlockContext
        if session and args.responseKey then
            session:queueMessage("npc", dialoguePayload(
                SYSTEM_SOURCE,
                args.responseKey,
                context,
                { route = args.route or "none" }
            ))
            view.spec.nodes.menu = Composer.BuildMenuNode(
                context,
                context and context.conversationMenuOptions
            )
            session.pendingClose = false
            session.pendingCloseReason = nil
            session.pendingNext = "menu"
            if #session.queue == 0 then session:finishPending() end
        else
            notifyFailure(view, "status.choice_rejected", args.reason)
        end
        return false, args.reason
    end
    local context = view.spec.context.conversationBlockContext
    view.spec.context.lastConversationRecruitment = {
        route = args.route,
        relationship = args.relationship,
        reason = args.reason,
    }
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("Conversation recruitment committed npc="
            .. tostring(args.npcID or "unknown") .. " route="
            .. tostring(args.route or "unknown"))
    end
    local session = view.session
    if session then
        session:queueMessage("npc", dialoguePayload(
            SYSTEM_SOURCE, args.responseKey or "response.recruit.admire.1", context,
            { route = args.route or "admire" }
        ))
        session.pendingClose = true
        session.pendingCloseReason = args.closeReason or "recruited"
        if #session.queue == 0 then session:finishPending() end
    end
    return true
end

function Composer.ReceiveGiftResult(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcId)
    if not view then return false end
    local context = view.spec and view.spec.context
        and view.spec.context.conversationBlockContext or nil
    local state = PNC.Network and PNC.Network.ClientState
    if args.relationshipDelta and state then
        state.lastConversationDelta = {
            npcID = args.npcId,
            source = "gift",
            delta = args.relationshipDelta,
            before = args.relationshipBefore,
            after = args.relationshipAfter,
            effects = args.giftEffect,
            itemTypes = args.itemTypes,
            at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        }
    end
    if args.success ~= true then
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("Conversation gift rejected npc="
                .. tostring(args.npcId or "unknown") .. " reason="
                .. tostring(args.reason or "unknown"))
        end
        return false, args.reason
    end
    if context then
        context.lastGift = {
            itemTypes = args.itemTypes,
            relationshipDelta = args.relationshipDelta,
            effect = args.giftEffect,
        }
        context.giftConversationActive = nil
    end
    if PNC.InventoryWindow and PNC.InventoryWindow.Close then
        PNC.InventoryWindow.Close()
    end
    local activeBlock = context and context.activeConversationBlockID
        and Registry.GetBlock(context.activeConversationBlockID) or nil
    if view.session and activeBlock and args.giftReplyKey then
        view.session:append("npc", dialoguePayload(
            activeBlock.textSource,
            args.giftReplyKey,
            context
        ))
    end
    -- The authored gift node is already the next node of the conversation.
    -- Closing the modal reveals it; do not reroll or append a second response.
    if view.session and view.session.currentNodeID ~= "block:gift"
        and #view.session.queue == 0
        and view.session.finishPending
    then
        view.session.pendingNext = "block:gift"
        view.session:finishPending()
    end
    return true
end

local function categoryChoices(context)
    local choices = {}
    for _, category in ipairs(Registry.ListCategories()) do
        local categoryEligible = Selector.IsCategoryEligible(
            category.id, context, false
        )
        if categoryEligible then
            local categoryTextValid = Loader.EnsureSource(
                category.textSource,
                { category.labelKey }
            )
            local selected = Selector.SelectBlock(category.id, context)
            local textValid = selected and ensureBlockText(selected)
            if selected and textValid and categoryTextValid then
                local selectedCategory = category
                choices[#choices + 1] = {
                    id = selectedCategory.id,
                    text = payload(
                        selectedCategory.textSource,
                        selectedCategory.labelKey
                    ),
                    -- Ask About is a topic browser and stays out of the
                    -- transcript; ordinary categories are player lines so
                    -- the NPC never appears to start a one-sided exchange.
                    log = selectedCategory.id
                        ~= "projecthoomans:ask_about",
                    action = function()
                        Composer.RequestCategory(context.npcID, selectedCategory.id)
                    end,
                }
            end
        end
    end
    return choices
end

function Composer.BuildGreeting(context)
    local categoryEligible = Selector.IsCategoryEligible(
        "projecthoomans:greetings", context, true
    )
    if not categoryEligible then return nil, "greeting_category_unavailable" end
    local block = Selector.SelectBlock("projecthoomans:greetings", context)
    if not block then return nil, "no_greeting" end
    local valid, reason = ensureBlockText(block)
    if not valid then return nil, reason end
    local node = block.nodes[block.entryNode]
    return dialoguePayload(
        block.textSource,
        selectedTextKey(block, block.entryNode, node, context),
        context
    ), block
end

function Composer.BuildRootNode(context, options)
    options = type(options) == "table" and options or {}
    local greeting, greetingBlock = Composer.BuildGreeting(context)
    local choices = {}
    if context.audiences.hostile then
        local choice = greetingBlock and greetingBlock.nodes.opening
            and greetingBlock.nodes.opening.choices[1] or nil
        if choice then
            choices[#choices + 1] = {
                id = "ceasefire",
                text = dialoguePayload(
                    greetingBlock.textSource,
                    choice.textKey,
                    context
                ),
                action = function()
                    Composer.RequestCategory(
                        context.npcID,
                        "projecthoomans:greetings",
                        choice.id
                    )
                end,
            }
        end
    else
        choices = categoryChoices(context)
        if options.askNameChoice then
            table.insert(choices, 1, options.askNameChoice)
        end
        if options.dossierChoice then choices[#choices + 1] = options.dossierChoice end
        local record = context.npcRecord or {}
        if record.recruited ~= true
            and tostring(record.faction or "") ~= "hostile"
        then
            choices[#choices + 1] = {
                id = "recruit",
                text = dialoguePayload(
                    SYSTEM_SOURCE, "choice.recruit", context
                ),
                action = function()
                    Composer.RequestRecruit(context.npcID)
                end,
            }
        end
    end
    local requiredSystemKeys = {
        "status.block_unavailable", "status.choice_rejected",
    }
    for _, key in ipairs(RECRUIT_SYSTEM_KEYS) do
        requiredSystemKeys[#requiredSystemKeys + 1] = key
    end
    Loader.EnsureSource(SYSTEM_SOURCE, requiredSystemKeys)
    local goodbyeValid = Loader.EnsureSource(GOODBYE_SOURCE, {
        "choice.goodbye", "response.goodbye",
    })
    if not goodbyeValid then return { npc = greeting, choices = choices } end
    choices[#choices + 1] = {
        id = "goodbye",
        text = dialoguePayload(
            GOODBYE_SOURCE, "choice.goodbye", context
        ),
        response = dialoguePayload(
            GOODBYE_SOURCE, "response.goodbye", context
        ),
        close = true,
        closeReason = "goodbye",
    }
    return { npc = greeting, choices = choices }
end

function Composer.BuildMenuNode(context, options)
    local node = Composer.BuildRootNode(context, options)
    node.npc = nil
    return node
end

return Composer
