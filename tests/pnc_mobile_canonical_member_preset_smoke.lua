local T = require "tests/support/test"

local generation = T.read(
    "ProjectHoomans", "server",
    "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Generation.lua")
local definition = T.read(
    "ProjectHoomans", "shared",
    "PNC/Core/Base/PNC_Types/PNC_Types_Definition.lua")
local lifecycle = T.read(
    "ProjectHoomans", "shared",
    "PNC/Core/API/PNC_API/Lifecycle.lua")
local templates = T.read(
    "ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Templates.lua")

T.contains(generation, "memberSpecs",
    "mobile generation accepts one canonical spec per member")
T.contains(generation, "personalInventory",
    "mobile generation transports the Core inventory payload")
T.contains(definition, "inventoryAuthority",
    "PNC definitions preserve canonical inventory authority")
T.contains(definition, "personalInventory",
    "PNC definitions preserve canonical Core inventory")
T.contains(lifecycle, "inventoryAuthority",
    "PNC spawn finalization honors canonical inventory")
T.contains(templates, "canonical",
    "PNC inventory templates have a canonical exact-item path")

T.finish("pnc_mobile_canonical_member_preset_smoke")
