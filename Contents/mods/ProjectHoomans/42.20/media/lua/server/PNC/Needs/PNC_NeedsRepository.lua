if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedsRepository = PNC.NeedsRepository or {}

local Repository = PNC.NeedsRepository
local Codec = PNC.NeedsStateCodec
local Definitions = PNC.NeedsDefinitions
local Reset = (PNC.Persistence and PNC.Persistence.Reset)
    or require "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_Reset"
Repository.MODDATA_KEY = "PNC_PlayerOwnedNeeds_V1"
Repository.Records = Repository.Records or {}
Repository.EvaluatedAt = Repository.EvaluatedAt or {}
Repository.PersistedAt = Repository.PersistedAt or 0
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

local function nowHours()
    return PNC.NeedsUtils and PNC.NeedsUtils.WorldAgeHours() or 0
end

local function realismEnabled()
    return PNC.Sandbox
        and PNC.Sandbox.PlayerOwnedNPCNutritionRealismEnabled
        and PNC.Sandbox.PlayerOwnedNPCNutritionRealismEnabled() == true
end

local function normalizeNutrition(nutrition)
    if type(nutrition) ~= "table" then return nil end
    return {
        calories = math.max(Definitions.NUTRITION.minimumCalories,
            math.min(Definitions.NUTRITION.maximumCalories,
                tonumber(nutrition.calories)
                    or Definitions.NUTRITION.defaultCalories)),
        calorieOverflow = 0,
        carbohydrates = math.max(Definitions.NUTRITION.minimumMacro,
            math.min(Definitions.NUTRITION.maximumMacro,
                tonumber(nutrition.carbohydrates)
                    or Definitions.NUTRITION.defaultCarbohydrates)),
        proteins = math.max(Definitions.NUTRITION.minimumMacro,
            math.min(Definitions.NUTRITION.maximumMacro,
                tonumber(nutrition.proteins)
                    or Definitions.NUTRITION.defaultProteins)),
        lipids = math.max(Definitions.NUTRITION.minimumMacro,
            math.min(Definitions.NUTRITION.maximumMacro,
                tonumber(nutrition.lipids)
                    or Definitions.NUTRITION.defaultLipids)),
        weight = math.max(Definitions.NUTRITION.minimumWeight,
            math.min(Definitions.NUTRITION.maximumWeight,
                tonumber(nutrition.weight)
                    or Definitions.NUTRITION.defaultWeight)),
    }
end

local function normalize(state)
    state = type(state) == "table" and state or {}
    return {
        needs = PNC.NeedsUtils.NormalizeState(state.needs or state, 0),
        nutrition = normalizeNutrition(state.nutrition),
        morale = {
            conditions = type(state.morale) == "table"
                and type(state.morale.conditions) == "table"
                and state.morale.conditions or {},
            lastDay = type(state.morale) == "table"
                and tonumber(state.morale.lastDay) or nil,
        },
    }
end

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Repository.Records end
    local raw = Reset.Read(Repository.MODDATA_KEY)
    local reason = Reset.Check(raw, Codec.VERSION, "v",
        function(value) return type(value.n) == "table" end)
    local decoded, at
    if reason == nil then
        decoded, at = Codec.Decode(raw)
    else
        decoded, at = {}, 0
    end
    local reset = reason ~= nil and reason ~= "empty_state"
    Repository.Records, Repository.EvaluatedAt = {}, {}
    Repository.PersistedAt = at
    for id, state in pairs(decoded) do
        Repository.Records[id] = normalize(state)
        Repository.EvaluatedAt[id] = at
    end
    Repository.Loaded, Repository.Dirty = true, reset
    Repository.LastReset = nil
    if reset then
        Reset.Mark(Repository, raw, Codec.VERSION, reason,
            "player_owned_needs", "v")
    end
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
        if realismEnabled() then
            state.nutrition = normalizeNutrition({
                weight = record and PNC.PlayerNeedsModel
                    and PNC.PlayerNeedsModel.GetInitialWeight
                    and PNC.PlayerNeedsModel.GetInitialWeight(record)
                    or Definitions.NUTRITION.defaultWeight,
            })
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
    local packed = Codec.Encode(Repository.Records, at)
    local written = Reset.Write(Repository.MODDATA_KEY, packed)
    if not written then return false, "moddata_unavailable" end
    Repository.PersistedAt = at
    Repository.Dirty = false
    return true, "saved"
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Repository.Load(true) end)
    Repository.LoadHookRegistered = true
end

return Repository
