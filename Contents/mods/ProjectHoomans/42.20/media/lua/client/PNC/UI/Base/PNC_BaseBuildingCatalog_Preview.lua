local RecipeState = require
    "PNC/UI/Base/PNC_BaseBuildingCatalog_Recipes"
local recipeDescriptor = RecipeState.Descriptor
local Preview = {}

local function facilityBuildUI()
    local buildUI = PNC.FacilityBuildUI
    if buildUI and buildUI.DrawNativePreview then return buildUI end
    local ok, loaded = pcall(require,
        "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildModal")
    if ok and loaded then return loaded end
    return buildUI
end

local function previewTexture(recipe, descriptor)
    local texture = descriptor and descriptor.iconTexture or nil
    if texture then return texture end
    local iconName = descriptor and descriptor.iconName
        or recipe and recipe.iconName
    if iconName and type(getTexture) == "function" then
        local ok, resolved = pcall(getTexture, tostring(iconName))
        if ok and resolved then return resolved end
    end
    return nil
end

local function previewText(ui, value, width)
    local text = tostring(value or "")
    local layout = ui and ui.Layout
    if layout and layout.Ellipsize then
        return layout.Ellipsize(text, UIFont.Small, math.max(1, width))
    end
    return text
end

local PreviewPanelClass

local function previewPanelClass()
    if PreviewPanelClass then return PreviewPanelClass end
    if not ISPanel then pcall(require, "ISUI/ISPanel") end
    if not ISPanel or type(ISPanel.derive) ~= "function" then return nil end

    PreviewPanelClass = ISPanel:derive("PNCBuildingRecipePreview")
    function PreviewPanelClass:new(x, y, width, height, owner)
        local object = ISPanel:new(x, y, width, height)
        setmetatable(object, self); self.__index = self
        object.owner = owner
        object.background = false
        return object
    end

    function PreviewPanelClass:render()
        ISPanel.render(self)
        local ui = PsychopatzCore and PsychopatzCore.UI or nil
        local theme = ui and ui.Theme or nil
        local colors = theme and theme.colors or {}
        local surface = colors.surfaceRaised
            or { r = 0.035, g = 0.05, b = 0.06, a = 1 }
        local border = colors.borderStrong or colors.border
            or { r = 0.22, g = 0.45, b = 0.50, a = 1 }
        local text = colors.text
            or { r = 0.91, g = 0.94, b = 0.96, a = 1 }
        local muted = colors.textMuted
            or { r = 0.65, g = 0.72, b = 0.76, a = 1 }
        local accent = colors.accent
            or { r = 0.22, g = 0.78, b = 0.94, a = 1 }
        local alpha = self.owner and self.owner.contentSurfaceAlpha or 0.9
        alpha = math.max(0.84, math.min(0.98, tonumber(alpha) or 0.9))
        self:drawRect(0, 0, self.width, self.height, alpha,
            surface.r, surface.g, surface.b)
        self:drawRectBorder(0, 0, self.width, self.height,
            border.a or 1, border.r, border.g, border.b)
        self:drawText("SELECTED BUILDING", 10, 7,
            muted.r, muted.g, muted.b, 1, UIFont.Small)

        local recipe = self.owner and self.owner.buildSelectedRecipe or nil
        if not recipe then
            self:drawTextCentre("SELECT A BUILDING TO PREVIEW",
                self.width / 2, math.max(20, self.height / 2 - 8),
                muted.r, muted.g, muted.b, 1, UIFont.Small)
            return
        end

        local descriptor = recipeDescriptor(recipe)
        local imageX, imageY = 10, 25
        local imageWidth = math.max(1, self.width - 20)
        local imageHeight = math.max(38, math.min(116, self.height - 78))
        local buildUI = facilityBuildUI()
        local drew = false
        if buildUI and buildUI.DrawNativePreview then
            local ok, result = pcall(buildUI.DrawNativePreview, self,
                descriptor and descriptor.previewTiles or nil,
                imageX, imageY, imageWidth, imageHeight, 1)
            drew = ok and result == true
        end
        if not drew then
            local texture = previewTexture(recipe, descriptor)
            if texture and self.drawTextureScaledAspect then
                local ok = pcall(self.drawTextureScaledAspect, self, texture,
                    imageX, imageY, imageWidth, imageHeight, 1, 1, 1, 1)
                drew = ok
            end
        end
        if not drew then
            self:drawTextCentre("PREVIEW UNAVAILABLE", self.width / 2,
                imageY + math.floor(imageHeight / 2),
                muted.r, muted.g, muted.b, 1, UIFont.Small)
        end

        local title = descriptor and descriptor.displayName
            or recipe.displayName or recipe.recipeName
            or recipe.objectInfoName or "BUILDING"
        local category = recipe.category or descriptor and descriptor.category
            or "Miscellaneous"
        local ready = true
        for _, material in ipairs(recipe.materials or {}) do
            if material.ready ~= true then ready = false; break end
        end
        local status = ready and "READY TO PLACE" or "MATERIALS REQUIRED"
        local statusColor = ready and (colors.success or accent)
            or (colors.warning or { r = 0.96, g = 0.68, b = 0.20, a = 1 })
        local titleY = imageY + imageHeight + 5
        self:drawText(previewText(ui, title, self.width - 20), 10, titleY,
            text.r, text.g, text.b, 1, UIFont.Small)
        self:drawText(previewText(ui, tostring(category) .. "  |  " .. status,
            self.width - 20), 10, titleY + 19, statusColor.r,
            statusColor.g, statusColor.b, 1, UIFont.Small)
    end
    return PreviewPanelClass
end

function Preview.Create(window)
    local class = previewPanelClass()
    if not class then return nil end
    local panel = class:new(0, 0, 1, 1, window)
    panel:initialise(); panel:instantiate(); window:addChild(panel)
    return panel
end


return Preview
