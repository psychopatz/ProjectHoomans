local TelemetryPrompt = PNC.Semantics.SemanticTelemetryPrompt
local UI = PsychopatzCore.UI
local Storage = PNC.Semantics.SemanticTelemetryStorage
local NEW_SEMANTIC = "__REQUEST_NEW_SEMANTIC__"
local TelemetryPromptWindow = TelemetryPrompt.Internal.WindowClass

local function tr(name, fallback)
    local translation = PNC and PNC.Translation
    local key = "UI_PNC_Conversation_Telemetry_" .. tostring(name)
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, fallback)
    end
    return fallback or key
end

local function reportFrom(view, rawText, result, source)
    local ir = result and result.ir or {}
    local decision = result and result.decision or {}
    local provenance = ir.provenance or {}
    return {
        rawText = tostring(rawText or ""),
        normalizedText = tostring(ir.normalizedText or ""),
        source = source,
        outcome = {
            route = decision.route,
            branch = decision.branch,
            reason = decision.reason or result.reason,
            confidence = ir.confidence,
            intent = ir.intent,
            speechAct = ir.speechAct,
            action = ir.action,
            parser = provenance.parser,
            pattern = provenance.pattern,
            provider = result.provider or provenance.provider,
        },
    }
end

function TelemetryPrompt.ShowNext()
    if TelemetryPrompt.Active or #TelemetryPrompt.Queue == 0 then
        return false
    end
    local report = table.remove(TelemetryPrompt.Queue, 1)
    local windowCaption = tr("Title", "Semantic telemetry")
    local window = UI.NewWindow(TelemetryPromptWindow, {
        title = windowCaption,
        width = 540,
        height = 620,
        persistenceKey = false,
        persistGeometry = false,
        resizable = false,
        collapsible = false,
        responsiveSpec = {
            width = 540,
            height = 620,
            minWidth = 460,
            minHeight = 560,
            maxWidth = 620,
            maxHeight = 720,
            anchor = "bottom_right",
        },
    })
    window.report = report
    TelemetryPrompt.Active = window
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:bringToTop()
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    return true
end

function TelemetryPrompt.Offer(view, rawText, result, source)
    if type(result) ~= "table" or type(result.decision) ~= "table"
        or result.decision.branch ~= "ASK_CLARIFICATION"
    then
        return false
    end
    local report = reportFrom(view, rawText, result, source)
    if report.rawText == "" then return false end

    local session = view and view.session
    local key = tostring(session and session.conversationID or "")
        .. ":" .. tostring(result.sequence or report.rawText)
    if TelemetryPrompt.Seen[key] then return false end
    if #TelemetryPrompt.Queue >= 8 then return false end
    if #TelemetryPrompt.SeenOrder >= 256 then
        local expired = table.remove(TelemetryPrompt.SeenOrder, 1)
        TelemetryPrompt.Seen[expired] = nil
    end
    TelemetryPrompt.Seen[key] = true
    TelemetryPrompt.SeenOrder[#TelemetryPrompt.SeenOrder + 1] = key
    TelemetryPrompt.Queue[#TelemetryPrompt.Queue + 1] = report
    TelemetryPrompt.ShowNext()
    return true
end


return TelemetryPrompt
