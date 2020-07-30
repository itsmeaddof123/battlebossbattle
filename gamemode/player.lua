-----------------------------------
--[[     MISC PLAYER HOOKS     ]]--
-----------------------------------

function GM:PlayerDisconnected(ply)
    net.Start("PlayerDisconnected")
    net.WriteEntity(ply)
    net.Broadcast()
    BBB.playing[ply] = nil
end

----------------------------------------
--[[     PLAYER SPAWN FUNCTIONS     ]]--
----------------------------------------

-- For one-time initializing
function GM:PlayerInitialSpawn(ply)
    ply:FullReset()
    ply:InitReset()
    ply:SpawnReset()
end

-- For every-life actions
function GM:PlayerSpawn(ply)
    if IsValid(ply) and ply:GetInitialized() then
        ply:SetMaxHealth(ply:GetMaxHP())
        ply:SpawnReset()
        if ply:SteamID64() then
            timer.Remove("respawn"..ply:SteamID64())
        end
    end
end

----------------------------------------
--[[     PLAYER DEATH FUNCTIONS     ]]--
----------------------------------------

-- Prevents the player from respawning manually
function GM:PlayerDeathThink(ply)
    return false
end

 -- Called first
function GM:DoPlayerDeath(victim, attacker, dmg)
end

local deathSounds = {
    "player/pl_pain5.wav",
    "player/pl_pain6.wav",
    "player/pl_pain7.wav",
    "vo/npc/barney/ba_pain06.wav",
    "vo/npc/barney/ba_pain07.wav",
    "vo/npc/barney/ba_pain09.wav",
    "vo/npc/barney/ba_no01.wav",
    "vo/npc/male01/no01.wav",
    "vo/npc/male01/no02.wav",
    "vo/npc/male01/pain04.wav",
    "vo/npc/male01/pain07.wav",
    "vo/npc/male01/pain08.wav",
    "vo/npc/male01/pain09.wav",
}
local killSounds = {
    "vo/npc/barney/ba_yell.wav",
    "vo/npc/barney/ba_ohyeah.wav",
    "vo/npc/barney/ba_gotone.wav",
    "vo/npc/barney/ba_downyougo.wav",
    "vo/npc/barney/ba_goingdown.wav",
    "vo/npc/male01/answer39.wav",
    "vo/npc/male01/gotone01.wav",
    "vo/npc/male01/gotone02.wav",
    "vo/npc/male01/oneforme.wav",
}
local eliminationSounds = {
    "vo/npc/barney/ba_laugh01.wav",
    "vo/npc/barney/ba_laugh02.wav",
    "vo/npc/barney/ba_laugh03.wav",
    "vo/npc/barney/ba_laugh04.wav",
    "vo/npc/barney/ba_bringiton.wav",
    "vo/npc/male01/answer35.wav",
    "vo/npc/male01/nice.wav",
    "vo/npc/male01/yeah02.wav",
}

-- Called second
function GM:PlayerDeath(victim, inflictor, attacker)
    if IsValid(victim) and victim:GetPlaying() then
        local lives = victim:GetLives()
        if GetRound() == "Battle" or GetRound() == "Armageddon" then
            lives = lives - 1
            if IsValid(attacker) and attacker:IsPlayer() and not (victim == attacker) then
                attacker:UpdateScore(50, "You got 50 points for the kill!")
            end
        end
        victim:SetLives(lives)
        if lives == 0 then
            victim:SetPlaying(false)
            BBB.playing[victim] = nil
            if victim:GetBoss() then
                if IsValid(attacker) and attacker:IsPlayer() and victim != attacker then
                    attacker:UpdateScore(150," You got 150 points for eliminating the boss!")
                    attacker:EmitSound(eliminationSounds[math.random(1, #eliminationSounds)])
                end
                messageSide("The Battle Boss has been defeated! Armageddon time!")
            else
                if IsValid(attacker) and attacker:IsPlayer() and victim != attacker then
                    attacker:UpdateScore(25, "You got 25 points for the elimination!")
                    attacker:EmitSound(eliminationSounds[math.random(1, #eliminationSounds)])
                end
                messageSide(victim:Name().." has been eliminated! Keep fighting!")
            end
        else
            if IsValid(attacker) and attacker:IsPlayer() and victim != attacker then
            attacker:EmitSound(killSounds[math.random(1, #killSounds)])
            end
        end
        if victim:GetBoss() and GetRound() == "Battle" and timer.Exists("endbattle") then
            EndBattle()
        end
        victim:EmitSound(deathSounds[math.random(1, #deathSounds)])
    end
    -- Tells clients kill info
end

-- Called third
function GM:PostPlayerDeath(ply)
    ply:SetHealth(0)
    ply:SetShield(0)
    if ply:GetPlaying() and ply:GetPlayable() and GetRound() != "Waiting" and GetRound() != "Scoring"then
        timer.Create("respawn"..ply:SteamID64(), 3, 1, function()
            if not IsValid(ply) then return end
            ply:Spawn()
            ply:ChatPrint("You will be protected for a few seconds until you rejoin the fight!")
            timer.Create("spawnprotection"..ply:SteamID64(), 5, 1, function()
                if not IsValid(ply) then return end
                ply:ChatPrint("Your spawn protection has ended!")
            end)
        end)
    else
        ply:Spectate(OBS_MODE_ROAMING)
    end
end

-----------------------------------------
--[[     PLAYER DAMAGE FUNCTIONS     ]]--
-----------------------------------------

-- Regenerates the player's shield until it hits the max or until the player takes damage again
local regenAmount = 0.5 -- How much is gained per regen
local function shieldRegen(ply, id)
    if IsValid(ply) and ply:Alive() and GetRound() ~= "Armageddon" then
        -- Raises the shield level
        if ply:GetShield() + regenAmount <= ply:GetMaxShield() then
            ply:SetShield(ply:GetShield() + regenAmount * ply:GetShieldRegen())
        -- Caps the shield level and stops regen
        else
            ply:SetShield(ply:GetMaxShield())
            ply:EmitSound("hl1/fvox/power_restored.wav")
            timer.Remove("shieldregen"..id)
        end
    else
        timer.Remove("shieldregen"..id) -- If the player is gone for any reason, we can use their id to remove the timer
    end
end

-- Begins the regen loop after the initial delay
local function shieldRegenStart(ply)
    if IsValid(ply) and GetRound() ~= "Armageddon" then
        timer.Create("shieldregen"..ply:SteamID64(), 0.15, 0, function()
            if IsValid(ply) then
                shieldRegen(ply, ply:SteamID64())
            end
        end)
    end
end

-- Victim callouts when taking damage
local minorHurts = {
    "vo/npc/barney/ba_pain01.wav",
    "vo/npc/barney/ba_pain02.wav",
    "vo/npc/barney/ba_pain04.wav",
    "vo/npc/male01/moan04.wav",
    "vo/npc/male01/pain01.wav",
    "vo/npc/male01/startle01.wav",
    "vo/npc/male01/startle02.wav",
    "vo/ravenholm/monk_pain05.wav",
    "vo/ravenholm/monk_pain08.wav",
}
local mediumHurts = {
    "vo/npc/barney/ba_pain03.wav",
    "vo/npc/barney/ba_pain05.wav",
    "vo/npc/barney/ba_pain08.wav",
    "vo/npc/male01/help01.wav",
    "vo/npc/male01/hitingut01.wav",
    "vo/npc/male01/imhurt01.wav",
    "vo/npc/male01/imhurt02.wav",
    "vo/npc/male01/pain02.wav",
    "vo/npc/male01/pain05.wav",
    "vo/ravenholm/monk_pain01.wav",
    "vo/ravenholm/monk_pain02.wav",
}
local majorHurts = {
    "vo/npc/barney/ba_pain10.wav",
    "vo/npc/barney/ba_wounded03.wav",
    "vo/npc/barney/ba_no02.wav",
    "vo/npc/male01/gordead_ans05.wav",
    "vo/npc/male01/gordead_ans06.wav",
    "vo/npc/male01/hitingut02.wav",
    "vo/npc/male01/pain03.wav",
    "vo/npc/male01/pain06.wav",
    "vo/ravenholm/monk_pain03.wav",
    "vo/ravenholm/monk_pain04.wav",
    "vo/ravenholm/monk_pain12.wav",
}

-- Handles damage taking
function GM:EntityTakeDamage(victim, dmg)
    if IsValid(victim) and victim:IsPlayer() then
         --Interrupts shield regen
        timer.Remove("shieldregenbuffer"..victim:SteamID64())
        timer.Remove("shieldregen"..victim:SteamID64())

        -- Gets relevant player info
        local shield = victim:GetShield()
        local baseDmg = dmg:GetDamage()
        local attacker = dmg:GetAttacker()

        -- Protects freshly respawned players
        if timer.Exists("spawnprotection"..victim:SteamID64()) then
            baseDmg = 0
        end

        -- Modify damage based on player stats
        baseDmg = baseDmg / victim:GetDefense()
        if IsValid(attacker) and attacker:IsPlayer() and not (attacker == victim) then
            -- Removes spawn protection if it exists
            if timer.Exists("spawnprotection"..attacker:SteamID64()) then
                timer.Remove("spawnprotection"..attacker:SteamID64())
                attacker:ChatPrint("You have ended your spawn protection!")
            end
            -- Rank advantage
            local weakTo = victim:GetWeakTo()
            local attRank = attacker:GetRank()
            if weakTo == attRank then
                baseDmg = baseDmg * 1.5
            end
            -- Attack bonus
            baseDmg = baseDmg * attacker:GetAttack()
            -- Get weapon for melee/ranged bonuses
            local attWep = attacker:GetActiveWeapon()
            local attWepName = ""
            if IsValid(attWep) and attWep:IsWeapon() then
                attWepName = attWep:GetPrintName()
            end
            -- Melee and ranged bonuses
            if dmg:GetDamageType() == DMG_SLASH then
                baseDmg = baseDmg * attacker:GetMeleeAttack()
            elseif dmg:GetDamageType() == DMG_BULLET then
                baseDmg = baseDmg * attacker:GetRangedAttack()
            end
            -- Points for doing the damage
            attacker:UpdateScore(0.1 * baseDmg)
        end

        -- Shield absorbs all the damage
        if shield >= baseDmg then
            victim:SetShield(shield - baseDmg)
            baseDmg = 0
        -- Shield breaks
        elseif shield > 0 then
            victim:SetShield(0)
            baseDmg = baseDmg - shield
            victim:EmitSound("hl1/fvox/armor_gone.wav")
        end

        -- Hurt sounds
        if not timer.Exists("hurtsoundcooldown"..victim:SteamID64()) and victim:Health() - baseDmg > 0 then
            timer.Create("hurtsoundcooldown"..victim:SteamID64(), 0.8, 1, function() end)
            if baseDmg < 1 then
                victim:EmitSound("weapons/physcannon/superphys_small_zap"..math.random(1, 4)..".wav", 100, 100, 0.75)
            elseif baseDmg <= 15 then
                victim:EmitSound(minorHurts[math.random(1, #minorHurts)])
            elseif baseDmg <= 40 then
                victim:EmitSound(mediumHurts[math.random(1, #mediumHurts)])
            else
                victim:EmitSound(majorHurts[math.random(1, #majorHurts)])
            end
        end

        dmg:SetDamage(baseDmg)

        if GetRound() ~= "Armageddon" then
            timer.Create("shieldregenbuffer"..victim:SteamID64(), 5, 1, function() shieldRegenStart(victim) end)
        end
    end
end

-- Disabled fall damage
function GM:GetFallDamage(ply, speed)
    return 0
end

-- Calculates fall damage and allows goomba stomps
function GM:OnPlayerHitGround(ply, inWater, onFloater, speed)
    if inWater or speed < 500 or not IsValid(ply) then return end
    local plyDmg = (speed - 500) / 3
    local ground = ply:GetGroundEntity()

    -- Goomba stomp damage
    if IsValid(ground) and ground:IsPlayer() then
        local damage = DamageInfo()
        damage:SetAttacker(ply)
        damage:SetInflictor(ply)
        damage:SetDamage(plyDmg)
        plyDmg = plyDmg / 2
        ground:TakeDamageInfo(damage)
    end

    -- Falling damage
    if not ply:GetBoss() then
        local damage = DamageInfo()
        damage:SetDamageType(DMG_FALL)
        damage:SetDamage(plyDmg)
        ply:TakeDamageInfo(damage)
    end

    ply:EmitSound("physics/body/body_medium_break2.wav")
end

-------------------------------------
--[[     OTHER PLAYER EVENTS     ]]--
-------------------------------------

-- Tells the player their consumable has expired
function consumeExpired(ply, itemId)
    net.Start("ConsumeExpired")
    net.WriteInt(itemId, 16)
    net.Send(ply)
end

-- Tells all players a given side message
function messageSide(arg)
    net.Start("MessageSide")
    net.WriteString(arg)
    net.Broadcast()
end

-- Handles the client request for crafting and responds with the results
net.Receive("CraftAttempt", function(len, ply)
    timer.Remove("trainstat"..ply:SteamID64())
    local catId = net.ReadInt(16)
    local itemId = net.ReadInt(16)
    local success = false
    local craftStatus = "Unknown error!"
    if IsValid(ply) and catId and itemId and not ply:GetCrafting() then
        ply:SetCrafting(true)
        local canCraft = false
        canCraft, craftStatus = ply:CanCraft(catId, itemId)
        if canCraft then
            success = ply:CraftItem(catId, itemId)
        end
        ply:SetCrafting(false)
    end

    -- Tells the client the status of the attempt
    net.Start("CraftResult")
    net.WriteBool(success)
    if success then
        net.WriteInt(catId, 16)
        net.WriteInt(itemId, 16)
    else
        net.WriteString(craftStatus)
    end
    net.Send(ply)
end)

-- Handles the client request for crafting
net.Receive("TrainAttempt", function(len, ply)
    local statId = net.ReadInt(16)
    local success = false
    local trainStatus = "Unknown error!"
    timer.Remove("trainstat"..ply:SteamID64())
    if IsValid(ply) and statId then
        success, trainStatus = ply:TrainStat(statId)
    end

    -- Tells the client the status of the attempt
    net.Start("TrainResult")
    net.WriteBool(success)
    if success then
        net.WriteInt(statId, 16)
    else
        net.WriteString(trainStatus)
    end
    net.Send(ply)
end)

-- Received when a player closes their training menu
net.Receive("TrainClosed", function(len, ply)
    timer.Remove("trainstat"..ply:SteamID64())
end)

-- Handles a player attempt to use a consumable
net.Receive("ConsumeAttempt", function(len, ply)
    local itemId = net.ReadInt(16)
    local success = false
    local consumeStatus = "Unknown error!"
    if IsValid(ply) and itemId then
        local canConsume = false
        canConsume, consumeStatus = ply:CanConsume(itemId)
        if canConsume then
            success = ply:ConsumeItem(itemId)
        end
    end

    -- Tells the client the status of the attempt
    net.Start("ConsumeResult")
    net.WriteBool(success)
    if success then
        net.WriteInt(itemId, 16)
    else
        net.WriteString(consumeStatus)
    end
    net.Send(ply)
end)

-- Handles a player attempt to use a boss ability
net.Receive("AbilityAttempt", function(len, ply)
    local key = net.ReadString()
    local success = false
    if IsValid(ply) and ply:GetBoss() and ply:GetPlaying() then
        if key == "Q" and not timer.Exists("abilitycooldown") then
            success = true
            timer.Create("abilitycooldown", 7, 1, function() end)
            -- Gravity Toss
            if GetRound() == "Crafting" then
                ply:EmitSound("ambient/levels/canals/windmill_wind_loop1.wav")
                timer.Simple(0.7, function()
                    if not IsValid(ply) then return end
                    ply:StopSound("ambient/levels/canals/windmill_wind_loop1.wav")
                end)
                for target, bool in pairs(BBB.playing) do
                    if IsValid(target) and target:Alive() and not target:GetBoss() then
                        target:ChatPrint("You've been hit by Gravity Toss!")
                        target:EmitSound("ambient/levels/canals/windmill_wind_loop1.wav")
                        target:SetVelocity(Vector(math.random(-400, 400), math.random(-400, 400), 400))
                        timer.Simple(0.7, function()
                            if not IsValid(target) then return end
                            target:StopSound("ambient/levels/canals/windmill_wind_loop1.wav")
                        end)
                    end
                end
            -- Gravity Pummel
            elseif GetRound() == "Battle" or GetRound() == "Armageddon" then
                ply:EmitSound("ambient/levels/canals/windmill_wind_loop1.wav")
                timer.Simple(0.7, function()
                    if not IsValid(ply) then return end
                    ply:StopSound("ambient/levels/canals/windmill_wind_loop1.wav")
                end)
                for target, bool in pairs(BBB.playing) do
                    if IsValid(target) and target:Alive() and not target:GetBoss() then
                        target:ChatPrint("You've been hit by Gravity Pummel!")
                        target:EmitSound("ambient/levels/canals/windmill_wind_loop1.wav")
                        target:SetVelocity(Vector(math.random(-150, 150), math.random(-150, 150), 600))
                        timer.Simple(0.5, function()
                            if not IsValid(target) then return end
                            target:StopSound("ambient/levels/canals/windmill_wind_loop1.wav")
                            target:SetVelocity(Vector(0, 0, -600))
                            target:EmitSound("npc/antlion_guard/shove1.wav")
                        end)
                    end
                end
            end
        elseif key == "E" and not timer.Exists("abilitycooldown") then
            success = true
            timer.Create("abilitycooldown", 7, 1, function() end)
            -- Slowness Beam
            if GetRound() == "Crafting" then
                for target, bool in pairs(BBB.playing) do
                    if IsValid(target) and target:Alive() and not target:GetBoss() then
                        target:ChatPrint("You've been slowed by the Slowness Beam!")
                        target:EmitSound("ambient/energy/spark5.wav")
                        target:SetWalkSpeed(target:GetWalkSpeed() - 200)
                        target:SetRunSpeed(target:GetRunSpeed() - 200)
                        timer.Simple(2, function()
                            if not IsValid(target) then return end
                            if GetRound() == "Crafting" or GetRound() == "Battle" or GetRound() == "Armageddon" then
                                target:SetWalkSpeed(target:GetWalkSpeed() + 200)
                                target:SetRunSpeed(target:GetRunSpeed() + 200)
                            end
                        end)
                    end
                end
            -- Death Beam
            elseif GetRound() == "Battle" or GetRound() == "Armageddon" then
                ply:EmitSound("ambient/energy/zap9.wav")
                for target, bool in pairs(BBB.playing) do
                    if IsValid(target) and target:Alive() and not target:GetBoss() then
                        target:ChatPrint("You've been struck by the Death Beam!")
                        target:EmitSound("ambient/energy/spark5.wav")
                        target:EmitSound("ambient/energy/zap8.wav")
                        target:EmitSound("player/pl_burnpain"..math.random(1, 3)..".wav")
                        target:SetWalkSpeed(target:GetWalkSpeed() - 5)
                        target:SetRunSpeed(target:GetRunSpeed() - 5)
                        local damage = DamageInfo()
                        damage:SetDamage(math.random(5, 25))
                        damage:SetDamageType(DMG_GENERIC)
                        damage:SetAttacker(ply)
                        target:TakeDamageInfo(damage)
                    end
                end
            end
        end
    end

    -- Tells the client the status of the attempt
    net.Start("AbilityResult")
    net.WriteString(key)
    net.WriteBool(success)
    net.Send(ply)
end)

-- Sends the requesting player info about each player's playing, boss, and score
net.Receive("ScoreboardRequest", function(len, requester)
    for k, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            net.Start("ScoreboardResult")
            net.WriteEntity(ply)
            net.WriteBool(ply:GetPlaying())
            net.WriteBool(ply:GetBoss())
            net.WriteInt(ply:GetScore(), 16)
            net.Send(requester)
        end
    end
end)