local plyMeta = FindMetaTable("Player")

------------------------------------------
--[[     PLAYER RESET, INITS, ETC     ]]--
------------------------------------------

-- This does reset stuff that overlaps between player init and round end
function plyMeta:FullReset()
    for i = 1, 6 do
        self:UpdateInv("mats", i, 0)
        self:UpdateInv("gear", i, 0)
        self:UpdateInv("consumable", i, 0)
        self:UpdateStat(i, 0)
    end
    self:SetPlayed(false)
    self:SetPlaying(false)
    self:SetLives(0)
    self:SetCrafting(false)
    self:SetMdl()
    self:SetRank("Classless")
    self:SetShield(0)
    self:SetMaxShield(100)
    self:SetMaxHP(100)
    self:SetJumpPower(200)
    self:SetWalkSpeed(300)
    self:SetRunSpeed(300)
    self:SetRangedAttack(1)
    self:SetMeleeAttack(1)
    self:SetAttack(1)
    self:SetShieldRegen(1)
    self:SetDefense(1)
    self:SetWeakTo("")
    self:SetScore(0)
    self:SetFrags(0)
    self:AllowFlashlight(true)
end

-- This does player init stuff that round end doesn't need to reset
function plyMeta:InitReset()
    net.Start("UpdateRound")
    net.WriteString(GetRound())
    net.WriteInt(GetEndTime(), 16)
    net.Send(self)
    self:SetBoss(false)
    self:SetCrouchedWalkSpeed(0.6)
    self:SetPlayable(true)
    self:SetPity(1)
    self:SetInitialized(true)
    self:SetDefaultModel(0)
end

-- This forces players to spawn for preparing and for crafting
function plyMeta:SpawnReset()
    if (GetRound() == "Preparing" and self:GetPlayable()) or ((GetRound() == "Crafting" or GetRound() == "Battle" or GetRound() == "Armageddon") and self:GetPlayable() and self:GetPlaying()) then
        self:UnSpectate()
        self:FullStrip()
        self:GiveTools()
        self:SetHealth(self:GetMaxHealth())
        self:SetShield(self:GetMaxShield())
    else
        self:KillSilent()
        return
    end
end

-- Fully strips the player
function plyMeta:FullStrip()
    self:StripWeapons()
    self:StripAmmo()
end

-- Weapon names for distribution
local battleMelee = {"bbb_enchantedknife", "bbb_kukriblade", "bbb_huntingknife", "bbb_combatknife", "bbb_kitchenknife", "bbb_bonecleaver"}
local battleRanged = {"bbb_magicwand", "bbb_speedsac", "bbb_crossbow", "bbb_lightsmg", "bbb_heavyblaster", "bbb_medkit"}

-- Gives the player their respective tools based on the round and their role and equipment
function plyMeta:GiveTools()
    if not self then return end
    if self:GetBoss() then
        if GetRound() == "Crafting" then
            self:Give("bbb_slapbat")
            self:Give("bbb_energyzapper")
        elseif GetRound() == "Battle" or GetRound() == "Armageddon" then
            self:Give("bbb_smackbat")
            self:Give("bbb_energyburster")
        end
    else
        if GetRound() == "Crafting" then
            self:Give("bbb_craftingfists")
        elseif GetRound() == "Battle" or GetRound() == "Armageddon" then
            -- Melee weapons
            if self:GetRank() == "Collector" then
                self:Give("bbb_plasticknife")
            elseif battleMelee[self.gear[1]] then
                self:Give(battleMelee[self.gear[1]])
            else
                self:Give("bbb_battlefists")
            end
            -- Ranged weapons
            if battleRanged[self.gear[2]] then
                self:Give(battleRanged[self.gear[2]])
            end
        end
    end
end

local function medicRegen(ply)
    if (GetRound() == "Battle" or GetRound() == "Armageddon") and ply:GetPlaying() then
        if ply:Alive() then
            ply:SetHealth(math.min(ply:Health() + 5, ply:GetMaxHealth()))
        end
    else
        timer.Remove("medicregen"..ply:SteamID64())
    end
end

-- Changes player stats based on mark, equip, rank, and training
function plyMeta:ChangeStats()
    -- Starts by getting each relevant stat
    local mark = self.gear[4]
    local equip = self.gear[5]
    local rank = self:GetRank()

    -- Changes stats based on mark
    if mark == 1 then
        self:SetRangedAttack(self:GetRangedAttack() + 0.5)
        self:SetMaxShield(self:GetMaxShield() - 25)
        self:SetShield(self:GetMaxShield())
    elseif mark == 2 then
        self:SetMeleeAttack(self:GetMeleeAttack() + 0.5)
        self:SetRangedAttack(self:GetRangedAttack() - 0.25)
    elseif mark == 3 then
        self:SetWalkSpeed(self:GetWalkSpeed() + 75)
        self:SetRunSpeed(self:GetRunSpeed() + 75)
        self:SetJumpPower(self:GetJumpPower() + 100)
        self:SetMaxHP(self:GetMaxHP() - 25)
    elseif mark == 4 then
        self:SetRangedAttack(self:GetRangedAttack() + 0.5)
        self:SetMeleeAttack(self:GetMeleeAttack() - 0.5)
    elseif mark == 5 then
        self:SetAttack(self:GetAttack() + 0.5)
        self:SetWalkSpeed(self:GetWalkSpeed() - 50)
        self:SetRunSpeed(self:GetRunSpeed() - 50)
    elseif mark == 6 then
        self:SetShieldRegen(self:GetShieldRegen() + 0.3)
        self:SetAttack(self:GetAttack() - 0.2)
    end

    -- Changes stats based on equip
    if equip == 1 then
        self:SetRangedAttack(self:GetRangedAttack() + 0.5)
    elseif equip == 2 then
        self:SetDefense(self:GetDefense() + 0.25)
    elseif equip == 3 then
        self:SetWalkSpeed(self:GetWalkSpeed() + 50)
        self:SetRunSpeed(self:GetRunSpeed() + 50)
    elseif equip == 4 then
        self:SetMaxShield(self:GetMaxShield() + 50)
        self:SetShield(self:GetMaxShield())
    elseif equip == 5 then
        self:SetMeleeAttack(self:GetMeleeAttack() + 0.5)
    elseif equip == 6 then
        self:SetMaxHP(self:GetMaxHP() + 50)
    end

    -- Changes stats based on rank
    if rank == "Warrior" then
        self:SetAttack(self:GetAttack() + 0.25)
    elseif rank == "Rogue" then
        self:SetWalkSpeed(self:GetWalkSpeed() + 75)
        self:SetRunSpeed(self:GetRunSpeed() + 75)
        self:SetDefense(self:GetDefense() + 0.1)
    elseif rank == "Medic" then
        timer.Create("medicregen"..self:SteamID64(), 1, 0, function() medicRegen(self) end)
        self:SetWalkSpeed(self:GetWalkSpeed() + 25)
        self:SetRunSpeed(self:GetRunSpeed() + 25)
    elseif rank == "Wild Card" then
        self:SetAttack(self:GetAttack() + 0.5)
        self:SetDefense(self:GetDefense() + 0.5)
    elseif rank == "Overtrained" then
        self:SetAttack(self:GetAttack() + 0.5)
        self:SetDefense(self:GetDefense() + 0.5)
        self:SetWalkSpeed(self:GetWalkSpeed() + 125)
        self:SetRunSpeed(self:GetRunSpeed() + 125)
        self:SetJumpPower(self:GetJumpPower() + 125)
        self:SetMaxHP(self:GetMaxHP() + 50)
        self:SetMaxShield(self:GetMaxShield() + 50)
    elseif rank == "Collector" then
        self:SetAttack(self:GetAttack() + 1)
        self:SetMeleeAttack(self:GetMeleeAttack() + 1)
        self:SetWalkSpeed(self:GetWalkSpeed() + 75)
        self:SetRunSpeed(self:GetRunSpeed() + 75)
    end

    -- Change stats based on training
    self:SetMaxHP(self:GetMaxHP() + self.stats[1])
    self:SetMaxShield(self:GetMaxShield() + self.stats[2])
    self:SetRangedAttack(self:GetRangedAttack() + 0.01 * self.stats[3])
    self:SetMeleeAttack(self:GetMeleeAttack() + 0.01 * self.stats[4])
    self:SetDefense(self:GetDefense() + 0.01 * self.stats[5])
    self:SetWalkSpeed(self:GetWalkSpeed() + self.stats[6])
    self:SetRunSpeed(self:GetRunSpeed() + self.stats[6])
    self:SetJumpPower(self:GetJumpPower() + self.stats[6])

    -- Makes sure players have updated health and shield
    self:SetShield(self:GetMaxShield())
    self:SetHealth(self:GetMaxHealth())
end

--------------------------------------------
--[[     IMPORTANT PLAYER FUNCTIONS     ]]--
--------------------------------------------

-- Decides the player's ability class and bonus points
function plyMeta:ChooseRank()
    local ranks = {"Wizard", "Warrior", "Rogue", "Infantry", "Berserker", "Medic"} -- Acts as a rudimentary switch case
    local uniqueSlots = {false, false, false, false, false, false}
    local uniqueGear = 0
    local totalGear = 0
    local potentialRank = 0

    if self:GetBoss() then self:SetRank("Battle Boss") return end

    for k, v in ipairs(self.gear) do
        if v ~= 0 then
            -- If a given rank's item hasn't been found yet, then this item is from a unique rank
            if not uniqueSlots[v] then
                uniqueSlots[v] = true
                uniqueGear = uniqueGear + 1
            end
            totalGear = totalGear + 1
            -- If this is the first iteration, give a new potential
            if potentialRank == 0 then 
                potentialRank = v
            -- If not, check to see if v is of a different rank
            elseif potentialRank ~= v then 
                potentialRank = -1
            end
        end
    end

    -- 5 gear of all the same rank
    if totalGear == 5 and potentialRank > 0 then
        self:SetRank(ranks[potentialRank])
        self:UpdateScore(50, "You got 50 points for achieving the rank of "..self.rank)
        return
    end

    -- 5 gear of all different ranks
    if uniqueGear == 5 then
        self:SetRank("Wild Card")
        self:SetMdl("models/player/monk.mdl")
        self:UpdateScore(75, "You got 75 points for achieving the secret rank of Wild Card!")
        return
    end
    if totalGear > 0 then return end

    -- At this point, we can look for the secret ranks
    local consumables = 0
    for k, v in ipairs(self.consumable) do
        consumables = consumables + v
    end
    if consumables == 0 then
        local trained = 0
        for k, v in ipairs(self.stats) do
            trained = trained + v
        end
        -- No crafting, lots of training
        if trained >= 100 then
            self:SetRank("Overtrained") 
            self:SetMdl("models/player/charple.mdl")
            self:UpdateScore(75, "You got 75 points for achieving the secret rank of Overtrained!")
        -- No crafting, no training, lots of materials
        elseif trained == 0 then
            local collected = 0
            for k, v in ipairs(self.mats) do
                collected = collected + v
            end
            print(self:Name().." collected "..tostring(collected).." materials!")
            if collected >= 50 then
                self:SetRank("Collector")
                self:SetMdl("models/player/gman_high.mdl")
                self:UpdateScore(150, "You got 75 points for achieving the secret rank of Collector!")
            end
        end
    -- No gear, 10+ consumables
    elseif consumables >= 10 then
        self:SetRank("Master Chemist")
        self:SetMdl("models/player/combine_super_soldier.mdl")
        self:UpdateScore(75, "You got 75 points for achieving the secret rank of Master Chemist!")
    end
end

---------------------------------------------------------------------------
--[[    PLAYER VARIABLE GETS AND SETS THAT EXIST ON THE SERVER ONLY    ]]--
---------------------------------------------------------------------------

-- Tracks whether a player is willing to play 
function plyMeta:GetPlayable() return self.playable end
function plyMeta:SetPlayable(arg) self.playable = arg end

-- Prevents players from sending one crafting request before another is over
function plyMeta:GetCrafting() return self.crafting end
function plyMeta:SetCrafting(arg) self.crafting = arg end

-- Track's the player's ranged attack multiplier
function plyMeta:GetRangedAttack() return self.rangedAttack end
function plyMeta:SetRangedAttack(arg) self.rangedAttack = arg end

-- Track's the player's melee attack multiplier
function plyMeta:GetMeleeAttack() return self.meleeAttack end
function plyMeta:SetMeleeAttack(arg) self.meleeAttack = arg end

-- Track's the player's overall attack multiplier
function plyMeta:GetAttack() return self.attack end
function plyMeta:SetAttack(arg) self.attack = arg end

-- Track's the player's shield regen multiplier
function plyMeta:GetShieldRegen() return self.shieldRegen end
function plyMeta:SetShieldRegen(arg) self.shieldRegen = arg end

-- Track's the player's overall defense multiplier
function plyMeta:GetDefense() return self.defense end
function plyMeta:SetDefense(arg) self.defense = arg end

-- Tracks who the player is weak to
function plyMeta:GetWeakTo() return self.weakTo end
function plyMeta:SetWeakTo(arg) self.weakTo = arg end

-- Track's the player's pity multiplier, which help them reach a boss round
function plyMeta:GetPity() return self.pity end
function plyMeta:SetPity(arg) self.pity = arg end

-- Track's whether the player has been fully initialized or not
function plyMeta:GetInitialized() return self.initialized end
function plyMeta:SetInitialized(arg) self.initialized = arg end

-- Tracks the number of lives a player has
function plyMeta:GetLives() return self.lives end
function plyMeta:SetLives(arg) self.lives = arg end

-- Tracks whether a player has participated at all in the current round
function plyMeta:GetPlayed() return self.played end
function plyMeta:SetPlayed(arg) self.played = arg end

-- Random default player models
local playerModels = {
"models/player/Group01/male_01.mdl",
"models/player/Group01/male_02.mdl",
"models/player/Group01/male_03.mdl",
"models/player/Group01/male_04.mdl",
"models/player/Group01/male_05.mdl",
"models/player/Group01/male_06.mdl",
"models/player/Group01/male_07.mdl",
"models/player/Group01/male_08.mdl",
"models/player/Group03/male_01.mdl",
"models/player/Group03/male_02.mdl",
"models/player/Group03/male_03.mdl",
"models/player/Group03/male_04.mdl",
"models/player/Group03/male_05.mdl",
"models/player/Group03/male_06.mdl",
"models/player/Group03/male_07.mdl",
"models/player/Group03/male_08.mdl",}

-- Gets the player's default model
function plyMeta:GetDefaultModel()
    if not self.defaultModel then return playerModels[math.random(#playerModels)] end
    if self.defaultModel >= 1 and self.defaultModel <= #playerModels then
        return self.defaultModel
    else
        return playerModels[math.random(#playerModels)]
    end
end
function plyMeta:SetDefaultModel(arg) self.defaultModel = arg end

-- Tracks the model that the player should have when spawning
function plyMeta:GetMdl() return self.mdl end
function plyMeta:SetMdl(arg)
    if arg then 
        self.mdl = arg
        self:SetModel(arg)
    else
        self.mdl = self:GetDefaultModel()
        self:SetModel(self:GetDefaultModel())
    end
end

------------------------------------------------------------------
--[[     PLAYER VARIABLE SETS THAT UPDATE A SINGLE CLIENT     ]]--
------------------------------------------------------------------

local function updateInfoCache(key, arg, ply)
    net.Start("UpdateInfoCache")
    net.WriteString(key)
    if isbool(arg) then
        net.WriteString("boolean")
        net.WriteBool(arg)
    elseif isnumber(arg) then
        net.WriteString("number")
        net.WriteInt(arg, 16)
    elseif isstring(arg) then
        net.WriteString("string")
        net.WriteString(arg)
    end
    net.Send(ply)
end

-- Tracks the player's ability class. Called rank in the code because "Class" obviously won't work
function plyMeta:GetRank() return self.rank end
function plyMeta:SetRank(arg)
    self.rank = arg
    updateInfoCache("rank", arg, self)
end

-- Tracks the player's shield
function plyMeta:GetShield() return self.shield end
function plyMeta:SetShield(arg)
    self.shield = arg
    updateInfoCache("shield", arg, self)
end

-- Tracks the player's max shield
function plyMeta:GetMaxShield() return self.maxShield end
function plyMeta:SetMaxShield(arg)
    self.maxShield = arg
    updateInfoCache("maxShield", arg, self)
end

-- Tracks the player's max hp (Needed because spawning resets max health)
function plyMeta:GetMaxHP() return self.maxHP end
function plyMeta:SetMaxHP(arg)
    self:SetMaxHealth(arg)
    self.maxHP = arg
    updateInfoCache("maxHP", arg, self)
end

-- Updates the player inv and informs the player
function plyMeta:GiveMat(index)
    if not self.mats then
        self.mats = {0, 0, 0, 0, 0, 0}
    end
    self:UpdateInv("mats", index, self.mats[index] + 1)
end
function plyMeta:GetInv(itemType, index) return self[itemType][index] end
function plyMeta:UpdateInv(itemType, index, info)
    if not self[itemType] then
        self[itemType] = {0, 0, 0, 0, 0, 0}
    end

    self[itemType][index] = info

    net.Start("UpdateInv")
    net.WriteString(itemType)
    net.WriteInt(index, 16)
    net.WriteInt(info, 16)
    net.Send(self)

    return true
end

-- Updates the player stat and informs the player
function plyMeta:GetStat(statId) return self.stats[statId] end
function plyMeta:UpdateStat(statId, info)
    if not self.stats then
        self.stats = {0, 0, 0, 0, 0,0}
    end
    self.stats[statId] = info

    net.Start("UpdateStat")
    net.WriteInt(statId, 16)
    net.WriteDouble(info)
    net.Send(self)
end

-----------------------------------------------------------------------------
--[[     PLAYER VARIABLE GETS AND SETS THAT UPDATE SCOREBOARD CACHES     ]]--
-----------------------------------------------------------------------------

local function updateScoreboard(key, arg, ply)
    net.Start("UpdateScoreboard")
    net.WriteString(key)
    if isbool(arg) then
        net.WriteString("boolean")
        net.WriteBool(arg)
    elseif isnumber(arg) then
        net.WriteString("number")
        net.WriteInt(arg, 16)
    end
    net.WriteEntity(ply)
    net.Broadcast()
end

-- Tracks whether a player is still playing in the current round
function plyMeta:GetPlaying() return self.playing end
function plyMeta:SetPlaying(arg)
    self.playing = arg
    updateScoreboard("playing", arg, self)
end

-- Tracks whether the player is the boss or not
function plyMeta:GetBoss() return self.boss end
function plyMeta:SetBoss(arg)
    self.boss = arg
    if arg then
        self:SetPity(0.6)
    end
    updateScoreboard("boss", arg, self)
end

-- Track's the player's score
function plyMeta:GetScore() return self.score end
function plyMeta:UpdateScore(arg, msg)
    self.score = self.score + arg
    updateScoreboard("score", math.floor(self.score), self)
    if msg and msg != "" then
        net.Start("ScoreMessage")
        net.WriteString(msg)
        net.Send(self)
    end
end
function plyMeta:SetScore(arg)
    self.score = arg
    updateScoreboard("score", math.floor(arg), self)
end

---------------------------------------------
--[[     SERVERSIDE DEATH SPECTATING     ]]--
---------------------------------------------

-- Fully spectates the player all at once
local oldSpec = plyMeta.Spectate
function plyMeta:Spectate(specType)
    oldSpec(self, specType)
    self:SetNoTarget(true)
    if type == OBS_MODE_ROAMING then
        self:SetMoveType(MOVETYPE_NOCLIP)
    end
end

-- Takes the player out of spectator mode
local oldUnSpec = plyMeta.UnSpectate
function plyMeta:UnSpectate()
    oldUnSpec(self)
    self:SetNoTarget(false)
end

------------------------------------------
--[[     CLIENT REQUEST FUNCTIONS     ]]--
------------------------------------------

-- Verifies that catId and itemId are valid, and that the player has the space and materials for it
function plyMeta:CanCraft(catId, itemId)
    if self:GetBoss() then return false, "Wrong role!" end
    if not self:GetPlaying() then return false, "Not playing!" end
    if GetRound() ~= "Crafting" then return false, "Wrong round!" end
    if catId <= 0 or catId >= 7 then return false, "Invalid item!" end
    if itemId <= 0 or itemId >= 7 then return false, "Invalid item!" end
    if catId < 6 and self.gear[catId] ~= 0 then return false, "Slot filled!" end

    local itemTable = craftingTable.items[catId][itemId]

    for k, v in ipairs(itemTable.cost) do
        if self.mats[k] < v then return false, "Missing materials!" end
    end

    return true, "Success!"
end

-- Charges the player for the item then puts it into their inventory
function plyMeta:CraftItem(catId, itemId)
    -- Points for crafting an item
    self:UpdateScore(5)
    local itemTable = craftingTable.items[catId][itemId]
    for k, v in ipairs(itemTable.cost) do
        self:UpdateInv("mats", k, self:GetInv("mats", k) - v)
    end
    if catId == 3 then
        if self and IsValid(self) then
            self:SetMdl(itemTable.mdl)
            self:SetWeakTo(itemTable.weak)
        end
    end
    if catId == 6 then
        return self:UpdateInv("consumable", itemId, self.consumable[itemId] + 1)
    else
        return self:UpdateInv("gear", catId, itemId)
    end
end

-- Part of a two-function recursion 
local function trainStat(ply, statId)
    if not IsValid(ply) then return end
    ply:UpdateStat(statId, ply:GetStat(statId) + 0.1)
    ply:UpdateScore(0.1)
    timer.Remove("trainstat"..ply:SteamID64())
    ply:TrainStat(statId)
end

function plyMeta:TrainStat(statId)
    if self:GetBoss() then return false, "Wrong role!" end
    if not self:GetPlaying() then return false, "Not playing!" end
    if GetRound() ~= "Crafting" then return false, "Wrong round!" end
    if statId <= 0 or statId >= 7 then return false, "Invalid item!" end
    local statLevel = self:GetStat(statId)
    if statLevel >= 50 then return false, "Stat fully trained!" end

    -- This timer causes a two-function recursion that ends once any of the above conditions are met
    local id = self:SteamID64()
    timer.Create("trainstat"..id, 0.1, 1, function()
        if not IsValid(self) then 
            timer.Remove("trainstat"..id)
            return
        end
        trainStat(self, statId)
    end)
    return true, "Success!"
end

function plyMeta:CanConsume(itemId)
    if self:GetBoss() then return false, "Wrong role!" end
    if not self:GetPlaying() or not self:Alive() then return false, "Not alive!" end
    if not (GetRound() == "Battle" or GetRound() == "Armageddon") then return false, "Wrong round!" end
    if itemId <= 0 or itemId >= 7 then return false, "Invalid item!" end
    if not self.consumable[itemId] or self.consumable[itemId] <= 0 then return false, "You don't have that!" end
    if timer.Exists("consume"..tostring(itemId)..self:SteamID64()) then return false, "Last consumable still in effect!" end

    return true, "Success!"
end

function plyMeta:ConsumeItem(itemId)
    local mult = 1
    if self:GetRank() == "Master Chemist" then
        mult = 3
    end
    -- Points for using a consumable
    self:UpdateScore(5 * mult, "You got "..tostring(5 * mult).." points for using that item!")
    self:UpdateInv("consumable", itemId, self.consumable[itemId] - 1)
    if itemId == 1 then
        if self:Health() + 50 * mult >= self:GetMaxHealth() then
            self:SetHealth(self:GetMaxHealth())
        else
            self:SetHealth(self:Health() + 50 * mult)
        end
    elseif itemId == 2 then
        self:SetDefense(self:GetDefense() + 0.25 * mult)
        timer.Create("consume"..tostring(itemId)..self:SteamID64(), 30, 1, function()
            if not IsValid(self) then return end
            if GetRound() == "Battle" or GetRound() == "Armageddon" then
                self:SetDefense(self:GetDefense() - 0.25 * mult)
                consumeExpired(self, itemId)
            end
        end)
    elseif itemId == 3 then
        if self:GetShield() + 50 * mult >= self:GetMaxShield() then
            self:SetShield(self:GetMaxShield())
        else
            self:SetShield(self:GetShield() + 50 * mult)
        end
    elseif itemId == 4 then
        self:SetShieldRegen(self:GetShieldRegen() + 0.25 * mult)
        timer.Create("consume"..tostring(itemId)..self:SteamID64(), 30, 1, function() 
            if not IsValid(self) then return end
            if GetRound() == "Battle" or GetRound() == "Armageddon" then
                self:SetShieldRegen(self:GetShieldRegen() - 0.25 * mult)
                consumeExpired(self, itemId)
            end
        end)
    elseif itemId == 5 then
        self:SetAttack(self:GetAttack() + 0.5 * mult)
        timer.Create("consume"..tostring(itemId)..self:SteamID64(), 30, 1, function() 
            if not IsValid(self) then return end
            if GetRound() == "Battle" or GetRound() == "Armageddon" then
                self:SetAttack(self:GetAttack() - 0.5 * mult)
                consumeExpired(self, itemId)
            end
        end)
    elseif itemId == 6 then
        self:SetWalkSpeed(self:GetWalkSpeed() + 75 * mult)
        self:SetRunSpeed(self:GetRunSpeed() + 75 * mult)
        self:SetJumpPower(self:GetJumpPower() + 75 * mult)
        timer.Create("consume"..tostring(itemId)..self:SteamID64(), 30, 1, function() 
            if not IsValid(self) then return end
            if GetRound() == "Battle" or GetRound() == "Armageddon" then
                consumeExpired(self, itemId)
                self:SetWalkSpeed(self:GetWalkSpeed() - 75 * mult)
                self:SetRunSpeed(self:GetRunSpeed() - 75 * mult)
                self:SetJumpPower(self:GetJumpPower() - 75 * mult)
            end
        end)
    end
    return true
end