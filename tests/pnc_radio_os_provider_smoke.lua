-- Offline contract test for the Core Radio OS Hoomans adapter.

local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/client/"
package.path = ROOT .. "?.lua;" .. package.path

local provider
local calls = {}
package.preload["PsychopatzCore/UI/Radio/OS/PsychopatzRadioOS"] = function()
    return {
        RegisterContactProvider = function(definition)
            provider = definition
            return true
        end,
        UnregisterContactProvider = function() return false end,
    }
end

PNC = {
    Network = {
        ClientState = {
            worldDiscovery = {
                revision = 7,
                entities = {
                    { kind = "settlement", entityID = "s2",
                        name = "Bravo", phaseName = "LOCATED" },
                    { kind = "settlement", entityID = "s1",
                        name = "Alpha", phaseName = "RUMORED",
                        approximate = true },
                },
            },
        },
    },
    Client = {
        RequestWorldDiscovery = function(action, options)
            calls[#calls + 1] = { action = action, options = options }
            return true, { state = "known" }
        end,
    },
    Translation = {
        GetKey = function(_, fallback) return fallback end,
    },
    WorldDiscoveryPresentation = {
        SignalName = function(entity) return entity.name end,
        Phase = function(value) return value end,
    },
}

dofile(ROOT .. "PNC/Integrations/PNC_PsychopatzCoreRadioOS.lua")
assert(provider and provider.id == "projecthoomans:contacts")
local page = provider.list(provider, { offset = 0, limit = 99 })
assert(#page.contacts == 2)
assert(page.contacts[1].id == "settlement:s2")
assert(page.contacts[1].actions[1].id == "projecthoomans:call_contact")
assert(page.total == 2 and page.revision == 7)

local accepted = provider.invoke(provider, "settlement:s1",
    "projecthoomans:call_contact")
assert(accepted == true)
assert(calls[1].action == "call_contact")
assert(calls[1].options.kind == "settlement")
assert(calls[1].options.entityID == "s1")

print("pnc_radio_os_provider_smoke: ok")
