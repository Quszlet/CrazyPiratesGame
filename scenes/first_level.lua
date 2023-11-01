local composer = require("composer")
local physics = require("physics")
local audio = require("audio")
physics.start()

local scene = composer.newScene() 

local backgroundFirst, backgroundSecond, backgroundThird
local life = {}
local indexLife = 3

local textScore, score
local xScore = 0
local character

local leftBorder = 20
local rightBorder = display.contentWidth
local topBorder = 130
local bottomBorder = display.contentHeight + 60

local timerEnemy, timerCoins

local enemyGroup, coinsGroup

local hitSound, coinSound, backgroundSounds

local hitSoundOptions, coinSoundOptions

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
        width = 165,
        height = 195,
        numFrames = 15
    }

    local imageSheet = graphics.newImageSheet("./images/enemy.png", sheetOptions)

    local sequanceData = {
        name = "swim",
        start = 1,
        count = 1,
        time = 2000,
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

    enemy.timer = timer.performWithDelay(10000, function ()
        enemy:removeSelf()
    end)
    
end

local function createCoins()
    local sheetOptions = {
        width = 205,
        height = 190,
        numFrames = 4
    }

    local imageSheet = graphics.newImageSheet("./images/money.png", sheetOptions)

    local sequanceData = {
        name = "spinning",
        start = 1,
        count = 1,
        time = 500,
        loopCount = 0,
        loopDirection = "forward"
    }

    local coin = display.newSprite(imageSheet, sequanceData)
    coin.x = math.random(10, 300)
    coin.y = -130
    coin.xScale = 0.2
    coin.yScale = 0.2

    coinsGroup:insert(coin)

    physics.addBody(coin, "dynamic", {radius = 20})

    coin.ID = "targetGood"

    coin.gravityScale = 0.0

    coin.isSensor = true

    coin:setLinearVelocity(0, 100)

    coin:play()

    coin.timer = timer.performWithDelay(10000, function ()
        coin:removeSelf()
    end)
end

local isBlinking = false

local function Count(self, event)
    if event.phase == "began" then
        if event.other.ID == "targetGood" then
            audio.play(coinSound, coinSoundOptions)
            xScore = xScore + 1
            timer.cancel(event.other.timer)
            event.other:removeSelf()

            if xScore == 10 then
                composer.gotoScene("scenes.win",  {time=2500, effect="crossFade" })
            end
        end

        if event.other.ID == "targetBad" then
            audio.play(hitSound, hitSoundOptions)

            if isBlinking then
                return
            end


            if indexLife > 0 then
                life[indexLife]:removeSelf()
                indexLife = indexLife - 1
            end

            if indexLife <= 0 then
                composer.gotoScene("scenes.gameover",  {time=2500, effect="crossFade" })
            end

            local blink = transition.blink(character, {time = 500})
            isBlinking = true

            if xScore ~= 0 then
                xScore = xScore - 1                
            end

            timer.performWithDelay(2000, function ()
                transition.cancel(blink)
                transition.to(character, {
                    time = 500,
                    alpha = 1,
                    transition = easing.outQuad
                })
                isBlinking = false
            end)
            timer.cancel(event.other.timer)
            event.other:removeSelf()
        end

        score.text = xScore
    end
    
end


function scene:create(event)
    local sceneGroup = self.view
    local backgroundGroup = display.newGroup()
    local TextGroup = display.newGroup()
    local lifeGroup = display.newGroup()
    coinsGroup = display.newGroup()
    enemyGroup = display.newGroup()
    
    
    backgroundFirst = display.newImageRect(backgroundGroup,"./images/background_first.png", 900, 860)
    backgroundFirst.x = 159
    backgroundFirst.y = display.contentCenterY

    backgroundSecond = display.newImageRect(backgroundGroup, "./images/background_first.png", 900, 860)
    backgroundSecond.x = 159
    backgroundSecond.y = backgroundFirst.y - display.contentHeight

    backgroundThird = display.newImageRect(backgroundGroup, "./images/background_first.png", 900, 860)
    backgroundThird.x = 159
    backgroundThird.y = backgroundSecond.y - display.contentHeight

    textScore = display.newText(TextGroup, "Счет: ", 40, -50, "Helvetica", 25) 
    score = display.newText(xScore, 80, -50, "Helvetica", 25) 
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

    character.collision = Count

    character.gravityScale = 0

    character.x = 175
    character.y = 500
    character.xScale = 0.5
    character.yScale = 0.5
    character:scale(-1, -1)
    character:addEventListener("collision", character)


 

    hitSoundOptions = {
        channel = 5,
        loops = -1,  
        duration = 2000 
    }

    coinSoundOptions = {
        channel = 6,
        loops = 0,  
        fadein = 100,
        duration = 400
    }
    
    hitSound = audio.loadSound("./sounds/hit.mp3")
    coinSound = audio.loadSound("./sounds/coin.mp3")

    audio.setVolume(0.05, {channel = 5})
    audio.setVolume(1, {channel = 6})


    sceneGroup:insert(backgroundGroup)
    sceneGroup:insert(TextGroup)
    sceneGroup:insert(character)
    sceneGroup:insert(enemyGroup)
    sceneGroup:insert(coinsGroup)
    sceneGroup:insert(lifeGroup)
end

function scene:show(event)
    if event.phase == "will" then
        Runtime:addEventListener("enterFrame", updateBackground)
        character:addEventListener("touch", moveObject)
        character:play()
        timerEnemy = timer.performWithDelay(2000, createEnemy, 0)
        timerCoins = timer.performWithDelay(5000, createCoins, 0)
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    if event.phase == "will" then
        timer.cancel(timerEnemy)
        timer.cancel(timerCoins)
        textScore.text = 0
    elseif event.phase == "did"  then
        Runtime:removeEventListener("enterFrame", updateBackground)
        character:removeEventListener("touch", moveObject)
        timer.cancelAll()
        physics.pause()
        composer.removeScene("scenes.first_level")     
    end
end

function scene:destroy(event)
    audio.stop(2) 
    audio.stop(5)
    audio.stop(6)  
    audio.dispose(backgroundSounds)  -- Уничтожить звук
    audio.dispose(coinSound)
    audio.dispose(hitSound)
    backgroundSounds = nil
    coinSound = nil
    hitSound = nil
end


scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)


return scene