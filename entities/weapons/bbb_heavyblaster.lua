if SERVER then
    AddCSLuaFile()
end

SWEP.Author             = "add___123"
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Heavy Blaster"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/c_irifle.mdl"
SWEP.WorldModel         = "models/weapons/w_irifle.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 1
SWEP.SlotPos            = 5

SWEP.DrawAmmo           = true
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = 10
SWEP.Primary.DefaultClip= 10
SWEP.Primary.Ammo       = "AR2"
SWEP.Primary.Recoil     = 0.75
SWEP.Primary.Damage     = 100
SWEP.Primary.Spread     = 0.01
SWEP.Primary.Delay      = 0.75
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

local shootSound = "weapons/ar2/npc_ar2_altfire.wav"

function SWEP:Initialize()
    self:SetHoldType("ar2")
end

function SWEP:PrimaryAttack()

    if self:CanPrimaryAttack() then
        local ply = self:GetOwner()
        ply:EmitSound(shootSound, 100, 100, 0.5)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        ply:SetAnimation(PLAYER_ATTACK1)

        local mult = 1
        if ply:GetModel() == "models/player/combine_soldier_prisonguard.mdl" then
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
        self:TakePrimaryAmmo(1)

        ply:ViewPunch(Angle(-1 * self.Primary.Recoil, math.random(-0.2, 0.2) * self.Primary.Recoil, 0))
        self:ShootEffects()
    else
        self:Reload()
    end


end

function SWEP:Reload()
	self:SetNextPrimaryFire(CurTime() + 1.6)
	self:DefaultReload( ACT_VM_RELOAD )
	self.Owner:SetAnimation(PLAYER_RELOAD)
	self:EmitSound("weapons/smg1/smg1_reload.wav")
    timer.Simple(1.6, function()
        local ply = self:GetOwner()
        if IsValid(ply) then
            ply:SetAmmo(self.Primary.ClipSize, self.Primary.Ammo)
        end
    end)
end

function SWEP:CanSecondaryAttack()
    return false
end

function SWEP:Deploy()
    local ply = self:GetOwner()
    ply:SetAmmo(self.Primary.ClipSize, self.Primary.Ammo)
end