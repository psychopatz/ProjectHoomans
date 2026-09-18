-- Compatibility coordinator for live-actor drag/drop in the layout editor.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
local Class = ISPNCPuppetOperaLayoutTab

require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_LiveDrag_Pointer"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab_LiveDrag_Commit"

function Class:setLivePointerFromEvent(list, x, y)
    return Internal.setLivePointerFromEvent(self, list, x, y)
end

function Class:updateLiveDropPreview()
    return Internal.updateLiveDropPreview(self)
end

function Class:updateLiveDrag(dx, dy)
    if not self.liveDragPending then return false end
    self.liveDragX = (tonumber(self.liveDragX) or 0) + (tonumber(dx) or 0)
    self.liveDragY = (tonumber(self.liveDragY) or 0) + (tonumber(dy) or 0)
    self.livePointerX = (tonumber(self.livePointerX) or 0)
        + (tonumber(dx) or 0)
    self.livePointerY = (tonumber(self.livePointerY) or 0)
        + (tonumber(dy) or 0)
    if not self.liveDragging then
        local distance = math.abs(self.liveDragX) + math.abs(self.liveDragY)
        if distance < 6 then return true end
        self.liveDragging = true
    end
    self:updateLiveDropPreview()
    return true
end

function Class:finishLiveDrag(list, x, y)
    return Internal.finishLiveDrag(self, list, x, y)
end

return Class
