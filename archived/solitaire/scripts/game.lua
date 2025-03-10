-- scripts/game.lua

Game = {
    state = "menu",  -- "menu", "playing", "card_pack_selection", "game_over"
    deck = {},  -- The player's deck
    tableau = {},  -- The tableau piles
    foundations = {},  -- The foundation piles
    stock = {},  -- The stock pile
    waste = {},  -- The waste pile
    selectedCard = nil,  -- The currently selected card
    cardPack = "animals",  -- Default card pack
    cardScale = 0.3,  -- Scale factor for cards
    cardSpacing = 60,  -- Reduced spacing between cards
    tableauStartX = 450,  -- Adjusted starting X position for tableau piles
    tableauStartY = 350,  -- Adjusted starting Y position for tableau piles
    cardWidth = 100,  -- Width of a card after scaling (adjust based on your card image dimensions)
    cardHeight = 150,  -- Height of a card after scaling (adjust based on your card image dimensions)
    reshuffleButton = {x = 100, y = 310, width = 100, height = 50, text = "Reshuffle", enabled = true},
    maxReshuffles = 3,  -- Number of reshuffles allowed
    reshuffleCount = 0,  -- Current reshuffle count
}

function Game:initialize()
    -- Initialize the random seed
    math.randomseed(os.time())

    -- Initialize the deck
    self:initializeDeck()

    -- Debug: Print the number of cards in the deck after initialization
    print("Number of cards in deck after initialization: " .. #self.deck)

    -- Initialize the tableau, foundations, stock, and waste
    self:initializeTableau()
    self:initializeFoundations()
    self:initializeStock()
    self.waste = {}

    -- Debug: Print the number of cards in the stock pile after initialization
    print("Number of cards in stock after initialization: " .. #self.stock)

    -- Deal cards to the tableau
    self:dealTableau()

    -- Debug: Print the number of cards in each tableau pile after dealing
    for i, pile in ipairs(self.tableau) do
        print("Tableau pile " .. i .. " has " .. #pile .. " cards")
    end
end

function Game:initializeDeck()
    -- Create a standard deck of 52 cards
    self.deck = {}
    for suit = 1, 4 do
        for value = 1, 13 do
            table.insert(self.deck, Card:new(value, suit, self.cardPack))
        end
    end

    -- Shuffle the deck
    self:shuffleDeck()
end

function Game:shuffleDeck()
    -- Shuffle the deck or stock pile
    local pile = self.deck or self.stock
    for i = #pile, 2, -1 do
        local j = math.random(i)
        pile[i], pile[j] = pile[j], pile[i]
    end
end

function Game:initializeTableau()
    self.tableau = {}
    for i = 1, 7 do
        self.tableau[i] = {}
    end
end

function Game:dealTableau()
    for i = 1, 7 do
        for j = 1, i do
            if #self.stock > 0 then
                local card = table.remove(self.stock, 1)
                if j == i then
                    card.flipped = false  -- Only the bottom card in each tableau pile is face-up
                else
                    card.flipped = true
                end
                table.insert(self.tableau[i], card)
            else
                -- If the stock pile is empty, stop dealing cards
                break
            end
        end
    end
end

function Game:initializeFoundations()
    self.foundations = {}
    for i = 1, 4 do
        self.foundations[i] = {}
    end
end

function Game:initializeStock()
    -- Move all cards from the deck to the stock pile
    self.stock = {}
    for i = 1, #self.deck do
        table.insert(self.stock, table.remove(self.deck, 1))
    end

    -- Debug: Print the number of cards in the stock pile after initialization
    print("Number of cards in stock after initialization: " .. #self.stock)
end

function Game:dealTableau()
    for i = 1, 7 do
        for j = 1, i do
            if #self.stock > 0 then
                local card = table.remove(self.stock, 1)
                if j == i then
                    card.flipped = false  -- Only the bottom card in each tableau pile is face-up
                else
                    card.flipped = true
                end
                table.insert(self.tableau[i], card)
            else
                -- If the stock pile is empty, stop dealing cards
                break
            end
        end
    end
end

function Game:update(dt)
    -- Update game logic (e.g., animations, timers)
end

function Game:checkWin()
    -- Check if all four Kings are in the foundation piles
    for i, pile in ipairs(self.foundations) do
        if #pile == 0 or pile[#pile].value ~= 13 then
            return false  -- If any foundation pile is empty or doesn't have a King, the game is not won
        end
    end
    return true  -- All foundation piles have a King
end

function Game:draw()
    -- Set background color
    love.graphics.clear(hexToRGB("#A77464"))

    -- Draw the game screen
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Solitaire", 20, 20)

    -- Draw the tableau
    for i, pile in ipairs(self.tableau) do
        for j, card in ipairs(pile) do
            local cardX = self.tableauStartX + (i - 1) * (self.cardWidth + self.cardSpacing)
            local cardY = self.tableauStartY + (j - 1) * 30  -- Offset for overlapping cards
            card:draw(cardX, cardY)
        end
    end

    -- Draw the foundations (no outlines)
    for i, pile in ipairs(self.foundations) do
        local foundationX = 600 + (i - 1) * (self.cardWidth + self.cardSpacing)
        local foundationY = 50
        if #pile > 0 then
            pile[#pile]:draw(foundationX, foundationY)
        end
    end

    -- Draw the stock (no outlines)
    local stockX = 100
    local stockY = 50
    if #self.stock > 0 then
        self.stock[#self.stock]:draw(stockX, stockY)
    end

    -- Draw the waste (no outlines)
    local wasteX = 220
    local wasteY = 50
    if #self.waste > 0 then
        self.waste[#self.waste]:draw(wasteX, wasteY)
    end

    love.graphics.setColor(1, 1, 1)
    if not self.reshuffleButton.enabled then
        love.graphics.setColor(0.5, 0.5, 0.5) -- Gray out the button if disabled
    end
    love.graphics.rectangle("line", self.reshuffleButton.x, self.reshuffleButton.y, self.reshuffleButton.width, self.reshuffleButton.height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print(self.reshuffleButton.text, self.reshuffleButton.x + 10, self.reshuffleButton.y + 10)

    -- Check for win condition
    if self:checkWin() then
        love.graphics.setColor(0, 1, 0)  -- Green color
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.print("You Win!", self.tableauStartX, self.tableauStartY - 100)
    end
end

function Game:handleMousePress(x, y, button)
    if button == 1 then
        -- Check if a card in the tableau was clicked
        for i, pile in ipairs(self.tableau) do
            for j, card in ipairs(pile) do
                local cardX = self.tableauStartX + (i - 1) * (self.cardWidth + self.cardSpacing)
                local cardY = self.tableauStartY + (j - 1) * 30
                if x >= cardX and x <= cardX + self.cardWidth and y >= cardY and y <= cardY + self.cardHeight then
                    if j == #pile and card.flipped then
                        card:toggleFlip()  -- Flip the card if it's the top card of the pile
                    elseif not card.flipped then
                        -- Select the card if it's not flipped
                        self.selectedCard = card
                        self.selectedCardPile = pile
                        self.selectedCardIndex = j
                        -- Automatically move the card to a valid position
                        self:autoMoveCard(card)
                    end
                end
            end
        end

        -- Check if the stock pile was clicked
        local stockX = 100
        local stockY = 50
        if x >= stockX and x <= stockX + self.cardWidth and y >= stockY and y <= stockY + self.cardHeight then
            if #self.stock > 0 then
                -- Move the top card from the stock to the waste pile
                local card = table.remove(self.stock)
                card.flipped = false  -- Flip the card when moving to waste
                table.insert(self.waste, card)
            else
                -- If the stock is empty, move all cards from the waste back to the stock
                for i = #self.waste, 1, -1 do
                    local card = table.remove(self.waste, i)
                    card.flipped = true  -- Flip the cards back when moving to stock
                    table.insert(self.stock, card)
                end
            end
        end

        -- Check if a card in the waste was clicked
        local wasteX = 230
        local wasteY = 50
        if x >= wasteX and x <= wasteX + self.cardWidth and y >= wasteY and y <= wasteY + self.cardHeight then
            if #self.waste > 0 then
                -- Select the top card in the waste pile
                self.selectedCard = self.waste[#self.waste]
                self.selectedCardPile = self.waste
                self.selectedCardIndex = #self.waste
                -- Automatically move the card to a valid position
                self:autoMoveCard(self.selectedCard)
            end
        end

        -- Check if a card in the foundation was clicked
        for i, pile in ipairs(self.foundations) do
            local foundationX = 700 + (i - 1) * (self.cardWidth + self.cardSpacing)
            local foundationY = 50
            if x >= foundationX and x <= foundationX + self.cardWidth and y >= foundationY and y <= foundationY + self.cardHeight then
                if self.selectedCard then
                    -- Move the selected card
                    if #pile > 0 then
                        self.selectedCard = pile[#pile]
                        self.selectedCardPile = pile
                        self.selectedCardIndex = #pile
                        self:autoMoveCard(self.selectedCard)
                    end
                end
            end
        end

        -- Check if reshuffle button was clicked
        if self.reshuffleButton.enabled and x >= self.reshuffleButton.x and x <= self.reshuffleButton.x + self.reshuffleButton.width
                and y >= self.reshuffleButton.y and y <= self.reshuffleButton.y + self.reshuffleButton.height then
            self:reshuffle()
        end
    end
end

function Game:autoMoveCard(card)
    -- Check if the card can be moved to a foundation pile
    for i, pile in ipairs(self.foundations) do
        if #pile == 0 and card.value == 1 then
            -- Move the card to an empty foundation pile if it's an Ace
            table.insert(pile, table.remove(self.selectedCardPile, self.selectedCardIndex))
            self.selectedCard = nil
            return
        elseif #pile > 0 and pile[#pile].suit == card.suit and pile[#pile].value == card.value - 1 then
            -- Move the card to the foundation pile if it follows the rules
            table.insert(pile, table.remove(self.selectedCardPile, self.selectedCardIndex))
            self.selectedCard = nil
            return
        end
    end

    -- Check if the card can be moved to a tableau pile
    for i, pile in ipairs(self.tableau) do
        if #pile == 0 and card.value == 13 then
            -- Move the card to an empty tableau pile if it's a King
            table.insert(pile, table.remove(self.selectedCardPile, self.selectedCardIndex))
            self.selectedCard = nil
            return
        elseif #pile > 0 then
            local topCard = pile[#pile]
            -- Check if the suits alternate in color (red vs. black)
            local isTopCardRed = topCard.suit == 2 or topCard.suit == 3  -- Hearts (2) or Diamonds (3)
            local isSelectedCardRed = card.suit == 2 or card.suit == 3  -- Hearts (2) or Diamonds (3)
            if isTopCardRed ~= isSelectedCardRed and topCard.value == card.value + 1 then
                -- Move the card to the tableau pile if it follows the rules
                table.insert(pile, table.remove(self.selectedCardPile, self.selectedCardIndex))
                self.selectedCard = nil
                return
            end
        end
    end
end

function Game:reshuffle()
    if self.reshuffleCount < self.maxReshuffles then
        -- Debug: Print the number of cards in the waste pile before moving
        print("Number of cards in waste before reshuffle: " .. #self.waste)

        -- Move all cards from the waste pile back to the stock pile
        for i = #self.waste, 1, -1 do
            local card = table.remove(self.waste, i)
            card.flipped = true  -- Flip the cards back when moving to stock
            table.insert(self.stock, card)
        end

        -- Debug: Print the number of cards in the stock pile after moving waste cards
        print("Number of cards in stock after moving waste cards: " .. #self.stock)

        -- Debug: Print the number of cards in the tableau piles before moving
        local totalTableauCards = 0
        for i, pile in ipairs(self.tableau) do
            totalTableauCards = totalTableauCards + #pile
        end
        print("Number of cards in tableau before reshuffle: " .. totalTableauCards)

        -- Move all cards from the tableau piles back to the stock pile
        for i, pile in ipairs(self.tableau) do
            for j = #pile, 1, -1 do
                local card = table.remove(pile, j)
                card.flipped = true  -- Flip the cards back when moving to stock
                table.insert(self.stock, card)
            end
        end

        -- Debug: Print the number of cards in the stock pile after moving tableau cards
        print("Number of cards in stock after moving tableau cards: " .. #self.stock)

        -- Shuffle the stock pile
        self:shuffleDeck()

        -- Debug: Print the number of cards in the stock pile after shuffling
        print("Number of cards in stock after shuffling: " .. #self.stock)

        -- Increment the reshuffle count
        self.reshuffleCount = self.reshuffleCount + 1

        -- Disable the reshuffle button if the limit is reached
        if self.reshuffleCount >= self.maxReshuffles then
            self.reshuffleButton.enabled = false
        end

        -- Reinitialize the tableau piles
        self:initializeTableau()
        self:dealTableau()

        -- Debug: Print the number of cards in each tableau pile
        for i, pile in ipairs(self.tableau) do
            print("Tableau pile " .. i .. " has " .. #pile .. " cards")
        end
    end
end


function Game:start(cardPack)
    self.cardPack = cardPack
    self.state = "playing"
    self:initialize()
end