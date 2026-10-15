--[[
========================================
=               LACKJACK               =
========================================
--]]

local DEBUG = false
for _, a in ipairs(arg) do
    if a:lower() == "--debug" or "-d" then
        DEBUG = true
    elseif a:sub(1, 2) == "--" then
        print("Warning: unknown flag " .. a)
    end
end

-- Trim leading/trailing garbage
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--[[ INITIALISATIONS ]]
math.randomseed(os.time())

--[[ THE DECK WITHOUT JACKS ]]
local SUITS = {"♠", "♡", "◇", "♣"}
local RANKS = {"A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Q", "K"}
local COLORS = {
    ["♡"] = "\x1b[31m",
    ["◇"] = "\x1b[31m",
    ["♠"] = "\x1b[37m",
    ["♣"] = "\x1b[37m"
}
local FACE_VALUE = {
    ["A"] = 11, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6,
    ["7"] = 7, ["8"] = 8, ["9"] = 9, ["10"] = 10, ["Q"] = 10, ["K"] = 10
}

--[[ BUILD THE DECKS ]]
local Card = {}
Card.__index = Card

Card.__tostring = function(self)
    local reset = "\x1b[0m"
    return COLORS[self.suit] .. self.rank .. self.suit .. reset
end

function Card.new(suit, rank)
    return setmetatable({suit = suit, rank = rank}, Card)
end

local function build_decks()
    local decks = {}
    for _, suit in ipairs(SUITS) do
        for _, rank in ipairs(RANKS) do
      	table.insert(decks, Card.new(suit, rank))
        end
    end
    return decks
end

local decks = build_decks()

local function draw_card()
    if #decks < 12 then
        decks = build_decks()
        print("The decks have been reshuffled")
    end
    return table.remove(decks, math.random(#decks)) 
end

--[[ GIVE CARDS TO THE PLAYER AND DEALER ]]
local function deal_cards(n)
    local player_hand = {}
    local dealer_hand = {}

    for i=1, n do
        player_hand[i] = draw_card()
        dealer_hand[i] = draw_card()
    end
    return player_hand, dealer_hand
end

local function score_hand(hand)
    local total = 0

    for _, card in ipairs(hand) do
        total = total + FACE_VALUE[card.rank]
        if total >= 22 and card.rank == "A" then
            total = total - 10
        end
    end

    return total
end

local player_hand, dealer_hand = deal_cards(2)
local player_score = score_hand(player_hand)
local dealer_score = score_hand(dealer_hand)

local function display_player_hand(hand)
    io.write("Player's hand: ")
    for i=1, #hand do
        io.write(tostring(hand[i]) .. " ")
    end                                        io.write("(" .. score_hand(hand) .. ")")
end

local function display_dealer_hand(hand)
    io.write("Dealer's hand: ")
    for i=1, #hand do
        if i == 2 then
            io.write("?? ")
        else
            io.write(tostring(hand[i]) .. " ")
        end
    end
    io.write("(??)\n")
    if DEBUG then
        print("For debugging hidden card is: " .. tostring(hand[2]) .. " (" .. score_hand(hand) .. ")" )
    end
end

print(display_player_hand(player_hand))
print(display_dealer_hand(dealer_hand))

--[[ HIT/STAND ]]
local function player_turn()
    if score_hand(player_hand) == 21 and #player_hand == 2 then
        print("BLACKJACK! Without Jacks even! You win!")
        bankroll = bankroll + bet * 1.5
    else
        while true do
            local total = score_hand(player_hand)
            print("You have " .. total .. ", [h]it or [s]tand?")

            local choice = trim(io.read() or ""):lower()
            if choice == "h" or choice == "hit" then
            local new_card = draw_card()
            table.insert(player_hand, new_card)
            print("You drew " .. tostring(new_card) .. ".")

                if score_hand(player_hand) > 21 then
                    print("You went over 21! You bust.")
                    return bust
                end
            elseif choice == "s" or choice == "stand" then
                return stand
            else
                print("Invalid choice, try again.")
            end
        end
    end
end

--[[ DEALER'S TURN ]]
local function dealer_turn(hand)
    io.write("\nThe dealer shows: ")
    for i=1, #hand do
        io.write(tostring(hand[i]) .. " ")
    end                                        io.write("(" .. score_hand(hand) .. ")\n")
    while score_hand(hand) < 17 do
        local new_card = draw_card()
        table.insert(hand, new_card)
        print("The dealer draws to 17: " .. tostring(new_card) .. ", total is now " .. score_hand(hand))
    end        

    if score_hand(hand) > 21 and score_hand(player_hand) <= 21 then
        print("Dealer bust! You win!")
    elseif score_hand(hand) > 21 and score_hand(player_hand) > 21 then
        print("Dealer bust. But you busted first... tough luck! You lose!")
    else
        if score_hand(hand) > score_hand(player_hand) then
            print("Dealer Wins!")
        elseif score_hand(hand) < score_hand(player_hand) then
            print("You win!")
        else
            print("This is a draw.")
        end
    end
end

--[[ LET'S PLAY ]]
player_turn()
dealer_turn(dealer_hand)
