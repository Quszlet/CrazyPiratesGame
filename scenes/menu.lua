local composer = require("composer")
local widget = require("widget")
local audio = require("audio")

local scene = composer.newScene()

BackGroundMusic = audio.loadStream("./sounds/background_music.mp3")
BackgroundMusicFirst = audio.loadStream("./sounds/background_first.mp3")
BackgroundMusicSecond = audio.loadStream("./sounds/background_fisrt.mp3")
BackgroundMusicThird = audio.loadStream("./sounds/background_third.mp3")


local function onFirstLevelButtonPressed(event)
    if event.phase == "ended" then
        audio.play(BackgroundMusicFirst, {channel = 2})
        audio.setVolume(0.2, {channel = 2})
        composer.gotoScene("scenes.first_level") -- Переход к сцене с игрой
    end
end

local function onSecondLevelButtonPressed(event)
    if event.phase == "ended" then
        audio.play(BackgroundMusicFirst, {channel = 3})
        audio.setVolume(0.2, {channel = 3})
        composer.gotoScene("scenes.second_level") 
    end
end

local function onThirdLevelButtonPressed(event)
    if event.phase == "ended" then
        audio.play(BackgroundMusicThird, {channel = 4})
        audio.setVolume(0.2, {channel = 4})
        composer.gotoScene("scenes.third_level") 
    end
end

function scene:create(event)
    local sceneGroup = self.view

    local background = display.newImageRect(sceneGroup, "./images/background.png", 900, 850)
    background.x = 159
    background.y = 250

    local nameGameText = display.newText{
        text = "Crazy Pirates",
        x = 155,
        y = 30,
        font = native.systemFontItalic,
        fontSize = 30
    }
    nameGameText:setFillColor(191, 144, 0)

    local firstLevelButton = widget.newButton{
        width = 100,
        height = 55,
        defaultFile = "./images/button_level1.png",
        onEvent = onFirstLevelButtonPressed
    }

    firstLevelButton.x = 60
    firstLevelButton.y = 470

    local secondLevelButton = widget.newButton{
        width = 100,
        height = 55,
        defaultFile = "./images/button_level2.png",
        onEvent = onSecondLevelButtonPressed
    }

    secondLevelButton.x = 262
    secondLevelButton.y = 470

    local thirdLevelButton = widget.newButton{
        width = 100,
        height = 55,
        defaultFile = "./images/button_level3.png",
        onEvent = onThirdLevelButtonPressed
    }

    thirdLevelButton.x = 162
    thirdLevelButton.y = 545


    audio.setVolume(0.3, {channel = 1})
    


    sceneGroup:insert(firstLevelButton)
    sceneGroup:insert(secondLevelButton)
    sceneGroup:insert(thirdLevelButton)
    sceneGroup:insert(nameGameText)
end

function scene:show(event)
    if event.phase == "will" then
       audio.play(BackGroundMusic)
    end
end

function scene:hide(event)
    local sceneGroup = self.view
    if event.phase == "did" then
        audio.stop(1)  -- Остановить воспроизведение звука
        audio.dispose(BackGroundMusic)
        composer.removeScene("scenes.menu")
    end
end

function scene:destroy(event)
   
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene