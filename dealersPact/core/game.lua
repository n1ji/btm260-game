-- core/game.lua

Game = {
    state = "menu",
    deck = {},
    dealerDeck = {},
    playerHand = {},
    dealerHand = {},
    soulEssence = 100,
    wheelOfFate = {},
    cardScale = 0.5,
    cardSpacing = 10,
    dealerStartX = 430,
    dealerStartY = 300,
    playerStartX = 430,
    playerStartY = 600,
    cardWidth = 338 * 0.5,
    cardHeight = 507 * 0.5,
    hoveredCard = nil,
    hoverFont = love.graphics.newFont("assets/fonts/NotoSansBold.ttf", 14),
    deckPosition = {x = 1400, y = 100},
    dealingAnimation = nil,
    maxHandSize = 5, -- Maximum number of cards in the player's hand
    shakeDuration = 0,
    shakeIntensity = 1.6,
    shakeOffset = {x = 0, y = 0},
    wheel = nil,
    screenWidth = love.graphics.getWidth(),
    screenHeight = love.graphics.getHeight(),
    musicVolume = 0.03,
    effectVolume = 0.5
}

function Game:indexOf(table, element)
    for i, v in ipairs(table) do
        if v == element then
            return i
        end
    end
    return -1
end

function Game:initialize()
    math.randomseed(os.time())
    self:initializeDecks()
    self:initializeWheelOfFate()
    self:drawHands()

    self.deckImage = love.graphics.newImage("assets/cards/back_lq.png")
    self.backMask = love.graphics.newImage("assets/cards/back_mask_lq.png")
    self.goldShader = love.graphics.newShader("assets/shaders/gold.glsl")
    self.goldShader:send("u_mask", self.backMask)

    self.optionsMenu = require("states.options")
    self.optionsMenu:initialize()

    -- self.wheel = require("core.wheel")
    -- self.wheel:initialize(self.screenWidth, self.screenHeight)
end

function Game:initializeDecks()
    self.deck = {}
    self.dealerDeck = {}

    -- Load cards from cards.lua
    local cards = require("data.cards")

    -- Add resource cards to player's deck
    for _, cardData in ipairs(cards.resourceCards) do
        table.insert(self.deck, Card:new("resource_lq", cardData.name, cardData.effect))
    end

    -- Add action cards to player's deck
    for _, cardData in ipairs(cards.actionCards) do
        table.insert(self.deck, Card:new("action_lq", cardData.name, cardData.effect))
    end

    -- Add gamble cards to player's deck
    for _, cardData in ipairs(cards.gambleCards) do
        table.insert(self.deck, Card:new("gamble_lq", cardData.name, cardData.effect))
    end

    -- Add dealer cards to dealer's deck
    for _, cardData in ipairs(cards.dealerCards) do
        table.insert(self.dealerDeck, Card:new("dealer_lq", cardData.name, cardData.effect))
    end

    self:shuffleDeck(self.deck)
    self:shuffleDeck(self.dealerDeck)
end

function Game:initializeWheelOfFate()
    local cards = require("data.cards")
    self.wheelOfFate = cards.wheelOfFate
end

function Game:update(dt)
    -- Update hover state for options menu buttons
    if self.state == "settings" then
        local mouseX, mouseY = love.mouse.getPosition()
        self.optionsMenu:updateHoverState(mouseX, mouseY)
    end

    -- Update hovered card
    local mouseX, mouseY = love.mouse.getPosition()
    self.hoveredCard = nil
    for i, card in ipairs(self.playerHand) do
        local cardX = self.playerStartX + (i - 1) * (self.cardWidth + self.cardSpacing)
        local cardY = self.playerStartY
        if mouseX >= cardX and mouseX <= cardX + self.cardWidth and
           mouseY >= cardY and mouseY <= cardY + self.cardHeight then
            self.hoveredCard = card
        end
    end

    -- Update dealing animation
    if self.dealingAnimation then
        local card = self.dealingAnimation
        card.animationProgress = card.animationProgress + dt * 2.5
        if card.animationProgress >= 1 then
            card.animationProgress = 1
            table.insert(self.playerHand, card)
            self.dealingAnimation = nil
        end
    end

    -- Shake Animation
    if self.shakeDuration > 0 then
        self.shakeDuration = self.shakeDuration - dt
        self.shakeOffset.x = (math.random() - 0.5) * 2 * self.shakeIntensity
        self.shakeOffset.y = (math.random() - 0.5) * 2 * self.shakeIntensity
    else
        self.shakeOffset.x = 0
        self.shakeOffset.y = 0
    end

    -- Update shader uniforms
    self.goldShader:send("u_time", love.timer.getTime())
    self.goldShader:send("u_resolution", {love.graphics.getWidth(), love.graphics.getHeight()})

    -- Update the wheel
    --self.wheel:update(dt)
end

function Game:shuffleDeck(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

function Game:drawHands()
    self.playerHand = {}
    self.dealerHand = {}
    for i = 1, 5 do
        table.insert(self.dealerHand, table.remove(self.dealerDeck, 1))
    end
end

function Game:dealCard()
    -- Check if the player's hand is already full
    if #self.playerHand >= self.maxHandSize then
        print("Your hand is full! You can't draw more than 5 cards.")
        return
    end

    if #self.deck > 0 then
        local card = table.remove(self.deck, 1)
        card.x = self.deckPosition.x
        card.y = self.deckPosition.y
        card.targetX = self.playerStartX + (#self.playerHand) * (self.cardWidth + self.cardSpacing)
        card.targetY = self.playerStartY
        card.animationProgress = 0
        self.dealingAnimation = card
        card.sound:play()
    else
        print("No more cards in the deck!")
    end
end

function Game:draw()
    love.graphics.clear(hexToRGB("#1A1B3A"))
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont("assets/fonts/EnchantedLand.otf", 36))
    love.graphics.print("Soul Essence: " .. self.soulEssence, 20, 20)

    -- Draw deck
    love.graphics.setShader(self.goldShader)
    love.graphics.draw(self.deckImage, self.deckPosition.x + self.shakeOffset.x, self.deckPosition.y + self.shakeOffset.y, 0, self.cardScale, self.cardScale)
    love.graphics.setShader()

    -- Draw player's hand
    for i, card in ipairs(self.playerHand) do
        local cardX = self.playerStartX + (i - 1) * (self.cardWidth + self.cardSpacing)
        local cardY = self.playerStartY
        card:draw(cardX, cardY)
        card:drawText(cardX, cardY)
    end

    -- Draw dealer's hand
    for i, card in ipairs(self.dealerHand) do
        local cardX = self.dealerStartX + (i - 1) * (self.cardWidth + self.cardSpacing)
        local cardY = self.dealerStartY - 200
        card:draw(cardX, cardY)
    end

    -- Draw the card being dealt (if any)
    if self.dealingAnimation then
        local card = self.dealingAnimation
        local x = card.x + (card.targetX - card.x) * card.animationProgress
        local y = card.y + (card.targetY - card.y) * card.animationProgress
        card:draw(x, y)
        card:drawText(x, y)
    end

    -- Draw hovered card details
    if self.hoveredCard then
        love.graphics.setColor(1, 1, 1)
        local font = self.hoverFont
        local padding = 10
        local maxWidth = 290
        local maxBoxWidth = 320

        -- Split the effect text into multiple lines if it's too long
        local effectLines = {}
        local currentLine = ""
        for word in self.hoveredCard.effect:gmatch("%S+") do
            if font:getWidth(currentLine .. " " .. word) <= maxWidth then
                currentLine = currentLine .. " " .. word
            else
                table.insert(effectLines, currentLine)
                currentLine = word
            end
        end
        table.insert(effectLines, currentLine)

        -- Calculate the total height of the hover box
        local lineHeight = font:getHeight()
        local totalHeight = padding * 2 + lineHeight * (#effectLines + 1)

        -- Draw the hover box background
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 10, 100, maxBoxWidth + 20 * 2, totalHeight - 15)
        love.graphics.setColor(1, 1, 1)

        -- Draw the effect lines
        love.graphics.setFont(font)
        love.graphics.print("Effect: " .. effectLines[1], 10 + padding, 100 + padding)
        for i = 2, #effectLines do
            love.graphics.print(effectLines[i], 10 + padding, 100 + padding * (i + 1))
        end
    end

--    self.wheel:draw()
end

function Game:handleMousePress(x, y, button)
    if button == 1 then
        -- Check if the deck was clicked
        if x >= self.deckPosition.x and x <= self.deckPosition.x + self.cardWidth and
           y >= self.deckPosition.y and y <= self.deckPosition.y + self.cardHeight then
            if self.dealingAnimation then
                return
            end

            if #self.playerHand >= self.maxHandSize then
                self.shakeDuration = 0.12
            else
                self:dealCard()
            end
        end

        -- Check if a card in the player's hand was clicked
        for i, card in ipairs(self.playerHand) do
            local cardX = self.playerStartX + (i - 1) * (self.cardWidth + self.cardSpacing)
            local cardY = self.playerStartY
            if x >= cardX and x <= cardX + self.cardWidth and y >= cardY and y <= cardY + self.cardHeight then
                self:playCard(card)
            end
        end

        --self.wheel:handleMousePress(x, y)
    end
end

function Game:playCard(card)
    if card.type == "resource" then
        self:applyResourceEffect(card.effect)
    elseif card.type == "action" then
        self:applyActionEffect(card.effect)
    elseif card.type == "gamble" then
        self:applyGambleEffect(card.effect)
    end
    local index = self:indexOf(self.playerHand, card)
    if index ~= -1 then
        table.remove(self.playerHand, index)
    end
end

function Game:applyResourceEffect(effect)
    if effect == "+10 points" then
        self.soulEssence = self.soulEssence + 10
    elseif effect == "+5 points, Draw 1" then
        self.soulEssence = self.soulEssence + 5
        self:dealCard()
    end
end

function Game:applyActionEffect(effect)
    if effect == "Swap one of your cards with a random card from the Dealer's hand" then
        self:swapCardWithDealer()
    elseif effect == "Reroll the Wheel of Fate effect for this round" then
        self:spinWheelOfFate()
    end
end

function Game:applyGambleEffect(effect)
    if effect == "Flip a coin: Heads, gain 20 points. Tails, lose 10 points" then
        if math.random(2) == 1 then
            self.soulEssence = self.soulEssence + 20
        else
            self.soulEssence = self.soulEssence - 10
        end
    end
end

function Game:spinWheelOfFate()
    local effect = self.wheelOfFate[math.random(#self.wheelOfFate)]
    print("Wheel of Fate: " .. effect.name)
end

function Game:start()
    self.state = "playing"
    self:initialize()

    -- Deal 5 cards to the player at the start of the game
    for i = 1, 5 do
        self:dealCard()
    end
end