-- Bounded per-conversation dialogue-director state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Context = PNC.Semantics.DialogueContextState
Context.DEFAULT_DIRECTOR_RECENT_LIMIT = 4
Context.DEFAULT_DIRECTOR_COOLDOWN_LIMIT = 16

local function copy(value)
    local fn = Context.Internal.CopyValue
    return type(fn) == "function" and fn(value) or value
end

local function boundedState(value)
    value = type(value) == "table" and value or {}
    local recent = {}
    local sourceRecent = type(value.recent) == "table" and value.recent or {}
    local first = math.max(
        1,
        #sourceRecent - Context.DEFAULT_DIRECTOR_RECENT_LIMIT + 1
    )
    for index = first, #sourceRecent do
        if type(sourceRecent[index]) == "table" then
            recent[#recent + 1] = copy(sourceRecent[index])
        end
    end
    local cooldowns = {}
    local count = 0
    if type(value.cooldowns) == "table" then
        local keys = {}
        for key in pairs(value.cooldowns) do
            if type(key) == "string" then keys[#keys + 1] = key end
        end
        table.sort(keys)
        for index = 1, #keys do
            if count >= Context.DEFAULT_DIRECTOR_COOLDOWN_LIMIT then break end
            local key = keys[index]
            local untilTurn = tonumber(value.cooldowns[key])
            if untilTurn then
                cooldowns[key] = math.max(0, math.floor(untilTurn))
                count = count + 1
            end
        end
    end
    return {
        active = type(value.active) == "table"
            and copy(value.active) or nil,
        recent = recent,
        cooldowns = cooldowns,
        revision = tonumber(value.revision) or 0,
    }
end

function Context:GetDirectorState()
    self.directorState = boundedState(self.directorState)
    return copy(self.directorState)
end

function Context:StoreDirectorState(value)
    local normalized = boundedState(value)
    normalized.revision = (tonumber(
        self.directorState and self.directorState.revision
    ) or 0) + 1
    self.directorState = normalized
    return true, copy(normalized)
end

function Context:DirectorSnapshot()
    return self:GetDirectorState()
end

return Context
