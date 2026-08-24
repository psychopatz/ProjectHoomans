if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}
PNC.Communities.Internal = PNC.Communities.Internal or {}

local Communities = PNC.Communities
local Internal = Communities.Internal
local Core = PNC.Core
local Constants = PNC.CommunityConstants
local Types = PNC.CommunityTypes
local CommunityMath = PNC.CommunityMath
local FactionTypes = PNC.FactionTypes
local rebuildDerivedIndexes = Internal.rebuildDerivedIndexes

function Communities.RebuildIndexes()
    Communities.EnsureLoaded()
    return rebuildDerivedIndexes()
end

function Communities.ValidateRegistry()
    Communities.EnsureLoaded()
    if PNC.CommunityValidation
        and PNC.CommunityValidation.ValidateRegistry
    then
        return PNC.CommunityValidation.ValidateRegistry()
    end
    return nil, "validator_unavailable"
end

Communities.IsInsideHomeArea =
    CommunityMath.IsInsideHomeArea
Communities.GetDistanceFromHome =
    CommunityMath.GetDistanceFromHome
Communities.NormalizeRegistry = Types.NormalizeRegistry
Communities.NormalizeCommunity = Types.NormalizeCommunity

local function onInitGlobalModData()
    Communities.Load()
end

if Events and Events.OnInitGlobalModData
    and not Communities.GlobalModDataHookRegistered
then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
    Communities.GlobalModDataHookRegistered = true
end


return Communities
