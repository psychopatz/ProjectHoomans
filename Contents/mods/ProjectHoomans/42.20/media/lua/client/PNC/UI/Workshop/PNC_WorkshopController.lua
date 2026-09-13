require "PsychopatzCore/UI/PsychopatzUI"

local Workshop = require
    "PNC/UI/Workshop/PNC_WorkshopCatalog"
local Shared = require
    "PNC/UI/Shared/PNC_ColonyUIShared"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"

local Controller = {}
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Client = PNC.ColonyManagementClient

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function Controller.CreateChildren(window)
    -- The legacy catalog renderer uses this value as its surface guard. Keep
    -- the compatibility value local to the Workshop window; it is not a
    -- Colony Management tab anymore.
    window.tab = "workshop"
    window.workshopSurface = true
    window.lastReceiveRevision = -1
    window.lastReceiveAt = 0
    window.lastRequestAt = 0
    Workshop.Create(window, UI)
    Controller.ApplyContentStyle(window)
end

function Controller.ApplyResponsiveLayout(window)
    local content = window:getContentRect({ top = 30, bottom = 12 })
    Workshop.Layout(window, Layout, content)
    window.workshopContentRect = content
    return content
end

function Controller.ApplyContentStyle(window)
    local signature = Options.GetContentOpacitySignature()
    if window.lastContentOpacitySignature == signature then return end
    for _, list in ipairs({
        window.workshopQueueList,
        window.workshopRecipeList,
        window.workshopSalvageList,
    }) do
        Options.ApplySurfaceOpacity(list, "detail")
    end
    window.lastContentOpacitySignature = signature
end

function Controller.Rebuild(window)
    window.tab = "workshop"
    return Workshop.Rebuild(window, window.snapshot or {}, Shared.Tr)
end

function Controller.Refresh(window, update)
    update = update or Client.ReadSnapshot()
    window.snapshot = update.snapshot or {}
    window.lastReceiveRevision = tonumber(update.revision) or 0
    window.lastReceiveAt = update.receivedAt or now()
    return Controller.Rebuild(window)
end

function Controller.RequestSnapshot(window)
    local _, _, requestedAt = Client.RequestSnapshot()
    window.lastRequestAt = requestedAt or now()
end

function Controller.OnControl(window, button)
    return Workshop.OnControl(window, button)
end

return Controller
