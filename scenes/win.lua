local composer = require("composer")
local widget = require("widget")

local scene = composer.newScene()

local function onMenuButtonPressed(event)
    if event.phase == "ended" then
        composer.gotoScene("scenes.menu") 
    end
end


function scene:create(event)
    local sceneGroup = self.view
    
    local background = display.newImageRect(sceneGroup, "./images/backgroundWin.jpg", 750, 720)
    background.x = 159
    background.y = 250

    local textYouLose = display.newImageRect(sceneGroup, "./images/you_win.png", 250, 150)
    textYouLose.x = 159
    textYouLose.y = 100

    local menuButton = widget.newButton{
        width = 100,
        height = 55,
        defaultFile = "./images/button_menu.png",
        onEvent = onMenuButtonPressed
    }

    menuButton.x = 159
    menuButton.y = 310

    sceneGroup:insert(menuButton)
end

scene:addEventListener("create", scene)

return scene