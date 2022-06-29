--[[
    GD50
    Match-3 Remake

    -- Tile Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The individual tiles that make up our game board. Each Tile can have a
    color and a variety, with the varietes adding extra points to the matches.
]]

Tile = Class{}

function Tile:init(x, y, color, variety)
    -- board positions
    self.gridX = x
    self.gridY = y

    -- coordinate positions
    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    -- tile appearance/points
    self.color = color
    self.variety = variety

    -- shiny tile
    self.shiny = math.random(10) == 1 and true or false
    self.tilealpha = 0.4
    Timer.every(2, function()
        Timer.tween(1, {[self] = {tilealpha = 0.05}}):finish(
            function()
            Timer.tween(1, {[self] = {tilealpha = 0.35}})
            end
        )
    end)
end

function Tile:render(x, y)

    -- draw shadow
    love.graphics.setColor(34, 32, 52, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    -- draw tile itself
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)

    -- render shiny block
    if self.shiny then
        love.graphics.setColor(255/255, 255/255, 255/255, self.tilealpha)
        love.graphics.rectangle('fill', (self.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.gridY - 1) * 32 + 16, 32, 32, 4)
        love.graphics.setColor(255, 255, 255, 255)
    end
end