resource.AddWorkshop(2181831767)
resource.AddWorkshop(788109554)
resource.AddWorkshop(1275272057)
resource.AddWorkshop(442214334)
resource.AddWorkshop(892493593)

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_menu.lua")
AddCSLuaFile("cl_messages.lua")

include("shared.lua")
include("player_meta.lua")
include("player.lua")
include("nav.lua")

util.AddNetworkString("AbilityAttempt")
util.AddNetworkString("AbilityResult")
util.AddNetworkString("ConsumeAttempt")
util.AddNetworkString("ConsumeExpired")
util.AddNetworkString("ConsumeResult")
util.AddNetworkString("CraftAttempt")
util.AddNetworkString("CraftResult")
util.AddNetworkString("DefaultModelChoice")
util.AddNetworkString("MessageSide")
util.AddNetworkString("PlayerDisconnected")
util.AddNetworkString("PrintColored")
util.AddNetworkString("ScoreboardRequest")
util.AddNetworkString("ScoreboardResult")
util.AddNetworkString("ScoreMessage")
util.AddNetworkString("SpectateToggle")
util.AddNetworkString("TogglePlayable")
util.AddNetworkString("TrainAttempt")
util.AddNetworkString("TrainClosed")
util.AddNetworkString("TrainResult")
util.AddNetworkString("UpdateInfoCache")
util.AddNetworkString("UpdateInv")
util.AddNetworkString("UpdateRound")
util.AddNetworkString("UpdateScoreboard")
util.AddNetworkString("UpdateStat")
util.AddNetworkString("WinnerMessage")
util.AddNetworkString("WinnerChosen")

--------------------------------
--[[     GAME FUNCTIONS     ]]--
-------------------------------

BBB = BBB or {
    round = "Waiting",
    time = 0,
    playing = {},
    estimatedPlaying = 0,
    bossLiving = false,
}

function GetRound() return BBB.round end
function GetEndTime() return BBB.time end

function GM:Initialize()
    StartWaiting()
    timer.Simple(5, InitializeSpawns)
end

---------------------------------------------
--[[     IMPORTANT ROUND DETERMINERS     ]]--
---------------------------------------------

local function minPlayersMet()
    local playable = 0
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:GetPlayable() then
            playable = playable + 1
        end
    end
    return playable >= 2
end

local function checkForEnd()
    -- Checks how many players are still playing
    local playing = 0
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) and ply:GetPlaying() then
            playing = playing + 1
        end
    end
    -- If there are more than 2 players playing then don't end the round
    if playing >= 2 then return end
    -- Remove other timers
    timer.Remove("endbattle")
    timer.Remove("endarmageddon")
    timer.Remove("checkforend")
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) then
            ply:UpdateScore(50, "You got 50 points for being the final survivor!")
        end
    end
    -- Add a small timer for final survivor declaration?
    EndArmageddon()
end

local function applyToxicity(ply, id, startTime)
    if IsValid(ply) and ply:GetPlaying() and GetRound() == "Armageddon" then
        if ply:Alive() then
            local damage = DamageInfo()
            damage:SetDamage(math.ceil((CurTime() - startTime) / 4))
            ply:TakeDamageInfo(damage)
            -- Points for surviving another second into armageddon
            ply:UpdateScore(2)
        end
    else
        timer.Remove("applytoxicity"..tostring(id))
    end
end

-- Attempts 3 times recurseively to pick a boss, and returns to waiting if none are found
local function pickBoss(attempt)
    local potentialBosses = {}
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:SetBoss(false)
            table.insert(potentialBosses, ply)
        end
    end
    local potentialBoss = potentialBosses[math.random(#potentialBosses)]
    if IsValid(potentialBoss) and potentialBoss:IsPlayer() then
        potentialBoss:SetBoss(true)
        BBB.bossLiving = true
        return potentialBoss
    elseif attempt <= 3 then
        return pickBoss(attempt + 1)
    else
        ResetTimers()
    end
end

local roundTimes = {
    Waiting = 1,
    Preparing = 7,
    Crafting = 165,
    Battle = 105,
    Armageddon = 105,
    Scoring = 5,
}

-- Sets the round marker and tells the clients
local function SetRound(arg)
    BBB.round = arg
    BBB.time = roundTimes[arg] + math.floor(CurTime())
    net.Start("UpdateRound")
    net.WriteString(GetRound())
    net.WriteInt(GetEndTime(), 16)
    net.Broadcast()
end

--------------------------------
--[[     GAMEMODE CYCLE     ]]--
--------------------------------

-- Starts the waiting timer which loops every 3 seconds until removed
function StartWaiting()
    SetRound("Waiting")
    timer.Create("endwaiting", roundTimes.Waiting, 0, EndWaiting)
end

-- Checks for game start conditions
function EndWaiting()
    if minPlayersMet() and SpawnsSelected() then
        timer.Remove("endwaiting")
        StartPreparing()
    end
end

-- Spawns players and checks to see if there is a valid boss selected
function StartPreparing()
    SetRound("Preparing")
    game.CleanUpMap()
    BBB.playing = {}
    BBB.estimatedPlaying = 0
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:GetPlayable() then
            BBB.estimatedPlaying = BBB.estimatedPlaying + 1
            ply:Spawn()
        end
    end
    SpawnMaterials()
    timer.Create("endpreparing", roundTimes.Preparing, 1, EndPreparing)
end

-- Begins the game or restarts the waiting timer
function EndPreparing()
    timer.Remove("endpreparing")
    if minPlayersMet() then
        -- Attempts to find a boss
        local bossFound = false
        for k, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                if not ply:GetPlayable() then
                    ply:KillSilent()
                elseif ply:GetBoss() then
                    bossFound = true
                    BBB.bossLiving = true
                end
            end
        end
        if not bossFound then  
            pickBoss(1)
        end
        StartCrafting()
    else
        StartWaiting()
    end
end

-- Respawns players who died and gets everyone ready for the crafting round
function StartCrafting()
    SetRound("Crafting")
    local amt = 0
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            if ply:GetPlayable() then
                ply:SetPlaying(true)
                ply:SetPlayed(true)
                ply:SetLives(3)
                ply:GiveTools()
                BBB.playing[ply] = true
                amt = amt + 1
            else
                BBB.playing[ply] = nil
            end
        end
    end
    -- The double loop is a necessary evil
    for ply, bool in pairs(BBB.playing) do
        if ply:GetBoss() then
            ply:EmitSound("vo/ravenholm/madlaugh0"..math.random(1, 4)..".wav", 150)
            ply:SetLives(1)
            ply:SetWalkSpeed(350)
            ply:SetRunSpeed(350)
            ply:SetJumpPower(350)
            ply:SetMaxHP(100 + 25 * amt)
            ply:SetMaxShield(100 + 10 * amt)
            ply:SetDefense(1.25)
            ply:SetShieldRegen(0.25)
            ply:SetModel("models/player/breen.mdl")
            if not ply:Alive() then
                ply:Spawn()
            else
                ply:SetHealth(ply:GetMaxHealth())
                ply:SetShield(ply:GetMaxShield())
                ply:GiveTools()
            end
        end
    end
    timer.Create("endcrafting", roundTimes.Crafting, 1, EndCrafting)
end

-- Determines player ranks before the battle phase begins
function EndCrafting()
    timer.Remove("endcrafting")
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) then
            ply:ChooseRank()
        end
    end
    RemoveMaterials()
    SpawnObstacles()
    StartBattle()
end

-- Gives players the necessary stats and tools and begins the battle phase
function StartBattle()
    SetRound("Battle")
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) then
            if not ply:Alive() then
                ply:Spawn()
            else
                ply:SetHealth(ply:GetMaxHealth())
                ply:SetShield(ply:GetMaxShield())
                ply:FullStrip()
                ply:GiveTools()
            end
            if ply:GetBoss() then
                ply:EmitSound("vo/Citadel/br_mock0"..tostring(3 * math.random(2, 3))..".wav", 150)
            end
            ply:ChangeStats()
        end
    end
    timer.Remove("abilitycooldown")
    if BBB.bossLiving then
        timer.Create("endbattle", roundTimes.Battle, 1, EndBattle)
    else
        timer.Create("endbattle", 10, 1, function()
            EndBattle()
        end)
    end
    timer.Create("checkforend", 3, 0, checkForEnd)
end

-- Transitions to the armageddon phase
function EndBattle()
    timer.Remove("endbattle")
    StartArmageddon()
end

-- Starts the armageddon
function StartArmageddon()
    SetRound("Armageddon")
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) then
            -- Points for reaching armageddon
            ply:UpdateScore(50, "You got 50 points for reaching Armageddon!")
            -- Automatically damages each living player to end the round
            local id = ply:SteamID64()
            local curtime = CurTime()
            timer.Create("applytoxicity"..tostring(id), 1, 0, function() applyToxicity(ply, id, curtime) end)
        end
    end
    timer.Create("breakobstacles", 7, 0, function()
        if GetRound() == "Armageddon" then
            RemoveObstacles(false)
        else
            timer.Remove("breakobstacles")
        end
    end)
    timer.Create("endarmageddon", roundTimes.Armageddon, 1, EndArmageddon)
end

-- Removes everyone's items and removes the boss
function EndArmageddon()
    timer.Remove("endarmageddon")
    timer.Remove("breakobstacles")
    timer.Remove("checkforend")
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:FullStrip()
        end
    end
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) then
            -- Points for surviving multiplied by the number of remaining lives
            ply:UpdateScore(50 * ply:GetLives(), "You got 50 points for each leftover life!")
        end
    end
    BBB.bossLiving = false
    RemoveMaterials()
    StartScoring()
end

function StartScoring()
    local playerScores = {}
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:GetPlayed() then
            -- Give the boss an extra score penalty
            if ply:GetBoss() then
                ply:SetScore(ply:GetScore() / 2)
            end
            ply:SetPity(ply:GetPity() + 0.2)
            playerScores[ply] = ply:GetScore()
        end
    end
    local playerScoresSorted = table.SortByKey(playerScores)
    local winner = playerScoresSorted[1]
    if IsValid(winner) and winner:GetBoss() then
        winner = playerScoresSorted[2]
    end
    for k, ply in ipairs(player.GetAll()) do
        ply:SetBoss(false)
    end
    if IsValid(winner) then
        winner:SetBoss(true)
        net.Start("WinnerMessage")
        local winnerMessage = winner:Name().." has won with "..tostring(math.floor(winner:GetScore())).." points and has proven worthy of being Battle Boss!"
        net.WriteString(winnerMessage)
        net.Broadcast()
    end
    SetRound("Scoring")
    timer.Create("endscoring", roundTimes.Scoring, 1, EndScoring)
end

-- Resets everyone's stats and starts checks if enough people are available for the next round
function EndScoring()
    timer.Remove("endscoring")
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:FullReset()
        end
    end
    if minPlayersMet() and SpawnsSelected() then
        StartPreparing()
    else
        StartWaiting()
    end
end

-- Allows a game to be completely stopped and restarted
function ResetTimers()
    timer.Remove("endwaiting")
    timer.Remove("endpreparing")
    timer.Remove("endcrafting")
    timer.Remove("endbattle")
    timer.Remove("endarmageddon")
    timer.Remove("endscoring")
    timer.Remove("checkforend")
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:SetBoss(false)
        end
    end
    BBB.bossLiving = false
    EndScoring()
end
