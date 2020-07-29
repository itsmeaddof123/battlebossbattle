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
SWEP.PrintName          = "Smack Bat"
SWEP.Instructions       = "Whack someone to send them flying!"

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
SWEP.Primary.Damage     = 60
SWEP.Primary.Power      = 750
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
            local damage = DamageInfo()
            damage:SetDamage(self.Primary.Damage)
            damage:SetDamageType(DMG_SLASH)
            damage:SetAttacker(ply)
            target:TakeDamageInfo(damage)
            ply:EmitSound(stabSound)

            if target:IsPlayer() then
                local slapDirection = target:GetPos() - ply:GetPos()
                local slapTable = slapDirection:ToTable()
                slapDirection:SetUnpacked(slapTable[1], slapTable[2], 0)
                slapDirection = self.Primary.Power * (slapDirection / slapDirection:Length()) + Vector(0, 0, self.Primary.Power / 1.75)
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