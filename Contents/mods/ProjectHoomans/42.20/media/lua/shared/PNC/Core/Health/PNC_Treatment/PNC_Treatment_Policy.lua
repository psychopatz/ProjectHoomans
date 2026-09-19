-- Treatment policy and medical skill helpers.

PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}
PNC.Treatment.Internal = PNC.Treatment.Internal or {}

local Treatment = PNC.Treatment
local Internal = Treatment.Internal
local Const = PNC.Const
local Skills = PNC.Skills
local Types = PNC.Types

local BANDAGE_NAMES = {
    ["Base.AlcoholBandage"] = "Sterilized Bandage",
    ["Base.Bandage"] = "Bandage",
    ["Base.Bandaid"] = "Adhesive Bandage",
    ["Base.AlcoholRippedSheets"] = "Sterilized Ripped Sheets",
    ["Base.RippedSheets"] = "Ripped Sheets",
}

local function bandageTypes()
    return type(Const.BANDAGE_TYPES) == "table" and Const.BANDAGE_TYPES
        or { Const.BANDAGE_TYPE or "Base.Bandage" }
end

local function isBandageType(fullType)
    local types = bandageTypes()
    local i
    if not fullType then return true end
    for i = 1, #types do
        if tostring(types[i]) == tostring(fullType) then return true end
    end
    return false
end

local function bandageDisplayName(fullType, item)
    if item and item.getDisplayName then
        return tostring(item:getDisplayName())
    end
    if item and item.getName then
        return tostring(item:getName())
    end
    return BANDAGE_NAMES[tostring(fullType or "")]
        or tostring(fullType or "Ripped Sheets")
end

local function playerFirstAidLevel(player)
    if player and player.getPerkLevel and Perks and Perks.Doctor then
        return math.max(0, math.min(10,
            math.floor(tonumber(player:getPerkLevel(Perks.Doctor)) or 0)))
    end
    return 0
end

local function isPlayerOwned(record)
    return record and (record.recruited == true
        or record.ownerOnlineID ~= nil
        or (record.ownerUsername ~= nil and tostring(record.ownerUsername) ~= ""))
        or false
end

Internal.BandageTypes = bandageTypes
Internal.IsBandageType = isBandageType
Internal.BandageDisplayName = bandageDisplayName
Internal.PlayerFirstAidLevel = playerFirstAidLevel

function Treatment.GetPlayerFirstAidLevel(player)
    return playerFirstAidLevel(player)
end

function Treatment.GetNPCFirstAidLevel(record)
    return Skills and Skills.GetLevel and Skills.GetLevel(record, "FirstAid") or 0
end

function Treatment.GetBandageDisplayName(fullType, item)
    return bandageDisplayName(fullType, item)
end

function Treatment.IsPlayerOwnedNPC(record)
    return isPlayerOwned(record)
end

-- Colonists use the player-managed inventory; other actors can represent
-- abstract treatment unless a caller explicitly requests item consumption.
function Treatment.RequiresNPCMedicalItem(record, options)
    options = type(options) == "table" and options or {}
    local colonist = Types and Types.IsColonist
        and Types.IsColonist(record) == true
        or tostring(record and record.tacticalClass or "")
            == tostring(Const.TACTICAL_CLASS_COLONIST or "colonist")
    if colonist then return true end
    return options.consumeItem == true
end

function Treatment.GetNPCMedicalPolicy(record, options)
    local requiresItem = Treatment.RequiresNPCMedicalItem(record, options)
    local constants = PNC.Const or {}
    return {
        mode = requiresItem and "inventory" or "abstract",
        requiresItem = requiresItem,
        bandageType = requiresItem and nil
            or constants.ABSTRACT_MEDICAL_TREATMENT_TYPE
                or "PNC.AbstractMedical",
        bandageName = requiresItem and nil
            or constants.ABSTRACT_MEDICAL_TREATMENT_NAME
                or "Abstract medical treatment",
    }
end

function Treatment.GetNPCBandageDuration(record)
    local skill = Treatment.GetNPCFirstAidLevel(record)
    return math.max(
        tonumber(Const.SELF_BANDAGE_MIN_DURATION_MS) or 3000,
        (tonumber(Const.SELF_BANDAGE_BASE_DURATION_MS) or 6500)
            - skill * (tonumber(Const.SELF_BANDAGE_FIRST_AID_REDUCTION_MS) or 350)
    )
end
