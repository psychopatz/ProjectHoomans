-- Headless conversation host creation and retargeting for inline chat.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

require "PNC/Conversation/PNC_ConversationTime"
require "PNC/Conversation/PNC_ConversationGroup"
pcall(require, "PNC/ConvoEngine/RuntimeFacade")

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local Resolver = PNC.CompanionTargetResolver
local State = InlineChat.State
local SemanticRuntime = PNC.Conversation and PNC.Conversation.Semantic
if SemanticRuntime and type(SemanticRuntime.Register) == "function" then
    SemanticRuntime.Register(PNC.Conversation, PNC.Conversation.Group, PNC.Conversation.Time)
end
local Hosts = Internal.Hosts or {}
Internal.Hosts = Hosts

function Hosts.Build(entry, player)
    if not PNC.Conversation.BuildDefinition or not PsychopatzCore.Conversation.CreateHeadless then
        if print then
            print("[PNC][InlineChat] inline_host_failed reason=dependencies_unavailable")
        end
        return nil
    end
    local definition = PNC.Conversation.BuildDefinition(entry, player)
    definition.context = definition.context or {}
    definition.context.nameplateConversation = true
    definition.context.guardThreats = false
    local host = PsychopatzCore.Conversation.CreateHeadless(definition)
    if not host or host.lifecycleError then
        if print then
            print("[PNC][InlineChat] inline_host_failed reason="
                .. tostring(host and host.lifecycleError or "create_headless"))
        end
        return nil
    end
    host.inlineChat = true
    host.pbrainz = true
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
    local oldHosts, newHosts, createdHosts, entries = {}, {}, {}, {}
    local targets = resolved and resolved.targets or {}
    local primaryTarget = resolved and (resolved.primary or resolved.target) or nil
    local mode = Resolver.NormalizeMode(requestedMode or State.mode or Config.MODE_NEAREST)
    local primaryID = tostring(primaryTarget and primaryTarget.id or "")
    local primaryIndex
    if not primaryTarget then return false, "no_primary_target" end
    for _, old in ipairs(State.hosts or {}) do
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
                    if created and created.close then created:close("inline_target_build_failed") end
                end
                return false, "target_host_build_failed:" .. id
            end
        end
    end
    if #newHosts == 0 then
        for _, created in ipairs(createdHosts) do
            if created and created.close then created:close("inline_target_build_failed") end
        end
        return false, "no_hosts"
    end
    for _, unused in pairs(oldHosts) do
        if unused and unused.close then unused:close("inline_retargeted") end
    end
    primaryIndex = primaryIndex or 1
    State.entries = entries
    State.hosts = newHosts
    State.target = entries[primaryIndex]
    State.targetID = tostring(State.target.id)
    State.host = newHosts[primaryIndex]
    State.groupConversation = nil
    if mode == Config.MODE_NEARBY and #newHosts > 1
        and SemanticRuntime and type(SemanticRuntime.CreateGroup) == "function"
    then
        local group, reason = SemanticRuntime.CreateGroup(State.host, newHosts, entries, player, { mode = mode })
        if group then
            State.groupConversation = group
        elseif print then
            print("[PNC][InlineChat] inline_group_failed reason=" .. tostring(reason or "group_create_failed"))
        end
    end
    for _, host in ipairs(newHosts) do
        if not State.groupConversation then
            host.groupConversation = nil
            host.groupMemberID = nil
            host.groupPrimary = nil
        end
    end
    return true
end

function Hosts.RefreshLocked(player)
    local entries = State.entries or {}
    local hosts = State.hosts or {}
    for index, entry in ipairs(entries) do
        local refreshed = Resolver.BuildConversationEntry({
            id = entry.id, source = entry.source, record = entry.record,
            snapshot = entry.snapshot, zombie = entry.zombie,
        })
        if refreshed and tostring(refreshed.id or "") ~= "" then
            refreshed.name = refreshed.name or entry.name
            entries[index] = refreshed
            Hosts.RefreshContext(hosts[index], refreshed, player)
            if State.targetID and tostring(State.targetID) == tostring(refreshed.id) then
                State.target = refreshed
            end
        end
    end
    if State.groupConversation and type(State.groupConversation.Rebind) == "function" then
        local rebound = State.groupConversation:Rebind(hosts, entries, State.host)
        if not rebound then
            State.groupConversation = nil
            for _, host in ipairs(hosts) do
                host.groupConversation = nil
                host.groupMemberID = nil
                host.groupPrimary = nil
            end
        else
            State.host = State.groupConversation:PrimaryView()
            local primary = State.groupConversation:MemberForHost(State.host)
            State.target = primary and primary.entry or State.target
            State.targetID = State.target and tostring(State.target.id or "") or State.targetID
        end
    end
end

InlineChat.RebuildHosts = function(player, resolved, mode)
    return Hosts.Rebuild(player, resolved, mode)
end

return Hosts
