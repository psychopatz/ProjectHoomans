-- Headless conversation host creation and retargeting.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Config = Internal.InlineChatConfig
local Resolver = PNC.CompanionTargetResolver
local Inline = Integration.Inline
local Hosts = Internal.InlineChatHosts or {}
Internal.InlineChatHosts = Hosts

function Hosts.Build(entry, player)
    if not PNC.Conversation.BuildDefinition
        or not PsychopatzCore.Conversation.CreateHeadless
    then
        return nil
    end
    local definition = PNC.Conversation.BuildDefinition(entry, player)
    definition.context = definition.context or {}
    definition.context.nameplateConversation = true
    definition.context.guardThreats = false
    local host = PsychopatzCore.Conversation.CreateHeadless(definition)
    if not host then
        if print then
            print("[PNC][LLM] inline_host_failed reason=create_headless")
        end
        return nil
    end
    if host.lifecycleError then
        if print then
            print("[PNC][LLM] inline_host_failed reason=lifecycle "
                .. tostring(host.lifecycleError))
        end
        return nil
    end
    host.hoomansLLM = true
    return host
end

function Hosts.RefreshContext(host, entry, player)
    if not host or not host.spec then return end
    local context = host.spec.context or {}
    context.entry = entry
    context.player = player
    context.nameplateConversation = true
    context.guardThreats = false
    host.spec.context = context
    host.spec.character = entry and entry.zombie or nil
end

function Hosts.Rebuild(player, resolved, requestedMode)
    local oldHosts = {}
    local newHosts = {}
    local createdHosts = {}
    local entries = {}
    local targets = resolved and resolved.targets or {}
    local primaryTarget = resolved
        and (resolved.primary or resolved.target) or nil
    local mode = Resolver.NormalizeMode(
        requestedMode or Inline.mode or Config.MODE_NEAREST
    )
    local primaryID = tostring(primaryTarget and primaryTarget.id or "")
    local primaryIndex
    if not primaryTarget then return false end
    for _, old in ipairs(Inline.hosts or {}) do
        local id = tostring(old and old.spec and old.spec.npcID or "")
        if id ~= "" then oldHosts[id] = old end
    end
    for _, candidate in ipairs(targets) do
        local entry = Resolver.BuildConversationEntry(candidate)
        local id = tostring(entry and entry.id or "")
        if id ~= "" then
            local host = oldHosts[id]
            if host and host.closed then
                host = nil
                oldHosts[id] = nil
            end
            if not host then
                host = Hosts.Build(entry, player)
                if host then createdHosts[#createdHosts + 1] = host end
            end
            if host then
                Hosts.RefreshContext(host, entry, player)
                oldHosts[id] = nil
                entries[#entries + 1] = entry
                newHosts[#newHosts + 1] = host
                if id == primaryID then primaryIndex = #entries end
            elseif mode ~= Config.MODE_NEARBY then
                for _, created in ipairs(createdHosts) do
                    if created and created.close then
                        created:close("inline_target_build_failed")
                    end
                end
                return false
            end
        end
    end
    if #newHosts == 0 then
        for _, created in ipairs(createdHosts) do
            if created and created.close then
                created:close("inline_target_build_failed")
            end
        end
        return false
    end
    for _, unused in pairs(oldHosts) do
        if unused and unused.close then unused:close("inline_retargeted") end
    end
    primaryIndex = primaryIndex or 1
    Inline.entries = entries
    Inline.hosts = newHosts
    Inline.target = entries[primaryIndex]
    Inline.targetID = tostring(Inline.target.id)
    Inline.host = newHosts[primaryIndex]
    return true
end

function Hosts.RefreshLocked(player)
    local entries = Inline.entries or {}
    local hosts = Inline.hosts or {}
    for index, entry in ipairs(entries) do
        local refreshed = Resolver.BuildConversationEntry({
            id = entry.id,
            source = entry.source,
            record = entry.record,
            snapshot = entry.snapshot,
            zombie = entry.zombie,
        })
        if refreshed and tostring(refreshed.id or "") ~= "" then
            refreshed.name = refreshed.name or entry.name
            entries[index] = refreshed
            Hosts.RefreshContext(hosts[index], refreshed, player)
            if Inline.targetID
                and tostring(Inline.targetID) == tostring(refreshed.id)
            then
                Inline.target = refreshed
            end
        end
    end
end

Integration.RebuildInlineHosts = function(player, resolved, mode)
    return Hosts.Rebuild(player, resolved, mode)
end

return Hosts
