--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- key & locks variable tracker
    local keyslocks = {
        ['keypicked'] = false,
        ['id'] = math.random(1, 4),
        ['keyplaced'] = false,
        ['lockplaced'] = false
    }
    local frameid = math.random(3, 6)

    -- function used in oncollide (of locks) to reveal flag & flagpole
    local revealflag = function(_)
        if keyslocks['keypicked'] then
            gSounds['powerup-reveal']:play()
            table.insert(objects,
                GameObject {
                    texture = "flagpoles",
                    x = (width - 1) * TILE_SIZE - 8,
                    y = 3 * TILE_SIZE,
                    width = 16,
                    height = 48,
                    frame = frameid,
                    collidable = false,
                    consumable = true,
                    solid = false,
                    onConsume = function (player, _)
                        gSounds['pickup']:play()
                        gStateMachine:change('play', {
                            levelwidth = width + 20,
                            score = player.score,
                        })
                    end
                })
                table.insert(objects,
                GameObject {
                    texture = "flags",
                    x = (width - 1) * TILE_SIZE,
                    y = 3 * TILE_SIZE,
                    width = 16,
                    height = 48,
                    frame = 9 * (frameid - 2) - 2,
                    collidable = false,
                    consumable = false,
                    solid = false,
                })
        else
            gSounds['empty-block']:play()
        end
    end

    -- insert blank tables into tiles for later access
    for _ = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY

        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x < width - 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- additional: make sure no pillar or other item spawn on 2 rightmost tile (for flag)
            -- chance to generate a pillar
            if math.random(8) == 1 and x < width - 1 then
                blockHeight = 2

                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end

                -- chance of putting a key above a pillar if not placed yet
                -- randomize the position as well vertically (should be above bush if there is any)
                -- only place key on last half of the map (prevent key from appearing from start)
                if math.random(10) == 1 and keyslocks['keyplaced'] == false and x > math.floor(width / 2) then
                    table.insert(objects,
                        GameObject {
                            texture = "keyslocks",
                            x = (x - 1) * TILE_SIZE,
                            y = math.random(0, 2) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            frame = keyslocks['id'],
                            collidable = true,
                            consumable = true,
                            solid = false,
                            onConsume = function(_, _)
                                gSounds['pickup']:play()
                                keyslocks['keypicked'] = true
                            end
                        }
                    )
                    keyslocks['keyplaced'] = true
                end

                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil

            -- chance to generate bushes
            elseif math.random(7) == 1 and x < width - 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 and x < width - 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(3) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, _)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }

                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )

            -- chance to spawn key
            elseif math.random(20) == 1 and keyslocks['keyplaced'] == false and x > math.floor(width / 2) and x < width - 1 then
                table.insert(objects,
                    GameObject {
                        texture = "keyslocks",
                        x = (x - 1) * TILE_SIZE,
                        y = math.random(1, 2) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = keyslocks['id'],
                        collidable = true,
                        consumable = true,
                        solid = false,
                        onConsume = function(_, _)
                            gSounds['pickup']:play()
                            keyslocks['keypicked'] = true
                        end
                    })
                keyslocks['keyplaced'] = true

            -- chance to spawn lock, only possible on last 30% of the map
            elseif math.random(10) == 1 and keyslocks['lockplaced'] == false and x > math.floor(width * 0.7) and x < width - 1 then
                table.insert(objects,
                    GameObject {
                        texture = "keyslocks",
                        x = (x - 1) * TILE_SIZE,
                        y = 1 * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = keyslocks['id'] + 4,
                        collidable = true,
                        consumable = false,
                        solid = true,
                        onCollide = revealflag,
                    })
                keyslocks['lockplaced'] = true
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles

    -- if key or lock is not placed yet, regenerate the level
    if keyslocks['keyplaced'] == false or keyslocks['lockplaced'] == false then
        return LevelMaker.generate(width, height)
    end

    return GameLevel(entities, objects, map)
end