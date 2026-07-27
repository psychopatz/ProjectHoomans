require "TimedActions/ISWashClothing"
require "TimedActions/ISBaseTimedAction"

PNC = PNC or {}
PNC.WashMedicalMaterialPatch = PNC.WashMedicalMaterialPatch or {}

local Patch = PNC.WashMedicalMaterialPatch

function Patch.IsReplaceAfterCleaningItem(item)
    return item ~= nil
        and not instanceof(item, "Clothing")
        and not instanceof(item, "InventoryContainer")
        and item.getItemAfterCleaning ~= nil
        and item:getItemAfterCleaning() ~= nil
end

if ISWashClothing and not ISWashClothing._pncMedicalMaterialPerformPatched then
    ISWashClothing._pncMedicalMaterialPerformPatched = true
    local originalPerform = ISWashClothing.perform

    function ISWashClothing:perform()
        if not Patch.IsReplaceAfterCleaningItem(self.item) then
            return originalPerform(self)
        end

        self:stopSound()
        self.item:setJobDelta(0.0)

        local obj = self.sink
        if instanceof(obj, "Drainable") then
            self.obj:setUsedDelta(
                self.startUsedDelta
                    + (self.endUsedDelta - self.startUsedDelta)
                    * self:getJobDelta()
            )
        end

        self.character:resetModel()
        -- complete() has already replaced the dirty medical material in the
        -- inventory and synchronized that remove/add pair. It is not clothing,
        -- so refreshing worn clothing and the hotbar is unnecessary. On
        -- Build 42.19 that nested event can fail in Kahlua's ReturnValues pool
        -- after a dirty rag or bandage is replaced.
        ISBaseTimedAction.perform(self)
    end
end

return Patch
