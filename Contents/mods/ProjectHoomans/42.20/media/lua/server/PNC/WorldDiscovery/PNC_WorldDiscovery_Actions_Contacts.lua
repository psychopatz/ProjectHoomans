if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes

function Discovery.CallContact(player, kind, entityID)
    local record, reason = Internal.PlayerRecord(player, true)
    if not record then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = reason,
        })
    end
    kind = tostring(kind or "")
    entityID = tostring(entityID or "")
    if not Types.IsKind(kind) or entityID == "" then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "invalid_contact",
        })
    end
    local entry = record.entities[kind]
        and record.entities[kind][entityID] or nil
    local phase = Types.ClampPhase(entry and entry.phase)
    if not entry or phase < Types.PHASE_RUMORED then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "contact_not_known",
            entityID = entityID, kind = kind,
        })
    end
    local entity = Discovery.ResolveEntity(kind, entityID)
    if not entity then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "entity_not_found",
            entityID = entityID, kind = kind,
        })
    end
    local updated, advanceReason
    if phase < Types.PHASE_LOCATED then
        updated, advanceReason = Discovery.SetResolvedPhase(
            player, entity, Types.PHASE_LOCATED, "contact_call", true)
        if not updated then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = advanceReason,
                entityID = entityID, kind = kind,
            })
        end
        Discovery.Save()
        phase = Types.PHASE_LOCATED
    else
        updated = entry
    end
    return Discovery.BuildSnapshot(player, {
        ok = true,
        reason = phase == Types.PHASE_LOCATED
            and advanceReason == "advanced"
            and "contact_located" or "contact_already_located",
        entityID = entityID,
        kind = kind,
        phase = phase,
        mapUpdated = advanceReason == "advanced",
        factionKnown = updated and updated.factionKnown == true or false,
    })
end

function Discovery.CanUseDebug(player)
    local coreDebug = PsychopatzCore and PsychopatzCore.Debug
    if not coreDebug or type(coreDebug.CanUse) ~= "function" then
        local ok, loaded = pcall(require, "PsychopatzCore/Debug/PsychopatzDebug")
        if ok then coreDebug = loaded end
    end
    return coreDebug and coreDebug.CanUse
        and coreDebug.CanUse(player) == true or false
end

function Discovery.HandleAction(player, args)
    args = type(args) == "table" and args or {}
    local action = tostring(args.action or "snapshot")
    if action == "radio_ambient" then
        return Discovery.RadioAmbient(player, args.channelID, args.frequency)
    end
    if action == "radio_scan" then
        return Discovery.RadioScan(player, args.channelID, args.frequency)
    end
    if action == "call_contact" then
        return Discovery.CallContact(player, args.kind, args.entityID)
    end
    if action == "debug_discover" then
        if not Discovery.CanUseDebug(player) then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = "not_authorized",
            })
        end
        local entry, reason = Discovery.SetPhase(
            player, tostring(args.kind or ""),
            tostring(args.entityID or ""),
            Types.PHASE_LOCATED, "debug_map"
        )
        return Discovery.BuildSnapshot(player, {
            ok = entry ~= nil,
            reason = reason,
            entityID = args.entityID,
            kind = args.kind,
            phase = entry and entry.phase,
        })
    end
    if action == "debug_discover_all" then
        if not Discovery.CanUseDebug(player) then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = "not_authorized",
            })
        end
        local scope = tostring(args.scope or "all")
        local requestedKind = scope == "settlements"
            and Types.KIND_SETTLEMENT
            or scope == "mobile_groups"
                and Types.KIND_MOBILE_GROUP or nil
        if scope ~= "all" and not requestedKind then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = "invalid_scope",
            })
        end
        local advanced = 0
        for _, entity in ipairs(Discovery.ListWorldEntities()) do
            if not requestedKind or entity.kind == requestedKind then
                local _, reason = Discovery.SetPhase(
                    player, entity.kind, entity.entityID,
                    Types.PHASE_LOCATED, "debug_map_all", true
                )
                if reason == "advanced" then advanced = advanced + 1 end
            end
        end
        Discovery.Save()
        return Discovery.BuildSnapshot(player, {
            ok = true,
            reason = "debug_discovered_all",
            scope = scope,
            count = advanced,
        })
    end
    if action == "debug_reset" then
        if not Discovery.CanUseDebug(player) then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = "not_authorized",
            })
        end
        local ok, reason = Discovery.ResetPlayer(player)
        return Discovery.BuildSnapshot(player, {
            ok = ok == true,
            reason = ok and "debug_reset" or reason,
        })
    end
    return Discovery.BuildSnapshot(player)
end

function Discovery.DiscoverNPCContext(player, npcID)
    local npc = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    local affiliation = npc and npc.affiliation or {}
    local changed = false
    local dirty = false
    if affiliation.communityID then
        local entity = Discovery.ResolveEntity(
            Types.KIND_SETTLEMENT, affiliation.communityID)
        local _, reason = Discovery.SetPhase(
            player,
            Types.KIND_SETTLEMENT,
            affiliation.communityID,
            Types.PHASE_CONTACTED,
            "conversation",
            true
        )
        changed = changed or reason == "advanced"
        dirty = dirty or reason == "advanced"
        if entity then
            local _, arrivalReason = Discovery.MarkContacted(
                player, entity, "conversation", true)
            changed = changed or arrivalReason == "advanced"
            dirty = dirty or arrivalReason == "advanced"
        end
    end
    if affiliation.factionID and PNC.AbstractGroups
        and PNC.AbstractGroups.FindByFactionID
    then
        local group = PNC.AbstractGroups.FindByFactionID(
            affiliation.factionID)
        if group then
            local entity = Discovery.ResolveEntity(
                Types.KIND_MOBILE_GROUP, group.id)
            local _, reason = Discovery.SetPhase(
                player,
                Types.KIND_MOBILE_GROUP,
                group.id,
                Types.PHASE_CONTACTED,
                "conversation",
                true
            )
            changed = changed or reason == "advanced"
            dirty = dirty or reason == "advanced"
            if entity then
                local _, arrivalReason = Discovery.MarkContacted(
                    player, entity, "conversation", true)
                changed = changed or arrivalReason == "advanced"
                dirty = dirty or arrivalReason == "advanced"
            end
        end
    end
    if dirty then Discovery.Save() end
    if changed and PNC.Network and PNC.Network.SendWorldDiscovery then
        PNC.Network.SendWorldDiscovery(player,
            Discovery.BuildSnapshot(player, {
                ok = true, reason = "contacted",
            }))
    end
    return changed
end

