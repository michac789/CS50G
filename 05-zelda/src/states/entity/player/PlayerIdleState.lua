--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayerIdleState = Class{__includes = EntityIdleState}

function PlayerIdleState:enter(params)

    -- render offset for spaced character sprite (negated in render function of state)
    self.entity.offsetY = 5
    self.entity.offsetX = 0
end

function PlayerIdleState:update(dt)
    if self.entity.carrypot then
        self.entity:changeAnimation('pot-idle-' .. self.entity.direction)
    end

    if love.keyboard.isDown('left') or love.keyboard.isDown('right') or
       love.keyboard.isDown('up') or love.keyboard.isDown('down') then
        self.entity:changeState('walk')
    end

    -- if not carrying pot then swing sword, else throw pot as projectile
    if love.keyboard.wasPressed('space') then
        if self.entity.carrypot then
            Event.dispatch('throwpot', self.entity)
        else
            self.entity:changeState('swing-sword')
        end
    end

    -- when 'c' key pressed: if colliding with pot, carry the pot, else the drop the pot
    if love.keyboard.isDown('c') and self.entity.allowpress == true then
        self.entity.allowpress = false
        if self.entity.carrypot then
            Event.dispatch('droppot', self.entity)
        else
            self.entity.cpressed = true
        end
    else
        self.entity.cpressed = false
    end
end