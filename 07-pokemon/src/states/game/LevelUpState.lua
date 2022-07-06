LevelUpState = Class{__includes = BaseState}

function LevelUpState:init(pokemon, HP, attack, defense, speed, callback)
    local msg = "Stats Increase: \n" .. 
        "HP     : " .. pokemon.HP - HP .. " + " .. HP .. " = " .. pokemon.HP .. "\n" ..
        "Attack : " .. pokemon.attack - attack .. " + " .. attack .. " = " .. pokemon.attack .. "\n" ..
        "HP: " .. pokemon.defense - defense .. " + " .. defense .. " = " .. pokemon.defense .. "\n" ..
        "HP: " .. pokemon.speed - speed .. " + " .. speed .. " = " .. pokemon.speed
    self.textbox = Textbox(0, VIRTUAL_HEIGHT - 64, VIRTUAL_WIDTH, 64, msg, gFonts['medium'])
    self.callback = callback or function() end
end

function LevelUpState:update(dt)
    self.textbox:update(dt)

    if self.textbox:isClosed() then
        self.callback()
        gStateStack:pop()
    end
end

function LevelUpState:render()
    self.textbox:render()
end
