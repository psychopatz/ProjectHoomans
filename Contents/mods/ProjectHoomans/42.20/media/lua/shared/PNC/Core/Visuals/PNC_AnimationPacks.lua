-- Unified modder-friendly Animation Pack registry & load-time compiler.
--
-- Lets base ProjectHoomans and third-party animation packs register, vary
-- (`mode = "add_to_pool"`), or override (`mode = "replace"`) both:
--   1. Locomotion / stance profiles (idle, walk, run, sneak, limp, crawl)
--      with optional `when` conditions (weaponClass, injured, mood, indoors).
--   2. Discrete scenes & pools (eat, drink, bandage, sit, sleep, attack, talk)
--      including first-class hand `props` and `equipmentMode`.
--
-- Packs compile on registration/unregistration into flat O(1) lookup tables
-- so runtime per-tick cost is near zero.
PNC = PNC or {}
PNC.AnimationPacks = PNC.AnimationPacks or {}

local Packs = PNC.AnimationPacks

Packs.VERSION = 1
Packs.Packs = Packs.Packs or {}
Packs.BaseScenes = Packs.BaseScenes or {}
Packs.OwnedScenes = Packs.OwnedScenes or {}
Packs.CompiledLocomotion = Packs.CompiledLocomotion or {}

local function copyShallow(source)
    local out = {}
    if type(source) ~= "table" then return out end
    for k, v in pairs(source) do out[k] = v end
    return out
end

local function normalizeStateKey(state)
    return string.lower(tostring(state or ""))
end

local function sortedEnabledPacks()
    local list = {}
    for _, pack in pairs(Packs.Packs) do
        if pack and pack.enabled ~= false then
            list[#list + 1] = pack
        end
    end
    table.sort(list, function(left, right)
        if left.priority ~= right.priority then
            return left.priority < right.priority
        end
        return left.id < right.id
    end)
    return list
end

local function normalizeLocomotionEntries(pack, stateKey, raw)
    local entries = {}
    if type(raw) ~= "table" then return entries end
    local list = raw[1] ~= nil and raw or { raw }
    for index = 1, #list do
        local item = list[index]
        if type(item) == "table" then
            local vars = type(item.vars) == "table" and item.vars or item
            entries[#entries + 1] = {
                packId = pack.id,
                priority = tonumber(item.priority) or pack.priority,
                order = index,
                when = type(item.when) == "table" and copyShallow(item.when) or nil,
                profile = {
                    moveAnim = vars.moveAnim,
                    walkType = vars.walkType,
                    engineWalkType = vars.engineWalkType,
                    animSpeed = tonumber(vars.animSpeed),
                    isRunning = vars.isRunning,
                    isCrawling = vars.isCrawling,
                    profileKey = vars.profileKey or stateKey,
                    customVars = type(vars.customVars) == "table"
                        and copyShallow(vars.customVars) or nil,
                },
            }
        end
    end
    return entries
end

local function matchesCondition(when, context)
    if not when then return true end
    if type(context) ~= "table" then return false end
    for key, expected in pairs(when) do
        if context[key] ~= expected then
            return false
        end
    end
    return true
end

function Packs.Recompile()
    local scenes = PNC.AnimationScenes
    local ordered = sortedEnabledPacks()

    -- 1. Restore any base scenes that were previously overridden by packs,
    --    and remove pack-only scenes before reapplying enabled packs.
    if scenes and type(scenes.Register) == "function"
        and type(scenes.Unregister) == "function"
    then
        for sceneId, _ in pairs(Packs.OwnedScenes) do
            if Packs.BaseScenes[sceneId] then
                scenes.Register(sceneId, Packs.BaseScenes[sceneId])
            else
                scenes.Unregister(sceneId)
            end
        end
        Packs.OwnedScenes = {}

        for pIdx = 1, #ordered do
            local pack = ordered[pIdx]
            if type(pack.scenes) == "table" then
                local sceneIds = {}
                for sceneId, _ in pairs(pack.scenes) do
                    sceneIds[#sceneIds + 1] = tostring(sceneId)
                end
                table.sort(sceneIds)
                for sIdx = 1, #sceneIds do
                    local sceneId = sceneIds[sIdx]
                    local spec = pack.scenes[sceneId]
                    if type(spec) == "table" then
                        local mode = string.lower(tostring(spec.mode or "replace"))
                        local targetId = sceneId
                        if mode == "add_to_pool"
                            and scenes.Definitions
                            and scenes.Definitions[targetId]
                            and not Packs.OwnedScenes[targetId]
                        then
                            -- Avoid clobbering an existing scene when adding
                            -- a pool variation under a colliding id.
                            targetId = pack.id .. ":" .. sceneId
                        end
                        if scenes.Definitions
                            and scenes.Definitions[targetId]
                            and not Packs.BaseScenes[targetId]
                            and not Packs.OwnedScenes[targetId]
                        then
                            Packs.BaseScenes[targetId] =
                                scenes.Definitions[targetId]
                        end
                        local ok = scenes.Register(targetId, spec)
                        if ok then
                            Packs.OwnedScenes[targetId] = pack.id
                        end
                    end
                end
            end
        end
    end

    -- 2. Compile locomotion rules sorted highest-priority first per state.
    local compiledLoco = {}
    for pIdx = 1, #ordered do
        local pack = ordered[pIdx]
        if type(pack.locomotion) == "table" then
            for rawState, rawEntries in pairs(pack.locomotion) do
                local stateKey = normalizeStateKey(rawState)
                if stateKey ~= "" then
                    compiledLoco[stateKey] = compiledLoco[stateKey] or {}
                    local bucket = compiledLoco[stateKey]
                    local normalized = normalizeLocomotionEntries(
                        pack, stateKey, rawEntries)
                    for i = 1, #normalized do
                        bucket[#bucket + 1] = normalized[i]
                    end
                end
            end
        end
    end
    for _, bucket in pairs(compiledLoco) do
        table.sort(bucket, function(left, right)
            if left.priority ~= right.priority then
                return left.priority > right.priority
            end
            local leftCond = left.when ~= nil
            local rightCond = right.when ~= nil
            if leftCond ~= rightCond then return leftCond end
            if left.packId ~= right.packId then
                return left.packId > right.packId
            end
            return left.order < right.order
        end)
    end
    Packs.CompiledLocomotion = compiledLoco
    return true
end

function Packs.RegisterPack(packId, spec)
    packId = tostring(packId or "")
    if packId == "" or type(spec) ~= "table" then
        return false, "invalid_animation_pack"
    end
    Packs.Packs[packId] = {
        id = packId,
        priority = tonumber(spec.priority) or 100,
        enabled = spec.enabled ~= false,
        label = tostring(spec.label or packId),
        author = spec.author and tostring(spec.author) or nil,
        locomotion = type(spec.locomotion) == "table"
            and spec.locomotion or nil,
        scenes = type(spec.scenes) == "table" and spec.scenes or nil,
    }
    Packs.Recompile()
    return true, Packs.Packs[packId]
end

function Packs.UnregisterPack(packId)
    packId = tostring(packId or "")
    if packId == "" or not Packs.Packs[packId] then return false end
    Packs.Packs[packId] = nil
    Packs.Recompile()
    return true
end

function Packs.SetPackEnabled(packId, enabled)
    packId = tostring(packId or "")
    local pack = Packs.Packs[packId]
    if not pack then return false end
    pack.enabled = enabled == true
    Packs.Recompile()
    return true
end

function Packs.ListPacks()
    local ordered = sortedEnabledPacks()
    local output = {}
    for i = 1, #ordered do
        output[i] = {
            id = ordered[i].id,
            priority = ordered[i].priority,
            label = ordered[i].label,
            enabled = ordered[i].enabled,
        }
    end
    return output
end

-- O(1) bucket lookup for locomotion stance overrides.
function Packs.ResolveLocomotion(animState, context)
    local stateKey = normalizeStateKey(animState)
    local bucket = Packs.CompiledLocomotion[stateKey]
    if not bucket then return nil end
    for i = 1, #bucket do
        local entry = bucket[i]
        if matchesCondition(entry.when, context) then
            return entry.profile
        end
    end
    return nil
end

return Packs
