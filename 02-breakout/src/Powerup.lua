Powerup = Class {}

-- initialize a powerup
function Powerup:init(skin)
    self.x = 0
    self.y = 0
    self.dy = 0
    self.visible = false
    self.skin = skin
    self.width = 16
    self.height = 16
end

-- called when a powerup is spawned
function Powerup:spawn(x, y)
    self.visible = true
    self.x = x
    self.y = y
    self.dy = 50
end

-- called when a powerup is collected / uncollected to reset position
function Powerup:reset()
    self.visible = false
    self.x = 0
    self.y = 0
    self.dy = 0
end

-- function to detect if powerup collides with paddle
function Powerup:collide(target)
    if self.x > target.x + target.width or target.x > self.x + self.width or
        self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    else
        return true
    end
end

-- update powerup position (only y position is moving from spawn)
function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

-- render on screen only if visible is true
function Powerup:render()
    if self.visible == true then
        love.graphics.draw(gTextures['main'], gFrames['powerup'][self.skin],
        self.x, self.y)
    end
end
