-- Unified Conversation UI + Headless InputBox controller for Looter Tolls.
-- Replaces the legacy standalone ISPNCFactionTollWindow with ConvoDSL story
-- choices and free-text semantic input.
PNC = PNC or {}
PNC.FactionTollConversation = PNC.FactionTollConversation or {}

local TollConvo = PNC.FactionTollConversation
local Const = PNC.Const

TollConvo.ActiveDemand = TollConvo.ActiveDemand or nil

local function sendTollDecision(demandID, decision)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player or not sendClientCommand or not demandID then return false end
    local choice = tostring(decision or "leave")
    local Perf = PNC.Semantics and PNC.Semantics.SpeechPerformance or nil
    if Perf and type(Perf.PerformForPlayer) == "function" then
        local act = choice == "pay" and "ACCEPT" or (choice == "refuse" and "REFUSE" or "DEPART")
        Perf.PerformForPlayer(player, { act = act })
    end
    sendClientCommand(player, Const.MODULE, Const.CMD_FACTION_TOLL_RESPONSE, {
        demandID = demandID,
        response = choice,
    })
    TollConvo.ActiveDemand = nil
    return true
end

function TollConvo.ParseFreeTextDecision(text)
    local s = string.lower(tostring(text or ""))
    if s == "" then return nil end
    if string.find(s, "refuse", 1, true) or string.find(s, "screw", 1, true)
        or string.find(s, "fight", 1, true) or string.find(s, "come take", 1, true)
        or string.find(s, "hell", 1, true) or string.find(s, "no deal", 1, true)
        or s == "no"
    then
        return "refuse"
    end
    if string.find(s, "leave", 1, true) or string.find(s, "leaving", 1, true)
        or string.find(s, "back out", 1, true) or string.find(s, "backing out", 1, true)
        or string.find(s, "walk away", 1, true) or string.find(s, "turning around", 1, true)
        or string.find(s, "sorry", 1, true)
    then
        return "leave"
    end
    if string.find(s, "pay", 1, true) or string.find(s, "take it", 1, true)
        or string.find(s, "here", 1, true) or string.find(s, "fine", 1, true)
        or string.find(s, "deal", 1, true)
    then
        return "pay"
    end
    return nil
end

function TollConvo.SubmitDecision(decision)
    local d = TollConvo.ActiveDemand
    if not d or not d.demandID then return false end
    return sendTollDecision(d.demandID, decision)
end

function TollConvo.SubmitFreeText(text)
    local decision = TollConvo.ParseFreeTextDecision(text)
    if not decision then return false end
    return TollConvo.SubmitDecision(decision)
end

function TollConvo.BuildChoices(demand)
    demand = type(demand) == "table" and demand or {}
    local amt = tonumber(demand.amount) or 0
    local itemName = demand.itemName
    local payLabel
    if itemName and itemName ~= "" and amt > 0 then
        payLabel = "Hand over " .. tostring(itemName) .. " + $" .. tostring(amt)
    elseif itemName and itemName ~= "" then
        payLabel = "Hand over " .. tostring(itemName)
    else
        payLabel = "Pay $" .. tostring(amt)
    end
    return {
        { id = "pay", label = payLabel, intent = "ACCEPT", subject = "TOLL" },
        { id = "leave", label = "Back out of their territory", intent = "WITHDRAW", subject = "TOLL" },
        { id = "refuse", label = "Refuse — stand your ground", intent = "REFUSE", subject = "TOLL" },
    }
end

function TollConvo.HandleServerMessage(args)
    args = type(args) == "table" and args or {}
    if args.kind == "result" then
        if args.ok == true or not args.reopen then
            TollConvo.ActiveDemand = nil
        end
        return true
    end
    if args.kind ~= "demand" then return false end

    TollConvo.ActiveDemand = args
    local choices = TollConvo.BuildChoices(args)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local conv = PNC.Conversation
    -- Open through the unified InlineChat / Conversation UI surface (no legacy popup).
    if conv and conv.InlineChat and type(conv.InlineChat.OpenPrompt) == "function" then
        conv.InlineChat.OpenPrompt({
            storyID = "convo.faction.looter_toll",
            speakerName = tostring(args.factionName or "Looters"),
            demandID = args.demandID,
            choices = choices,
            onChoice = function(choiceID) TollConvo.SubmitDecision(choiceID) end,
            onFreeText = function(text) return TollConvo.SubmitFreeText(text) end,
        }, player)
        return true
    end
    if conv and type(conv.Open) == "function" and args.guardEntry then
        conv.Open(args.guardEntry, player)
        return true
    end
    return true
end

return TollConvo
