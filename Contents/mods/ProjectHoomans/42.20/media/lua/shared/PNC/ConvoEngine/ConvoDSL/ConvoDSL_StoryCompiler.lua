-- Runtime compiler for declarative `.convo` branching `story` / `extend story` blocks.
-- Registers node response pools into ResponseCatalog and compiles the story graph
-- directly into FlowRegistry (zero offline codebuilder needed).

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Compiler = {}
Compiler._definitions = {}
Compiler.Metadata = {}

local WEATHER_FIELDS = {
    raining = true,
    foggy = true,
    snowing = true,
}

local function compileGate(gate)
    local gateType = WEATHER_FIELDS[gate.luaKey] and "pnc:weather" or "pnc:context"
    local field = gate.luaKey
    return {
        type = gateType,
        field = field,
        operator = "==",
        value = gate.expected,
        passReasonKey = field .. "_pass",
        failReasonKey = field .. "_fail",
        unknownReasonKey = field .. "_unknown",
    }
end

local function buildChoiceFrame(choice)
    local intent = (choice.intent and choice.intent ~= "") and choice.intent or "INFORM"
    local frame = {
        intent = intent,
        speechAct = intent,
    }
    if choice.action and choice.action ~= "" then
        frame.action = choice.action
    end
    if choice.subject and choice.subject ~= "" then
        frame.subject = choice.subject
    end
    if choice.stateValue and choice.stateValue ~= "" then
        frame.stateValue = choice.stateValue
    end
    return frame
end

local function frameSignature(frame)
    return tostring(frame.intent or "") .. "|" .. tostring(frame.speechAct or "")
        .. "|" .. tostring(frame.action or "") .. "|" .. tostring(frame.subject or "")
        .. "|" .. tostring(frame.stateValue or "")
end

local function buildOfferFromChoice(storyID, choice)
    local fullID = string.find(choice.offerID, ".", 1, true)
        and choice.offerID or (storyID .. "." .. choice.offerID)
    local frame = buildChoiceFrame(choice)
    return {
        id = fullID,
        labelKey = fullID .. ".label",
        labelFallback = choice.label ~= "" and choice.label or fullID,
        utteranceKey = fullID .. ".say",
        utteranceFallback = choice.say ~= "" and choice.say or choice.label,
        consumers = { "participant" },
        frame = frame,
    }, frame
end

local function registerNodePool(Catalog, script, storyID, node, isExtend)
    if not Catalog or type(Catalog.Register) ~= "function" then return nil end
    if #(node.variants or {}) == 0 then return node.responsePool end

    local poolID = node.responsePool or ("story." .. storyID .. "." .. node.nodeID)
    local variants = {}
    for i = 1, #node.variants do
        local var = node.variants[i]
        local vid = poolID .. "." .. var.variantID
        local tid = script.namespace .. "." .. poolID .. "." .. var.variantID
        variants[i] = {
            id = vid,
            templateID = tid,
            fallback = var.fallback,
            when = var.when,
            priority = var.priority or 6,
            hasTokens = string.find(var.fallback, "{", 1, true) ~= nil,
            theme = var.theme,
        }
    end

    if isExtend and type(Catalog.Get) == "function" and Catalog.Get(poolID) ~= nil
        and type(Catalog.Extend) == "function"
    then
        Catalog.Extend(poolID, { variants = variants })
    else
        Catalog.Register(poolID, { variants = variants })
    end
    return poolID
end

local function mergeNodeInto(existingNode, incomingNode, storyID, meta, blueprintRawByID)
    existingNode.terminal = incomingNode.terminal or existingNode.terminal == true
    if incomingNode.responsePool then
        existingNode.responsePool = incomingNode.responsePool
    end
    if incomingNode.gate then
        existingNode.gate = compileGate(incomingNode.gate)
        existingNode.onPass = incomingNode.gate.onPass
        existingNode.onFail = incomingNode.gate.onFail
        existingNode.onUnknown = incomingNode.gate.onUnknown
    end

    local allChoices = {}
    for i = 1, #(incomingNode.choices or {}) do
        allChoices[#allChoices + 1] = incomingNode.choices[i]
    end
    if type(blueprintRawByID) == "table" then
        for i = 1, #(incomingNode.uses or {}) do
            local bpOffers = blueprintRawByID[incomingNode.uses[i]]
            if type(bpOffers) == "table" then
                for j = 1, #bpOffers do
                    allChoices[#allChoices + 1] = bpOffers[j]
                end
            end
        end
    end

    if #allChoices > 0 then
        existingNode.branchOffers = existingNode.branchOffers or {}
        existingNode.accepts = existingNode.accepts or {}
        local seenOffer = {}
        for i = 1, #existingNode.branchOffers do
            seenOffer[existingNode.branchOffers[i].id] = true
        end
        local seenFrame = {}
        for i = 1, #existingNode.accepts do
            seenFrame[frameSignature(existingNode.accepts[i])] = true
        end

        for i = 1, #allChoices do
            local ch = allChoices[i]
            local offer, frame = buildOfferFromChoice(storyID, ch)
            if not seenOffer[offer.id] then
                seenOffer[offer.id] = true
                existingNode.branchOffers[#existingNode.branchOffers + 1] = offer
            end
            local sig = frameSignature(frame)
            if not seenFrame[sig] then
                seenFrame[sig] = true
                existingNode.accepts[#existingNode.accepts + 1] = frame
            end
            if ch.target and ch.target ~= "" then
                existingNode.choiceTargets = existingNode.choiceTargets or {}
                existingNode.choiceTargets[offer.id] = ch.target
                meta.choiceTargets[existingNode.id .. ":" .. offer.id] = ch.target
                if frame.intent == "REFUSE" then
                    existingNode.onRefuse = existingNode.onRefuse or ch.target
                elseif (frame.intent == "QUESTION" or frame.intent == "CLARIFY")
                    and not existingNode.onClarify
                then
                    existingNode.onClarify = ch.target
                else
                    existingNode.onMatch = existingNode.onMatch or ch.target
                end
            end
        end
    end

    for trKey, trVal in pairs(incomingNode.transitions or {}) do
        existingNode[trKey] = trVal
    end
    if not existingNode.terminal and not existingNode.gate
        and existingNode.onUnrelated == nil
    then
        existingNode.onUnrelated = "suspend"
    end

    if #(incomingNode.recommends or {}) > 0 then
        meta.recommends[existingNode.id] = meta.recommends[existingNode.id] or {}
        local list = meta.recommends[existingNode.id]
        for i = 1, #incomingNode.recommends do
            list[#list + 1] = incomingNode.recommends[i]
        end
    end
end

function Compiler.ApplyStories(scripts, blueprintRawByID)
    local Catalog = PNC.ConvoEngine.ResponseCatalog
    local FlowRegistry = PNC.ConvoEngine.DialogueFlowRegistry
    if type(FlowRegistry) ~= "table" and type(require) == "function" then
        local ok, loaded = pcall(require, "PNC/ConvoEngine/Dialogue/FlowRegistry")
        if ok and type(loaded) == "table" then FlowRegistry = loaded end
    end

    local storyCount = 0
    local extendedCount = 0
    local errors = {}

    for sIdx = 1, #scripts do
        local script = scripts[sIdx]
        for i = 1, #(script.stories or {}) do
            local st = script.stories[i]
            local isExtend = st.mode == "extend"
            local def = isExtend and Compiler._definitions[st.storyID] or nil
            local meta = Compiler.Metadata[st.storyID]
            if not def then
                def = {
                    id = st.storyID,
                    version = 1,
                    owner = script.pack or "ProjectHoomans",
                    triggers = {},
                    initial = st.initial,
                    nodes = {},
                }
                meta = {
                    guards = {},
                    choiceTargets = {},
                    recommends = {},
                }
            end

            for tIdx = 1, #(st.triggers or {}) do
                def.triggers[#def.triggers + 1] = st.triggers[tIdx]
            end
            for gIdx = 1, #(st.guards or {}) do
                meta.guards[#meta.guards + 1] = st.guards[gIdx]
            end
            if st.initial and st.initial ~= "" then
                def.initial = st.initial
            end

            for nIdx = 1, #(st.nodes or {}) do
                local node = st.nodes[nIdx]
                local poolID = registerNodePool(Catalog, script, st.storyID, node, isExtend)
                node.responsePool = poolID
                local targetNode = def.nodes[node.nodeID]
                if not targetNode then
                    targetNode = { id = node.nodeID, terminal = node.terminal == true }
                    def.nodes[node.nodeID] = targetNode
                end
                if not def.initial then
                    def.initial = node.nodeID
                end
                mergeNodeInto(targetNode, node, st.storyID, meta, blueprintRawByID)
            end

            Compiler._definitions[st.storyID] = def
            Compiler.Metadata[st.storyID] = meta

            if FlowRegistry and type(FlowRegistry.UpsertStory) == "function" then
                local ok, res = FlowRegistry.UpsertStory(def)
                if not ok then
                    errors[#errors + 1] = tostring(script.sourcePath) .. ":" .. tostring(st.lineNo)
                        .. ": story '" .. st.storyID .. "' invalid (" .. tostring(res) .. ")"
                elseif isExtend then
                    extendedCount = extendedCount + 1
                else
                    storyCount = storyCount + 1
                end
            end
        end
    end

    return storyCount, extendedCount, errors
end

function Compiler.Reset()
    for k in pairs(Compiler._definitions) do
        Compiler._definitions[k] = nil
    end
    for k in pairs(Compiler.Metadata) do
        Compiler.Metadata[k] = nil
    end
end

return Compiler
