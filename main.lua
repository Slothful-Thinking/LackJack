--[[
========================================
=               LACKJACK               =
========================================
--]]

-- DEFAULT VALUES
local DEBUG = false
local BANKROLL = 100
local SAVE_FILE = "lackjack.sav"
local BANKROLL_FROM_FLAG = false

-- TEXT FORMATTING
local BOLD = "\x1b[1m"
local BLINK = "\x1b[5m"
local RESET = "\x1b[0m"

for i = 1, #arg do
    local opt = arg[i]:lower()
    if opt == "--debug" or opt == "-d" then
        DEBUG = true
    elseif opt == "--bankroll" or opt == "-b" then
        BANKROLL_FROM_FLAG = true
        BANKROLL = tonumber(arg[i + 1]) or 100
        if BANKROLL <= 0 then
            print("\nA negative bankroll? Sure, buddy. Using 100.")
            BANKROLL = 100
        elseif BANKROLL < 500 then
        elseif BANKROLL <= 1000 then
            print("\nYou sure you can afford that much? Alright I guess.")
        elseif BANKROLL <= 4000 then
            print("\nCome on now. Your fiancée is not gonna be happy.")
        else
            print("N\nah, that's too much. We cap it at 4K here, we lost 4Js already!")
            BANKROLL = 4000
        end
    elseif opt:sub(1, 2) == "--" then
        print("\nWarning: unknown flag " .. arg[i])
    end
end

--[[ UTILITIES ]]
math.randomseed(os.time())

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function delay(seconds)
    local t0 = os.clock()
    while os.clock() - t0 < seconds do end
end

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

local Card = {}
Card.__index = Card

Card.__tostring = function(self)
    return COLORS[self.suit] .. self.rank .. self.suit .. RESET
end

function Card.new(suit, rank)
    return setmetatable({suit = suit, rank = rank}, Card)
end

local function build_deck()
    local deck = {}
    for _, suit in ipairs(SUITS) do
        for _, rank in ipairs(RANKS) do
            table.insert(deck, Card.new(suit, rank))
        end
    end
    return deck
end

local deck = build_deck()

local function draw_card()
    if #deck < 12 then
        deck = build_deck()
        print("\n" .. BOLD .. "The deck has been reshuffled." .. RESET)
    end
    return table.remove(deck, math.random(#deck))
end

local function deal_cards(n)
    local hand = {}
    for i = 1, n do
        hand[i] = draw_card()
    end
    return hand
end

local function score_hand(hand)
    local total = 0
    local number_aces = 0
    for _, card in ipairs(hand) do
        total = total + FACE_VALUE[card.rank]
        if card.rank == "A" then
            number_aces = number_aces + 1
        end
    end
    while total > 21 and number_aces > 0 do
        total = total - 10
        number_aces = number_aces - 1
    end
    return total
end

local function is_natural(hand)
    return #hand == 2 and score_hand(hand) == 21
end

--[[ DISPLAY ]]
local function display_player_hand(hand)
    io.write("Player's hand: ")
    for i = 1, #hand do
        io.write(tostring(hand[i]), " ")
    end
    io.write("(" .. score_hand(hand) .. ")\n")
end

local function display_dealer_hand(hand)
    io.write("Dealer's hand: ")
    for i = 1, #hand do
        if i == 2 then
            io.write("?? ")
        else
            io.write(tostring(hand[i]), " ")
        end
    end
    io.write("(" .. FACE_VALUE[hand[1].rank] .. "+)\n")
    if DEBUG and #hand >= 2 then
        print("Why are you cheating? The hidden card is " .. tostring(hand[2])
            .. " (" .. score_hand(hand) .. "). Happy now?")
    end
end

--[[ BETTING ]]
local function ask_bet()
    while true do
        io.write("You have " .. BANKROLL .. ".\nBet how much? ")
        local input = trim(io.read() or "")
        local amount = tonumber(input)

        if amount == nil then
            print("\nWe said a " .. BOLD .. "number" .. RESET .. "You know things like your 123456 password?")
        elseif amount <= 0 then
            print("\nNo loans here! " .. BOLD .. "YOU" .. RESET .. " give me money, not the other way around")
        elseif amount > BANKROLL then
            print("\nYou wish you had that much, eh? Try again within your limits.")
        elseif amount == BANKROLL then
            if amount == 1 then
                delay(1.0)
                print("\nDown to your final coin, eh?")
                delay(0.5)
                print("Alright then. Don't blame me if the deck laughs at you.")
                delay(0.5)
                print("After everything. You're either brave or broken.")
                delay(0.5)
            else
                print("\nAll in it is. It's your money, so... whatever.")
            end
            return amount
        elseif amount ~= math.floor(amount) then
            print("\nCoins only. This isn't a stock exchange.")
        else
            return amount
        end
    end
end

--[[ PLAYER'S TURN ]]
-- returns "blackjack", "bust", or "stand"
local function player_turn(hand)
    if is_natural(hand) then
        print("\n" .. BOLD .. BLINK .. "BLACKJACK" .. RESET .. "! Without Jacks even!")
        delay(0.5)
        return "blackjack"
    end

    local warnings = 0
    while true do
        local total = score_hand(hand)
        io.write("\nYou have " .. total .. ", [h]it or [s]tand? ")
        local choice = trim(io.read() or ""):sub(1, 1):lower()

        if total == 21 then
            if choice == "h" then
                warnings = warnings + 1
                if warnings == 1 then
                    delay(0.7)
                    print("\nAre you sure about that?\nYou already have 21 you know?")
                elseif warnings == 2 then
                    print("\nNo seriously, " .. BOLD .. "YOU HAVE 21" .. RESET .. "!\nYou know, the maximum?")
                else
                    delay(1.0)
                    print("\nAlright whatever.")
                    delay(0.5)
                    local new_card = draw_card()
                    table.insert(hand, new_card)
                    if score_hand(hand) > 21 then
                        print("\nYou draw " .. tostring(new_card)
                            .. " and bust! Would you look at that!\nAbove 21! Who would have thought...")
                        delay(0.5)
                        return "bust"
                    else
                        print("You draw " .. tostring(new_card) .. ".")
                        delay(0.3)
                        print("\nOh come on! Are you kidding me? Did you sleep with the deck or something?")
                        delay(0.5)
                        warnings = 0
                    end
                end
            elseif choice == "s" then
                if warnings >= 2 then
                    print("\nI see you come to your senses. Took you long enough.")
                elseif warnings == 1 then
                    print("\nGood boy.")
                end
                return "stand"
            end
        else
            if choice == "h" then
                local new_card = draw_card()
                table.insert(hand, new_card)
                delay(0.3)
                print("You draw " .. tostring(new_card) .. ".")
                delay(0.3)
                if score_hand(hand) > 21 then
                    print("You have " .. score_hand(hand) .. " and are over 21! You bust.")
                    delay(0.5)
                    return "bust"
                end
            elseif choice == "s" then
                return "stand"
            else
                print("Invalid choice, try again.")
            end
        end
    end
end

--[[ DEALER'S TURN ]] 
-- theater only: reveal + draw to 17
-- yes even when it's a dead hand
local function dealer_turn(hand)
    io.write("\nThe dealer shows: ")
    delay(0.5)
    for i = 1, #hand do
        io.write(tostring(hand[i]), " ")
    end
    io.write("(" .. score_hand(hand) .. ")\n")
    delay(0.5)
    while score_hand(hand) < 17 do
        local new_card = draw_card()
        table.insert(hand, new_card)
        print("The dealer draws to 17: " .. tostring(new_card)
            .. ", total is now " .. score_hand(hand))
        delay(0.5)
    end
end

--[[ RESOLUTION ]]
local function settle(bet, ph, dh, presult)
    local ps, ds = score_hand(ph), score_hand(dh)
    local p_nat, d_nat = is_natural(ph), is_natural(dh)

    if p_nat and d_nat then
        print("\nTwo naturals. A push. Nobody wins. Everyone is annoyed.")
    elseif d_nat then
        print("\nDealer has blackjack. Should have seen it coming. You lose!")
        BANKROLL = BANKROLL - bet
    elseif p_nat then
        local winnings = math.floor(bet * 1.5)
        if winnings < bet * 1.5 then
            print("\nYou win " .. bet * 1.5 .. "... wait!")
            delay(0.5)
            print("\nNo! We only do full coins here. I'll keep the 50c.")
            delay(0.7)
            print("We don't even have enough to pay the Jacks.")
            delay(0.5)
        else
            print("\nYou win " .. winnings .. "!")
        end
        BANKROLL = BANKROLL + winnings
    elseif presult == "bust" then
        if ds > 21 then
            print("\nDealer bust. But you busted first... tough luck! You lose!")
        else
            print("\nYou busted. I kept drawing anyway, just to annoy you.")
            delay(0.4)
            print("Normally against the rules. Who's going to stop me? You?")
        end
        BANKROLL = BANKROLL - bet
    elseif ds > 21 then
        print("\nDealer bust! You win!")
        BANKROLL = BANKROLL + bet
    elseif ds > ps then
        print("\nDealer wins!")
        BANKROLL = BANKROLL - bet
    elseif ps > ds then
        print("\nYou win!")
        BANKROLL = BANKROLL + bet
    else
        print("\nThis is a draw.")
    end
    delay(0.3)
    print("\nYour bankroll is now " .. BANKROLL .. ".")
    delay(0.3)
end

--[[ ONE ROUND ]]
local function play_round()
    local player_hand = deal_cards(2)
    local dealer_hand = deal_cards(2)
    local bet = ask_bet()
    delay(0.5)
    display_player_hand(player_hand)
    delay(0.5)
    display_dealer_hand(dealer_hand)
    delay(0.5)
    local result = player_turn(player_hand)
    delay(0.5)
    dealer_turn(dealer_hand)
    settle(bet, player_hand, dealer_hand, result)
end

--[[ SAVE / LOAD ]]
local function save_game(bankroll)
    local f = io.open(SAVE_FILE .. ".tmp", "w")
    if not f then
        return false
    end
    f:write(tostring(bankroll), "\n")
    f:close()
    os.rename(SAVE_FILE .. ".tmp", SAVE_FILE)
    return true
end

local function load_game()
    local f = io.open(SAVE_FILE, "r")
    if not f then return nil end
    local saved = tonumber(f:read("*l") or "")
    f:close()
    if saved and saved > 0 and saved < 4000 then
        return saved
    end
    return nil
end

--[[ PLAY AGAIN / QUIT / SAVE ]]
local function play_again()
    while true do
        io.write("\nPlay again? [y]es / [n]o / [s]ave and quit ")
        local answer = (trim(io.read() or "")):sub(1, 1):lower()

        if answer == "s" then
            if save_game(BANKROLL) then
                print("\nLedger closed. Bankroll recorded: " .. BANKROLL)
            else
                print("Couldn't save. The house misplaced its ledger.\nIt's probably hanging out with the Jacks.")
            end
            return false
        elseif answer == "n" then
            print("\nThanks for playing LackJack.\nWe hope you had a good time.\nIf you see the Jacks, tell them to bring their asses back here!")
            return false
        elseif answer == "y" then
            return true
        else
            print("\nWhat are you doing? This isn't a valid option.")
        end
    end
end

--[[ MENU ]]
local function main_menu()
    print("What would you like to do?")
    print("[s]tart a new game or [l]oad a save")
    while true do
        local answer = (trim(io.read() or "")):sub(1, 1):lower()
        if answer == "l" then
            local saved = load_game()
            if saved then
                print("\nWe found a ledger: " .. saved .. " coins. Oh. You again. Fine, sit down.")
                return saved
            end
            print("\nNo ledger found. Nothing to load but your debts. New game it is.")
            return 100
        elseif answer == "s" then
            if load_game() then
                io.write("\nStarting fresh burns the old ledger. Are you sure? [y/n] ")
                local sure = (trim(io.read() or "")):sub(1, 1):lower()
                if sure == "y" then
                    os.remove(SAVE_FILE)
                    print("\nThe old ledger goes in the fire. Hey! Don't look at me like that! " .. BOLD .. "YOU" .. RESET .. " said Yes.")
                else
                    return main_menu()
                end
            end
            return 100
        else
            print("\nInvalid option, please use " .. BOLD .. "s" .. RESET .. " or " .. BOLD .. "l" .. RESET)
        end
    end
end

--[[ ENDINGS ]]
local function game_over_broke()
    print(BOLD .. BLINK .. "GAME OVER" .. RESET)
    delay(2)
    print("\nYou're broke. The dealer smirks.")
    delay(0.4)
    print("\nCome back when you have better odds... if we ever find the Jacks.")
    delay(0.5)
    print("\nFinal tally: You lost everything.")
    os.remove(SAVE_FILE)
end

local function game_over_rich()
    print("\nOh shit! I guess I'm losing my job now.")
    delay(0.7)
    print("\nI hate you.\n -- Sincerely, Jack.")
    os.remove(SAVE_FILE)
end

--[[ LET'S PLAY ]]
print("Welcome to LackJack!\n")
delay(0.5)

if not BANKROLL_FROM_FLAG then
    BANKROLL = main_menu()
end

while true do
    play_round()

    if BANKROLL <= 0 or BANKROLL >= 4000 then
        delay(1.0)
        break
    end

    if not play_again() then
        break
    end
end

if BANKROLL <= 0 then
    game_over_broke()
elseif BANKROLL >= 4000 then
    game_over_rich()
end

