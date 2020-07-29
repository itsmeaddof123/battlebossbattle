if SERVER then
    AddCSLuaFile()
end

SWEP.Author             = "add___123"
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Energy Burster"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/c_physcannon.mdl"
SWEP.WorldModel         = "models/weapons/w_Physics.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 1
SWEP.SlotPos            = 5

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = 10
SWEP.Primary.DefaultClip= 10
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Recoil     = 1
SWEP.Primary.Damage     = 100
SWEP.Primary.Spread     = 0.01
SWEP.Primary.Delay      = 0.5
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

local shootSounds = {"npc/combine_gunship/attack_stop2.wav", "npc/env_headcrabcanister/incoming.wav"}

function SWEP:Initialize()
    self:SetHoldType("revolver")
end

function SWEP:PrimaryAttack()

    local ply = self:GetOwner()
    for k, v in ipairs(shootSounds) do
        ply:EmitSound(v, 100, 100, 0.25)
    end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local bullet = {
        Num         = self.Primary.NumShots,
        Src         = ply:GetShootPos(),
        Dir         = ply:GetAimVector(),
        Spread      = Vector(self.Primary.Spread, self.Primary.Spread, 0),
        Tracer      = 1,
        TracerName  = "ToolTracer",
        Force       = 1000,
        Damage      = self.Primary.Damage,
        AmmoType    = self.Primary.Ammo,
    }

    ply:FireBullets(bullet)

    ply:ViewPunch(Angle(-1 * self.Primary.Recoil, math.random(-0.2, 0.2) * self.Primary.Recoil, 0))
    self:ShootEffects()

end

function SWEP:CanSecondaryAttack()
    return false
end