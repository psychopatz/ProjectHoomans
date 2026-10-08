-- Public namespace for the Bandits -> Hoomans inbound damage bridge.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}
PNC.Compatibility.Bandits.IncomingBridge =
    PNC.Compatibility.Bandits.IncomingBridge or {
        installAttempts = 0,
    }

local Bridge = PNC.Compatibility.Bandits.IncomingBridge
Bridge.installAttempts = tonumber(Bridge.installAttempts) or 0
Bridge.metrics = Bridge.metrics or {
    routed = 0,
    rejected = 0,
    requests = 0,
}

return Bridge
