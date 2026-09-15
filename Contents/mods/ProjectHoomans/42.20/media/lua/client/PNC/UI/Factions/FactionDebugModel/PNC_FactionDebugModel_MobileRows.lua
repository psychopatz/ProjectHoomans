-- Mobile-group tab row projection.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal
require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"

local MobileModel = PNC.MobileGroupDebugModel
local MOBILE_POOL_MEANINGS = Internal.MobilePoolMeanings

local function appendMobileSummaryRows(rows, snapshot, counts, departure)
    local playerBaseCount = math.max(
        0, math.floor(tonumber(departure.playerBaseCount) or 0)
    )
    local summaryRows = {
        Internal.Row("How to read this tab",
            "Choose a filter above. Every group belongs to one visible pool.",
            "success"),
        Internal.Row("Your current colony",
            snapshot.currentPlayerFactionID or "not detected",
            snapshot.currentPlayerFactionID and "success" or "warning"),
        Internal.Row("Player-colony gate",
            playerBaseCount > 0
                and ("OPEN / " .. tostring(playerBaseCount)
                    .. " registered player base(s)")
                or "LOCKED / no registered player base exists",
            playerBaseCount > 0 and "success" or "danger"),
        Internal.Row("ALL MOBILE GROUPS",
            tostring(counts.all)
                .. " group(s) / all active mobile factions",
            counts.all > 0 and "success" or "textMuted"),
        Internal.Row("WAITING ON ROAD",
            tostring(counts.staging)
                .. " group(s) / visible road lobby; not traveling yet",
            counts.staging > 0 and "success" or "textMuted"),
        Internal.Row("TRAVELING TO PLAYER COLONY",
            tostring(counts.player_colony)
                .. " group(s) / abstract traversal toward your colony",
            counts.player_colony > 0 and "danger" or "textMuted"),
        Internal.Row("TRAVELING TO AI SETTLEMENT",
            tostring(counts.ai_settlement)
                .. " group(s) / abstract traversal toward an AI settlement",
            counts.ai_settlement > 0 and "warning" or "textMuted"),
        Internal.Row("STREET ROAMING",
            tostring(counts.street_roaming)
                .. " group(s) / ambient behavior or shelter",
            counts.street_roaming > 0 and "warning" or "textMuted"),
        Internal.Row("Settlement travel total",
            tostring(counts.en_route)
                .. " group(s) / player + AI settlement destinations"),
        Internal.Row("Waiting on road means", MOBILE_POOL_MEANINGS.staging),
        Internal.Row("Player travel means", MOBILE_POOL_MEANINGS.player_colony),
        Internal.Row("AI travel means", MOBILE_POOL_MEANINGS.en_route),
        Internal.Row("Street roaming means", MOBILE_POOL_MEANINGS.street_roaming),
        Internal.Row("Quick test",
            "Select a road group, then use Force Settlement Departure."
                .. " It should move into a travel pool."),
        Internal.Row("Why groups may still be waiting",
            playerBaseCount > 0
                and "The daily roll is chance-based; force a departure to test immediately."
                or "Player-colony travel is disabled until the player creates a base; AI travel still needs an AI settlement."),
        Internal.Row("Daily departure rule",
            string.format(
                "daytime / every %.0f h / base %.0f%% / sandbox x%.2f / budget %d",
                tonumber(departure.intervalHours) or 24,
                (tonumber(departure.baseChance) or 0.10) * 100,
                tonumber(departure.sandboxMultiplier) or 1,
                tonumber(departure.budget) or 12
            )),
    }
    for _, row in ipairs(summaryRows) do
        rows[#rows + 1] = row
    end
end

local function appendSelectedMobileRows(rows, snapshot, reason)
    local selected = snapshot.selectedFaction
    local mobile = selected and selected.mobile or nil
    if mobile and mobile.active == true then
        local pool = Model.MobilePool(
            mobile, snapshot.currentPlayerFactionID)
        local site = mobile.site or {}
        local home = site.home or {}
        rows[#rows + 1] = Internal.Row(
            "Selected mobile group",
            tostring(selected.name) .. " / " .. tostring(selected.id),
            "success"
        )
        rows[#rows + 1] = Internal.Row(
            "Selected pool",
            Model.MobileCategoryLabel(Model.MobileCategory(
                mobile, snapshot.currentPlayerFactionID)),
            Model.MobileCategoryTone(Model.MobileCategory(
                mobile, snapshot.currentPlayerFactionID))
        )
        rows[#rows + 1] = Internal.Row(
            "Lifecycle / presence",
            MobileModel.StateText(mobile)
                .. " / " .. tostring(mobile.presence or "unknown")
        )
        rows[#rows + 1] = Internal.Row(
            "Activity",
            tostring(mobile.activity or "street_roaming")
        )
        rows[#rows + 1] = Internal.Row(
            "Destination",
            MobileModel.TargetText(mobile),
            pool == "player_colony" and "danger" or "text"
        )
        if mobile.travel then
            rows[#rows + 1] = Internal.Row(
                "Travel started",
                tostring(mobile.travel.startedAt or 0)
                    .. " h / departure day "
                    .. tostring(mobile.travel.departureDay or 0),
                "danger"
            )
        end
        rows[#rows + 1] = Internal.Row(
            "Staging site",
            tostring(site.id or "unknown") .. " @ "
                .. string.format(
                    "%.0f, %.0f, %.0f",
                    tonumber(home.x) or 0,
                    tonumber(home.y) or 0,
                    tonumber(home.z) or 0
                )
        )
    else
        rows[#rows + 1] = Internal.Row(
            "Selection",
            reason or "Select a mobile group from the list.",
            "textMuted"
        )
    end
end

function Model.BuildMobileRows(snapshot, authorized, reason)
    if authorized ~= true then
        return {
            Internal.Row("Access", "Admin/debug mode required", "danger"),
        }
    end
    snapshot = snapshot or {}
    local counts = Model.BuildMobilePoolCounts(snapshot)
    local departure = snapshot.mobileDeparture or {}
    local rows = {}
    appendMobileSummaryRows(rows, snapshot, counts, departure)
    appendSelectedMobileRows(rows, snapshot, reason)
    return rows
end
return Model
