-- Pure Lua 5.1 / Kahlua2 line-by-line streaming parser for .convo packs.
-- Supports: namespace, lang, theme, pack, lex/extend lex, blueprint/extend blueprint,
-- pool/beat/flow/extend, multi-line `say` variants, ` >> ` multi-turn plans,
-- and declarative branching `story` / `extend story` graphs.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Schema = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL_Schema"

local Parser = {}

local OFFER_KV_KEYS = {
    label = true,
    say = true,
    intent = true,
    subject = true,
    action = true,
    claim = true,
    style = true,
    utility = true,
    when = true,
    stateValue = true,
}

local NODE_TRANSITION_KEYS = {
    on_match = "onMatch",
    on_clarify = "onClarify",
    on_refuse = "onRefuse",
    on_unrelated = "onUnrelated",
    next = "next",
}

local function trim(s)
    return string.match(tostring(s or ""), "^%s*(.-)%s*$") or ""
end

local function unescapeQuoted(s)
    s = string.gsub(s, '\\"', '"')
    s = string.gsub(s, "\\n", "\n")
    s = string.gsub(s, "\\r", "\r")
    s = string.gsub(s, "\\\\", "\\")
    return s
end

local function stripQuotes(raw)
    local s = trim(raw)
    local len = #s
    if len >= 2 and string.sub(s, 1, 1) == '"' and string.sub(s, len, len) == '"' then
        return unescapeQuoted(string.sub(s, 2, len - 1))
    end
    return s
end

local function parsePredicates(rawPreds, source, lineNo)
    if not rawPreds then return nil, nil end
    local trimmed = trim(rawPreds)
    if trimmed == "" or trimmed == "default" then return nil, nil end

    local out = nil
    local pos = 1
    while true do
        local comma = string.find(trimmed, ",", pos, true)
        local token
        if comma then
            token = trim(string.sub(trimmed, pos, comma - 1))
            pos = comma + 1
        else
            token = trim(string.sub(trimmed, pos))
        end
        if token ~= "" and token ~= "default" then
            local luaKey, val, err = Schema.ResolvePredicate(token, source, lineNo)
            if err then return nil, err end
            out = out or {}
            out[luaKey] = val
        end
        if not comma then break end
    end
    return out, nil
end

local function parseFrameExpr(rawExpr, source, lineNo)
    local trimmed = trim(rawExpr)
    if trimmed == "" then
        return nil, tostring(source) .. ":" .. tostring(lineNo) .. ": empty trigger frame"
    end
    local frame = {}
    local pos = 1
    while true do
        local comma = string.find(trimmed, ",", pos, true)
        local token
        if comma then
            token = trim(string.sub(trimmed, pos, comma - 1))
            pos = comma + 1
        else
            token = trim(string.sub(trimmed, pos))
        end
        if token ~= "" then
            local eq = string.find(token, "=", 1, true)
            if not eq then
                return nil, tostring(source) .. ":" .. tostring(lineNo)
                    .. ": trigger expects key=value, got '" .. token .. "'"
            end
            local k = trim(string.sub(token, 1, eq - 1))
            local v = stripQuotes(string.sub(token, eq + 1))
            if v == "true" then v = true
            elseif v == "false" then v = false
            end
            frame[k] = v
        end
        if not comma then break end
    end
    return frame, nil
end

local function parseWordList(raw, source, lineNo)
    local words = {}
    local parts = {}
    local buf = {}
    local inQuotes = false
    local escaped = false
    local len = #raw

    for i = 1, len do
        local ch = string.sub(raw, i, i)
        if escaped then
            buf[#buf + 1] = ch
            escaped = false
        elseif ch == "\\" and inQuotes then
            buf[#buf + 1] = ch
            escaped = true
        elseif ch == '"' then
            inQuotes = not inQuotes
            buf[#buf + 1] = ch
        elseif ch == "|" and not inQuotes then
            parts[#parts + 1] = table.concat(buf)
            buf = {}
        else
            buf[#buf + 1] = ch
        end
    end
    parts[#parts + 1] = table.concat(buf)

    for i = 1, #parts do
        local p = trim(parts[i])
        local plen = #p
        if not (plen >= 2 and string.sub(p, 1, 1) == '"' and string.sub(p, plen, plen) == '"') then
            return nil, tostring(source) .. ":" .. tostring(lineNo)
                .. ": expected quoted string in lex list, got '" .. p .. "'"
        end
        words[#words + 1] = unescapeQuoted(string.sub(p, 2, plen - 1))
    end
    if #words == 0 then
        return nil, tostring(source) .. ":" .. tostring(lineNo) .. ": empty lex word list"
    end
    return words, nil
end

local function parseLexEntry(stripped, source, lineNo)
    local rest = stripped
    local rawPreds = nil
    local pri = 6

    if string.sub(rest, 1, 1) == "[" then
        local closeBracket = string.find(rest, "]", 2, true)
        if not closeBracket then return nil, nil, nil, false end
        rawPreds = string.sub(rest, 2, closeBracket - 1)
        rest = trim(string.sub(rest, closeBracket + 1))
    end

    local priStr, afterPri = string.match(rest, "^%(priority%s+(%d+)%)%s*(.*)$")
    if not priStr then
        priStr, afterPri = string.match(rest, "^%(pri%s+(%d+)%)%s*(.*)$")
    end
    if priStr then
        pri = tonumber(priStr) or 6
        rest = afterPri
    end

    local rawWords = string.match(rest, "^:%s*(.+)$")
    if not rawWords then return nil, nil, nil, false end

    local when, err = parsePredicates(rawPreds, source, lineNo)
    if err then return nil, nil, nil, err end
    local words, wErr = parseWordList(rawWords, source, lineNo)
    if wErr then return nil, nil, nil, wErr end
    return words, when, pri, nil
end

local function parseSayLine(stripped, source, lineNo)
    local rest = string.match(stripped, "^say(.*)$")
    if not rest then return nil, false end
    local firstChar = string.sub(rest, 1, 1)
    if firstChar ~= "" and firstChar ~= " " and firstChar ~= "\t" and firstChar ~= ":" then
        return nil, false
    end
    rest = trim(rest)

    local rawPreds = nil
    local pri = 6
    local explicitID = nil

    if string.sub(rest, 1, 1) == "[" then
        local closeBracket = string.find(rest, "]", 2, true)
        if not closeBracket then return nil, false end
        rawPreds = string.sub(rest, 2, closeBracket - 1)
        rest = trim(string.sub(rest, closeBracket + 1))
    end

    local priStr, afterPri = string.match(rest, "^%(priority%s+(%d+)%)%s*(.*)$")
    if not priStr then
        priStr, afterPri = string.match(rest, "^%(pri%s+(%d+)%)%s*(.*)$")
    end
    if priStr then
        pri = tonumber(priStr) or 6
        rest = afterPri
    end

    local idStr, afterID = string.match(rest, "^as%s+([%w_%.%-]+)%s*(.*)$")
    if idStr then
        explicitID = idStr
        rest = afterID
    end

    if string.sub(rest, 1, 1) ~= ":" then
        return nil, false
    end
    local tail = trim(string.sub(rest, 2))
    local inlineText = nil
    if tail ~= "" then
        local tlen = #tail
        if not (tlen >= 2 and string.sub(tail, 1, 1) == '"' and string.sub(tail, tlen, tlen) == '"') then
            return nil, false
        end
        inlineText = unescapeQuoted(string.sub(tail, 2, tlen - 1))
    end

    local when, err = parsePredicates(rawPreds, source, lineNo)
    if err then return nil, err end

    return {
        when = when,
        priority = pri,
        explicitID = explicitID,
        inlineText = inlineText,
        lineNo = lineNo,
    }, nil
end

local function parseGateLine(stripped, source, lineNo)
    local rawPred, rawTargets = string.match(stripped, "^gate%s+%[([^%]]+)%]%s*%->%s*(.+)$")
    if not rawPred or not rawTargets then return nil, false end
    local luaKey, expected, err = Schema.ResolvePredicate(rawPred, source, lineNo)
    if err then return nil, err end

    local targets = {}
    local pos = 1
    while true do
        local bar = string.find(rawTargets, "|", pos, true)
        if not bar then
            targets[#targets + 1] = trim(string.sub(rawTargets, pos))
            break
        end
        targets[#targets + 1] = trim(string.sub(rawTargets, pos, bar - 1))
        pos = bar + 1
    end
    if #targets < 2 or targets[1] == "" or targets[2] == "" then
        return nil, tostring(source) .. ":" .. tostring(lineNo)
            .. ": gate requires '-> pass_node | fail_node [| unknown_node]'"
    end
    return {
        rawPred = trim(rawPred),
        luaKey = luaKey,
        expected = expected,
        onPass = targets[1],
        onFail = targets[2],
        onUnknown = targets[3] and targets[3] ~= "" and targets[3] or targets[2],
        lineNo = lineNo,
    }, nil
end

local function autoVariantID(targetContainer, explicitID, repeatIndex)
    if explicitID and explicitID ~= "" then
        if repeatIndex and repeatIndex > 1 then
            return explicitID .. "_" .. tostring(repeatIndex)
        end
        return explicitID
    end
    local idx = #targetContainer.variants + 1
    if targetContainer.mode == "extend" then
        local scope = (targetContainer.theme and targetContainer.theme ~= "" and targetContainer.theme)
            or (targetContainer.pack and targetContainer.pack ~= "" and targetContainer.pack)
            or nil
        if scope then
            return scope .. ".v" .. tostring(idx)
        end
    end
    return "v" .. tostring(idx)
end

local function matchPoolHeader(stripped)
    local kind, poolID = string.match(stripped, "^(pool)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "replace" end
    kind, poolID = string.match(stripped, "^(beat)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "replace" end
    kind, poolID = string.match(stripped, "^(flow)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "replace" end
    poolID = string.match(stripped, "^extend%s+pool%s+([%w_%.%-]+)$")
    if poolID then return "extend", poolID, "extend" end
    kind, poolID = string.match(stripped, "^(extend)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "extend" end
    return nil, nil, nil
end

function Parser.NewStream(sourcePath, defaultLang)
    local stream = {
        sourcePath = tostring(sourcePath or "<memory>"),
        namespace = "hoomans",
        language = string.upper(tostring(defaultLang or "EN")),
        theme = nil,
        pack = nil,
        lexicons = {},
        blueprints = {},
        pools = {},
        stories = {},
        lineNo = 0,
        err = nil,
        _currentLex = nil,
        _currentBlueprint = nil,
        _currentPool = nil,
        _currentStory = nil,
        _currentNode = nil,
        _currentOffer = nil,
        _activeSay = nil,
        _activeSayTarget = nil,
        _activeSayCount = 0,
    }

    local function closeActiveSay()
        if stream._activeSay ~= nil and stream._activeSayCount == 0 then
            stream.err = stream.sourcePath .. ":" .. tostring(stream._activeSay.lineNo)
                .. ": dangling 'say:' without text line"
            return false
        end
        stream._activeSay = nil
        stream._activeSayTarget = nil
        stream._activeSayCount = 0
        return true
    end

    local function resetContext()
        stream._currentLex = nil
        stream._currentBlueprint = nil
        stream._currentPool = nil
        stream._currentStory = nil
        stream._currentNode = nil
        stream._currentOffer = nil
    end

    function stream:feedLine(rawLine)
        if self.err then return false, self.err end
        self.lineNo = self.lineNo + 1
        local idx = self.lineNo
        local src = self.sourcePath
        local stripped = trim(rawLine)
        if stripped == "" or string.sub(stripped, 1, 1) == "#" then
            return true, nil
        end

        -- Consecutive quoted lines continue an active multi-line `say:` block.
        if self._activeSay ~= nil then
            local slen = #stripped
            if slen >= 2 and string.sub(stripped, 1, 1) == '"'
                and string.sub(stripped, slen, slen) == '"'
            then
                self._activeSayCount = self._activeSayCount + 1
                local target = self._activeSayTarget
                local ps = self._activeSay
                target.variants[#target.variants + 1] = {
                    variantID = autoVariantID(target, ps.explicitID, self._activeSayCount),
                    fallback = unescapeQuoted(string.sub(stripped, 2, slen - 1)),
                    when = ps.when,
                    priority = ps.priority,
                    theme = target.theme or self.theme,
                    lineNo = idx,
                }
                return true, nil
            end
            if not closeActiveSay() then
                return false, self.err
            end
        end

        local nsVal = string.match(stripped, "^namespace%s+(.+)$")
        if nsVal then
            nsVal = trim(nsVal)
            if not string.match(nsVal, "^[%w_%.%-]+$") then
                self.err = src .. ":" .. tostring(idx) .. ": invalid namespace '" .. nsVal .. "'"
                return false, self.err
            end
            self.namespace = nsVal
            return true, nil
        end

        local langVal = string.match(stripped, "^language%s+(.+)$")
            or string.match(stripped, "^lang%s+(.+)$")
        if langVal then
            langVal = string.upper(trim(langVal))
            if not string.match(langVal, "^%u%u%u?%u?%u?%u?%u?%u?$") then
                self.err = src .. ":" .. tostring(idx) .. ": invalid language '" .. langVal .. "'"
                return false, self.err
            end
            self.language = langVal
            return true, nil
        end

        local themeVal = string.match(stripped, "^theme%s+(.+)$")
        if themeVal then
            themeVal = trim(themeVal)
            if not string.match(themeVal, "^[%w_%.%-]+$") then
                self.err = src .. ":" .. tostring(idx) .. ": invalid theme '" .. themeVal .. "'"
                return false, self.err
            end
            self.theme = themeVal
            return true, nil
        end

        local packVal = string.match(stripped, "^pack%s+(.+)$")
        if packVal then
            packVal = trim(packVal)
            if not string.match(packVal, "^[%w_%.%-]+$") then
                self.err = src .. ":" .. tostring(idx) .. ": invalid pack '" .. packVal .. "'"
                return false, self.err
            end
            self.pack = packVal
            return true, nil
        end

        -- Top-level story / extend story headers
        local extendStoryID = string.match(stripped, "^extend%s+story%s+([%w_%.%-]+)$")
        if extendStoryID then
            resetContext()
            self._currentStory = {
                storyID = extendStoryID,
                mode = "extend",
                triggers = {},
                guards = {},
                initial = nil,
                nodes = {},
                theme = self.theme,
                pack = self.pack,
                lineNo = idx,
            }
            self.stories[#self.stories + 1] = self._currentStory
            return true, nil
        end

        local storyID = string.match(stripped, "^story%s+([%w_%.%-]+)$")
        if storyID then
            resetContext()
            self._currentStory = {
                storyID = storyID,
                mode = "replace",
                triggers = {},
                guards = {},
                initial = nil,
                nodes = {},
                theme = self.theme,
                pack = self.pack,
                lineNo = idx,
            }
            self.stories[#self.stories + 1] = self._currentStory
            return true, nil
        end

        local extendLexID = string.match(stripped, "^extend%s+lexicon%s+([%w_%.%-]+)$")
            or string.match(stripped, "^extend%s+lex%s+([%w_%.%-]+)$")
        if extendLexID then
            resetContext()
            self._currentLex = { lexID = extendLexID, mode = "extend", entries = {}, lineNo = idx }
            self.lexicons[#self.lexicons + 1] = self._currentLex
            return true, nil
        end

        local lexID = string.match(stripped, "^lexicon%s+([%w_%.%-]+)$")
            or string.match(stripped, "^lex%s+([%w_%.%-]+)$")
        if lexID then
            resetContext()
            self._currentLex = { lexID = lexID, mode = "replace", entries = {}, lineNo = idx }
            self.lexicons[#self.lexicons + 1] = self._currentLex
            return true, nil
        end

        local extendBpID = string.match(stripped, "^extend%s+blueprint%s+([%w_%.%-]+)$")
        if extendBpID then
            resetContext()
            self._currentBlueprint = { blueprintID = extendBpID, mode = "extend", offers = {}, lineNo = idx }
            self.blueprints[#self.blueprints + 1] = self._currentBlueprint
            return true, nil
        end

        local bpID = string.match(stripped, "^blueprint%s+([%w_%.%-]+)$")
        if bpID then
            resetContext()
            self._currentBlueprint = { blueprintID = bpID, mode = "replace", offers = {}, lineNo = idx }
            self.blueprints[#self.blueprints + 1] = self._currentBlueprint
            return true, nil
        end

        -- Inside a `story` block: handle story-level and node-level statements before pool headers.
        if self._currentStory ~= nil then
            local nodeID, nodeFlags = string.match(stripped, "^node%s+([%w_%.%-]+)%s*(.*)$")
            if nodeID then
                self._currentOffer = nil
                local isTerminal = string.find(nodeFlags or "", "terminal", 1, true) ~= nil
                self._currentNode = {
                    nodeID = nodeID,
                    terminal = isTerminal,
                    responsePool = nil,
                    variants = {},
                    choices = {},
                    uses = {},
                    gate = nil,
                    recommends = {},
                    transitions = {},
                    theme = self.theme,
                    pack = self.pack,
                    mode = self._currentStory.mode,
                    lineNo = idx,
                }
                self._currentStory.nodes[#self._currentStory.nodes + 1] = self._currentNode
                return true, nil
            end

            local triggerExpr = string.match(stripped, "^trigger%s+(.+)$")
            if triggerExpr then
                local frame, fErr = parseFrameExpr(triggerExpr, src, idx)
                if fErr then self.err = fErr; return false, self.err end
                self._currentStory.triggers[#self._currentStory.triggers + 1] = frame
                return true, nil
            end

            local guardName = string.match(stripped, "^guard%s+([%w_%.%-]+)$")
            if guardName then
                self._currentStory.guards[#self._currentStory.guards + 1] = guardName
                return true, nil
            end

            local initNode = string.match(stripped, "^initial%s+([%w_%.%-]+)$")
            if initNode then
                self._currentStory.initial = initNode
                return true, nil
            end

            if self._currentNode ~= nil then
                local nodePoolRef = string.match(stripped, "^pool%s+([%w_%.%-]+)$")
                if nodePoolRef then
                    self._currentOffer = nil
                    self._currentNode.responsePool = nodePoolRef
                    return true, nil
                end

                local recID = string.match(stripped, "^recommend%s+([%w_%.%-]+)$")
                if recID then
                    self._currentOffer = nil
                    self._currentNode.recommends[#self._currentNode.recommends + 1] = recID
                    return true, nil
                end

                local useID = string.match(stripped, "^use%s+([%w_%.%-]+)$")
                if useID then
                    self._currentOffer = nil
                    self._currentNode.uses[#self._currentNode.uses + 1] = useID
                    return true, nil
                end

                local gateInfo, gateErr = parseGateLine(stripped, src, idx)
                if gateErr and gateErr ~= false then
                    self.err = gateErr; return false, self.err
                elseif gateInfo then
                    self._currentOffer = nil
                    self._currentNode.gate = gateInfo
                    return true, nil
                end

                local chID, chTarget = string.match(stripped, "^choice%s+([%w_%.%-]+)%s*%->%s*([%w_%.%-]+)%s*:$")
                if not chID then
                    chID = string.match(stripped, "^choice%s+([%w_%.%-]+)%s*:$")
                end
                if chID then
                    self._currentOffer = {
                        offerID = chID,
                        target = chTarget,
                        label = "",
                        say = "",
                        intent = "INFORM",
                        subject = "",
                        action = nil,
                        claim = nil,
                        style = nil,
                        utility = nil,
                        stateValue = nil,
                        when = nil,
                        lineNo = idx,
                    }
                    self._currentNode.choices[#self._currentNode.choices + 1] = self._currentOffer
                    return true, nil
                end

                local trKey, trVal = string.match(stripped, "^([%w_]+)%s*:%s*([%w_%.%-]+)$")
                if trKey and NODE_TRANSITION_KEYS[trKey] then
                    self._currentOffer = nil
                    self._currentNode.transitions[NODE_TRANSITION_KEYS[trKey]] = trVal
                    return true, nil
                end

                if self._currentOffer ~= nil then
                    local kvKey, kvVal = string.match(stripped, "^([%w_]+)%s*:%s*(.+)$")
                    if kvKey and OFFER_KV_KEYS[kvKey] then
                        if kvKey == "when" then
                            local inner = trim(kvVal)
                            if string.sub(inner, 1, 1) == "[" and string.sub(inner, -1) == "]" then
                                inner = string.sub(inner, 2, #inner - 1)
                            end
                            local w, wErr = parsePredicates(inner, src, idx)
                            if wErr then self.err = wErr; return false, self.err end
                            self._currentOffer.when = w
                        else
                            self._currentOffer[kvKey] = stripQuotes(kvVal)
                        end
                        return true, nil
                    end
                end

                local sayInfo, sayErr = parseSayLine(stripped, src, idx)
                if sayErr and sayErr ~= false then
                    self.err = sayErr; return false, self.err
                elseif sayInfo then
                    self._currentOffer = nil
                    if sayInfo.inlineText ~= nil then
                        local node = self._currentNode
                        node.variants[#node.variants + 1] = {
                            variantID = autoVariantID(node, sayInfo.explicitID, 1),
                            fallback = sayInfo.inlineText,
                            when = sayInfo.when,
                            priority = sayInfo.priority,
                            theme = self.theme,
                            lineNo = idx,
                        }
                    else
                        self._activeSay = sayInfo
                        self._activeSayTarget = self._currentNode
                        self._activeSayCount = 0
                    end
                    return true, nil
                end
            end
        end

        local poolKind, poolID, poolMode = matchPoolHeader(stripped)
        if poolKind and poolID then
            resetContext()
            self._currentPool = {
                kind = poolKind,
                mode = poolMode,
                poolID = poolID,
                theme = self.theme,
                pack = self.pack,
                variants = {},
                offers = {},
                uses = {},
                lineNo = idx,
            }
            self.pools[#self.pools + 1] = self._currentPool
            return true, nil
        end

        if self._currentLex ~= nil then
            local words, when, pri, lexErr = parseLexEntry(stripped, src, idx)
            if lexErr == false then
                self.err = src .. ":" .. tostring(idx) .. ": invalid lex entry '" .. stripped .. "'"
                return false, self.err
            elseif lexErr then
                self.err = lexErr
                return false, self.err
            end
            self._currentLex.entries[#self._currentLex.entries + 1] = {
                words = words,
                when = when,
                priority = pri,
                lineNo = idx,
            }
            return true, nil
        end

        if self._currentPool == nil and self._currentBlueprint == nil then
            self.err = src .. ":" .. tostring(idx)
                .. ": expected lex/blueprint/pool/beat/flow/extend/story header before '" .. stripped .. "'"
            return false, self.err
        end

        local useID = self._currentPool ~= nil and string.match(stripped, "^use%s+([%w_%.%-]+)$") or nil
        if useID then
            self._currentOffer = nil
            self._currentPool.uses[#self._currentPool.uses + 1] = useID
            return true, nil
        end

        local offerID = string.match(stripped, "^offer%s+([%w_%.%-]+)%s*:$")
        if offerID then
            self._currentOffer = {
                offerID = offerID,
                label = "",
                say = "",
                intent = "INFORM",
                subject = "",
                action = nil,
                claim = nil,
                style = nil,
                utility = nil,
                stateValue = nil,
                when = nil,
                lineNo = idx,
            }
            if self._currentBlueprint ~= nil then
                self._currentBlueprint.offers[#self._currentBlueprint.offers + 1] = self._currentOffer
            else
                self._currentPool.offers[#self._currentPool.offers + 1] = self._currentOffer
            end
            return true, nil
        end

        if self._currentOffer ~= nil then
            local kvKey, kvVal = string.match(stripped, "^([%w_]+)%s*:%s*(.+)$")
            if kvKey and OFFER_KV_KEYS[kvKey] then
                if kvKey == "when" then
                    local inner = trim(kvVal)
                    if string.sub(inner, 1, 1) == "[" and string.sub(inner, -1) == "]" then
                        inner = string.sub(inner, 2, #inner - 1)
                    end
                    local w, wErr = parsePredicates(inner, src, idx)
                    if wErr then
                        self.err = wErr
                        return false, self.err
                    end
                    self._currentOffer.when = w
                else
                    self._currentOffer[kvKey] = stripQuotes(kvVal)
                end
                return true, nil
            end
        end

        if self._currentPool == nil then
            self.err = src .. ":" .. tostring(idx) .. ": unrecognized statement '" .. stripped .. "'"
            return false, self.err
        end

        local sayInfo, sayErr = parseSayLine(stripped, src, idx)
        if sayErr == false then
            self.err = src .. ":" .. tostring(idx) .. ": unrecognized statement '" .. stripped .. "'"
            return false, self.err
        elseif sayErr then
            self.err = sayErr
            return false, self.err
        end

        self._currentOffer = nil
        if sayInfo.inlineText ~= nil then
            local pool = self._currentPool
            pool.variants[#pool.variants + 1] = {
                variantID = autoVariantID(pool, sayInfo.explicitID, 1),
                fallback = sayInfo.inlineText,
                when = sayInfo.when,
                priority = sayInfo.priority,
                theme = pool.theme,
                lineNo = idx,
            }
        else
            self._activeSay = sayInfo
            self._activeSayTarget = self._currentPool
            self._activeSayCount = 0
        end
        return true, nil
    end

    function stream:finish()
        if self.err then return nil, self.err end
        if not closeActiveSay() then return nil, self.err end
        local src = self.sourcePath

        local seenLex = {}
        for i = 1, #self.lexicons do
            local lx = self.lexicons[i]
            if lx.mode ~= "extend" then
                if seenLex[lx.lexID] then
                    return nil, src .. ":" .. tostring(lx.lineNo) .. ": duplicate lex '" .. lx.lexID .. "'"
                end
                seenLex[lx.lexID] = true
            end
            if #lx.entries == 0 then
                return nil, src .. ":" .. tostring(lx.lineNo) .. ": lex '" .. lx.lexID .. "' has no entries"
            end
        end

        local seenPools = {}
        for i = 1, #self.pools do
            local pool = self.pools[i]
            if pool.mode ~= "extend" then
                if seenPools[pool.poolID] then
                    return nil, src .. ":" .. tostring(pool.lineNo) .. ": duplicate pool '" .. pool.poolID .. "'"
                end
                seenPools[pool.poolID] = true
            end
            if #pool.variants == 0 and #pool.offers == 0 and #pool.uses == 0 then
                return nil, src .. ":" .. tostring(pool.lineNo)
                    .. ": pool '" .. pool.poolID .. "' has no 'say' variants"
            end
            local seenVars = {}
            for j = 1, #pool.variants do
                local v = pool.variants[j]
                if seenVars[v.variantID] then
                    return nil, src .. ":" .. tostring(v.lineNo)
                        .. ": duplicate variant '" .. v.variantID .. "' in pool '" .. pool.poolID .. "'"
                end
                seenVars[v.variantID] = true
            end
        end

        for i = 1, #self.stories do
            local st = self.stories[i]
            if st.mode ~= "extend" and #st.nodes == 0 then
                return nil, src .. ":" .. tostring(st.lineNo)
                    .. ": story '" .. st.storyID .. "' has no nodes"
            end
        end

        return {
            sourcePath = self.sourcePath,
            namespace = self.namespace,
            language = self.language,
            theme = self.theme,
            pack = self.pack,
            lexicons = self.lexicons,
            blueprints = self.blueprints,
            pools = self.pools,
            stories = self.stories,
        }, nil
    end

    return stream
end

function Parser.ParseText(text, sourcePath, defaultLang)
    local stream = Parser.NewStream(sourcePath, defaultLang)
    local normalized = string.gsub(tostring(text or ""), "\r\n", "\n")
    normalized = string.gsub(normalized, "\r", "\n")
    local pos = 1
    local len = #normalized
    while pos <= len do
        local nl = string.find(normalized, "\n", pos, true)
        local line
        if not nl then
            line = string.sub(normalized, pos)
            pos = len + 1
        else
            line = string.sub(normalized, pos, nl - 1)
            pos = nl + 1
        end
        local ok, err = stream:feedLine(line)
        if not ok then return nil, err end
    end
    return stream:finish()
end

return Parser
