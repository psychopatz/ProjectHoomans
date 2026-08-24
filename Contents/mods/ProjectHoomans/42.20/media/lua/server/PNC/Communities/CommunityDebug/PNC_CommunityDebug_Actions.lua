if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunityDebug = PNC.CommunityDebug or {}
PNC.CommunityDebugInternal = PNC.CommunityDebugInternal or {}

local Debug = PNC.CommunityDebug
local H = PNC.CommunityDebugInternal
local Communities = PNC.Communities
local CommunityMath = PNC.CommunityMath
local Constants = PNC.CommunityConstants
local Core = PNC.Core

function Debug.PerformAction(player, args)
    local action = tostring(
        args and args.communityAction or ""
    )
    local communityID = args and args.communityID
    local factionID = args and args.factionID
    local npcID = args and args.npcID
    local at = H.WorldAgeHours()
    local ok
    local reason
    local value
    if action == "create_settlement"
        or action == "create_camp"
    then
        local record = npcID and PNC.Registry.Get(npcID)
            or nil
        local x = record and record.x
            or player and player.getX and player:getX()
        local y = record and record.y
            or player and player.getY and player:getY()
        local z = record and record.z
            or player and player.getZ and player:getZ()
        local mode = action == "create_camp"
            and "camped" or "settled"
        ok, reason, value = Communities.Create({
            factionID = factionID,
            name = mode == "camped"
                and "Debug Community Camp "
                    .. tostring(math.floor(at * 1000))
                or "Debug Community Settlement "
                    .. tostring(math.floor(at * 1000)),
            mode = mode,
            home = { x = x, y = y, z = z },
            createdAt = at,
        })
        if ok then
            communityID = value.id
            local site = PNC.CommunitySiteResolver
                and PNC.CommunitySiteResolver.DescribeAt
                and PNC.CommunitySiteResolver.DescribeAt(
                    x,
                    y,
                    z,
                    { createdAt = at }
                ) or nil
            if site then
                ok, reason, value = Communities.ReserveSite(
                    communityID,
                    site,
                    at
                )
            end
        end
    elseif action == "assign" then
        ok, reason, value = Communities.AddNPC(
            communityID,
            npcID,
            {
                communityRole = args.communityRole,
                joinedAt = at,
            }
        )
    elseif action == "transfer" then
        ok, reason, value = Communities.TransferNPC(
            npcID,
            communityID,
            {
                communityRole = args.communityRole,
                worldAgeHours = at,
            }
        )
    elseif action == "remove" then
        ok, reason, value = Communities.RemoveNPC(
            communityID,
            npcID,
            "debug_removed",
            at
        )
    elseif action == "leader" then
        ok, reason, value = Communities.SetLeader(
            communityID,
            npcID,
            at
        )
    elseif action == "role" then
        if args.communityRole == "leader" then
            ok, reason, value = Communities.SetLeader(
                communityID,
                npcID,
                at
            )
        else
            ok, reason, value = Communities.AddNPC(
                communityID,
                npcID,
                {
                    communityRole = args.communityRole,
                    joinedAt = at,
                }
            )
        end
    elseif action == "set_home_to_npc" then
        local record = npcID and PNC.Registry.Get(npcID)
            or nil
        if not record then
            ok, reason = false, "npc_not_found"
        else
            local community = Communities.Get(communityID)
            ok, reason, value = Communities.SetHome(
                communityID,
                {
                    x = record.x,
                    y = record.y,
                    z = record.z,
                    radius = community
                        and community.home.radius,
                }
            )
        end
    elseif action == "security" then
        local community = Communities.Get(communityID)
        if not community then
            ok, reason = false, "community_not_found"
        else
            ok, reason, value = Communities.SetSecurity(
                communityID,
                community.security
                    + (tonumber(args.delta) or 0)
            )
        end
    elseif action == "morale" then
        local community = Communities.Get(communityID)
        if not community then
            ok, reason = false, "community_not_found"
        else
            ok, reason, value = Communities.SetMorale(
                communityID,
                community.morale
                    + (tonumber(args.delta) or 0)
            )
        end
    elseif action == "supply_add" then
        ok, reason, value = Communities.AddSupply(
            communityID,
            args.category,
            tonumber(args.amount) or 0
        )
    elseif action == "supply_remove" then
        ok, reason, value = Communities.RemoveSupply(
            communityID,
            args.category,
            tonumber(args.amount) or 0
        )
    elseif action == "archive" then
        ok, reason, value = Communities.Archive(
            communityID,
            "manual_debug",
            at
        )
    elseif action == "destroy" then
        ok, reason, value = Communities.Destroy(
            communityID,
            "manual_debug",
            at
        )
    elseif action == "claim_site" then
        local playerKey = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetEntityKey
            and PNC.PlayerCharacters.GetEntityKey(player, {
                callback = "community_site_claim",
                worldAgeHours = at,
            }) or nil
        ok, reason, value = Communities.ClaimSite(
            args and args.siteID,
            playerKey,
            at
        )
    elseif action == "unclaim_site" then
        local playerKey = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetEntityKey
            and PNC.PlayerCharacters.GetEntityKey(player, {
                callback = "community_site_unclaim",
                worldAgeHours = at,
            }) or nil
        ok, reason, value = Communities.UnclaimSite(
            args and args.siteID,
            playerKey
        )
    elseif action == "validate" then
        Debug.LastValidation =
            PNC.CommunityValidation.ValidateRegistry()
        ok = Debug.LastValidation.ok
        reason = ok and "registry_valid"
            or "registry_invalid"
    elseif action == "repair_indexes" then
        local changed =
            PNC.CommunityValidation.RepairIndexes()
        Debug.LastValidation =
            PNC.CommunityValidation.ValidateRegistry()
        ok = true
        reason = changed and "indexes_repaired"
            or "indexes_already_valid"
    else
        ok, reason = false, "unsupported_community_action"
    end
    return Debug.BuildSnapshot(
        communityID,
        factionID,
        npcID,
        H.ActionResult(ok, reason, action),
        player
    )
end

return Debug

