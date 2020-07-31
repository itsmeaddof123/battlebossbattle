include("shared.lua")
include("cl_hud.lua")
include("cl_scoreboard.lua")
include("cl_menu.lua")
include("cl_messages.lua")

local craftingSongs = { "music/hl1_song14.mp3", "music/hl1_song20.mp3", "music/hl1_song24.mp3", "music/hl1_song26.mp3", 
                        "music/hl2_song1.mp3", "music/hl2_song12_long.mp3", "music/hl2_song26.mp3", "music/hl2_song30.mp3",
                        "music/hl2_song32.mp3", "music/hl2_song7.mp3", "music/hl2_song8.mp3", 
                        }

local battleSongs = {   "music/hl1_song10.mp3", "music/hl1_song15.mp3", "music/hl1_song17.mp3", "music/hl1_song19.mp3",
                        "music/hl1_song25_remix3.mp3", "music/hl2_song14.mp3", "music/hl2_song15.mp3", "music/hl2_song16.mp3",
                        "music/hl2_song20_submix0.mp3", "music/hl2_song25_teleporter.mp3", "music/hl2_song29.mp3", "music/hl2_song3.mp3",
                        "music/hl2_song31.mp3", "music/hl2_song4.mp3", 
                        }

-----------------------------------------------------------------------
--[[     PLAYER VARIABLE UPDATES FROM THE SERVER TO THE CLIENT     ]]--
-----------------------------------------------------------------------

-- Cache with local player info
playerCache = playerCache or {
    round = "Waiting",
    time = 0,
    shield = 0,
    maxShield = 0,
    lastAbility = 0,
    playSongs = true,
    songVolume = 50,
    scoreboardInitialized = false,
}

-- Cache with info on each player
scoreboardCache = scoreboardCache or {}

-- Used to initialize a player's scoreboard cache to prevent errors when there's missing info
function cacheInit() return {playing = false, boss = false, score = 0} end

-- Updates the player cache with new player info
net.Receive("UpdateInfoCache", function(len)
    local key = net.ReadString()
    local varType = net.ReadString()
    if varType == "boolean" then
        playerCache[key] = net.ReadBool()
    elseif varType == "number" then
        playerCache[key] = net.ReadInt(16)
    elseif varType == "string" then
        playerCache[key] = net.ReadString()
    end
end)

-- Updates the player cache with new inventory info
net.Receive("UpdateInv", function(len)
    local itemType = net.ReadString()
    local itemId = net.ReadInt(16)
    local amt = net.ReadInt(16)
    if not playerCache[itemType] then
        playerCache[itemType] = {0, 0, 0, 0, 0, 0}
    end
    if itemType == "mats" and amt > playerCache[itemType][itemId] then
        local matImage = vgui.Create("DImage")
        matImage:SetSize(100, 100)
        matImage:SetPos(ScrW() * math.random(30, 70) / 100 - 100, ScrH() * math.random(65, 95) / 100 - 100)
        matImage:MoveTo(ScrW() / 2 - 50, ScrH() + 1000, 2, 1.5, -1, function() matImage:Remove() end)
        matImage:SetImage(craftingTable.materials[itemId])
    end
    playerCache[itemType][itemId] = amt
end)

-- Update the player cache with new stat info
local statNames = {"Max Health", "Max Shield", "Ranged Strength", "Melee Strength", "Defense", "Speed & Jump"}
net.Receive("UpdateStat", function(len)
    local statId = net.ReadInt(16)
    local amt = net.ReadDouble()
    if not playerCache.stats then
        playerCache.stats = {0, 0, 0, 0, 0, 0}
    end
    playerCache.stats[statId] = amt
    if amt > 0 and IsValid(LocalPlayer()) then
        local ply = LocalPlayer()
        if timer.Exists("trainingsound") then
            timer.Remove("trainingsound")
            timer.Create("trainingsound", 0.25, 1, function()
                if ply then ply:StopSound("ambient/levels/labs/teleport_active_loop1.wav") end
                timer.Remove("trainingsound")
            end)
        else
            ply:EmitSound("ambient/levels/labs/teleport_active_loop1.wav", 100, 100, 0.5)
            timer.Create("trainingsound", 0.25, 1, function()
                if ply then ply:StopSound("ambient/levels/labs/teleport_active_loop1.wav") end
                timer.Remove("trainingsound")
            end)
        end
    end
    if amt >= 50 and IsValid(LocalPlayer()) then
        LocalPlayer():ChatPrint("Finished training: "..statNames[statId])
        LocalPlayer():EmitSound("hl1/fvox/bell.wav")
    end
end)

-- Updates the player cache with new round info
net.Receive("UpdateRound", function(len)
    playerCache.round = net.ReadString()
    playerCache.time = net.ReadInt(16)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if playerCache.round == "Crafting" and IsValid(ply) then
        if playerCache.playSongs then
            ply:EmitSound(craftingSongs[math.random(1, #craftingSongs)], 100, 100, playerCache.songVolume / 100)
        elseif ply then
            ply:EmitSound("ambient/alarms/warningbell1.wav")
        end
        if scoreboardCache[ply] and scoreboardCache[ply].boss then
            messageTop("Crafting: Slap players with your bat, destroy props with your zapper, and use your abilities to slow the others!")
        else
            messageTop("Crafting: Punch props to gain materials! Craft gear and train stats to get ready for the Battle Round!")
        end
    elseif playerCache.round == "Battle" and IsValid(ply) then
        playerCache.lastAbility = 0
        if playerCache.playSongs then
            for k, v in ipairs(craftingSongs) do
                ply:StopSound(v)
            end
            ply:EmitSound(battleSongs[math.random(1, #battleSongs)], 100, 100, playerCache.songVolume / 100)
        else
            ply:EmitSound("ambient/alarms/warningbell1.wav")
        end
        if IsValid(trainingPanel) then
            trainingPanel:Remove()
        end
        if IsValid(craftingPanel) then
            craftingPanel:Remove()
        end
        if playerCache.rank then
            messageTop(craftingTable.ranks[playerCache.rank])
        end
    elseif playerCache.round == "Armageddon" and IsValid(ply) then
        ply:EmitSound("ambient/alarms/alarm_citizen_loop1.wav", 100, 100, 0.75)
        timer.Simple(5.7, function() if IsValid(ply) then ply:StopSound("ambient/alarms/alarm_citizen_loop1.wav") end end)
        messageTop("Armageddon: Shields are disabled. You're all dying. It's only a matter of time before it all ends and the victor is crowned!")
    elseif playerCache.round == "Scoring" and IsValid(ply) then
        for k, v in ipairs(battleSongs) do
            ply:StopSound(v)
        end
        toggleConsumables(false)
    end
end)

-- e
net.Receive("WinnerMessage", function(len)
    messageTop(net.ReadString())
end)

-- Updates the scoreboard cache with new player info
net.Receive("UpdateScoreboard", function(len)
    local key = net.ReadString()
    local vartype = net.ReadString()
    local arg
    if vartype == "boolean" then
        arg = net.ReadBool()
    elseif vartype == "number" then
        arg = net.ReadInt(16)
    end
    local ply = net.ReadEntity()

    if IsValid(ply) then
        if scoreboardCache[ply] then
            scoreboardCache[ply][key] = arg
        else
            scoreboardCache[ply] = cacheInit()
            scoreboardCache[ply][key] = arg
        end
        if key == "boss" and arg == true and playerCache.round == "Armageddon" then
            messageTop("The champion of this game is "..ply:Name()..", who has won with "..tostring(scoreboardCache[ply].score).." points! They have earned the title of Battle Boss!")
        end
    end
end)

net.Receive("MessageSide", function(len)
    local msg = net.ReadString()
    if isstring(msg) then
        messageSide(msg)
    end
end)

net.Receive("ScoreMessage", function(len)
    local msg = net.ReadString()
    if IsValid(LocalPlayer()) then LocalPlayer():ChatPrint(msg) end
end)

net.Receive("ConsumeExpired", function(len)
    local itemId = net.ReadInt(16)
    if IsValid(LocalPlayer()) then LocalPlayer():ChatPrint("Your "..craftingTable.items[6][itemId].name.." has expired!") end
    -- Add a sound here
end)

-- Removes a player from the cache
net.Receive("PlayerDisconnected", function(len)
    local ply = net.ReadEntity()
    if IsValid(ply) then
        scoreboardCache[ply] = nil
    end
end)

-- Handles the server response to a boss ability attempt
net.Receive("AbilityResult", function(len)
    local success = net.ReadBool()
    if success then
        playerCache.lastAbility = CurTime()
    end
end)

-- Initializes the player's scoreboard cache
net.Receive("ScoreboardResult", function(len)
    local ply = net.ReadEntity()
    local playingInfo = net.ReadBool()
    local bossInfo = net.ReadBool()
    local scoreInfo = net.ReadInt(16)
    if IsValid(ply) then
        if not scoreboardCache[ply] then
            scoreboardCache[ply] = cacheInit()
        end
        scoreboardCache[ply].playing = playingInfo
        scoreboardCache[ply].boss = bossInfo
        scoreboardCache[ply].score = scoreInfo
    end
end)

-- Toggle crafting and training
toggleCraft = false
toggleTrain = false
hook.Add("OnSpawnMenuOpen", "SpawnMenuClose", function()
    local ply = LocalPlayer()
    if ply and scoreboardCache[ply] and scoreboardCache[ply].playing then
        if scoreboardCache[ply].boss and (playerCache.round == "Crafting" or playerCache.round == "Battle" or playerCache.round == "Crafting") then
            if playerCache.lastAbility + 7.1 <= CurTime() then
                net.Start("AbilityAttempt")
                net.WriteString("Q")
                net.SendToServer()
            end
        elseif playerCache.round == "Crafting" then
            toggleCrafting(not toggleCraft)
        elseif playerCache.round == "Battle" or playerCache.round == "Armageddon" then
            toggleConsumables(true)
        end
    end
    return false
end)
hook.Add("OnSpawnMenuClose", "SpawnMenuClose", function()
    toggleConsumables(false)
end)
hook.Add("KeyPress", "UseOpened", function(ply, key)
    if scoreboardCache[ply] and scoreboardCache[ply].playing and key == IN_USE then
        if scoreboardCache[ply].boss and (playerCache.round == "Crafting" or playerCache.round == "Battle" or playerCache.round == "Crafting") then
            if playerCache.lastAbility + 7.1 <= CurTime() then
                net.Start("AbilityAttempt")
                net.WriteString("E")
                net.SendToServer()
            end
        elseif playerCache.round == "Crafting" then
            toggleTraining(not toggleTrain)
        elseif playerCache.round == "Battle" or playerCache.round == "Armageddon" then
            toggleConsumables(true)
        end
    end
end)
hook.Add("KeyReleased", "UseReleased", function(ply, key)
    toggleConsumables(false)
end)
hook.Add("PlayerButtonDown", "MenuToggler", function(ply, key)
    if key == KEY_F1 then
        toggleF1Menu(not toggleF1)
    end
    -- Cheap way to tell the server that the player is ready to receive scoreboard information
    if not playerCache.scoreboardInitialized and not timer.Exists("waitforinfo") then
        timer.Create("waitforinfo", 3, 1, function() timer.Remove("waitforinfo") end) -- Gives the server time to respond
        net.Start("ScoreboardRequest")
        net.SendToServer()
    end
end)

hook.Add("PlayerButtonUp", "ConsumeReleaser", function(ply, key)
    if key == KEY_Q or key == KEY_E then
        toggleConsumables(false)
    end
end)