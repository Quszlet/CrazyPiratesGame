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

local timerEnemy

local enemyGroup, bulletGroup

local hitSound, shotSound, enemyHitSound

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

local function destroyEnemyCount(self, event)
    if event.phase == "began" then
        if event.other.ID == "playerBullet" then
            audio.play(enemyHitSound, {
                channel = 8,
                loops = 0,  
                duration = 2000 
            })
            xScore = xScore + 10
            if xScore == 100 then
                composer.gotoScene("scenes.win", {time=2500, effect="crossFade" })
            end
            event.other:remove()
            self:remove()
            score.text = xScore
        end
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

    enemy.ID = "enemy"

    enemyGroup:insert(enemy)

    physics.addBody(enemy, "dynamic", {radius = 20})

    enemy.ID = "targetBad"

    enemy.gravityScale = 0.0

    enemy.isSensor = true

    enemy:setLinearVelocity(0, 100)

    function enemy:remove()
        timer.cancel(self.shootTimer)
        display.remove(self)
    end


    local function shoot(event)
        if event.source.params.enemy then
            local enemy = event.source.params.enemy
            local firstBullet = display.newImageRect(bulletGroup, "./images/cannonball.png", 15, 15)
            firstBullet.x = enemy.x
            firstBullet.y = enemy.y
            
            physics.addBody(firstBullet, "dynamic")
            firstBullet.isSensor = true
            firstBullet.ID = "bullet"
            firstBullet.gravityScale = 0
            firstBullet:setLinearVelocity(100, 100) 

            function firstBullet:remove()
                display.remove(self)
            end



            local bulletSecond = display.newImageRect(bulletGroup, "./images/cannonball.png", 15, 15)
            bulletSecond.x = enemy.x
            bulletSecond.y = enemy.y

            physics.addBody(bulletSecond, "dynamic")
            bulletSecond.isSensor = true
            bulletSecond.ID = "bullet"
            bulletSecond.gravityScale = 0
            bulletSecond:setLinearVelocity(-100, 100) 


            function bulletSecond:remove()
                display.remove(self)
            end
        else
            timer.cancel(event.source)  
        end
    end
    enemy.shootTimer = timer.performWithDelay(1500, shoot, 0)
    enemy.shootTimer.params = { enemy = enemy }


    enemy.collision = destroyEnemyCount

    enemy:addEventListener("collision", enemy)

    enemy.timer = timer.performWithDelay(10000, function ()
        enemy:remove()
    end)
end


local isBlinking = false

local function countLife(self, event)
    if event.phase == "began" then
        if event.other.ID == "targetBad" or event.other.ID == "bullet" then

            if isBlinking then
                return
            end

            local blink = transition.blink(character, {time = 500})
            isBlinking = true

            audio.play(hitSound, {
                channel = 6,
                loops = -1,  
                fadein = 100,
                duration = 2000 
            })
            if indexLife > 0 then
                life[indexLife]:removeSelf()
                indexLife = indexLife - 1
            end

            if indexLife <= 0 then
                composer.gotoScene("scenes.gameover",  {time=2500, effect="crossFade" })
            end

            if xScore ~= 0 then
                xScore = xScore - 10               
            end

            event.other:remove()
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

        score.text = xScore
       
    end
end

local function characterShoot(event)
    if event.source.params.character then
        local character = event.source.params.character
        local firstBullet = display.newImageRect(bulletGroup, "./images/cannonball.png", 15, 15)
        firstBullet.x = character.x
        firstBullet.y = character.y
        
        physics.addBody(firstBullet, "dynamic")
        firstBullet.isSensor = true
        firstBullet.ID = "playerBullet"
        firstBullet.gravityScale = 0
        firstBullet:setLinearVelocity(100, 0) 


        function firstBullet:remove()
            display.remove(self)
        end

        local bulletSecond = display.newImageRect(bulletGroup, "./images/cannonball.png", 15, 15)
        bulletSecond.x = character.x
        bulletSecond.y = character.y

        physics.addBody(bulletSecond, "dynamic")
        bulletSecond.isSensor = true
        bulletSecond.ID = "playerBullet"
        bulletSecond.gravityScale = 0
        bulletSecond:setLinearVelocity(-100, 0) 

        function bulletSecond:remove()
            display.remove(self)
        end

        audio.play(shotSound, {
            channel = 7,
            loops = -1
        })
    else
        timer.cancel(event.source)  
    end
end

function scene:create(event)
    local sceneGroup = self.view
    local backgroundGroup = display.newGroup()
    local TextGroup = display.newGroup()
    local lifeGroup = display.newGroup()
    enemyGroup = display.newGroup()
    bulletGroup = display.newGroup()
    
    
    backgroundFirst = display.newImageRect(backgroundGroup,"./images/background_second.png", 900, 860)
    backgroundFirst.x = 159
    backgroundFirst.y = display.contentCenterY

    backgroundSecond = display.newImageRect(backgroundGroup, "./images/background_second.png", 900, 860)
    backgroundSecond.x = 159
    backgroundSecond.y = backgroundFirst.y - display.contentHeight

    backgroundThird = display.newImageRect(backgroundGroup, "./images/background_second.png", 900, 860)
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

    character.collision = countLife

    character.gravityScale = 0

    character.x = 175
    character.y = 500
    character.xScale = 0.5
    character.yScale = 0.5
    character:scale(-1, -1)
    character:addEventListener("collision", character)


    

    hitSound= audio.loadSound("./sounds/hit.mp3")
    shotSound = audio.loadSound("./sounds/shot.mp3")
    enemyHitSound = audio.loadSound("./sounds/enemyhit.mp3")

    audio.setVolume(0.05, {channel = 6})
    audio.setVolume(0.1, {channel = 7})
    audio.setVolume(0.05, {channel = 8})



    sceneGroup:insert(backgroundGroup)
    sceneGroup:insert(TextGroup)
    sceneGroup:insert(character)
    sceneGroup:insert(enemyGroup)
    sceneGroup:insert(lifeGroup)
    sceneGroup:insert(bulletGroup)
end

function scene:show(event)
    if event.phase == "will" then
        audio.play(BackgroundMusicSecond, {channel = 1})
        Runtime:addEventListener("enterFrame", updateBackground)
        character:addEventListener("touch", moveObject)
        character.shootTimer = timer.performWithDelay(2600, characterShoot, 0)
        character.shootTimer.params = { character = character }
        character:play()
        timerEnemy = timer.performWithDelay(2000, createEnemy, 0)
    end
end

function scene:hide(event)
    if event.phase == "will" then
        timer.cancel(timerEnemy)
        timer.cancel(character.shootTimer)
        for i = 1, enemyGroup.numChildren do
            timer.cancel(enemyGroup[i].shootTimer)
        end
        textScore.text = 0
    elseif event.phase == "did"  then
        Runtime:removeEventListener("enterFrame", updateBackground)
        character:removeEventListener("touch", moveObject)
        timer.cancelAll()
        physics.pause()
        audio.stop(3)  -- Остановить воспроизведение звука
        audio.stop(6)
        audio.stop(7)
        audio.stop(8)
        audio.dispose(BackgroundMusicSecond)
        audio.dispose(hitSound)
        audio.dispose(shotSound)
        audio.dispose(enemyHitSound)
        hitSound = nil
        shotSound = nil
        composer.removeScene("scenes.second_level")     
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)


return scene