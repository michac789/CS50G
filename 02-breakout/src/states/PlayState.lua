--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.scoretracker = self.score
    self.highScores = params.highScores
    self.balls = {params.ball}
    self.level = params.level
    self.powerup = params.powerup
    self.recoverPoints = params.recoverPoints
    self.powerkey = Powerup(10)
    self.haskey = false

    -- give ball random starting velocity
    for _, ball in pairs(self.balls) do
        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)
    end
end

function PlayState:update(dt)
    -- pausing feature
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions of paddle, ball, powerup and key
    self.paddle:update(dt)
    for _, ball in pairs(self.balls) do
        ball:update(dt)
    end
    self.powerup:update(dt)
    self.powerkey:update(dt)

    -- handle collision of all balls
    for _, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            -- tweak angle of bounce based on where it hits the paddle
            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- activate multiball powerup when colliding with paddle
    if self.powerup:collide(self.paddle) then
        self.powerup:reset()
        gSounds['powerup']:play()

        for _ = 0, 50 do
            local newball = Ball()
            newball.x = self.paddle.x + (self.paddle.width / 2) - 4
            newball.y = self.paddle.y - 8
            newball.dx = math.random(-200, 200)
            newball.dy = math.random(-50, -60)
            newball.skin = math.random(7)
            table.insert(self.balls, newball)
        end
    end

    -- activate key powerup when colliding with paddle
    if self.powerkey:collide(self.paddle) then
        self.powerkey:reset()
        gSounds['powerup']:play()
        self.haskey = true
    end

    -- detect collision across all bricks with all balls
    for _, brick in pairs(self.bricks) do
        for _, ball in pairs(self.balls) do
            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- trigger the brick's hit function, which removes it from play
                    brick:hit()

                if brick.locked == true then
                    if self.haskey == true then
                        brick:hit(true)
                        self.haskey = false
                    end
                    -- locked bring worth 1000 points only when they are destroyed, otherwise no points awarded
                    if brick.inPlay == false then
                        self.score = self.score + 1000
                    end
                else
                    -- add to score (regular bricks)
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)
                end

                --[[
                    add probability (20%) to spawn multi ball powerup everytime any ball hits any brick,
                    given that this particular powerup does not exist (visible) yet on screen
                ]]
                if self.powerup.visible == false then
                    if math.random(1, 2) == 1 then
                        self.powerup:spawn(brick.x + 8, brick.y)
                    end
                end

                --[[
                    key powerup to open the bricked wall, one key only for one single bricked wall;
                    key powerup cannot be spawn when you have it (but not used yet) or existing key powerup
                    has not been collected;
                    key powerup does not carry forward when you lose a heart or go to next level
                ]]
                if self.powerkey.visible == false and self.haskey == false then
                    if math.random(1, 5) == 1 then
                        self.powerkey:spawn(brick.x + 8, brick.y)
                    end
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    local newball = Ball()
                    newball.skin = math.random(7)

                    self.powerup:reset()
                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = newball,
                        recoverPoints = self.recoverPoints,
                        powerup = self.powerup,
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8

                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then

                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32

                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then

                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8

                -- bottom edge if no X collisions or top collision, last possibility
                else

                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- add paddle length every multiples of 3000 score
    if self.score >= math.ceil((self.scoretracker + 1) / 3000) * 3000 then
        if self.paddle.size < 4 then
            self.paddle.size = self.paddle.size + 1
            self.paddle.width = self.paddle.width + 32
            gSounds['longerpaddle']:play()
        end
        self.scoretracker = self.score
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    -- only if the ball is the last one!
    local count = 0
    for _, _ in pairs(self.balls) do
        count = count + 1
    end
    if count == 1 then
        for _, ball in pairs(self.balls) do
            if ball.y >= VIRTUAL_HEIGHT then
                self.health = self.health - 1
                gSounds['hurt']:play()
                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    -- reset powerup
                    self.powerup:reset()

                    -- shrink the paddle when player loses a heart
                    local newpaddle = self.paddle
                    if newpaddle.size > 1 then
                        newpaddle.size = newpaddle.size - 1
                        newpaddle.width = newpaddle.width - 32
                    end

                    gStateMachine:change('serve', {
                        paddle = newpaddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints,
                        powerup = self.powerup,
                    })
                end
            end
        end
    end

    -- remove ball from screen
    for i, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.balls, i)
        end
    end

    -- if powerup goes below bounds, reset it
    if self.powerup.y > VIRTUAL_HEIGHT then
        gSounds['powerupdrop']:play()
        self.powerup:reset()
    end
    if self.powerkey.y > VIRTUAL_HEIGHT then
        gSounds['powerupdrop']:play()
        self.powerkey:reset()
    end

    -- for rendering particle systems
    for _, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for _, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for _, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    -- render paddle, ball, multiball powerup, key powerup
    self.paddle:render()
    for _, ball in pairs(self.balls) do
        ball:render()
    end
    self.powerup:render()
    self.powerkey:render()

    renderScore(self.score)
    renderHealth(self.health)
    if self.haskey == true then
        renderKey()
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for _, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end
    end

    return true
end