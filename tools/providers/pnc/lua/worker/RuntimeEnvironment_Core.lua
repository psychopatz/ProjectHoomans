-- PsychopatzCore compatibility façade used by production modules.

local Core = {}

local function actorID(record)
    if type(record) ~= "table" then return nil end
    local id = record.coreActorID or record.actorId or record.id
        or record.npcID
    if id == nil or tostring(id) == "" then return nil end
    return tostring(id)
end

local function actorIdentity(record, id)
    local supplied = type(record) == "table" and record.identity or nil
    supplied = type(supplied) == "table" and supplied or {}
    local survivor = supplied.survivor
        or (type(record) == "table" and record.survivor)
        or {}
    local seed = supplied.identitySeed
        or (type(record) == "table" and record.identitySeed)
        or id
    local archetype = supplied.archetypeID
        or (type(record) == "table" and (record.archetypeID or record.archetype))
        or "core.actor"
    return {
        identitySeed = tostring(seed),
        archetypeID = tostring(archetype),
        displayName = supplied.displayName
            or (type(record) == "table" and record.displayName)
            or id,
        survivor = {
            forename = survivor.forename
                or (type(record) == "table" and record.forename),
            surname = survivor.surname
                or (type(record) == "table" and record.surname),
            gender = survivor.gender
                or (type(record) == "table" and record.gender),
        },
    }
end

function Core.configure(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local runtime = context.runtime
    PsychopatzCore = PsychopatzCore or {}
    PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
    PsychopatzCore.Conversation.Text = PsychopatzCore.Conversation.Text or {}
    if type(PsychopatzCore.Conversation.Text.Resolve) ~= "function" then
        PsychopatzCore.Conversation.Text.Resolve = function(value)
            return value and (value.fallback or value.text) or ""
        end
    end
    if type(PsychopatzCore.Conversation.Text.RegisterFallback) ~= "function" then
        PsychopatzCore.Conversation.Text.RegisterFallback = function(key, value)
            Runtime.fallbacks = Runtime.fallbacks or {}
            Runtime.fallbacks[key] = value
            return value
        end
    end
    PsychopatzCore.RuntimeRole = {
        AllowsServerCode = function() return true end,
        IsPureClient = function() return runtime.mode == "multiplayer" end,
    }
    PsychopatzCore.DebugTrace = {
        IsEnabled = function() return true end,
        Record = function(definition)
            Runtime.trace[#Runtime.trace + 1] = Values.copy(definition)
            return true
        end,
    }
end

-- The worker uses the real Core actor registry once production modules have
-- loaded it.  Recreate the isolated registry at each scenario reset so a
-- SAVE import or fixture cannot leak canonical actor/social state into the
-- next working world.
function Core.ensureActor(context, record)
    local Runtime = context.Runtime
    local Actors = PsychopatzCore and PsychopatzCore.Actors
    if type(Actors) ~= "table"
        or type(Actors.NewRegistry) ~= "function"
        or type(Actors.Create) ~= "function"
    then
        return false, "core_actor_registry_unavailable"
    end

    if Runtime.coreActorFixtureRevision ~= Runtime.workingWorldRevision then
        Actors.DefaultRegistry = Actors.NewRegistry()
        Runtime.coreActorFixtureRevision = Runtime.workingWorldRevision
    end

    local id = actorID(record)
    if not id then return false, "core_actor_id_required" end
    if Actors.DefaultRegistry:Has(id) then return true, "existing" end

    local created, reason = Actors.Create({
        actorId = id,
        ownerMod = "ProjectHoomans",
        archetypeID = (type(record) == "table" and (
            record.archetypeID or record.archetype
        )) or "core.actor",
        identity = actorIdentity(record, id),
    })
    if not created then
        return false, "core_actor_create_failed:" .. tostring(reason)
    end
    return true, "created"
end

return Core
