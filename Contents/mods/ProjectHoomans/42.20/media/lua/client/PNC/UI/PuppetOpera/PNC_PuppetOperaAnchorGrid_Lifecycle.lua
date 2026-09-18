-- PZ lifecycle and model binding for the Puppet Opera anchor grid.

local Class = ISPNCPuppetOperaAnchorGrid

function Class:initialise()
    ISPanel.initialise(self)
    self.background = true
    self.backgroundColor = {
        r = 0.055,
        g = 0.070,
        b = 0.080,
        a = 1,
    }
    self.borderColor = {
        r = 0.22,
        g = 0.30,
        b = 0.34,
        a = 1,
    }
end

function Class:setModel(model)
    self.model = model
end

return Class
