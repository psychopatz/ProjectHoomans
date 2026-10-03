local Provider = {}

function Provider.configure(config, source, policy, bridge)
    local function build()
        local entries = {}
        local stateCounts = {}
        local sourceCounts = {}
        local generatedBridgeFiles = {}
        local dedupedZombieClips = {}
        local bridgeCount = 0
        local fullBodyBridgeCount = 0
        local dedupedZombieRows = 0
        local playerCatalogClips = policy.buildPlayerCatalog(
            source.rawFiles, source.resolve
        )

        for _, raw in ipairs(source.rawFiles) do
            local value = source.resolve(raw)
            local fields = value.fields
            local spec = value.spec
            local duplicateZombieClip = spec.source == "zombie"
                and fields.anim ~= nil and fields.anim ~= ""
                and playerCatalogClips[fields.anim] == true
            if duplicateZombieClip then
                dedupedZombieRows = dedupedZombieRows + 1
                dedupedZombieClips[fields.anim] = true
            else
                local isNative = spec.source == "player_native"
                local isEmote = spec.id == "native_emotes"
                local action = isNative and policy.actionName(value.conditions)
                    or nil
                local emote = isNative and policy.emoteName(value.conditions)
                    or nil
                local hasClip = fields.anim ~= nil and fields.anim ~= ""
                local entryState
                local mode
                local route
                local playable
                local bridgePath
                local bridgeFile
                local selectedAction = action
                local selectedEmote = emote
                local variables = isNative
                    and (isEmote and {} or policy.selectors(value.conditions))
                    or {}
                local fullBodyPreview = policy.wantsFullBodyPreview(value)
                local compatibility
                local unsupportedReason

                if isNative then
                    entryState = isEmote and "Emote" or action or "unbound"
                    mode = (isEmote or fullBodyPreview) and "emote" or "action"
                    route = fullBodyPreview
                        and "player_emote_bridge" or "native_player"
                    playable = hasClip and (fullBodyPreview or
                        ((isEmote and emote ~= nil and emote ~= "")
                            or (not isEmote and action ~= nil and action ~= "")))
                    compatibility = fullBodyPreview
                        and "full-body player emote preview"
                        or "native player context"
                    if not playable then
                        unsupportedReason =
                            "No supported player action/emote selector"
                    end
                    if playable and fullBodyPreview then
                        local name = policy.bridgeName(value)
                        bridgeFile = name .. ".xml"
                        selectedAction = nil
                        selectedEmote = name
                        bridgePath = bridge.write(value, name, "full_body_emote")
                        generatedBridgeFiles["emote/" .. bridgeFile] = true
                        bridgeCount = bridgeCount + 1
                        fullBodyBridgeCount = fullBodyBridgeCount + 1
                    end
                else
                    entryState = spec.source == "zombie"
                        and policy.rootState(value.relative)
                        or "player/" .. tostring(value.folder)
                    mode = fullBodyPreview and "emote" or "action"
                    route = hasClip and (fullBodyPreview
                        and "player_emote_bridge" or "player_bridge")
                        or "zombie_only"
                    playable = hasClip
                    compatibility = playable and (fullBodyPreview
                        and "experimental full-body player emote bridge"
                        or "experimental player action bridge")
                        or "source graph only"
                    unsupportedReason = not hasClip
                        and "Source XML has no resolved animation clip" or nil
                    if playable then
                        local name = policy.bridgeName(value)
                        bridgeFile = name .. ".xml"
                        if fullBodyPreview then
                            selectedAction = nil
                            selectedEmote = name
                        else
                            selectedAction = name
                        end
                        bridgePath = bridge.write(value, name,
                            fullBodyPreview and "full_body_emote" or "action")
                        generatedBridgeFiles[(fullBodyPreview
                            and "emote/" or "actions/") .. bridgeFile] = true
                        bridgeCount = bridgeCount + 1
                        if fullBodyPreview then
                            fullBodyBridgeCount = fullBodyBridgeCount + 1
                        end
                    end
                end

                local entry = {
                    state = entryState,
                    source = spec.source,
                    sourceState = isNative and spec.statePrefix
                        or spec.statePrefix .. "/" .. tostring(value.folder),
                    mode = mode,
                    route = route,
                    compatibility = compatibility,
                    unsupportedReason = unsupportedReason,
                    folder = value.folder,
                    file = value.file,
                    path = value.path,
                    originalPath = value.path,
                    bridgeFile = bridgeFile,
                    bridgePath = bridgePath,
                    extends = value.extends,
                    node = fields.name,
                    anim = fields.anim,
                    action = selectedAction,
                    emote = selectedEmote,
                    fullBody = fullBodyPreview,
                    looped = policy.safeBoolean(fields.looped, true),
                    speed = tonumber(fields.speed) or 1.0,
                    playable = playable == true,
                    variables = variables,
                    transitionCount = value.transitionCount or 0,
                    conditions = value.conditions,
                    events = value.events,
                }
                entries[#entries + 1] = entry
                stateCounts[entry.state] = (stateCounts[entry.state] or 0) + 1
                sourceCounts[entry.source] =
                    (sourceCounts[entry.source] or 0) + 1
            end
        end

        local dedupedZombieClipCount = 0
        for _ in pairs(dedupedZombieClips) do
            dedupedZombieClipCount = dedupedZombieClipCount + 1
        end
        return {
            entries = entries,
            stateCounts = stateCounts,
            sourceCounts = sourceCounts,
            bridgeCount = bridgeCount,
            fullBodyBridgeCount = fullBodyBridgeCount,
            dedupedZombieRows = dedupedZombieRows,
            dedupedZombieClipCount = dedupedZombieClipCount,
            generatedBridgeFiles = generatedBridgeFiles,
        }
    end

    local function quote(value)
        if value == nil then return "nil" end
        return string.format("%q", tostring(value))
    end

    local function write(result)
        table.sort(result.entries, function(left, right)
            if left.state ~= right.state then return left.state < right.state end
            if left.source ~= right.source then return left.source < right.source end
            return (left.file or "") < (right.file or "")
        end)

        local output = {}
        local function line(value) output[#output + 1] = value end
        line("-- GENERATED FILE. Do not edit by hand.")
        line("-- Sources: vanilla player, mod player, and zombie AnimSets ("
            .. tostring(#result.entries) .. " XML nodes; "
            .. tostring(result.bridgeCount) .. " static player bridges)")
        line("PNC = PNC or {}")
        line("PNC.PlayerAnimationDebugCatalog = {")
        line("    generatedCount = " .. tostring(#result.entries) .. ",")
        line("    bridgeCount = " .. tostring(result.bridgeCount) .. ",")
        line("    fullBodyBridgeCount = "
            .. tostring(result.fullBodyBridgeCount) .. ",")
        line("    dedupe = {")
        line("        zombieRowsRemoved = "
            .. tostring(result.dedupedZombieRows) .. ",")
        line("        zombieClipsRemoved = "
            .. tostring(result.dedupedZombieClipCount) .. ",")
        line("        policy = \"resolved zombie m_AnimName already playable from player catalog\",")
        line("    },")
        line("    sourceCounts = {")
        local sources = {}
        for sourceName in pairs(result.sourceCounts) do
            sources[#sources + 1] = sourceName
        end
        table.sort(sources)
        for _, sourceName in ipairs(sources) do
            line("        [" .. quote(sourceName) .. "] = "
                .. tostring(result.sourceCounts[sourceName]) .. ",")
        end
        line("    },")
        line("    stateCounts = {")
        local states = {}
        for state in pairs(result.stateCounts) do states[#states + 1] = state end
        table.sort(states)
        for _, state in ipairs(states) do
            line("        [" .. quote(state) .. "] = "
                .. tostring(result.stateCounts[state]) .. ",")
        end
        line("    },")
        line("    entries = {")
        for _, entry in ipairs(result.entries) do
            line("        {")
            line("            state = " .. quote(entry.state) .. ",")
            line("            source = " .. quote(entry.source) .. ",")
            line("            sourceState = " .. quote(entry.sourceState) .. ",")
            line("            mode = " .. quote(entry.mode) .. ",")
            line("            route = " .. quote(entry.route) .. ",")
            line("            compatibility = " .. quote(entry.compatibility) .. ",")
            line("            unsupportedReason = "
                .. quote(entry.unsupportedReason) .. ",")
            line("            folder = " .. quote(entry.folder) .. ",")
            line("            file = " .. quote(entry.file) .. ",")
            line("            path = " .. quote(entry.path) .. ",")
            line("            originalPath = " .. quote(entry.originalPath) .. ",")
            line("            bridgeFile = " .. quote(entry.bridgeFile) .. ",")
            line("            bridgePath = " .. quote(entry.bridgePath) .. ",")
            line("            extends = " .. quote(entry.extends) .. ",")
            line("            node = " .. quote(entry.node) .. ",")
            line("            anim = " .. quote(entry.anim) .. ",")
            line("            action = " .. quote(entry.action) .. ",")
            line("            emote = " .. quote(entry.emote) .. ",")
            line("            fullBody = " .. tostring(entry.fullBody) .. ",")
            line("            looped = " .. tostring(entry.looped) .. ",")
            line("            speed = " .. tostring(entry.speed) .. ",")
            line("            playable = " .. tostring(entry.playable) .. ",")
            line("            transitionCount = "
                .. tostring(entry.transitionCount) .. ",")
            line("            variables = {")
            for _, variable in ipairs(entry.variables or {}) do
                line("                { name = " .. quote(variable.name)
                    .. ", kind = " .. quote(variable.kind)
                    .. ", value = " .. quote(variable.value) .. " },")
            end
            line("            },")
            line("            conditions = {")
            for _, condition in ipairs(entry.conditions or {}) do
                line("                { name = " .. quote(condition.name)
                    .. ", kind = " .. quote(condition.kind)
                    .. ", value = " .. quote(condition.value) .. " },")
            end
            line("            },")
            line("            events = {")
            for _, event in ipairs(entry.events or {}) do
                line("                { name = " .. quote(event.name)
                    .. ", time = " .. quote(event.time)
                    .. ", parameter = " .. quote(event.parameter) .. " },")
            end
            line("            },")
            line("        },")
        end
        line("    },")
        line("}")
        line("")
        line("return PNC.PlayerAnimationDebugCatalog")

        local outputFile = assert(io.open(config.outputPath, "wb"))
        outputFile:write(table.concat(output, "\n"))
        outputFile:close()
        print("Generated " .. config.outputPath .. " with "
            .. tostring(#result.entries) .. " entries and "
            .. tostring(result.bridgeCount) .. " player bridges")
    end

    return { build = build, write = write }
end

return Provider
