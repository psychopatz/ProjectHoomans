local T = require "tests/support/test"

T.addPackagePaths()

local humanVisual = {}
local visuals = {}
local addCalls = {}
local bodyParts = {}
local BodyPartType = {}

function humanVisual:hasBodyVisualFromItemType(fullType)
    return visuals[fullType] == true
end

function humanVisual:removeBodyVisualFromItemType(fullType)
    if not visuals[fullType] then
        return nil
    end
    visuals[fullType] = nil
    return {}
end

for _, name in ipairs({
    "Head", "Neck",
}) do
    local model = name == "Head"
        and "Base.Bandage_Head" or "Base.Bandage_Neck"
    bodyParts[name] = {
        getBandageModel = function()
            return model
        end,
    }
end

function BodyPartType.FromString(name)
    return bodyParts[name]
end

PNC = {
    ClientPresenceSync = { Internal = {} },
    NPCWounds = {
        Parts = {
            Head = { engine = "Head" },
            Neck = { engine = "Neck" },
        },
        PartOrder = { "Head", "Neck" },
    },
}
_G.BodyPartType = BodyPartType

local zombie = {
    getHumanVisual = function()
        return humanVisual
    end,
    addVisualBandage = function(_, bodyPart, bloody)
        local fullType = bodyPart:getBandageModel()
            .. (bloody and "_Blood" or "")
        visuals[fullType] = true
        addCalls[#addCalls + 1] = fullType
    end,
    resetModelNextFrame = function() end,
}

local Bandages = T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Bandages.lua")

local snapshot = {
    id = "npc-test",
    liveBodyLease = "lease-1",
    bodyHealth = {
        wounds = {
            Head = { bandaged = true, bandageDirty = false },
        },
    },
}

-- A wrap that existed before Hoomans took ownership remains managed by the
-- base game after the Hoomans wound is cleared.
visuals["Base.Bandage_Neck_Blood"] = true

local changed = Bandages.Internal.SyncBandageVisuals(zombie, snapshot)
T.truthy(changed, "clean head bandage is applied")
T.truthy(visuals["Base.Bandage_Head"],
    "clean head visual is present")
T.falsy(visuals["Base.Bandage_Head_Blood"],
    "clean head does not use blood visual")
snapshot.bodyHealth.wounds.Neck = {
    bandaged = true,
    bandageDirty = false,
}
changed = Bandages.Internal.SyncBandageVisuals(zombie, snapshot)
T.truthy(changed, "managed neck bandage supersedes natural bloody wrap")
T.truthy(visuals["Base.Bandage_Neck"],
    "clean neck visual is present")
T.falsy(visuals["Base.Bandage_Neck_Blood"],
    "natural bloody neck visual is hidden while managed")

snapshot.bodyHealth.wounds.Neck = nil
changed = Bandages.Internal.SyncBandageVisuals(zombie, snapshot)
T.truthy(changed, "natural neck wrap is restored after wound disappears")
T.falsy(visuals["Base.Bandage_Neck"],
    "managed clean neck visual is removed")
T.truthy(visuals["Base.Bandage_Neck_Blood"],
    "natural bloody neck visual is restored")

snapshot.bodyHealth.wounds.Head.bandageDirty = true
changed = Bandages.Internal.SyncBandageVisuals(zombie, snapshot)
T.truthy(changed, "dirty transition changes the head visual")
T.falsy(visuals["Base.Bandage_Head"],
    "clean head visual is removed on dirty transition")
T.truthy(visuals["Base.Bandage_Head_Blood"],
    "bloody head visual is present after dirty transition")

snapshot.bodyHealth = nil
changed = Bandages.Internal.SyncBandageVisuals(zombie, snapshot)
T.falsy(changed, "incomplete health data does not clear visible wraps")
T.truthy(visuals["Base.Bandage_Head_Blood"],
    "visible wrap is retained until health data is authoritative")

snapshot.bodyHealth = { wounds = {} }
changed = Bandages.Internal.SyncBandageVisuals(zombie, snapshot)
T.truthy(changed, "healed wound removes the managed visual")
T.falsy(visuals["Base.Bandage_Head_Blood"],
    "head visual is removed after wound disappears")
T.equal(#addCalls, 4, "reconciliation does not duplicate bandage visuals")

T.finish("pnc_bandage_visuals_smoke")
