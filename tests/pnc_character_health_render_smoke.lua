local T = require "tests/support/test"

package.preload["ISUI/ISContextMenu"] = function() return {} end

PNC = {
    CharacterWindowTabs = {},
    CharacterWindowShared = {
        GetSnapshot = function(snapshot, payload)
            return payload and payload.snapshot or snapshot or {}
        end,
        GetMedicalActivity = function(snapshot, payload)
            local resolved = payload and payload.snapshot or snapshot or {}
            local state = resolved.treatmentState
            if not state or state.phase == "idle" then return nil end
            return {
                source = "self",
                label = "Self-bandaging",
                partId = state.partId,
                bandageName = state.bandageName,
            }
        end,
        Text = function(_, fallback) return fallback end,
        Clamp = function(value, minimum, maximum)
            value = tonumber(value) or 0
            return math.max(minimum, math.min(maximum, value))
        end,
    },
    NPCWounds = {
        PartOrder = { "Head" },
        Parts = {
            Head = {
                id = "Head", label = "Head", weight = 1,
                x = 0.5, y = 0.08,
            },
        },
    },
    NeedsDefinitions = {
        CONSEQUENCES = { criticalThreshold = 0.84 },
        WHOLE_BODY_AILMENT_ORDER = {
            "starvation", "dehydration", "knox_fever", "blood_loss",
        },
        WHOLE_BODY_AILMENTS = {
            starvation = {
                id = "starvation", needType = "hunger",
                label = "Starvation", cause = "Hunger",
                labelKey = "Starvation", causeKey = "Hunger",
            },
            dehydration = {
                id = "dehydration", needType = "thirst",
                label = "Dehydration", cause = "Thirst",
                labelKey = "Dehydration", causeKey = "Thirst",
            },
            knox_fever = {
                id = "knox_fever", label = "Fever",
                labelKey = "Fever", severityProgression = "building",
            },
            blood_loss = {
                id = "blood_loss", label = "Losing blood",
                labelKey = "Losing blood", displayMode = "flavor",
                cause = "Active bleeding", causeKey = "Active bleeding",
            },
        },
        GetLevel = function(_, value)
            return tonumber(value) >= 0.84 and "CRITICAL" or "NORMAL"
        end,
    },
    Client = { CanUseDebug = function() return true end },
}
UIFont = { Small = "Small" }
PsychopatzCore = {
    UI = {
        Layout = {
            Ellipsize = function(value) return value end,
        },
    },
}
getTexture = function() return nil end
getTextManager = function()
    return { getFontHeight = function() return 14 end }
end

T.load(T.path("ProjectHoomans", "client", "PNC/UI/CharacterWindow/PNC_CharacterWindow_Health.lua"))

local drawn = {}
local drawCalls = {}
local view = {
    width = 500,
    height = 500,
    healthHitRegions = {},
    drawText = function(_, value, x, y, r, g, b, a, font)
        drawn[#drawn + 1] = tostring(value)
        drawCalls[#drawCalls + 1] = {
            x = x, y = y, r = r, g = g, b = b, a = a, font = font,
        }
    end,
    drawTextureScaled = function() end,
}
local snapshot = {
    hpCurrent = 42,
    hpMax = 100,
    healthState = "normal",
    bodyHealth = {
        wounds = {
            Head = {
                type = "scratch",
                damage = 2,
                severity = 2,
                bandaged = true,
                bandageName = "Bandage",
                bandageHealedPoints = 1,
                bandageInitialDamage = 3,
                healRatePerWorldHour = 1,
                dirtyAtWorldHour = 1,
            },
        },
        wholeBodyAilments = {
            starvation = { severity = 0.75 },
            dehydration = { severity = 1 },
            knox_fever = { severity = 0.60 },
            blood_loss = { active = true, flavorOnly = true },
        },
    },
    needs = { hunger = 0.90, thirst = 0.91, fatigue = 0 },
    treatmentState = {
        phase = "bandaging",
        partId = "Head",
        bandageName = "Bandage",
    },
}

PNC.CharacterWindowTabs.RenderHealth(view, snapshot, {}, 0)
local text = table.concat(drawn, "\n")
T.contains(text, "Whole Body", "health details identify the whole body")
T.contains(text, "Starvation: 75% | Hunger: 90% (CRITICAL) - RECOVERING",
    "health details identify recovering starvation")
T.contains(text, "Dehydration: 100% | Thirst: 91% (CRITICAL) - DAMAGE ACTIVE",
    "health details identify active dehydration damage")
T.contains(text, "Fever: 60% - BUILDING",
    "health details identify Knox fever progression")
T.contains(text, "Losing blood - Active bleeding",
    "health details show bleeding without a percentage")
T.contains(text, "Medical Activity", "health details show medical activity")
T.contains(text, "Self-bandaging | Head | Bandage: Bandage",
    "health details show self-treatment target")
T.contains(text, "DEBUG Healed:",
    "health details render debug healing text")
for i = 1, #drawCalls do
    T.equal(type(drawCalls[i].a), "number",
        "health drawText call " .. tostring(i) .. " has numeric alpha")
T.equal(drawCalls[i].font, UIFont.Small,
        "health drawText call " .. tostring(i) .. " passes font after alpha")
end
PNC.Client.CanUseDebug = function() return false end
local wholeBodyRegion
for i = 1, #view.healthHitRegions do
    if view.healthHitRegions[i].partId == "WholeBody" then
        wholeBodyRegion = view.healthHitRegions[i]
        break
    end
end
T.truthy(wholeBodyRegion, "whole-body detail is a selectable health region")
local region = wholeBodyRegion
T.falsy(PNC.CharacterWindowTabs.OnHealthRightMouseUp(view,
    region.x + 1, region.y + 1),
    "whole-body ailment does not open a bandage menu")

T.finish("pnc_character_health_render_smoke")
