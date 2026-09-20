-- Resolve semantic target IDs to compact, namespace-safe identity seeds.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Internal = Events.Internal
local targetSeed = Internal.TargetSeed

local function resolveEntityReference(value)
    local EntityRef = PNC and PNC.EntityRef
    local Registry = PNC and PNC.Registry
    local raw
    local parsed
    local account
    local character
    local record
    if type(value) == "table" then
        raw = value.key or value.targetID or value.entityID
            or value.npcID or value.id
    else
        raw = value
    end
    raw = tostring(raw or "")
    if raw == "" or #raw > 128 or string.find(raw, "%c") then
        return nil
    end
    if EntityRef and type(EntityRef.Parse) == "function" then
        parsed = EntityRef.Parse(raw)
    end
    if not parsed and Registry and type(Registry.Get) == "function" then
        record = Registry.Get(raw)
        if record and EntityRef and type(EntityRef.Parse) == "function" then
            parsed = EntityRef.Parse("npc:" .. raw)
        end
    end
    if not parsed and not string.find(raw, ":", 1, true) then
        if EntityRef and type(EntityRef.Parse) == "function" then
            parsed = EntityRef.Parse("npc:" .. raw)
        end
        if not parsed then
            parsed = { key = "npc:" .. raw, kind = "npc", npcID = raw }
        end
    end
    if not parsed then
        account, character = string.match(raw, "^([^:]+):([^:]+)$")
        if account and character and EntityRef
            and type(EntityRef.Parse) == "function"
        then
            parsed = EntityRef.Parse(
                "player:" .. account .. ":" .. character
            )
        end
    end
    if not parsed then return nil end
    if parsed.kind == "npc" and Registry
        and type(Registry.Get) == "function"
    then
        record = record or Registry.Get(parsed.npcID)
    end
    parsed.record = record
    parsed.seed = targetSeed(parsed, record)
    return parsed
end

function Events.ResolveTarget(value)
    return resolveEntityReference(value)
end

Internal.ResolveEntityReference = resolveEntityReference

return true
