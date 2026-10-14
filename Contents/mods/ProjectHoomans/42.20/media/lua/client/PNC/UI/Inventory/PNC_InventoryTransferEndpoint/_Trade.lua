local Endpoint = PNC.InventoryTransferEndpoint
local Helpers = require "PNC/UI/Inventory/PNC_InventoryTransferEndpoint/_Common"
local Model = Helpers.Model

function Endpoint.Trade(traderID, options)
    options = type(options) == "table" and options or {}
    local endpoint = {
        kind = "trade",
        role = "counterparty",
        id = traderID and tostring(traderID) or nil,
        npcID = options.npcID and tostring(options.npcID) or nil,
        snapshot = options.snapshot or {},
        snapshotSerial = 1,
        selectedContainer = "root",
        expandedGroups = {},
        readOnly = false,
    }

    function endpoint:setSnapshot(snapshot)
        self.snapshot = type(snapshot) == "table" and snapshot or {}
        self.snapshotSerial = (tonumber(self.snapshotSerial) or 0) + 1
        return self.snapshot
    end

    function endpoint:payload()
        return self.snapshot
    end

    function endpoint:inventory()
        return nil
    end

    function endpoint:revision()
        return math.max(0, math.floor(tonumber(
            self.snapshot and self.snapshot.stockVersion or 0
        ) or 0))
    end

    function endpoint:snapshotGeneration()
        return math.max(0, math.floor(tonumber(self.snapshotSerial) or 0))
    end

    function endpoint:containers()
        return {{
            id = "root",
            label = tostring(self.snapshot and self.snapshot.stockLabel
                or "For Sale"),
        }}
    end

    function endpoint:rows()
        return Model.BuildTradeStockRows(
            self.snapshot and self.snapshot.items or {}
        )
    end

    function endpoint:priceFor(fullType, operation, itemIDs)
        if operation == "SELL" then
            for _, item in ipairs(self.snapshot and self.snapshot.sellRows or {}) do
                if tostring(item.fullType or "") == tostring(fullType or "") then
                    if type(itemIDs) == "table" and type(item.itemIDs) == "table" then
                        local wanted = {}
                        for _, itemID in ipairs(itemIDs) do
                            wanted[tostring(itemID)] = true
                        end
                        for _, itemID in ipairs(item.itemIDs) do
                            if wanted[tostring(itemID)] then
                                return math.max(0, math.floor(
                                    tonumber(item.unitPrice) or 0))
                            end
                        end
                    elseif type(itemIDs) ~= "table" then
                        return math.max(0, math.floor(tonumber(item.unitPrice) or 0))
                    end
                end
            end
            -- A concrete sell quote must come from a matching server row;
            -- never fall back to a stock definition quote for a player item.
            return 0
        end
        for _, item in ipairs(self.snapshot and self.snapshot.items or {}) do
            if tostring(item.fullType or "") == tostring(fullType or "") then
                local value = operation == "SELL"
                    and item.sellPrice
                    or item.unitPrice
                return math.max(0, math.floor(tonumber(value) or 0))
            end
        end
        return 0
    end

    function endpoint:weight()
        return tonumber(self.snapshot and self.snapshot.usedWeight) or 0,
            tonumber(self.snapshot and self.snapshot.maxWeight) or 0
    end

    function endpoint:requestSnapshot()
        if type(options.requestSnapshot) == "function" then
            return options.requestSnapshot(self) == true
        end
        return false
    end

    function endpoint:send()
        return false, "trade_endpoint_requires_accept"
    end

    function endpoint:commit(buyRows, sellRows)
        if type(options.commit) ~= "function" then
            return false, "trade_commit_unavailable"
        end
        return options.commit(self, buyRows or {}, sellRows or {})
    end

    return endpoint
end

return Endpoint
