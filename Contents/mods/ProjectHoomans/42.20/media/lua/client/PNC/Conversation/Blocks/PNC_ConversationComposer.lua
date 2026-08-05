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
    return context
end

local function payload(source, key, args)
    return Loader.Payload(source, key, args)
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
        if not sendClientCommand then return false end
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
    return false
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
        end
    end
end

function Composer.RequestCategory(npcID, categoryID, autoChoiceID)
    local view = activeView(npcID)
    local lifecycle = lifecycleState(view)
    if not view or not lifecycle then return false, "conversation_not_ready" end
    local id = requestID("category")
    view.spec.context.pendingConversationRequest = id
    view.spec.context.pendingConversationAutoChoice = autoChoiceID and {
        categoryID = categoryID,
        choiceID = autoChoiceID,
    } or nil
    return sendRequest(PNC.Const.CMD_CONVERSATION_CATEGORY_REQUEST, {
        requestID = id,
        npcID = tostring(npcID),
        token = lifecycle.token,
        categoryID = categoryID,
        registryFingerprint = Registry.GetFingerprint(),
    })
end

function Composer.RequestChoice(npcID, blockID, nodeID, choiceID)
    local view = activeView(npcID)
    local lifecycle = lifecycleState(view)
    if not view or not lifecycle then return false, "conversation_not_ready" end
    local id = requestID("choice")
    view.spec.context.pendingConversationRequest = id
    return sendRequest(PNC.Const.CMD_CONVERSATION_CHOICE_REQUEST, {
        requestID = id,
        npcID = tostring(npcID),
        token = lifecycle.token,
        blockID = blockID,
        nodeID = nodeID,
        choiceID = choiceID,
        registryFingerprint = Registry.GetFingerprint(),
    })
end

local function lockedText(block, choice, reason)
    local key = choice.lockedReasonKey or reason
    if not key then return payload(block.textSource, choice.textKey) end
    local text = PsychopatzCore.Conversation.Text
    local label = text.Resolve(payload(block.textSource, choice.textKey))
    local explanation = text.Resolve(payload(block.textSource, key))
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
                    and payload(block.textSource, selectedChoice.textKey)
                    or lockedText(block, selectedChoice, reason),
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
        npc = payload(
            block.textSource,
            selectedTextKey(block, nodeID, node, context)
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

local function restoreCurrentChoices(view)
    local session = view and view.session
    if session and session.currentNode then
        session:setChoices(session.currentNode.choices or {})
    end
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
        if view.session then
            view.session:append("npc", payload(SYSTEM_SOURCE,
                "status.block_unavailable", {
                    reason = tostring(args.reason or "unavailable"),
                }))
        end
        restoreCurrentChoices(view)
        return false, args.reason
    end
    local block = Registry.GetBlock(args.blockID)
    local context = view.spec.context.conversationBlockContext
    if not block or not context then return false, "block_unavailable" end
    local attached, nodeID = Composer.AttachBlock(view.spec, block, context)
    if not attached then return false, nodeID end
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
        if session then
            session:append("npc", payload(SYSTEM_SOURCE,
                "status.choice_rejected", {
                    reason = tostring(args.reason or "unavailable"),
                }))
        end
        restoreCurrentChoices(view)
        return false, args.reason
    end
    local block = Registry.GetBlock(args.blockID)
    if not block or not session then return false end
    if args.responseKey then
        session:queueMessage("npc", payload(block.textSource, args.responseKey))
    end
    session.pendingClose = args.close == true
    session.pendingNext = args.nextNodeID
        and "block:" .. tostring(args.nextNodeID) or nil
    if #session.queue == 0 then session:finishPending() end
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
    return payload(
        block.textSource,
        selectedTextKey(block, block.entryNode, node, context)
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
                text = payload(greetingBlock.textSource, choice.textKey),
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
    end
    Loader.EnsureSource(SYSTEM_SOURCE, {
        "status.block_unavailable", "status.choice_rejected",
    })
    local goodbyeValid = Loader.EnsureSource(GOODBYE_SOURCE, {
        "choice.goodbye", "response.goodbye",
    })
    if not goodbyeValid then return { npc = greeting, choices = choices } end
    choices[#choices + 1] = {
        id = "goodbye",
        text = payload(GOODBYE_SOURCE, "choice.goodbye"),
        response = payload(GOODBYE_SOURCE, "response.goodbye"),
        close = true,
    }
    return { npc = greeting, choices = choices }
end

return Composer
