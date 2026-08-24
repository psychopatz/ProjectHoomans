local T = require "tests/support/test"

local path = "PNC/Social/PNC_SocialEventHooks.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Social/SocialEventHooks/"
local providers = {
    "PNC_SocialEventHooks_Core",
    "PNC_SocialEventHooks_RescueContributions",
    "PNC_SocialEventHooks_Treatment",
    "PNC_SocialEventHooks_Encounter",
    "PNC_SocialEventHooks_ThreatAttribution",
    "PNC_SocialEventHooks_EventRegistration",
}

local previous = 0
local publicFunctions = {}
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
    local providerSource = T.read(
        "ProjectHoomans", "server", prefix .. provider .. ".lua")
    for name in providerSource:gmatch(
        "function%s+Hooks%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

local weaponHandlers = {}
local zombieHandlers = {}
Events = {
    OnWeaponHitCharacter = {
        Add = function(handler)
            weaponHandlers[#weaponHandlers + 1] = handler
        end,
    },
    OnZombieDead = {
        Add = function(handler)
            zombieHandlers[#zombieHandlers + 1] = handler
        end,
    },
}
PNC = {
    EntityRef = {
        ForNPC = function(id)
            return id and ("npc:" .. tostring(id)) or nil
        end,
    },
}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.SocialEventHooks[name]), "function",
        "entry point preserves SocialEventHooks." .. name)
end
T.equal(publicCount, 13, "social-event-hooks public function count")
T.equal(type(PNC.SocialEventHooks.RescueContributions), "table",
    "rescue contributions remain initialized")
T.equal(type(PNC.SocialEventHooks.ThreatAttributions), "table",
    "threat attributions remain initialized")
T.equal(#weaponHandlers, 1, "weapon-hit engine hook registered once")
T.equal(#zombieHandlers, 1, "zombie-dead engine hook registered once")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
Events = nil

T.finish("pnc_social_event_hooks_presence_boundary_smoke")
