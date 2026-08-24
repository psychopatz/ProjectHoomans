if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}
PNC.FactionBehavior.Internal = PNC.FactionBehavior.Internal or {}

local Behavior = PNC.FactionBehavior
local Internal = Behavior.Internal
local Factions = PNC.Factions
local EntityRef = PNC.EntityRef
local Core = PNC.Core

Behavior.ReconciliationQueue =
    Behavior.ReconciliationQueue or {}
Behavior.ReconciliationKeys =
    Behavior.ReconciliationKeys or {}

local function same(left, right)
    return PNC.FactionTypes.AreEqual(left, right)
end

local function currentWorldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

local function ownerIdentity(faction)
    local parsed = faction and faction.ownerPlayerKey
        and EntityRef.Parse(faction.ownerPlayerKey) or nil
    local player = parsed
        and PNC.PlayerCharacters
        and PNC.PlayerCharacters.RuntimeByUUID
        and PNC.PlayerCharacters.RuntimeByUUID[
            parsed.characterUUID
        ] or nil
    return parsed, player
end

local function factionHasPlayerMembers(faction)
    if not faction then return false end
    for _, _ in pairs(faction.playerMemberKeys or {}) do
        return true
    end
    return false
end

local function factionAtWarWithPlayerFaction(factionID)
    local faction = Factions.Registry.byID[factionID]
    if not faction then return false end
    for otherID, relation in pairs(faction.relations or {}) do
        if relation.atWar == true
            and Factions.AreAtWar(factionID, otherID)
        then
            local other = Factions.Registry.byID[otherID]
            if factionHasPlayerMembers(other) then
                return true
            end
        end
    end
    return false
end

local function playerEntityKey(player)
    local context = PNC.PlayerContext and PNC.PlayerContext.Peek
        and PNC.PlayerContext.Peek(player) or nil
    if context then return context.entityKey end
    local uuid = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetCharacterUUID
        and PNC.PlayerCharacters.GetCharacterUUID(player) or nil
    local record = uuid and PNC.PlayerCharacters.Registry
        and PNC.PlayerCharacters.Registry.byUUID
        and PNC.PlayerCharacters.Registry.byUUID[uuid] or nil
    return record and EntityRef.ForPlayerIdentity(
        record.accountKey or record.accountIdentity, uuid
    ) or nil
end

local function conversationParleyActive(record, targetKey)
    local parley = record and record.runtime
        and record.runtime.conversationParley or nil
    if type(parley) ~= "table" then return false end
    if (tonumber(parley.untilAt) or 0) <= Core.Now() then
        record.runtime.conversationParley = nil
        return false
    end
    return targetKey ~= nil
        and targetKey == parley.playerKey
end

local function targetContext(target)
    if type(target) ~= "table"
        and type(target) ~= "userdata"
    then
        return nil, nil, nil
    end
    if target.id and PNC.FactionTypes.IsValidNPCID
        and PNC.FactionTypes.IsValidNPCID(target.id)
    then
        local factionID =
            Factions.GetOrganizationalFactionID(target)
        return factionID, EntityRef.ForNPC(target.id), target
    end
    local playerFaction =
        Factions.GetPlayerDiplomacyFaction(target)
    return playerFaction and playerFaction.id or nil,
        playerEntityKey(target),
        nil
end

local function insideFactionCommunity(factionID, target)
    if not target or not target.getX or not target.getY
        or not PNC.Communities
        or not PNC.Communities.GetForFaction
        or not PNC.CommunityMath
        or not PNC.CommunityMath.IsInsideHomeArea
    then
        return false
    end
    local x = target:getX()
    local y = target:getY()
    local z = target.getZ and target:getZ() or 0
    for _, community in ipairs(
        PNC.Communities.GetForFaction(factionID) or {}
    ) do
        if community.status == "active"
            and PNC.CommunityMath.IsInsideHomeArea(
                community,
                x,
                y,
                z
            )
        then
            return true
        end
    end
    return false
end

Internal.same = same
Internal.currentWorldAgeHours = currentWorldAgeHours
Internal.ownerIdentity = ownerIdentity
Internal.factionHasPlayerMembers = factionHasPlayerMembers
Internal.factionAtWarWithPlayerFaction = factionAtWarWithPlayerFaction
Internal.playerEntityKey = playerEntityKey
Internal.conversationParleyActive = conversationParleyActive
Internal.targetContext = targetContext
Internal.insideFactionCommunity = insideFactionCommunity
