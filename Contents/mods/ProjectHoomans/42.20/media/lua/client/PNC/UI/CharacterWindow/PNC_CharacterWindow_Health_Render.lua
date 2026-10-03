PNC = PNC or {}
PNC.CharacterWindowTabs = PNC.CharacterWindowTabs or {}
PNC.CharacterWindowHealth = PNC.CharacterWindowHealth or {}

local Tabs = PNC.CharacterWindowTabs
local Health = PNC.CharacterWindowHealth
local Shared = PNC.CharacterWindowShared
local Debug = require "PNC/UI/CharacterWindow/PNC_CharacterWindow_Health_Debug"

function Tabs.RenderHealth(view, snapshot, payload, topY)
    local resolved = Shared.GetSnapshot(snapshot, payload)
    local payloadHealth = payload and payload.health or {}
    local health = {
        current = resolved.hpCurrent or payloadHealth.current,
        max = resolved.hpMax or payloadHealth.max,
        state = resolved.healthState or payloadHealth.state,
        incapacitatedReason = payloadHealth.incapacitatedReason,
    }
    local body = resolved.bodyHealth or payloadHealth.body or {}
    local needs = resolved.needs or payload and payload.needs or {}
    local wholeBodyAilments = body.wholeBodyAilments or resolved.wholeBodyAilments or payload and payload.wholeBodyAilments or {}
    local wounds = body.wounds or {}
    local rows = Health.SortWounds(wounds)
    local padding = 12
    local silhouetteWidth = Shared.Clamp(math.floor(view.width * 0.34), 165, 205)
    local silhouetteHeight = math.min(302, math.max(220, view.height - padding * 2 - 24))
    local hpCurrent = tonumber(health.current) or tonumber(body.overallPercent) or 0
    local hpMax = math.max(1, tonumber(health.max) or 100)
    local bodyBounds = Health.DrawBody(view, resolved.isFemale == true, padding, padding, silhouetteWidth, silhouetteHeight, wounds, hpCurrent, hpMax)
    local x = padding + silhouetteWidth + 10
    local width = math.max(150, view.width - x - padding)
    local y = topY
    local state = tostring(health.state or "normal")
    local fontHeight = getTextManager():getFontHeight(UIFont.Small)
    local injuryTint = math.max(0.2, 1 - Shared.Clamp(hpCurrent / hpMax, 0, 1))
    local debugAllowed = PNC.Client and PNC.Client.CanUseDebug and PNC.Client.CanUseDebug() == true

    view:drawText(Shared.Text("IGUI_health_Overall_Body_Status", "Overall Body Status"), x, y, 1, 1, 1, 1, UIFont.Small)
    y = y + fontHeight
    view:drawText(Health.OverallStatus(hpCurrent, hpMax, state == "incapacitated"), x, y, 1, 1 - injuryTint, 1 - injuryTint, 1, UIFont.Small)
    y = y + fontHeight
    y = Health.RenderMedicalActivity(view, x, y, width, fontHeight, snapshot, payload)
    if debugAllowed then
        local infection = body.infection
        local infected = infection and (infection.active == true or infection.fatal == true)
        local infectionText = infected and string.format("DEBUG Knox infection: YES | %s | %.0f%% | %.1f C", tostring(infection.stage or "incubating"), (tonumber(infection.progress) or 0) * 100, tonumber(infection.temperatureC) or 37) or "DEBUG Knox infection: NO"
        view:drawText(infectionText, x, y, infected and 1 or 0.45, infected and 0.35 or 0.9, 0.2, 1, UIFont.Small)
        y = y + fontHeight
    end
    y = Health.RenderAilments(view, x, y, width, fontHeight, needs, wholeBodyAilments) + fontHeight
    y = Health.RenderWounds(view, x, y, width, fontHeight, rows, body, debugAllowed)
    if state == "incapacitated" then
        y = y + 6
        local reason = tostring(health.incapacitatedReason or "")
        if reason == "" or reason == "critical injury" then reason = Shared.Text("UI_PNC_Health_CriticalInjury", "critical injury") end
        view:drawText(PNC.Translation.TrFormat("UI_PNC_Health_Incapacitated", "Incapacitated - %1", reason), x, y, 0.95, 0.36, 0.31, 1, UIFont.Small)
        y = y + fontHeight + 6
        view:drawText(Shared.Text("UI_PNC_Health_IncapacitatedHelp", "Bandage the wounds; they will stand once sufficiently recovered."), x, y, 0.72, 0.72, 0.72, 1, UIFont.Small)
        y = y + fontHeight + 6
    end
    view:drawText(Shared.Text("IGUI_health_RightClickTreatement", "Right click an injury to treat it."), padding, padding + bodyBounds.height + 4, 1, 1, 1, UIFont.Small)
    return math.max(y, padding + bodyBounds.height) + 12
end

function Tabs.OnHealthRightMouseUp(view, x, y)
    local regions = view.healthHitRegions or {}
    local i
    for i = #regions, 1, -1 do
        local region = regions[i]
        if x >= region.x and x <= region.x + region.width and y >= region.y and y <= region.y + region.height then
            return Debug.ShowHealthMenu(view, region.partId, x, y)
        end
    end
    return Debug.ShowHealthMenu(view, nil, x, y)
end

return Health
