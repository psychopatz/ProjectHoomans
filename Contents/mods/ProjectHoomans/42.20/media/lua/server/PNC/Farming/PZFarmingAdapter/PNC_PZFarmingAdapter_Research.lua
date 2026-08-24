-- Persistent farming research effects.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PZFarmingAdapter = PNC.PZFarmingAdapter or {}
local Adapter = PNC.PZFarmingAdapter
local Internal = Adapter.Internal
local Research = PNC.FarmingResearch
local farmingSystem = Internal.FarmingSystem
local eachTile = Internal.EachTile
local cropState = Internal.CropState
local validateLoadedPlot = Internal.ValidateLoadedPlot
local farmingSkill = Internal.FarmingSkill

local function savePlant(plant)
    if type(plant.saveData) ~= "function" then
        return false, "VANILLA_PLANT_SAVE_UNAVAILABLE"
    end
    plant:saveData()
    return true
end

local function alivePlant(plant)
    return plant and type(plant.isAlive) == "function"
        and plant:isAlive() ~= false
end

local function applyPlantEffect(plant, effect, body)
    if not alivePlant(plant) then return false, "PLANT_NOT_READY" end
    if effect == "boost_yield" then
        plant.bonusYield = true
        return savePlant(plant)
    elseif effect == "fertilize" then
        if type(plant.fertilize) ~= "function" then
            return false, "VANILLA_FERTILIZER_UNAVAILABLE"
        end
        -- Compost uses vanilla's safe fertilizer path and is persistent in
        -- SPlantGlobalObject, making this a good debug stand-in for future
        -- fertilizer items and research modifiers.
        plant:fertilize({ skill = farmingSkill(body), compost = true })
        return true
    elseif effect == "gmo_upgrade" then
        -- These are all vanilla persisted fields.  Keeping the debug upgrade
        -- on vanilla state means later research can replace this with a
        -- calculated modifier without inventing a second plant authority.
        plant.bonusYield = true
        plant.cursed = false
        plant.hasWeeds = false
        plant.compost = true
        plant.health = math.max(tonumber(plant.health) or 0, 100)
        return savePlant(plant)
    end
    return false, "UNKNOWN_FARMING_RESEARCH_EFFECT"
end

function Adapter.ApplyResearchEffect(component, effect, body)
    local normalized = Research and Research.NormalizeEffect
        and Research.NormalizeEffect(effect) or nil
    if not normalized then return false, "UNKNOWN_FARMING_RESEARCH_EFFECT" end
    if normalized == "fast_growth" then
        return Adapter.ForceGrowPlot(component)
    end
    local system = farmingSystem()
    if not system then return false, "FARMING_SYSTEM_UNAVAILABLE" end
    local ready, reason = validateLoadedPlot(component)
    if not ready then return false, reason end
    local applied = 0
    local ok, failure = eachTile(component, function(x, y, z)
        local plant = Adapter.GetPlantAt(x, y, z)
        if plant and cropState(plant) ~= "plow" then
            local changed, changeReason = applyPlantEffect(plant, normalized, body)
            if not changed then
                if changeReason ~= "PLANT_NOT_READY" then
                    return false, changeReason
                end
            else
                applied = applied + 1
            end
        end
        return true
    end)
    if not ok then return false, failure end
    if applied <= 0 then return false, "NO_PLANTS_AVAILABLE" end
    local resultReason = {
        boost_yield = "YIELD_BOOSTED",
        fertilize = "FERTILIZER_APPLIED",
        gmo_upgrade = "GMO_UPGRADE_APPLIED",
    }
    return true, resultReason[normalized], {
        applied = applied, effect = normalized,
    }
end

return Adapter
