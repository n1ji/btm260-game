-- states/menu.lua
local Button = require("ui.button")

Menu = {}

function Menu:initialize()
    self.screenWidth = 1680
    self.screenHeight = 960
    love.window.setMode(self.screenWidth, self.screenHeight, {resizable=false})
    love.window.setTitle("The Dealer's Pact")

    self.white = {1, 1, 1, 1}
    self.black = {hexToRGB("#0B0B0B")}
    self.red = {hexToRGB("#8B0000")}
    self.gold = {hexToRGB("#CAA52B")}
    self.purple = {hexToRGB("#3B1E5F")}
    self.blue = {hexToRGB("#1A1B3A")}
    self.gray = {0.8, 0.8, 0.8, 1}
    self.hoverColor = {0.6, 0.6, 0.6, 1}

    self.titleFont = love.graphics.newFont("assets/fonts/EnchantedLand.otf", 74)
    self.buttonFont = love.graphics.newFont("assets/fonts/EnchantedLand.otf", 50)

    self.music = love.audio.newSource("assets/sounds/mainMenu.mp3", "stream")
    self.music:setVolume(Game.musicVolume)
    self.music:setLooping(true)
    love.audio.play(self.music)

    self.titleText = "The Dealer's Pact"
    self.titleX = self.screenWidth / 2 - self.titleFont:getWidth(self.titleText) / 2
    self.titleY = 100

    local buttonGap = 30
    local buttonStartY = 250

    self.mainMenuButtons = {
        Button:new("Play", self.screenWidth / 2 - 100, buttonStartY, 200, 50, "play", 20, 40),
        Button:new("Settings", self.screenWidth / 2 - 100, buttonStartY + 50 + buttonGap, 200, 50, "settings", 20, 40),
        Button:new("Quit", self.screenWidth / 2 - 100, buttonStartY + 2 * (50 + buttonGap), 200, 50, "quit", 20, 40)
    }

    -- Load the options menu
    self.optionsMenu = require("states.options")
    self.optionsMenu:initialize()
    self.currentMenu = "main"
end

function Menu:update(dt)
    -- Update hover state for options menu buttons
    if self.currentMenu == "settings" then
        local mouseX, mouseY = love.mouse.getPosition()
        self.optionsMenu:updateHoverState(mouseX, mouseY)
    end
    if self.currentMenu == "main" then
        local mouseX, mouseY = love.mouse.getPosition()
        for i, button in ipairs(self.mainMenuButtons) do
            button.hovered = button:isHovered(mouseX, mouseY)
        end
    end
end

function Menu:draw()
    love.graphics.clear(self.blue)
    if self.currentMenu == "main" then
        love.graphics.setFont(self.titleFont)
        love.graphics.setColor(self.white)
        love.graphics.print(self.titleText, self.titleX, self.titleY)

        love.graphics.setFont(self.buttonFont)
        for i, button in ipairs(self.mainMenuButtons) do
            button:draw()
        end
    elseif self.currentMenu == "settings" then
        self.optionsMenu:draw()
    end
end

function Menu:handleMousePress(x, y, button)
    if self.currentMenu == "main" then
        for i, btn in ipairs(self.mainMenuButtons) do
            if btn:isHovered(x, y) then
                if btn.action == "play" then
                    Game.state = "playing"
                    Game:initialize()
                elseif btn.action == "settings" then
                    self.currentMenu = "settings"
                elseif btn.action == "quit" then
                    love.event.quit()
                end
            end
        end
    elseif self.currentMenu == "settings" then
        local result = self.optionsMenu:handleMousePress(x, y)
        if result == "return" then
            self.currentMenu = "main"  -- Return to the main menu
        end
    end
end