-- Creation-only defaults for community modes and owning faction archetypes.

PNC = PNC or {}
PNC.CommunityProfiles = PNC.CommunityProfiles or {}

local Profiles = PNC.CommunityProfiles

Profiles.ByMode = {
    settled = {
        radius = 35,
        capacity = {
            population = 12,
            beds = 8,
            storage = 100,
        },
        security = 30,
        morale = 0,
    },
    camped = {
        radius = 15,
        capacity = {
            population = 8,
            beds = 2,
            storage = 30,
        },
        security = 10,
        morale = -5,
    },
    staging = {
        radius = 15,
        capacity = {
            population = 8,
            beds = 0,
            storage = 20,
        },
        security = 10,
        morale = 0,
    },
    evacuating = {
        radius = 15,
        capacity = {
            population = 8,
            beds = 0,
            storage = 20,
        },
        security = 5,
        morale = -10,
    },
    abandoned = {
        radius = 15,
        capacity = {
            population = 0,
            beds = 0,
            storage = 0,
        },
        security = 0,
        morale = 0,
    },
    destroyed = {
        radius = 15,
        capacity = {
            population = 0,
            beds = 0,
            storage = 0,
        },
        security = 0,
        morale = -100,
    },
}

Profiles.ByArchetype = {
    settler = {
        security = 5,
        storage = 20,
    },
    looter = {
        security = 10,
        ammunition = 10,
    },
    trader = {
        storage = 30,
        tools = 5,
    },
    refugee = {
        food = -5,
        medicine = 2,
        morale = -5,
    },
}

function Profiles.GetMode(mode)
    return Profiles.ByMode[mode]
end

function Profiles.GetArchetype(archetypeID)
    return Profiles.ByArchetype[archetypeID]
end

return Profiles
