if SERVER then
    AddCSLuaFile()
    resource.AddFile("models/weapons/v_batty_t.mdl")
    resource.AddFile("models/weapons/w_batty_t.mdl")
    resource.AddFile("materials/models/weapons/v_models/bat/baseballbat.vmt")
    resource.AddFile("materials/models/weapons/v_models/bat/baseballbat_ref.vtf")
    resource.AddFile("materials/models/weapons/v_models/bat/me_bat_tex.vtf")
    resource.AddFile("materials/models/weapons/v_models/bat/me_bat_tex_norm.vmt")
    resource.AddFile("materials/models/weapons/w_models/bat/baseballbat.vmt")
    resource.AddFile("materials/models/weapons/w_models/bat/baseballbat_ref.vtf")
    resource.AddFile("materials/models/weapons/w_models/bat/me_bat_tex.vtf")
    resource.AddFile("materials/models/weapons/w_models/bat/me_bat_tex_norm.vmt")
end

SWEP.Author             = ""
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Slap Bat"
SWEP.Instructions       = "Whack someone to slap them away!"

SWEP.ViewModel          = "models/weapons/v_batty_t.mdl"
SWEP.WorldModel         = "models/weapons/w_batty_t.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 0
SWEP.SlotPos            = 1

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Damage     = 100
SWEP.Primary.Power      = 500
SWEP.Primary.Delay      = 0.8
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

local swingSound = Sound("Weapon_Crowbar.Single")
local hitSound = Sound("Weapon_Crowbar.Melee_Hit")
local stabSound = Sound("Weapon_Crowbar.Melee_Hit")

function SWEP:Initialize()
    self:SetHoldType("melee")
end

function SWEP:PrimaryAttack()

    local ply = self:GetOwner()

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    ply:SetAnimation(PLAYER_ATTACK1)

    ply:LagCompensation(true)

    local shootPos = ply:GetShootPos()
    local endShootPos = shootPos + ply:GetAimVector() * 100
    local tmin = Vector(1, 1, 1) * -10
    local tmax = Vector(1, 1, 1) * 10
    
    local trace = util.TraceLine({
        start = shootPos,
        endpos = endShootPos,
        filter = ply,
        mask = MASK_SHOT,
    })

    if not trace.Hit then
        trace = util.TraceHull({
            start = shootPos,
            endpos = endShootPos,
            filter = ply,
            mask = MASK_SHOT_HULL,
            mins = tmin,
            maxs = tmax,
        })
    end

    if trace.Hit then
        local target = trace.Entity
        self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
        if SERVER and IsValid(target) then
            if not target:IsPlayer() then
                local damage = DamageInfo()
                damage:SetDamage(self.Primary.Damage)
                damage:SetDamageType(DMG_SLASH)
                damage:SetAttacker(ply)
                target:TakeDamageInfo(damage)
            else
                ply:EmitSound(stabSound)
                local slapMult = 1
                -- Reduces the effectiveness of consecutive slaps
                if timer.Exists("slapcooldown4"..target:SteamID64()) then
                    slapMult = 0
                    ply:PrintColord(Color(200, 200, 200), "Your slap is at ", Color(255, 25, 25), "minimum power! ", Color(200, 200, 200), "Time to find a ", Color(255, 255, 255), "new target.")
                    timer.Remove("slapcooldown3"..target:SteamID64())
                    timer.Create("slapcooldown3"..target:SteamID64(), 5, 1, function() end)
                elseif timer.Exists("slapcooldown3"..target:SteamID64()) then
                    slapMult = 0.25
                    ply:PrintColord(Color(200, 200, 200), "Your slap is feeling ", Color(255, 25, 25), "very weak! ", Color(200, 200, 200), "Try hitting ", Color(255, 255, 255), "someone else.")
                    timer.Create("slapcooldown4"..target:SteamID64(), 5, 1, function() end)
                elseif timer.Exists("slapcooldown2"..target:SteamID64()) then
                    slapMult = 0.5
                    ply:PrintColord(Color(200, 200, 200), "Your slap is getting ", Color(255, 25, 25), "weaker! ", Color(200, 200, 200), "Maybe hit ", Color(255, 255, 255), "someone else.")
                    timer.Create("slapcooldown3"..target:SteamID64(), 5, 1, function() end)
                elseif timer.Exists("slapcooldown1"..target:SteamID64()) then
                    slapMult = 0.75
                    ply:PrintColord(Color(200, 200, 200), "Your slap feels ", Color(255, 25, 25), "weaker ", Color(200, 200, 200), "as you hit ", Color(255, 255, 255), target:Name(), Color(200, 200, 200), " again!")
                    timer.Create("slapcooldown2"..target:SteamID64(), 5, 1, function() end)
                else
                    ply:UpdateScore(5, "You got 5 points for slapping "..target:Name().."!")
                    timer.Create("slapcooldown1"..target:SteamID64(), 5, 1, function() end)
                end
                local slapDirection = target:GetPos() - ply:GetPos()
                local slapTable = slapDirection:ToTable()
                slapDirection:SetUnpacked(slapTable[1], slapTable[2], 0)
                slapDirection = slapMult * self.Primary.Power * (slapDirection / slapDirection:Length()) + Vector(0, 0, self.Primary.Power / 2)
                target:SetVelocity(slapDirection)
            end
        elseif SERVER then 
            ply:EmitSound(hitSound)
        end
    else
        self.Weapon:SendWeaponAnim(ACT_VM_HITCENTER)
        if SERVER then ply:EmitSound(swingSound) end
    end

    ply:LagCompensation(false)

end

function SWEP:CanSecondaryAttack()
    return false
end