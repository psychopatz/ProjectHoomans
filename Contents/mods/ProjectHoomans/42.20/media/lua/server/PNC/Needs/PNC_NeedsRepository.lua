if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedsRepository = PNC.NeedsRepository or {}

local Repository = PNC.NeedsRepository
local Codec = PNC.NeedsStateCodec
local Definitions = PNC.NeedsDefinitions
Repository.MODDATA_KEY = "PNC_PlayerOwnedNeeds_V1"
Repository.Records = Repository.Records or {}
Repository.EvaluatedAt = Repository.EvaluatedAt or {}
Repository.PersistedAt = Repository.PersistedAt or 0
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

local function nowHours()
    return PNC.NeedsUtils and PNC.NeedsUtils.WorldAgeHours() or 0
end

local function normalize(state)
    state = type(state) == "table" and state or {}
    local nutrition = state.nutrition or {}
    return {
        needs = PNC.NeedsUtils.NormalizeState(state.needs or state, 0),
        nutrition = {
            calories = math.max(Definitions.NUTRITION.minimumCalories,
                math.min(Definitions.NUTRITION.maximumCalories,
                    tonumber(nutrition.calories)
                        or Definitions.NUTRITION.defaultCalories)),
            weight = math.max(Definitions.NUTRITION.minimumWeight,
                math.min(Definitions.NUTRITION.maximumWeight,
                    tonumber(nutrition.weight)
                        or Definitions.NUTRITION.defaultWeight)),
        },
    }
end

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Repository.Records end
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    local decoded, at = Codec.Decode(raw)
    Repository.Records, Repository.EvaluatedAt = {}, {}
    Repository.PersistedAt = at
    for id, state in pairs(decoded) do
        Repository.Records[id] = normalize(state)
        Repository.EvaluatedAt[id] = at
    end
    Repository.Loaded, Repository.Dirty = true, false
    return Repository.Records
end

function Repository.Get(recordOrID, create)
    Repository.Load()
    local record = type(recordOrID) == "table" and recordOrID or nil
    local id = tostring(record and record.id or recordOrID or "")
    if id == "" then return nil end
    local state = Repository.Records[id]
    if not state and create ~= false then
        state = normalize(nil)
        if record and PNC.PlayerNeedsModel and PNC.PlayerNeedsModel.GetInitialWeight then
            state.nutrition.weight = PNC.PlayerNeedsModel.GetInitialWeight(record)
        end
        Repository.Records[id] = state
        Repository.EvaluatedAt[id] = nowHours()
        Repository.Dirty = true
    end
    return state
end

function Repository.GetEvaluatedAt(recordOrID)
    local id = tostring(type(recordOrID) == "table" and recordOrID.id
        or recordOrID or "")
    return tonumber(Repository.EvaluatedAt[id]) or Repository.PersistedAt
end

function Repository.SetEvaluatedAt(recordOrID, at)
    local id = tostring(type(recordOrID) == "table" and recordOrID.id
        or recordOrID or "")
    if id ~= "" then Repository.EvaluatedAt[id] = math.max(0, tonumber(at) or 0) end
end

function Repository.MarkDirty() Repository.Dirty = true end

function Repository.Remove(recordOrID)
    Repository.Load()
    local id = tostring(type(recordOrID) == "table" and recordOrID.id
        or recordOrID or "")
    if Repository.Records[id] == nil then return false end
    Repository.Records[id], Repository.EvaluatedAt[id] = nil, nil
    Repository.Dirty = true
    return true
end

function Repository.Save()
    Repository.Load()
    if not Repository.Dirty then return false, "not_dirty" end
    local at = nowHours()
    if PNC.IndividualNeeds and PNC.Registry and PNC.Registry.Data then
        for id, state in pairs(Repository.Records) do
            local record = PNC.Registry.Data[id]
                or PNC.Registry.Get and PNC.Registry.Get(id) or nil
            if record and record.alive ~= false
                and PNC.IndividualNeeds.IsEligible(record) then
                PNC.IndividualNeeds.AdvanceTo(record, at, "save_catchup")
            end
        end
    end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    if not target then return false, "moddata_unavailable" end
    local packed = Codec.Encode(Repository.Records, at)
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(packed) do target[key] = value end
    Repository.PersistedAt = at
    Repository.Dirty = false
    return true, "saved"
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Repository.Load(true) end)
    Repository.LoadHookRegistered = true
end

return Repository
