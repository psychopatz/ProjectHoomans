local Window = ISPNCScavengeWindow
if not Window then return end

local Internal = Window.Internal or {}
local UI = Internal.UI
local tr = Internal.tr
local readable = Internal.readable

function ISPNCScavengeWindow:prerender()
    UI.Window.prerender(self)
    if self.debugEnabled and self.snapshot and self.snapshot.sessionId then
        local now = getTimeInMillis and getTimeInMillis() or 0
        if now >= (tonumber(self.nextDebugRequestAt) or 0) then
            self.nextDebugRequestAt = now + 750
            PNC.Client.SendScavengeRequest("debug_dump", {
                sessionId = self.snapshot.sessionId,
            })
        end
    end
    if not self.layout then return end
    local snapshot = self.snapshot or {}
    local progress = tonumber(snapshot.progress) or 0
    local rect = self.layout.rect
    local progressText = tr("UI_PNC_Scavenge_Progress",
        "Search: %s%%  |  %s searched  |  %s unreachable",
        progress, tonumber(snapshot.searchedCount) or 0,
        tonumber(snapshot.unreachableCount) or 0)
    local scavengerCount = tonumber(snapshot.scavengerCount)
        or #(snapshot.scavengers or self.npcIds or {})
    progressText = tr("UI_PNC_Scavenge_SearcherCount",
        "Scavengers: %s", scavengerCount) .. "  |  " .. progressText
    self:drawText(progressText, rect.x,
        rect.y + 3, 0.72, 0.86, 0.94, 1, UIFont.Small)
    local carry = snapshot.carry
    local carryText = carry and tr("UI_PNC_Scavenge_Carry",
        "Carry %s / %s (%s)",
        string.format("%.2f", tonumber(carry.usedWeight) or 0),
        string.format("%.2f", tonumber(carry.maxWeight) or 0),
        readable(carry.level)) or tr("UI_PNC_Scavenge_CarryUnavailable",
            "Carry unavailable")
    carryText = carryText .. tr("UI_PNC_Scavenge_QueuedLoad",
        "  |  Queued ~%s", string.format("%.2f",
            tonumber(self.estimatedLoad) or 0))
    self:drawTextRight(carryText, rect.x + rect.width, rect.y + 3,
        0.72, 0.74, 0.78, 1, UIFont.Small)
end

