local composer = require("composer")
local physics = require("physics")
local audio = require("audio")
physics.start()

local scene = composer.newScene() 
scene.purgeOnSceneChange = true

local backgroundFirst, backgroundSecond, backgroundThird
local life = {}
local indexLife = 3

local textScore, score
local xScore = 0

local character
local dragon

local leftBorder = 20
local rightBorder = display.contentWidth
local topBorder = 130
local bottomBorder = display.contentHeight + 60

local timerEnemy, timerFireball, timerShoot

local enemyGroup, bulletGroup

local explosionSound, shootSound, hitSound

local function moveObject(event)
    if event.phase == "began" then
        display.currentStage:setFocus(character)
        character.touchOffsetX = event.x - character.x
        character.touchOffsetY = event.y - character.y
    elseif event.phase == "moved" then
        character.x = event.x - character.touchOffsetX
        character.y = event.y - character.touchOffsetY

        -- Проверка и корректировка позиции игрока, если он выходит за границы
        if character.x < leftBorder then
            character.x = leftBorder
        elseif character.x > rightBorder then
            character.x = rightBorder
        end

        if character.y < topBorder then
            character.y = topBorder
        elseif character.y > bottomBorder then
            character.y = bottomBorder
        end
    elseif event.phase == "ended" then
        display.currentStage:setFocus(nil)
    end
end


local function updateBackground()
    backgroundFirst.y = backgroundFirst.y + 1
    backgroundSecond.y = backgroundSecond.y + 1
    backgroundThird.y = backgroundThird.y + 1

    if backgroundFirst.y >= backgroundFirst.contentHeight + 200 then
        backgroundFirst.y = backgroundThird.y - backgroundThird.contentHeight
    end
    if backgroundSecond.y >= backgroundSecond.contentHeight + 200 then
        backgroundSecond.y =  backgroundFirst.y - backgroundFirst.contentHeight
    end
    if backgroundThird.y >= backgroundThird.contentHeight + 200 then
        backgroundThird.y = backgroundSecond.y - backgroundSecond.contentHeight
    end
end

local function createEnemy()
    local sheetOptions = {
        width = 145,
        height = 110,
        numFrames = 16
    }

    local imageSheet = graphics.newImageSheet("./images/water_dragon.png", sheetOptions)

    local sequanceData = {
        name = "swim",
        start = 1,
        count = 4,
        time = 500,
        loopCount = 0,
        loopDirection = "forward"
    }

    local enemy = display.newSprite(imageSheet, sequanceData)
    enemy.x = math.random(10, 300)
    enemy.y = -130
    enemy.xScale = 0.5
    enemy.yScale = 0.5

    enemyGroup:insert(enemy)

    physics.addBody(enemy, "dynamic", {radius = 20})

    enemy.ID = "targetBad"

    enemy.gravityScale = 0.0

    enemy.isSensor = true

    enemy:setLinearVelocity(0, 100)

    enemy:play()
end

local isBlinking = false

local function explosiveHit(self, event)
    if event.phase == "began" then
        if event.other.ID == "explosion" or event.other.ID == "targetBad" then
            
            if isBlinking then
                return
            end

            local blink = transition.blink(character, {time = 500})
            isBlinking = true
            if indexLife > 0 then
                life[indexLife]:removeSelf()
                indexLife = indexLife - 1
            end

            if indexLife <= 0 then
                composer.gotoScene("scenes.gameover",  {time=2000, effect="crossFade" })
            end

            if xScore ~= 0 then
                xScore = xScore - 20                
            end

            if event.other.ID == "targetBad" then
                event.other:removeSelf()
            end

            audio.play(hitSound, {
                channel = 5,
                loops = 0,  
                fadein = 100, 
            })

            timer.performWithDelay(2000, function ()
                transition.cancel(blink)
                transition.to(character, {
                    time = 500,
                    alpha = 1,
                    transition = easing.outQuad
                })
            isBlinking = false
            end)
        end
        score.text = xScore
    end
end

local dragonRed

local function dragonHit(self, event)
    if event.phase == "began" then
        if event.other.ID == "playerBullet" then
            
            dragon.alpha = 0
            dragonRed:setFillColor(1, 0, 0, 1)
            timer.performWithDelay(500, function ()
                dragonRed:setFillColor(1, 0, 0, 0)
                dragon.alpha = 1
            end)
            dragon.HP = dragon.HP - 10
            xScore = xScore + 20  

            if dragon.HP <= 0 then
                composer.gotoScene("scenes.win",  {time=2000, effect="crossFade" })
            end


            event.other:removeSelf()
        end
        score.text = xScore
    end
end

local function characterShoot(event)
    local bullet = display.newImageRect(bulletGroup, "./images/cannonball.png", 15, 15)
    bullet.x = character.x
    bullet.y = character.y
    
    physics.addBody(bullet, "dynamic")
    bullet.isSensor = true
    bullet.ID = "playerBullet"
    bullet.gravityScale = 0
    bullet:setLinearVelocity(0, -100) 

    audio.play(shootSound, {
        channel = 6,
        loops = 0,  
        fadein = 100, 
    })
end


local function onAnimationComplete(event)
    if event.phase == "ended"  then
        event.target:removeSelf() 
    end
end

local function attackFireboll()
    local dangerZone = display.newCircle(bulletGroup, character.x, character.y, 60)
    dangerZone:setFillColor(1, 0, 0)
    dangerZone.alpha = 0.3
    local dangerZoneX = dangerZone.x
    local dangerZoneY = dangerZone.y
    timer.performWithDelay(2000, function()
        dangerZone:removeSelf()
        local fireball =  display.newImageRect(bulletGroup, "./images/fireball.png", 30, 30)
        fireball.x = dragon.x
        fireball.y = dragon.y

        local sheetOptions = {
            width = 125,
            height = 125,
            numFrames = 46
        }

        local imageSheet = graphics.newImageSheet("./images/explosion.png", sheetOptions)

            local sequanceData = {
                name = "explosion",
                start = 1,
                count = 46,
                time = 1000,
                loopCount = 1,
                loopDirection = "forward"
            }

        transition.to(fireball, { x = dangerZone.x, y = dangerZone.y, time = 500, onComplete = function()
            if fireball then
                fireball:removeSelf() 
            end
            local explosion = display.newSprite(bulletGroup, imageSheet, sequanceData)
            audio.play(explosionSound, {
                channel = 7,
                loops = 0,  
                fadein = 100, 
            })
            physics.addBody(explosion, "dynamic", {radius = 43})
            explosion.gravityScale = 0
            explosion.isSensor = true
            explosion.ID = "explosion"
            explosion.x = dangerZoneX
            explosion.y = dangerZoneY
            explosion:addEventListener("sprite", onAnimationComplete)
            explosion:play()
        end })
    end)
end

function scene:create(event)
    local sceneGroup = self.view
    local backgroundGroup = display.newGroup()
    local TextGroup = display.newGroup()
    local lifeGroup = display.newGroup()
    enemyGroup = display.newGroup()
    bulletGroup = display.newGroup()
    
    
    backgroundFirst = display.newImageRect(backgroundGroup,"./images/background_third.png", 900, 860)
    backgroundFirst.x = 159
    backgroundFirst.y = display.contentCenterY

    backgroundSecond = display.newImageRect(backgroundGroup, "./images/background_third.png", 900, 860)
    backgroundSecond.x = 159
    backgroundSecond.y = backgroundFirst.y - display.contentHeight

    backgroundThird = display.newImageRect(backgroundGroup, "./images/background_third.png", 900, 860)
    backgroundThird.x = 159
    backgroundThird.y = backgroundSecond.y - display.contentHeight

    textScore = display.newText(TextGroup, "Счет: ", 40, -50, "Helvetica", 25) 
    score = display.newText(xScore, 90, -50, "Helvetica", 25) 
    TextGroup:insert(score)

    local firstLife = display.newImageRect(lifeGroup, "./images/life.png", 40, 50)
    firstLife.x = display.contentWidth - 20
    firstLife.y = -50

    local secondLife = display.newImageRect(lifeGroup, "./images/life.png", 40, 50)
    secondLife.x = display.contentWidth - 55
    secondLife.y = -50

    local thirdLife = display.newImageRect(lifeGroup, "./images/life.png", 40, 50)
    thirdLife.x = display.contentWidth - 90
    thirdLife.y = -50

    table.insert(life, firstLife)
    table.insert(life, secondLife)
    table.insert(life, thirdLife)

    local sheetOptions = {
        width = 165,
        height = 195,
        numFrames = 15
    }

    local imageSheet = graphics.newImageSheet("./images/characterSprite.png", sheetOptions)

    local sequanceData = {
        name = "swim",
        start = 1,
        count = 1,
        time = 2000,
        loopCount = 0,
        loopDirection = "forward"
    }

    character = display.newSprite(imageSheet, sequanceData)

    physics.addBody(character, "dynamic", {radius = 20})

    character.collision = explosiveHit

    character.gravityScale = 0

    character.x = 175
    character.y = 500
    character.xScale = 0.5
    character.yScale = 0.5
    character:scale(-1, -1)
    character:addEventListener("collision", character)

    local sheetOptionsSecond = {
        width = 96,
        height = 90,
        numFrames = 15
    }

    local imageSheetSecond = graphics.newImageSheet("./images/dragon.png", sheetOptionsSecond)

    local sequanceDataSecond = {
        name = "fly",
        start = 1,
        count = 4,
        time = 1000,
        loopCount = 0,
        loopDirection = "forward"
    }

    dragon = display.newSprite(imageSheetSecond, sequanceDataSecond)

    physics.addBody(dragon, "dynamic", {radius = 20})

    dragon.HP = 150
    dragon.isSensor = true
    dragon.gravityScale = 0

    dragon.xScale = 1.5
    dragon.yScale = 1.5
    dragon.x = 159
    dragon.y = 10

    dragon.collision = dragonHit

    dragon:addEventListener("collision", dragon)

    dragonRed = display.newSprite(imageSheetSecond, sequanceDataSecond)

    dragonRed:setFillColor(1, 0, 0, 0)

    physics.addBody(dragonRed, "dynamic", {radius = 20})

    dragonRed.isSensor = true
    dragonRed.gravityScale = 0

    dragonRed.xScale = 1.5
    dragonRed.yScale = 1.5
    dragonRed.x = 159
    dragonRed.y = 10

    hitSound = audio.loadStream("./sounds/hit.mp3")
    shootSound = audio.loadStream("./sounds/shot.mp3")
    explosionSound = audio.loadStream("./sounds/explosion.mp3")

    audio.setVolume(0.05, {channel = 5})
    audio.setVolume(0.1, {channel = 6})
    audio.setVolume(0.5, {channel = 7})

    sceneGroup:insert(backgroundGroup)
    sceneGroup:insert(TextGroup)
    sceneGroup:insert(character)
    sceneGroup:insert(dragon)
    sceneGroup:insert(dragonRed)
    sceneGroup:insert(enemyGroup)
    sceneGroup:insert(bulletGroup)
    sceneGroup:insert(lifeGroup)
end

function scene:show(event)
    if event.phase == "will" then
        Runtime:addEventListener("enterFrame", updateBackground)
        character:addEventListener("touch", moveObject)
        character:play()
        dragon:play()
        dragonRed:play()
        timer.performWithDelay(4000, function()
            timerEnemy = timer.performWithDelay(2000, createEnemy, 0)
            timerShoot = timer.performWithDelay(3000, characterShoot, 0)
            timerFireball = timer.performWithDelay(4000, attackFireboll, 0)
        end)
    end
end

function scene:hide(event)
    if event.phase == "will" then
        timer.cancel(timerEnemy)
        timer.cancel(timerShoot)
        timer.cancel(timerFireball)
        textScore.text = 0
    elseif event.phase == "did"  then
        Runtime:removeEventListener("enterFrame", updateBackground)
        character:removeEventListener("touch", moveObject)
        physics.pause()
        audio.stop(4)  
        audio.stop(5)  
        audio.stop(6)  
        audio.stop(7)  
        audio.dispose(hitSound)
        audio.dispose(shootSound)
        audio.dispose(explosionSound)
        hitSound = nil
        shootSound = nil
        explosionSound = nil
        composer.removeScene("scenes.third_level")     
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)


return scene