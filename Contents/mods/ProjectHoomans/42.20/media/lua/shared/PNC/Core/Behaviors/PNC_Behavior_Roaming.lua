--[[
    PNC Behavior Roaming
    Faction-neutral roaming that scans for configured enemies before moving.
    Roam modes are registered independently so radius, route, or venue-specific
    variants can be added without changing the behavior coordinator.
]]

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local Registry = PNC.BehaviorRegistry
local JobSystem = PNC.JobSystem
local OrderSystem = PNC.OrderSystem
local Targeting = PNC.BehaviorTargeting
local BehaviorCombat = PNC.BehaviorCombat
local Common = PNC.BehaviorCommon
local Core = PNC.Core
local Const = PNC.Const
local Perception = PNC.Perception

Roaming.Modes = Roaming.Modes or {}

function Roaming.RegisterMode(mode, handler)
    mode = tostring(mode or "")
    if mode == "" or type(handler) ~= "function" then return false end
    Roaming.Modes[mode] = handler
    return true
end

function Roaming.Tick(record, zombie)
    local order = record.orderSpec or {}
    local mode = tostring(order.roamMode or Const.ROAM_MODE_AREA)
    local handler = Roaming.Modes[mode]
    if not handler then
        mode = Const.ROAM_MODE_AREA
        handler = Roaming.Modes[mode]
    end
    if not handler then return false end
    record.activeBehavior = "Roam:" .. mode
    return handler(record, zombie, order) == true
end

Roaming.Internal = Roaming.Internal or {}
Roaming.Internal.Order = {
    Const = Const,
}
require "PNC/Core/Behaviors/PNC_Behavior_Roaming_Order"
local Order = Roaming.Internal.Order

Roaming.Internal.Context = {
    Core = Core,
    Const = Const,
    Targeting = Targeting,
    Common = Common,
}
require "PNC/Core/Behaviors/PNC_Behavior_Roaming_Context"
local Context = Roaming.Internal.Context

Roaming.Internal.AreaMovement = {
    Core = Core,
    Const = Const,
    Common = Common,
    ChooseAreaGoal = Context.ChooseAreaGoal,
    SyncAreaBounds = Context.SyncAreaBounds,
    AreaStateChanged = Context.AreaStateChanged,
    HasActivePassage = Context.HasActivePassage,
    BeginAreaPause = Context.BeginAreaPause,
}
require "PNC/Core/Behaviors/PNC_Behavior_Roaming_AreaMovement"
Roaming.Internal.AreaMode = {
    Core = Core,
    Const = Const,
    Common = Common,
    BehaviorCombat = BehaviorCombat,
    ChooseAreaGoal = Context.ChooseAreaGoal,
    SyncAreaBounds = Context.SyncAreaBounds,
    AreaStateChanged = Context.AreaStateChanged,
    HasActivePassage = Context.HasActivePassage,
    BeginAreaPause = Context.BeginAreaPause,
    ResolveRoamingThreat = Context.ResolveRoamingThreat,
    AreaMovement = Roaming.Internal.AreaMovement,
}
require "PNC/Core/Behaviors/PNC_Behavior_Roaming_AreaMode"
Roaming.RegisterMode(Const.ROAM_MODE_AREA, Roaming.Internal.AreaMode.Run)

Roaming.Internal.PlayerMode = {
    Core = Core,
    Const = Const,
    Common = Common,
    Perception = Perception,
}
require "PNC/Core/Behaviors/PNC_Behavior_Roaming_PlayerMode"
Roaming.RegisterMode(Const.ROAM_MODE_PLAYER, Roaming.Internal.PlayerMode.Run)

Roaming.Internal.RoadMode = {
    Core = Core,
    Const = Const,
    Common = Common,
    BehaviorCombat = BehaviorCombat,
    RandomFraction = Context.RandomFraction,
    BeginAreaPause = Context.BeginAreaPause,
    ResolveRoamingThreat = Context.ResolveRoamingThreat,
    AreaMode = Roaming.Internal.AreaMode.Run,
}
require "PNC/Core/Behaviors/PNC_Behavior_Roaming_RoadMode"
Roaming.RegisterMode(Const.ROAM_MODE_ROAD, Roaming.Internal.RoadMode.Run)

Roaming.Internal.ShelterMode = {
    Core = Core,
    Const = Const,
    Common = Common,
    BehaviorCombat = BehaviorCombat,
    ResolveRoamingThreat = Context.ResolveRoamingThreat,
}
require "PNC/Core/Behaviors/PNC_Behavior_Roaming_ShelterMode"
Roaming.RegisterMode(Const.ROAM_MODE_SHELTER, Roaming.Internal.ShelterMode.Run)
OrderSystem.RegisterNormalizer(Const.ORDER_ROAM, Order.Normalize)
OrderSystem.RegisterNormalizer(Const.ORDER_HOSTILE_ROAM, Order.Normalize)
JobSystem.RegisterOrder(Const.ORDER_ROAM, Const.JOB_ROAM)
JobSystem.RegisterOrder(Const.ORDER_HOSTILE_ROAM, Const.JOB_ROAM)
Registry.Register(Const.JOB_ROAM, Roaming.Tick)

return Roaming
