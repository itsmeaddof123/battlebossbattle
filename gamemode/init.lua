AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_menu.lua")
AddCSLuaFile("cl_messages.lua")

include("shared.lua")
include("player_meta.lua")
include("player.lua")
include("models.lua")
include("nav.lua")

util.AddNetworkString("CraftAttempt")
util.AddNetworkString("CraftResult")
util.AddNetworkString("TrainAttempt")
util.AddNetworkString("TrainResult")
util.AddNetworkString("TrainClosed")
util.AddNetworkString("UpdateStat")
util.AddNetworkString("ConsumeAttempt")
util.AddNetworkString("ConsumeResult")
util.AddNetworkString("ConsumeExpired")
util.AddNetworkString("UpdateInv")
util.AddNetworkString("UpdateRound")
util.AddNetworkString("UpdateInfoCache")
util.AddNetworkString("UpdateScoreboard")
util.AddNetworkString("ScoreMessage")
util.AddNetworkString("PlayerDisconnected")
util.AddNetworkString("WinnerChosen")
util.AddNetworkString("RoundRequest")
util.AddNetworkString("MessageSide")
util.AddNetworkString("AbilityAttempt")
util.AddNetworkString("AbilityResult")

--------------------------------
--[[     GAME FUNCTIONS     ]]--
-------------------------------

BBB = BBB or {
    round = "Waiting",
    time = 0,
    playing = {},
    estimatedPlaying = 0,
}

function GetRound() return BBB.round end
function GetEndTime() return BBB.time end

function GM:Initialize()
    StartWaiting()
    timer.Simple(10, InitializeSpawns)
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
        if IsValid(ply) then
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
            -- Points for being the final survivor - will also get points for surviving armageddon
            ply:UpdateScore(50, "You got 50 points for being the final survivor!")
            -- Declare player final survivor
        end
    end
    -- Add a small timer for final survivor declaration?
    EndArmageddon()
end

local function applyToxicity(ply, id, startTime)
    if IsValid(ply) and ply:GetPlaying() and GetRound() == "Armageddon" then
        if ply:Alive() then
            local damage = DamageInfo()
            damage:SetDamage(math.ceil((CurTime() - startTime) / 7))
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
        return potentialBoss
    elseif attempt <= 3 then
        return pickBoss(attempt + 1)
    else
        ResetTimers()
    end
end

local roundTimes = {
    Waiting = 2,
    Preparing = 10,
    Crafting = 150,
    Battle = 120,
    Armageddon = 90,
    Scoring = 10,
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
    if minPlayersMet() then
        -- Attempts to find a boss
        local bossFound = false
        for k, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:GetPlayable() then
                if ply:GetBoss() then
                    bossFound = true
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
        if IsValid(ply) and ply:GetPlayable() then
            ply:SetPlaying(true)
            ply:SetPlayed(true)
            ply:SetLives(3)
            ply:GiveTools()
            BBB.playing[ply] = true
            amt = amt + 1
        end
    end
    -- The double loop is a necessary evil
    for ply, bool in pairs(BBB.playing) do
        if ply:GetBoss() then
            ply:SetLives(1)
            ply:SetWalkSpeed(400)
            ply:SetRunSpeed(600)
            ply:SetJumpPower(400)
            ply:SetMaxHP(100 + 50 * amt)
            ply:SetMaxShield(100 + 25 * amt)
            ply:SetDefense(1.5)
            ply:SetShieldRegen(0.75)
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
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) then
            ply:ChooseRank()
        end
    end
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
            ply:ChangeStats()
        end
    end
    timer.Create("endbattle", roundTimes.Battle, 1, EndBattle)
    timer.Create("checkforend", 3, 0, checkForEnd)
end

-- Transitions to the armageddon phase
function EndBattle()
    StartArmageddon()
end

-- Starts the armageddon
function StartArmageddon()
    SetRound("Armageddon")
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) then
            -- Points for reaching armageddon
            ply:UpdateScore(50, "You got 50 points for reaching armageddon!")
            -- Automatically damages each living player to end the round
            local id = ply:SteamID64()
            local curtime = CurTime()
            timer.Create("applytoxicity"..tostring(id), 1, 0, function() applyToxicity(ply, id, curtime) end)
        end
    end
    timer.Create("endarmageddon", roundTimes.Armageddon, 1, EndArmageddon)
end

-- Removes everyone's items and removes the boss
function EndArmageddon()
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:SetBoss(false)
            ply:FullStrip()
        end
    end
    for ply, bool in pairs(BBB.playing) do
        if IsValid(ply) then
            -- Points for surviving multiplied by the number of remaining lives
            ply:UpdateScore(50 * ply:GetLives(), "You got 50 points for each leftover life!")
        end
    end
    timer.Remove("checkforend")
    RemoveMaterials()
    StartScoring()
end

function StartScoring()
    local playerScores = {}
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:GetPlayed() then
            ply:SetScore(ply:GetScore() * ply:GetPity())
            ply:SetPity(ply:GetPity() + 0.1) -- Pity points increase the scores of players who repeatedly lose (Resets when boss)
            playerScores[ply] = ply:GetScore()
        end
    end
    local winner = table.SortByKey(playerScores)[1]
    if winner then
        winner:SetBoss(true)
    end
    SetRound("Scoring")
    timer.Create("endscoring", roundTimes.Scoring, 1, EndScoring)
end

-- Resets everyone's stats and starts checks if enough people are available for the next round
function EndScoring()
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:FullReset()
        end
    end
    if minPlayersMet() then
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
    EndScoring()
end
