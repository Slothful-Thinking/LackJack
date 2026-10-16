--[[
========================================
=               LACKJACK               =
========================================
--]]

local DEBUG = false
local BANKROLL = 100
local SAVE_FILE = "lackjack.sav"

for i = 1, #arg do
    local opt = arg[i]:lower()
    if opt == "--debug" or opt == "-d" then
        DEBUG = true
    elseif opt == "--bankroll" or opt == "-b" then
    BANKROLL = tonumber(arg[i + 1]) or 100

        if BANKROLL <= 0 then
            print("A negative bankroll? Sure, buddy. Using 100.")
            BANKROLL = 100
        elseif BANKROLL <= 500 then
        elseif BANKROLL <= 1000 then
            print("You sure you can afford that much? Alright I guess.")
        elseif BANKROLL <= 4000 then
            print("Come on now. Your fiancée is not gonna be happy. ")
        else
            print("Nah, that's too much. We cap it at 5K here, we lost 4Js already!")
            BANKROLL = 4000
        end
    elseif opt:sub(1, 2) == "--" then
        print("Warning: unknown flag " .. arg[i])
    end
end

-- Trim leading/trailing garbage
local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--[[ INITIALISATIONS ]]
math.randomseed(os.time())

--[[ DELAY ]]
local function delay(seconds)
    local now = os.time()
    local target = now + seconds
    repeat until os.time() >= target
--[[    local function wait(sec)
        sec = 0.1
        local t0 = os.clock()
        while os.clock() - t0 < sec do end
    end
--]]
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

--[[ DISPLAY THE HANDS ]]
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
    io.write("(" .. tostring(FACE_VALUE[hand[1].rank]) .. "+?)\n")
    if DEBUG then
        print("Why are you cheating? The hidden card is " .. tostring(hand[2]) .. " (" .. score_hand(hand) .. "). Happy now?" )
    end
end


--[[ BETTING ]]
local function ask_bet()
    while true do
        io.write("You have " .. BANKROLL .. ".\nBet how much? ")
        delay(0.5)
        local input = trim(io.read() or "")
        local amount = tonumber(input)

        if amount == nil then
            print("We said a number. You know things like your 123456 password?")
        elseif amount <= 0 then
            print("No loans here! YOU give me money, not the other way around")
        elseif amount > BANKROLL then
            print("You wish you had that much, eh? Try again within your limits.")
        elseif amount == BANKROLL then
            if amount == 1 then
                delay(1.0)
                print("Down to your final coin, eh?")
                delay(0.5)
                print("Alright then. Don't blame me if the deck laughs at you.")
                delay(0.5)
                print("After everything. You're either brave or broken.")
               delay(0.5)
               return amount
            else
                print("All in it is. It's your money, so... whatever.")
                return amount
            end
        elseif amount ~= math.floor(amount) then
            print("Coins only. This isn't a stock exchange.")
        else
            return amount
        end
    end
end

--[[ HIT/STAND ]]
local function player_turn()
    if score_hand(player_hand) == 21 and #player_hand == 2 then
        print("BLACKJACK! Without Jacks even! You win!")
        delay(0.5)
    else
        while true do
            local total = score_hand(player_hand)
            print("You have " .. total .. ", [h]it or [s]tand?")

            local choice = trim(io.read() or ""):lower()
            if total == 21 then
                if choice == "h" or choice == "hit" then
                    delay(1.0)
                    print("Are you sure about that?\nYou already have 21 you know?")
                    local choice = trim(io.read() or ""):lower()
                    if choice == "h" or choice == "hit" then
                        print("No seriously, YOU HAVE 21!")
                        delay(0.5)
                        print("You know, the maximum?")
                        local choice = trim(io.read() or ""):lower()
                        if choice == "h" or choice == "hit" then
                            delay(1.0)                            
                            print("Alright whatever.")
                            delay(0.5)
                            local new_card = draw_card()
                            table.insert(player_hand, new_card)
                            print("You draw " .. tostring(new_card) .. " and bust! Would you look at that! Above 21! Who would have thought...")
                            return bust
                        else
                            print("I see you come to your senses. Took you long enough.")
                            delay(0.5)
                        break
                        end
                    else
                        print("Good boy.")
                        break
                        delay(0.5)
                    end
                end
            else
                if choice == "h" or choice == "hit" then
                local new_card = draw_card()
                table.insert(player_hand, new_card)
                delay(0.5)
                print("You draw " .. tostring(new_card) .. ".")
                delay(0.5)

                    if score_hand(player_hand) > 21 then
                        print("You have " .. tostring(score_hand(player_hand)) .. " and are over 21! You bust.")
                        delay(0.5)
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
end

--[[ DEALER'S TURN ]]
local function dealer_turn(hand)
    io.write("\nThe dealer shows: ")
    delay(0.5)
    for i=1, #hand do
        io.write(tostring(hand[i]) .. " ")
    end                                        io.write("(" .. score_hand(hand) .. ")\n")
    while score_hand(hand) < 17 do
        local new_card = draw_card()
        table.insert(hand, new_card)
        print("The dealer draws to 17: " .. tostring(new_card) .. ", total is now " .. score_hand(hand))
        delay(0.5)
    end        
    if score_hand(player_hand) == 21 and #player_hand == 2 then
        local winnings = math.floor(bet * 1.5)
        if winnings < bet * 1.5 then
            print("You win " .. bet * 1.5 .. "... wait!")
            delay(0.5)
            print("No! We only do full coins here. I'll keep the 50c.")
            delay(0.7)
            print("We don't even have enough to pay the Jacks.")
            delay(0.5)
            print("Your bankroll is now " .. BANKROLL + winnings .. ".")
            BANKROLL = BANKROLL + winnings
        else
            print("You win " .. winnings .. ", your bankroll is now " .. BANKROLL + winnings .. ".")
            BANKROLL = BANKROLL + winnings
            delay(0.5)
        end
    elseif score_hand(hand) > 21 and score_hand(player_hand) <= 21 then
        print("Dealer bust! You win!")
        delay(0.5)
        print("Your bankroll is now " .. BANKROLL + bet .. ".")
        BANKROLL = BANKROLL + bet
        delay(0.5)
    elseif score_hand(hand) > 21 and score_hand(player_hand) > 21 then
        print("Dealer bust. But you busted first... tough luck! You lose!")
        delay(0.5)
        print("Your bankroll is now " .. BANKROLL - bet .. ".")
        BANKROLL = BANKROLL - bet
        delay(0.5)
    elseif score_hand(hand) <= 21 and score_hand(player_hand) <= 21 and score_hand(hand) > score_hand(player_hand) then
        print("Dealer Wins!")
        delay(0.5)
        print("Your bankroll is now " .. BANKROLL - bet .. ".")
        BANKROLL = BANKROLL - bet
        delay(0.5)
    elseif score_hand(hand) <= 21 and score_hand(player_hand) <= 21 and score_hand(hand) < score_hand(player_hand) then
        print("You win!")
        delay(0.5)
        print("Your bankroll is now " .. BANKROLL + bet .. ".")
        BANKROLL = BANKROLL + bet
        delay(0.5)
    elseif score_hand(hand) <= 21 and score_hand(player_hand) <= 21 and score_hand(hand) == score_hand(player_hand) then
        print("This is a draw.")
        delay(0.5)
        print("Your bankroll is now " .. BANKROLL .. ".")
        delay(0.5)
    else
        print("Dealer wins.")
        delay(0.5)
        print("Your bankroll is now " .. BANKROLL - bet .. ".")
        BANKROLL = BANKROLL - bet
        delay(0.5)
    end
end

--[[ CONTINUE / QUIT / SAVE ]]
local function save_game(BANKROLL)
    local tmp = SAVE_FILE .. ".tmp"
    local f = io.open(tmp, "w")
    if not f then
        return false
    end
    f:write(tostring(BANKROLL), "\n")
    f:close()
    os.rename(tmp, SAVE_FILE)
end

local function load_game()
    local f = io.open(SAVE_FILE, "r")
    if not f then return nil end
    local saved = tonumber(f:read("*l") or "")
    f:close()
    return saved
end

local function play_again()
    io.write("Play again? [y]es / [n]o / [s]ave and quit ")
    local answer = (trim(io.read() or "")):sub(1, 1):lower()

    while BANKROLL > 0 do
        if answer == "s" and save_game(BANKROLL) == false then
            print("Couldn't save. The house misplaced its ledger.\nIt's probably hanging out with the Jacks.")
            return false
        elseif answer == "s" then
            save_game(BANKROLL)
            print("Ledger closed. Bankroll recorded: " .. BANKROLL)
            return false
        elseif answer == "n" then
            print("Thanks for playing LackJack.\nWe hope you had a good time.\nIf you see the Jacks, tell them to bring their asses back here!")
            return false
        elseif answer == "y" then
            return new_game()
        elseif answer ~= "n" or answer ~= "y" or answer ~= "s" then
            print("What are you doing? This isn't a valid option.\nPlease try again.")
            return false
        end
    end
    return true
end

local function new_game()
    while true do
        if BANKROLL > 4000 then
            print("Oh shit! I guess I'm losing my job now.")
            delay(0.5)
            print("\n\nI hate you.\n -- Sincerely, Jack.")
            break
        elseif BANKROLL > 0 then
            player_hand, dealer_hand = deal_cards(2)
            player_score = score_hand(player_hand)
            dealer_score = score_hand(dealer_hand)
            bet = ask_bet()
            delay(1.0)
            print(display_player_hand(player_hand))
            delay(1.0)
            print(display_dealer_hand(dealer_hand))
            delay(1.0)
            player_turn()
            delay(1.0)
            dealer_turn(dealer_hand)
            if BANKROLL <= 0 then
                print("GAME OVER")
                delay(1.0)
                print("You're broke. The dealer smirks.")
                delay(0.3)
                print("Come back when you have better odds... if we ever find the Jacks.")
                delay(0.5)
                print("Final tally: You lost everything.")
                play_again()
            end
        end
    end
end

local function menu()
    while true do
        print("\n\n\nWhat would you like to do?")
        print("[S]tart a new game or [l]oad a save: ")
        local answer = (trim(io.read() or "")):sub(1, 1):lower()
        if answer == "s" then
            new_game()
        elseif answer == "l" then
            load_game()
        else
            print("Invalid option, please use \"s\" or \"l\"")
        end
    end
end
        

--[[ LET'S PLAY ]]
print("Welcome to LackJack!\n")
delay(0.5)
menu()
