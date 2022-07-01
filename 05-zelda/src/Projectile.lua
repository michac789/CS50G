--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Projectile = Class{}

function Projectile:init(def, x, y)
    self.texture = def.texture
    self.frame = def.frame
    self.width = def.width
    self.height = def.height

    self.x = x
    self.y = y

    self.dx = 0
    self.dy = 0
end

function Projectile:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt
end

function Projectile:render()
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.states[self.state].frame or self.frame],
        self.x, self.y)
end