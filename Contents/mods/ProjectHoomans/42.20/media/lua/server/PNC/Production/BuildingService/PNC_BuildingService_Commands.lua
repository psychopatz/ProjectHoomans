if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BuildingService = PNC.BuildingService or {}
PNC.BuildingServiceInternal = PNC.BuildingServiceInternal or {}

local Service = PNC.BuildingService
local H = PNC.BuildingServiceInternal
local Catalog = PNC.BuildRecipeCatalog
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions

function Service.Queue(player, args)
    args = type(args) == "table" and args or {}
    local context, reason = H.ContextFor(player)
    if not context then return nil, reason end
    local descriptor = Catalog.Get(args.recipeKey or args.objectInfoName)
    if not descriptor then return nil, "BUILD_RECIPE_NOT_FOUND" end
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not x or not y or not z then return nil, "BUILD_TARGET_REQUIRED" end
    local blueprint = {
        recipeKey = descriptor.recipeKey,
        objectInfoName = descriptor.objectInfoName,
        x = math.floor(x), y = math.floor(y), z = math.floor(z),
        nSprite = math.max(1, math.min(4, math.floor(
            tonumber(args.nSprite) or 1))),
        north = args.north == true,
        sprite = args.sprite and tostring(args.sprite) or nil,
    }
    if not H.TargetValid(context.base, blueprint) then
        return nil, "BUILD_TARGET_OUTSIDE_BASE"
    end
    Repository.Load()
    if H.DuplicateAt(context.colony.id, blueprint) then
        return nil, "BUILD_TARGET_ALREADY_QUEUED"
    end
    local requirements = H.Copy(descriptor.requirements or {})
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        context.storage.id, requirements,
        "blueprint:" .. tostring(blueprint.objectInfoName))
    if not reservation then return nil, reason or "MISSING_MATERIALS" end
    local payload = {
        mode = "object_build",
        materialKind = "build_object",
        storageId = context.storage.id,
        materialRequirements = requirements,
        blueprint = blueprint,
        requesterOnlineID = player and player.getOnlineID
            and tonumber(player:getOnlineID()) or nil,
    }
    payload = PNC.WorkInputService.Bind(payload, context.storage.id,
        reservation.id, "building_materials")
    local order
    order, reason = PNC.WorkService.Commands.Queue({
        operation = Definitions.OPERATION.BUILD_OBJECT,
        colonyId = context.colony.id, factionId = context.faction.id,
        baseId = context.base.id, requiredWork = descriptor.buildWork,
        requiredSkills = descriptor.requiredSkills,
        recipeRevision = 1, payload = payload, funded = false,
    })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        return nil, reason or "BUILD_QUEUE_FAILED"
    end
    return order
end

function Service.DebugGrantMaterials(player, args)
    args = type(args) == "table" and args or {}
    local storage, reason = PNC.ColonyStorageService.ResolveForPlayer(player)
    if not storage then return nil, reason end
    local descriptor = Catalog.Get(args.recipeKey or args.objectInfoName)
    if not descriptor then return nil, "BUILD_RECIPE_NOT_FOUND" end

    -- Use the first valid alternative for each recipe input.  This mirrors
    -- the stockpile reservation policy and gives the tester a H.Complete set
    -- of inputs without creating a second build/materials pipeline.
    local products = {}
    for _, requirement in ipairs(descriptor.requirements or {}) do
        local fullType = requirement.fullType
            or requirement.itemTypes and requirement.itemTypes[1]
        local quantity = math.max(1, math.floor(
            tonumber(requirement.amount) or 1))
        if fullType then
            products[#products + 1] = {
                fullType = tostring(fullType), quantity = quantity,
            }
        end
    end
    if #products == 0 then return nil, "BUILD_RECIPE_HAS_NO_MATERIALS" end

    local transactionId = args.requestId and tostring(args.requestId) or nil
    local deposited, depositReason, _, depositDetails =
        PNC.ColonyStorageService.DebugAction(player, {
            debugAction = "add_many",
            storageId = storage.id,
            products = products,
            requestId = transactionId,
            transactionLogging = args.transactionLogging,
        })
    if not deposited then return nil, depositReason end
    return {
        recipeKey = descriptor.recipeKey,
        storageId = storage.id,
        products = products,
        storageDetails = depositDetails,
    }, "MATERIALS_GRANTED"
end

