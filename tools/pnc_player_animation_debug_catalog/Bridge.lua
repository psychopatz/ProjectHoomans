local Provider = {}

function Provider.configure(config, policy)
    local function shellQuote(value)
        return "'" .. string.gsub(tostring(value), "'", "'\\''") .. "'"
    end

    local function writeTag(lines, tag, value)
        if value ~= nil and value ~= "" then
            lines[#lines + 1] = "\t<" .. tag .. ">"
                .. policy.xmlEscape(value) .. "</" .. tag .. ">"
        end
    end

    local function writeBridge(value, name, bridgeMode)
        local fields = value.fields
        local fullBody = bridgeMode == "full_body_emote"
        local outputRoot = fullBody and config.emoteBridgeRoot
            or config.bridgeRoot
        local outputMediaRoot = fullBody and config.emoteBridgeMediaRoot
            or config.bridgeMediaRoot
        local bridgePath = outputRoot .. "/" .. name .. ".xml"
        local lines = {
            '<?xml version="1.0" encoding="utf-8"?>',
            "<animNode>",
        }
        writeTag(lines, "m_Name", name)
        writeTag(lines, "m_AnimName", fields.anim)
        writeTag(lines, "m_Priority", fields.priority)
        writeTag(lines, "m_ConditionPriority", fields.conditionPriority)
        writeTag(lines, "m_deferredBoneAxis", fields.deferredBoneAxis)
        writeTag(lines, "m_SyncTrackingEnabled", fields.syncTrackingEnabled)
        writeTag(lines, "m_useDeferredMovement", fields.useDeferredMovement)
        writeTag(lines, "m_deferredRotationScale", fields.deferredRotationScale)
        writeTag(lines, "m_Looped", tostring(policy.safeBoolean(
            fields.looped, true)))
        writeTag(lines, "m_EarlyTransitionOut", fields.earlyTransitionOut)
        writeTag(lines, "m_StopAnimOnExit", fields.stopAnimOnExit)
        writeTag(lines, "m_SpeedScale", tonumber(fields.speed) or "1.00")
        writeTag(lines, "m_BlendTime", fields.blendTime)
        writeTag(lines, "m_BlendOutTime", fields.blendOutTime)
        lines[#lines + 1] = "\t<m_Conditions>"
        lines[#lines + 1] = "\t\t<m_Name>"
            .. (fullBody and "emote" or "PerformingAction") .. "</m_Name>"
        lines[#lines + 1] = "\t\t<m_Type>STRING</m_Type>"
        lines[#lines + 1] = "\t\t<m_Value>"
            .. policy.xmlEscape(name) .. "</m_Value>"
        lines[#lines + 1] = "\t</m_Conditions>"
        if fullBody then
            if not policy.safeBoolean(fields.looped, true) then
                lines[#lines + 1] = "\t<m_Events>"
                lines[#lines + 1] = "\t\t<m_EventName>EmoteFinishing</m_EventName>"
                lines[#lines + 1] = "\t\t<m_Time>End</m_Time>"
                lines[#lines + 1] = "\t\t<m_ParameterValue></m_ParameterValue>"
                lines[#lines + 1] = "\t</m_Events>"
            end
            lines[#lines + 1] = "\t<m_SubStateBoneWeights>"
            lines[#lines + 1] = "\t\t<boneName>Bip01</boneName>"
            lines[#lines + 1] = "\t\t<includeDescendants>true</includeDescendants>"
            lines[#lines + 1] = "\t</m_SubStateBoneWeights>"
        end
        lines[#lines + 1] = "</animNode>"

        local file = assert(io.open(bridgePath, "wb"))
        file:write(table.concat(lines, "\n"), "\n")
        file:close()
        return outputMediaRoot .. name .. ".xml"
    end

    local function removeStale(root, directory, generatedBridgeFiles)
        local stalePipe = assert(io.popen("find " .. shellQuote(root)
            .. " -maxdepth 1 -type f \\( -name 'PNC_PlayerBridge_*.xml'"
            .. " -o -name 'PNC_PH_*.xml' \\)"))
        for path in stalePipe:lines() do
            local file = path:match("([^/]+)$")
            if not generatedBridgeFiles[directory .. file] then
                assert(os.remove(path))
            end
        end
        assert(stalePipe:close())
    end

    assert(os.execute("mkdir -p " .. shellQuote(config.bridgeRoot)))
    assert(os.execute("mkdir -p " .. shellQuote(config.emoteBridgeRoot)))

    return {
        write = writeBridge,
        removeStale = removeStale,
    }
end

return Provider
