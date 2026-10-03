local Provider = {}

function Provider.configure(config, source)
    local SAFE_SELECTORS = {
        AttachAnim = true,
        BandageType = true,
        FoodType = true,
        LootPosition = true,
        PourType = true,
        RackAiming = true,
        ReadType = true,
        RemoveBarricade = true,
        SitGroundAnim = true,
        Weapon = true,
        WeaponReloadType = true,
        WearClothingLocation = true,
    }
    local FULL_BODY_PREVIEW_CLIPS = {
        Bob_Asleep = true,
        Bob_Awake = true,
        Bob_EmotePassOut_Back = true,
        Bob_SatChair = true,
        Bob_SatChairIn = true,
        Bob_SitGround_ActionIdle = true,
        Bob_SitGround_Idle = true,
        Bob_SitGround_Making = true,
        Bob_SitGround_RubHands = true,
        Bob_SitGround_SleepIdle = true,
    }

    local function actionName(conditions)
        for _, condition in ipairs(conditions or {}) do
            if condition.name == "PerformingAction" and condition.value
                and condition.value ~= ""
            then
                return condition.value
            end
        end
        return nil
    end

    local function emoteName(conditions)
        for _, condition in ipairs(conditions or {}) do
            if condition.name == "emote" and condition.value
                and condition.value ~= ""
            then
                return condition.value
            end
        end
        return nil
    end

    local function buildPlayerCatalog(rawFiles, resolve)
        local result = {}
        for _, raw in ipairs(rawFiles) do
            if raw.spec.source == "player_native"
                or raw.spec.source == "player_mod"
            then
                local value = resolve(raw)
                local fields = value.fields
                local hasClip = fields.anim ~= nil and fields.anim ~= ""
                local playable
                if raw.spec.source == "player_mod" then
                    playable = hasClip
                else
                    local isEmote = raw.spec.id == "native_emotes"
                    local action = isEmote and nil or actionName(value.conditions)
                    local emote = isEmote and emoteName(value.conditions) or nil
                    playable = hasClip and ((isEmote and emote ~= nil
                        and emote ~= "") or (not isEmote and action ~= nil
                        and action ~= ""))
                end
                if playable then result[fields.anim] = true end
            end
        end
        return result
    end

    local function selectors(conditions)
        local result = {}
        local seen = {}
        for _, condition in ipairs(conditions or {}) do
            local name = condition.name
            local value = condition.value
            if name and name ~= "PerformingAction" and SAFE_SELECTORS[name]
                and value ~= nil and value ~= ""
            then
                local key = name .. "\000" .. tostring(value)
                if not seen[key] then
                    result[#result + 1] = {
                        name = name,
                        kind = condition.kind,
                        value = value,
                    }
                    seen[key] = true
                end
            end
        end
        return result
    end

    local function rootState(relative)
        return relative:match("^([^/]+)/") or relative
    end

    local function xmlEscape(value)
        value = tostring(value or "")
        value = string.gsub(value, "&", "&amp;")
        value = string.gsub(value, "<", "&lt;")
        value = string.gsub(value, ">", "&gt;")
        value = string.gsub(value, '"', "&quot;")
        return value
    end

    local function safeBoolean(value, default)
        if value == nil or value == "" then return default end
        return string.lower(tostring(value)) == "true"
    end

    local function wantsFullBodyPreview(value)
        if value.spec.source == "zombie" then
            if value.fields.upperOnly ~= nil and value.fields.upperOnly ~= "" then
                return safeBoolean(value.fields.upperOnly, true) == false
            end
            return FULL_BODY_PREVIEW_CLIPS[value.fields.anim] == true
        end
        return value.spec.source == "player_native"
            and value.spec.id == "native_actions"
            and FULL_BODY_PREVIEW_CLIPS[value.fields.anim] == true
    end

    local function safeName(value)
        local result = string.gsub(tostring(value or ""), "[^%w]+", "_")
        result = string.gsub(result, "^_+", "")
        result = string.gsub(result, "_+$", "")
        return result ~= "" and result or "Animation"
    end

    local SHORT_STATE_NAMES = {
        ["hitreaction"] = "HR",
        ["hitreactionpvp"] = "PVP",
        ["walktoward"] = "WT",
        ["walktoward-network"] = "WTN",
        ["pathfind"] = "PF",
        ["bumped"] = "BUMP",
        ["attack"] = "ATK",
        ["attack-network"] = "ATKN",
        ["idle"] = "IDLE",
    }

    local function stableShortHash(value)
        local hash = 0
        value = tostring(value or "")
        for index = 1, #value do
            hash = (hash * 31 + string.byte(value, index)) % 16777216
        end
        return string.format("%06x", hash)
    end

    local function bridgeStem(value)
        local stem = safeName(value.fields.name or value.file)
        stem = string.gsub(stem, "^PNC_Anim_", "")
        stem = string.gsub(stem, "^PNC_", "")
        stem = string.gsub(stem, "^Anim_", "")
        return stem ~= "" and stem or "Animation"
    end

    local function bridgeStateSuffix(value)
        local state = rootState(value.relative)
        return SHORT_STATE_NAMES[state]
            or string.upper(string.sub(safeName(state), 1, 6))
    end

    local usedBridgeNames = {}
    for _, raw in ipairs(source.rawFiles) do
        if raw.fields.name and raw.fields.name ~= "" then
            usedBridgeNames[string.lower(raw.fields.name)] = true
        end
    end
    local vanillaPlayerRoot = config.pzRoot .. "/media/AnimSets/player"
    for _, path in ipairs(source.listFiles({
        sourceRoot = vanillaPlayerRoot,
        minDepth = 1,
    })) do
        local fields = source.parseFields(source.readFile(path))
        if fields.name and fields.name ~= "" then
            usedBridgeNames[string.lower(fields.name)] = true
        end
    end

    local function bridgeName(value)
        local base = "PNC_PH_" .. bridgeStem(value)
        local candidates = {
            base,
            base .. "_" .. bridgeStateSuffix(value),
            base .. "_" .. stableShortHash(value.spec.id .. "/"
                .. value.relative),
        }
        for _, candidate in ipairs(candidates) do
            local key = string.lower(candidate)
            if not usedBridgeNames[key] then
                usedBridgeNames[key] = true
                return candidate
            end
        end
        local index = 2
        while true do
            local candidate = candidates[3] .. "_" .. tostring(index)
            local key = string.lower(candidate)
            if not usedBridgeNames[key] then
                usedBridgeNames[key] = true
                return candidate
            end
            index = index + 1
        end
    end

    return {
        actionName = actionName,
        emoteName = emoteName,
        buildPlayerCatalog = buildPlayerCatalog,
        selectors = selectors,
        rootState = rootState,
        xmlEscape = xmlEscape,
        safeBoolean = safeBoolean,
        wantsFullBodyPreview = wantsFullBodyPreview,
        bridgeName = bridgeName,
    }
end

return Provider
