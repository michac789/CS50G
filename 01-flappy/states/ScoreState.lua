--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

function ScoreState:init()

end

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]
function ScoreState:enter(params)
    self.score = params.score
    if self.score >= 20 then
        self.trophy = love.graphics.newImage('assets/goldmedal.png')
    elseif self.score >= 8 then
        self.trophy = love.graphics.newImage('assets/silvermedal.png')
    elseif self.score >= 3 then
        self.trophy = love.graphics.newImage('assets/bronzemedal.png')
    else
        self.trophy = nil
    end
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
    end
end

function ScoreState:render()
    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 20, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 50, VIRTUAL_WIDTH, 'center')

    love.graphics.printf('Press Enter to Play Again!', 0, 80, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(smallFont)
    love.graphics.printf('Get higher scores to earn better trophies!', 0, 110, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('3 points = bronze trophy', 0, 130, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('8 points = silver trophy', 0, 145, VIRTUAL_WIDTH, 'center')
    love.graphics.printf('20 points = gold trophy', 0, 160, VIRTUAL_WIDTH, 'center')

    if self.trophy ~= nil then
        love.graphics.draw(self.trophy,
        (VIRTUAL_WIDTH - self.trophy:getWidth() / 2) / 2,
        VIRTUAL_HEIGHT - self.trophy:getHeight() / 2 - 40,
        0, 0.5, 0.5)
    end
end