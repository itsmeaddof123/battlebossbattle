if SERVER then
    AddCSLuaFile()
end

SWEP.Author             = "add___123"
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Magic Wand"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/c_stunstick.mdl"
SWEP.WorldModel         = "models/weapons/w_stunbaton.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 1
SWEP.SlotPos            = 1

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Recoil     = 1
SWEP.Primary.Damage     = 75
SWEP.Primary.Spread     = 0.005
SWEP.Primary.Delay      = 0.65
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

function SWEP:Initialize()
    self:SetHoldType("melee")
end

function SWEP:PrimaryAttack()

    local ply = self:GetOwner()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    ply:SetAnimation(PLAYER_ATTACK1)

    ply:EmitSound("ambient/levels/citadel/weapon_disintegrate"..math.random(1, 4)..".wav")

    local mult = 1
    if ply:GetModel() == "models/vinrax/player/gandalf.mdl" then
        mult = 1.2
    end
            
    local bullet = {
        Num         = self.Primary.NumShots,
        Src         = ply:GetShootPos(),
        Dir         = ply:GetAimVector(),
        Spread      = Vector(self.Primary.Spread, self.Primary.Spread, 0),
        Tracer      = 1,
        TracerName  = "AirboatGunHeavyTracer",
        Force       = 1000,
        Damage      = self.Primary.Damage * mult,
        AmmoType    = self.Primary.Ammo,
    }
    ply:FireBullets(bullet)

    self:SendWeaponAnim(ACT_VM_MISSCENTER)
    ply:ViewPunch(Angle(-1 * self.Primary.Recoil, math.random(-0.2, 0.2) * self.Primary.Recoil, 0))
    self:ShootEffects()

end

function SWEP:CanSecondaryAttack()
    return false
end