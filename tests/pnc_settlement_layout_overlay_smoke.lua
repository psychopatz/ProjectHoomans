local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/?.lua",
    "/home/psychopatz/Zomboid/Workshop/psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    package.path,
}, ";")

local Overlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"
local region = { levels = { [0] = { rows = { [4] = { 2, 5 } } } } }
local layers = Overlay.BuildLayers({
    id = "base_a", geometry = { region = region },
    facilities = {{
        id = "facility_a", definitionId = "farm", components = {
            { id = "field_a", kind = "region", role = "farm.field",
                region = region },
            { id = "anchor_a", kind = "anchor", role = "work.anchor",
                x = 3, y = 4, z = 0 },
        },
    }},
    stockpileNodes = {{ id = "stock_a", x = 4, y = 4, z = 0 }},
}, true)

equal(#layers, 4, "base, facility, anchor, and stockpile layers")
equal(layers[2].componentId, "field_a", "component identity retained")
equal(layers[3].region.levels[0].rows[4][1], 3, "anchor tile region")
equal(layers[4].kind, "stockpile", "stockpile overlay kind")

print("pnc_settlement_layout_overlay_smoke: ok")
