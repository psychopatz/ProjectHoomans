require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"

PNCBandageAction = ISBaseTimedAction:derive("PNCBandageAction")

local function targetRecord(npcId)
    local record = PNC and PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId) or nil
    if record then return record end
    return PNC and PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        and PNC.Network.ClientState.snapshots[npcId] or nil
end

local function targetBody(npcId)
    local body = PNC and PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(npcId) or nil
    if body then return body end
    local snapshot = PNC and PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        and PNC.Network.ClientState.snapshots[npcId] or nil
    return snapshot and PNC.Network.FindZombieByOnlineID
        and PNC.Network.FindZombieByOnlineID(snapshot.bodyOnlineID) or nil
end

local function itemStillPresent(character, item)
    local inventory = character and character.getInventory and character:getInventory() or nil
    local ok
    local present
    if not item then return true end
    if not inventory then return false end
    if inventory.containsRecursive then
        ok, present = pcall(inventory.containsRecursive, inventory, item)
        if ok then return present == true end
    end
    if inventory.contains then
        ok, present = pcall(inventory.contains, inventory, item)
        if ok then return present == true end
    end
    return item.getContainer and item:getContainer() ~= nil
end

local function inRange(character, npcId)
    local record = targetRecord(npcId)
    if record and PNC and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId)
        and PNC.Treatment and PNC.Treatment.IsPlayerInBandageRange
    then
        return PNC.Treatment.IsPlayerInBandageRange(character, npcId)
    end
    local body = targetBody(npcId)
    local x = body and body:getX() or tonumber(record and record.x)
    local y = body and body:getY() or tonumber(record and record.y)
    local z = body and body:getZ() or tonumber(record and record.z)
    local range = PNC and PNC.Const and tonumber(PNC.Const.BANDAGE_RANGE) or 3
    if not character or not x or not y or not z then return false end
    if math.abs((tonumber(character:getZ()) or 0) - z) >= 1 then return false end
    local dx = character:getX() - x
    local dy = character:getY() - y
    return dx * dx + dy * dy <= range * range
end

function PNCBandageAction:isValid()
    local record = targetRecord(self.npcId)
    if not self.character or self.character:isDead() then return false end
    if record and record.alive == false then return false end
    if not inRange(self.character, self.npcId) then return false end
    return self.debugFree == true or itemStillPresent(self.character, self.item)
end

function PNCBandageAction:waitToStart()
    local body = targetBody(self.npcId)
    if not body then return false end
    self.character:faceThisObject(body)
    return self.character:shouldBeTurning()
end

function PNCBandageAction:update()
    local body = targetBody(self.npcId)
    if body then self.character:faceThisObject(body) end
    if self.item then self.item:setJobDelta(self:getJobDelta()) end
    if self.character.setMetabolicTarget and Metabolics then
        self.character:setMetabolicTarget(Metabolics.LightDomestic)
    end
end

function PNCBandageAction:start()
    -- Vanilla uses its Loot/Mid first-aid pose when one character bandages
    -- another character. The bandage item job delta supplies the standard
    -- timed-action loading indicator.
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
    self.character:reportEvent("EventLootItem")
    self:setOverrideHandModels(nil, nil)
    if self.item then
        self.item:setJobType(getText("ContextMenu_Apply_Bandage"))
        self.item:setJobDelta(0)
    end
    if self.character.playSound then
        self.sound = self.character:playSound("FirstAidApplyBandage")
    end
end

function PNCBandageAction:stopSound()
    if self.sound and self.character.getEmitter
        and self.character:getEmitter():isPlaying(self.sound)
    then
        self.character:stopOrTriggerSound(self.sound)
    end
    self.sound = nil
end

function PNCBandageAction:stop()
    self:stopSound()
    if self.item then self.item:setJobDelta(0) end
    ISBaseTimedAction.stop(self)
end

function PNCBandageAction:perform()
    self:stopSound()
    if self.item then self.item:setJobDelta(0) end
    if PNC and PNC.Client and PNC.Client.CompleteBandage then
        PNC.Client.CompleteBandage(
            self.npcId,
            self.partId,
            self.debugFree,
            self.bandageType
        )
    end
    ISBaseTimedAction.perform(self)
end

function PNCBandageAction:new(character, npcId, partId, item, debugFree, bandageType)
    local action = ISBaseTimedAction.new(self, character)
    local doctorLevel = character.getPerkLevel and Perks
        and tonumber(character:getPerkLevel(Perks.Doctor)) or 0
    action.npcId = tostring(npcId)
    action.partId = tostring(partId)
    action.item = item
    action.debugFree = debugFree == true
    action.bandageType = bandageType
    action.stopOnWalk = true
    action.stopOnRun = true
    action.maxTime = math.max(80, 120 - doctorLevel * 4)
    return action
end

function PNCBandageAction.Queue(character, npcId, partId, debugFree, bandageType)
    local item
    if debugFree ~= true then
        item = PNC and PNC.Treatment and PNC.Treatment.FindBandage
            and PNC.Treatment.FindBandage(character, bandageType) or nil
        if not item then return false, "missing_bandage" end
    end
    ISTimedActionQueue.add(PNCBandageAction:new(
        character,
        npcId,
        partId,
        item,
        debugFree,
        bandageType
    ))
    return true, "queued"
end

return PNCBandageAction
