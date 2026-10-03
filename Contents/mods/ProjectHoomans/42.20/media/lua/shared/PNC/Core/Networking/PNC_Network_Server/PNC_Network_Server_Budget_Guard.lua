PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

local Network = PNC.Network
local Internal = Network.Internal
local Const = PNC.Const
local Budget = Network.PayloadBudget or {}
Network.PayloadBudget = Budget
Internal.PayloadBudget = Budget
local Deps = Internal.PayloadBudgetCore or {}
local isModModule = Deps.isModModule

local function serverRunning()
    if type(isServer) ~= "function" then return false end
    local ok, value = pcall(isServer)
    return ok and value == true
end

--[[
    Safety net: every mod file that calls the vanilla `sendServerCommand`
    directly still goes through the budget. Only this mod's module is
    inspected, so vanilla and third-party traffic pays a single string compare.

    The wrapper is tracked with a module flag instead of a field on the bound
    Java function, because arbitrary keys cannot be set on engine functions.
]]
function Internal.InstallSendGuard()
    if Internal.SendGuardInstalled == true then return true end
    if not serverRunning() then return false end
    local current = sendServerCommand
    if current == nil then return false end
    Internal.RawSendServerCommand = current
    local function guardedSend(a, b, c, d)
        if type(a) == "string" then
            -- sendServerCommand(module, command, args) broadcast form.
            if not isModModule(a) then
                return Internal.RawSendServerCommand(a, b, c)
            end
            return Internal.SendGuarded(nil, a, b, c)
        end
        -- sendServerCommand(player, module, command, args) targeted form.
        if not isModModule(b) then
            return Internal.RawSendServerCommand(a, b, c, d)
        end
        return Internal.SendGuarded(a, b, c, d)
    end
    sendServerCommand = guardedSend
    Internal.SendGuardInstalled = true
    return true
end

if type(Internal.RawSendServerCommand) ~= "function"
    and type(sendServerCommand) == "function"
then
    Internal.RawSendServerCommand = sendServerCommand
end

Internal.InstallSendGuard()

return Budget
