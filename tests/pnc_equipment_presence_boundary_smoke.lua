local source = assert(io.open(
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Equipment/PNC_Equipment.lua",
    "r"
)):read("*a")

local providers = {
    "PNC_Equipment_Descriptors",
    "PNC_Equipment_VisualState",
    "PNC_Equipment_ActivityHands",
    "PNC_Equipment_Worn",
    "PNC_Equipment_Attached",
    "PNC_Equipment_Hands",
    "PNC_Equipment_Apply",
    "PNC_Equipment_Replica",
    "PNC_Equipment_CombatState",
    "PNC_Equipment_Describe",
}

local previous = 0
for i = 1, #providers do
    local needle = "require \"PNC/Core/Equipment/PNC_Equipment/"
        .. providers[i] .. "\""
    local position = assert(source:find(needle, 1, true), needle)
    assert(position > previous, providers[i] .. " load order")
    previous = position
end

print("PASS pnc_equipment_presence_boundary_smoke")
