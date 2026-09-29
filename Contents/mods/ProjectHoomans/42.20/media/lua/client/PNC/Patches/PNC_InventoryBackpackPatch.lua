--[[
    Vanilla inventory backpack refresh guard.

    Build 42.20 `ISInventoryPage:refreshBackpacks()` walks the vehicle containers
    of every nearby square without checking the part it just asked for:

        for partIndex = 1, vehicle:getPartCount() do
            local vehiclePart = vehicle:getPartByIndex(partIndex - 1)
            if vehiclePart:getItemContainer() and ... then   -- line 1765
                    -- no nil / null check on vehiclePart

    When a vehicle's part list has a hole - a destroyed part, or a vehicle caught
    mid-(re)load after a chunk reload or a long teleport - `getPartByIndex`
    yields a null reference. Calling a method on it throws inside the Kahlua
    invoker (`ReturnValues.put: "callFrame" is null`) and the whole backpack
    refresh aborts with a stack dump, once per frame, for as long as the broken
    part is in range. Nothing in that path belongs to this mod: the stack is
    pure vanilla Lua plus the Kahlua invoker.

    Vanilla cannot be corrected from here, so the refresh runs under pcall. A
    failure is counted and reported once, and further attempts are throttled so
    a broken vehicle cannot spam the log or burn a thrown exception per frame.
    The page simply keeps its previous container list until a refresh succeeds.
]]

if not ISInventoryPage then
    require "ISUI/ISInventoryPage"
end

PNC = PNC or {}

if not PNC._InventoryBackpackPatchApplied then
    PNC._InventoryBackpackPatchApplied = true

    local originalRefreshBackpacks = ISInventoryPage.refreshBackpacks
    -- A future game version may rename or remove the function; leave vanilla
    -- alone rather than installing a guard around nothing.
    if type(originalRefreshBackpacks) ~= "function" then
        return
    end
    local RETRY_COOLDOWN_MS = 1000
    local failures = 0
    local nextAttemptAt = 0

    local function nowMs()
        if getTimestampMs then
            return tonumber(getTimestampMs()) or 0
        end
        return 0
    end

    local function report(err)
        if not (PNC.Core and PNC.Core.LogWarn) then
            return
        end
        PNC.Core.LogWarn(
            "PNC inventory backpack refresh recovered from a vanilla vehicle"
                .. " part null; further failures are throttled"
                .. " error=" .. tostring(err)
        )
    end

    function ISInventoryPage:refreshBackpacks()
        local time = nowMs()
        -- A broken vehicle part keeps failing every frame. Throttle instead of
        -- throwing a Java exception and dumping a stack trace per frame.
        if failures > 0 and time > 0 and time < nextAttemptAt then
            return
        end
        local ok, err = pcall(originalRefreshBackpacks, self)
        if ok then
            failures = 0
            return
        end
        failures = failures + 1
        nextAttemptAt = time + RETRY_COOLDOWN_MS
        if failures == 1 then
            report(err)
        end
    end
end
