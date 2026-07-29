-- Client-only speech and emote presentation for authority-owned commands.

PNC = PNC or {}
PNC.CompanionCommandPresentation = PNC.CompanionCommandPresentation or {}

local Presentation = PNC.CompanionCommandPresentation
local Commands = PNC.CompanionCommands
local Flavor = PNC.CompanionCommandFlavor

Presentation.FlavorRevision = Presentation.FlavorRevision or 0

local function speak(actor, text)
    if not actor or not text or text == "" then return false end
    if actor.Say then
        actor:Say(text)
        return true
    end
    if actor.setHaloNote then
        actor:setHaloNote(text, 255, 255, 255, 300)
        return true
    end
    return false
end

local function targetName(target)
    return tostring(target and (
        target.name
        or target.displayName
        or target.characterWindow and target.characterWindow.displayName
        or target.source and (
            target.source.name
            or target.source.displayName
            or target.source.characterWindow
                and target.source.characterWindow.displayName
        )
    ) or "Companion")
end

local function normalizeTargets(context)
    if type(context) ~= "table" then return {} end
    if type(context.targets) == "table" then return context.targets end
    if context.target then return { context.target } end
    if context.id or context.name or context.displayName
        or context.source
    then
        return { context }
    end
    return {}
end

local function formatTargetNames(targets)
    local count = #targets
    if count <= 0 then return "everyone" end
    if count == 1 then return targetName(targets[1]) end
    if count == 2 then
        return targetName(targets[1])
            .. " and " .. targetName(targets[2])
    end
    return targetName(targets[1])
        .. ", " .. targetName(targets[2])
        .. ", and " .. tostring(count - 2) .. " more"
end

function Presentation.BuildFlavorContext(player, context)
    local targets = normalizeTargets(context)
    local names = formatTargetNames(targets)
    return {
        name = targets[1] and targetName(targets[1]) or "Companion",
        names = names,
        count = #targets,
        player = tostring(player and player.getUsername
            and player:getUsername() or "Survivor"),
    }
end

function Presentation.ShowPlayerFlavor(player, commandID, context)
    local seed
    local text
    local flavorContext
    if not player
        or player.isDead and player:isDead()
    then
        return false
    end
    Presentation.FlavorRevision = Presentation.FlavorRevision + 1
    seed = tostring(player.getUsername and player:getUsername() or "")
        .. ":" .. tostring(PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
        .. ":" .. tostring(Presentation.FlavorRevision)
    flavorContext = Presentation.BuildFlavorContext(player, context)
    text = Flavor and Flavor.Resolve
        and Flavor.Resolve(commandID, "player", seed, flavorContext)
        or nil
    speak(player, text)
    return true
end

function Presentation.PlayCommand(player, commandID, target)
    local definition = Commands and Commands.Get(commandID) or nil
    if not player or not definition
        or player.isDead and player:isDead()
    then
        return false
    end
    if definition.emote and player.playEmote then
        player:playEmote(definition.emote)
    end
    Presentation.ShowPlayerFlavor(player, commandID, {
        target = target,
    })
    return true
end

local function isLocalOwner(snapshot, player)
    local owner = snapshot and snapshot.characterWindow
        and snapshot.characterWindow.ownerUsername or nil
    if not player or owner == nil or not player.getUsername then return false end
    return tostring(owner) == tostring(player:getUsername() or "")
end

function Presentation.SyncAcknowledgement(zombie, snapshot, modData)
    local feedback = snapshot and snapshot.commandFeedback or nil
    local revision = tonumber(feedback and feedback.revision)
    local token
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local text
    if not zombie or not modData or not feedback or revision == nil then
        return false
    end
    token = tostring(feedback.id or "")
        .. ":" .. tostring(revision)
        .. ":" .. tostring(feedback.issuedAt or 0)
    if tostring(modData.PNC_CommandAckToken or "") == token then
        return false
    end
    -- Consume feedback even when it belongs to another player so ownership
    -- changes never replay an old acknowledgement locally.
    modData.PNC_CommandAckToken = token
    if not isLocalOwner(snapshot, player) then return false end
    text = Flavor and Flavor.Resolve
        and Flavor.Resolve(
            feedback.id,
            "npc",
            tostring(snapshot.id or "") .. ":" .. tostring(revision),
            {
                name = tostring(snapshot.displayName or snapshot.name
                    or "Companion"),
                names = tostring(snapshot.displayName or snapshot.name
                    or "Companion"),
                count = 1,
                player = tostring(player and player.getUsername
                    and player:getUsername() or "Survivor"),
            }
        )
        or nil
    return speak(zombie, text)
end

return Presentation
