local T = require "tests/support/test"

PNC = {
    Core = {
        IsAuthority = function() return true end,
        Now = function() return 100 end,
    },
    Const = {
        PRESENCE_ABSTRACT = "abstract",
    },
    Persistence = {
        Reset = {
            Check = function() return nil end,
            Read = function() return nil end,
            Write = function() return true end,
        },
        CoreSocial = {
            FromCoreSocial = function(coreSocial)
                return {
                    morale = coreSocial.morale or 0,
                    relationships = {
                        ["player:test"] = {
                            approval = 7,
                            respect = 3,
                            familiarity = 2,
                        },
                    },
                    personality = {
                        boldness = 0.75,
                    },
                }
            end,
        },
    },
    Registry = {
        Internal = {},
    },
}
Events = {
    OnInitGlobalModData = {
        Add = function() end,
    },
}
ModData = {
    getOrCreate = function()
        return {
            records = {},
            deathMarkers = {},
        }
    end,
    remove = function() end,
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Registry/PNC_Registry/PNC_Registry_StorageCore.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Registry/PNC_Registry/PNC_Registry_LoadDirty.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Registry/PNC_Registry/PNC_Registry_Records.lua"
)
PNC.Registry.Loaded = true

local actor = {
    actorId = "actor:abstract:one",
    revision = 5,
    ownerMod = "DynamicTrading",
    identity = {
        identitySeed = 42,
        archetypeID = "core.survivor",
        displayName = "Mara Velez",
        gender = "female",
        survivor = {
            forename = "Mara",
            surname = "Velez",
            voiceProfile = { id = "voice:mara" },
        },
    },
    appearance = {
        resolved = {
            hairModel = "Long",
            beardModel = "",
            outfit = "Survivor",
        },
    },
    persona = {
        traits = { patient = true },
    },
    knowledge = {
        facts = { roads = true },
    },
    social = {
        morale = 0.25,
    },
    world = {
        position = { x = 120, y = 240, z = 0 },
    },
    providerLease = {
        provider = "DTAbstract",
        state = "abstract",
    },
    extensions = {
        ["PsychopatzCore.SurvivorWorld"] = {
            factionID = "faction:traders",
            communityID = "community:market",
            groupID = "group:caravan",
            role = "trader",
        },
    },
}

PsychopatzCore = {
    Actors = {
        Get = function(id)
            return id == actor.actorId and actor or nil
        end,
        Presentation = {
            BuildPortrait = function(value)
                T.equal(value, actor, "portrait source actor")
                return {
                    actorID = actor.actorId,
                    appearance = {
                        hairModel = "Long",
                    },
                    equipment = {
                        worn = {
                            Torso_Upper = "Base.Tshirt",
                            Legs = "Base.Trousers",
                        },
                    },
                }
            end,
        },
    },
}

local View = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Registry/PNC_CoreActorRuntimeView.lua"
)
local record, reason = View.Ensure(actor.actorId, {
    provider = "DTAbstract",
    providerState = "abstract",
    trader = true,
})
T.truthy(record, reason)
T.equal(record.id, actor.actorId, "runtime view ID")
T.equal(record.coreActorID, actor.actorId, "canonical Core actor binding")
T.equal(record.persist, false, "runtime view must never persist")
T.truthy(record.runtimeView, "runtime view marker")
T.truthy(record.abstractOnly, "runtime view is permanently abstract")
T.equal(record.presenceState, "abstract", "abstract presence")
T.equal(record.name, "Mara Velez", "Core identity projected")
T.equal(record.factionID, "faction:traders", "Core faction projected")
T.equal(record.communityID, "community:market", "Core community projected")
T.equal(record.groupID, "group:caravan", "Core group projected")
T.equal(record.role, "trader", "Core role projected")
T.truthy(record.roles and record.roles.trader,
    "DT trader role projected")
T.equal(record.appearance.hairModel, "Long",
    "Core appearance projected")
T.equal(record.equipment.worn.Torso_Upper, "Base.Tshirt",
    "Core clothing projected")
T.equal(record.social.relationships["player:test"].approval, 7,
    "Core social state projected")

local accessPlayer = {
    getUsername = function() return "RuntimeViewTester" end,
}
local granted, grantKey = View.GrantConversationAccess(
    record,
    accessPlayer,
    "debug",
    5000
)
T.truthy(granted, grantKey)
T.truthy(record.runtime.abstractConversationAccess[grantKey],
    "conversation access grant stored only on runtime view")
local consumed, accessSource = View.ConsumeConversationAccess(
    record,
    accessPlayer,
    100
)
T.truthy(consumed, accessSource)
T.equal(accessSource, "debug",
    "conversation access source preserved")
local consumedAgain, consumeReason =
    View.ConsumeConversationAccess(
        record,
        accessPlayer,
        100
    )
T.falsy(consumedAgain,
    "conversation access grant must be single-use")
T.equal(consumeReason, "abstract_access_denied",
    "consumed authorization denial reason")

T.equal(PNC.Registry.Get(actor.actorId), record,
    "Registry.Get resolves runtime view")
T.equal(PNC.Registry.GetRuntimeView(actor.actorId), record,
    "runtime view lookup")
T.equal(PNC.Registry.Data[actor.actorId], nil,
    "runtime view must not enter persistent registry")

local iterated = 0
PNC.Registry.ForEach(function()
    iterated = iterated + 1
end)
T.equal(iterated, 0,
    "runtime view must not enter persistent/scheduled enumeration")

T.truthy(PNC.Registry.MarkDirty(record, "social"),
    "runtime view accepts logical dirty notification")
T.equal(PNC.Registry.DirtyByID[actor.actorId], nil,
    "runtime view dirty notification must not create ModData work")

T.truthy(View.Remove(actor.actorId), "runtime view removal")
T.equal(PNC.Registry.Get(actor.actorId), nil,
    "removed runtime view no longer resolves")

T.finish("pnc_core_actor_runtime_view_smoke")
