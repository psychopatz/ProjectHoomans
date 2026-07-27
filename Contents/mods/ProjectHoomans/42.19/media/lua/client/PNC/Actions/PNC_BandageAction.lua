require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"

PNCBandageAction = ISBaseTimedAction:derive("PNCBandageAction")

local LOW_TREATMENT_PARTS = {
    Groin = true,
    UpperLeg_L = true,
    UpperLeg_R = true,
    LowerLeg_L = true,
    LowerLeg_R = true,
    Foot_L = true,
    Foot_R = true,
}

local HIGH_TREATMENT_PARTS = {
    Head = true,
    Neck = true,
}

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
    if not item then return true end
    if not inventory then return false end
    if inventory.containsRecursive then
        return inventory:containsRecursive(item) == true
    end
    if inventory.contains then
        return inventory:contains(item) == true
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

function PNCBandageAction.ResolveLootPosition(npcId, partId)
    local record = targetRecord(npcId)
    local body = targetBody(npcId)
    local healthState = tostring(
        record and (
            record.healthState
            or record.health and record.health.state
        ) or ""
    )
    local downed = healthState == "incapacitated"
        or body and body.isOnFloor and body:isOnFloor() == true
    partId = tostring(partId or "")
    if downed or LOW_TREATMENT_PARTS[partId] then return "Low" end
    if HIGH_TREATMENT_PARTS[partId] then return "High" end
    return "Mid"
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
    -- Treating another character uses the mid-height interaction pose. The
    -- self-bandage action anim raises the player's arm because it expects the
    -- patient's BodyDamage to belong to the acting character.
    self:setActionAnim("Loot")
    self.character:SetVariable(
        "LootPosition",
        PNCBandageAction.ResolveLootPosition(self.npcId, self.partId)
    )
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
    if self:isValid()
        and PNC and PNC.Client and PNC.Client.CompleteBandage
    then
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
    action.stopOnAim = true
    action.useProgressBar = true
    action.maxTime = math.max(80, 120 - doctorLevel * 4)
    return action
end

function PNCBandageAction.Queue(character, npcId, partId, debugFree, bandageType)
    local item
    if not inRange(character, npcId) then
        return false, "out_of_range"
    end
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
