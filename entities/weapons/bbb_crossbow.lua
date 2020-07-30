if SERVER then
    AddCSLuaFile()
end

SWEP.Author             = "add___123"
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Crossbow"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/v_crossbow.mdl"
SWEP.WorldModel         = "models/weapons/w_crossbow.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 1
SWEP.SlotPos            = 3

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Recoil     = 0.5
SWEP.Primary.Damage     = 80
SWEP.Primary.Spread     = 0.005
SWEP.Primary.Delay      = 1.2
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

local shootSound = "weapons/crossbow/fire1.wav"
local wooshSound = "npc/manhack/mh_blade_snick1.wav"

function SWEP:Initialize()
    self:SetHoldType("crossbow")
end

function SWEP:PrimaryAttack()

    local ply = self:GetOwner()
    ply:EmitSound(shootSound, 100, 100, 0.5)
    ply:EmitSound(wooshSound, 100, 100, 0.5)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    ply:SetAnimation(PLAYER_ATTACK1)

    local mult = 1
    if ply:GetModel() == "models/player/shay_cormac.mdl" then
        mult = 1.2
    end
            
    local bullet = {
        Num         = self.Primary.NumShots,
        Src         = ply:GetShootPos(),
        Dir         = ply:GetAimVector(),
        Spread      = Vector(self.Primary.Spread, self.Primary.Spread, 0),
        Tracer      = 1,
        TracerName  = "AirboatGunTracer",
        Force       = 1000,
        Damage      = self.Primary.Damage * mult,
        AmmoType    = self.Primary.Ammo,
    }

    ply:FireBullets(bullet)
    ply:ViewPunch(Angle(-1 * self.Primary.Recoil, math.random(-0.2, 0.2) * self.Primary.Recoil, 0))
    self:ShootEffects()

    self:SendWeaponAnim(ACT_VM_RELOAD)
    ply:SetAnimation(PLAYER_RELOAD)
    self:EmitSound("weapons/crossbow/reload1.wav")

end

function SWEP:CanSecondaryAttack()
    return false
end