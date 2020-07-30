if SERVER then
    AddCSLuaFile()
end

SWEP.Author             = "add___123"
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Light SMG"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/c_smg1.mdl"
SWEP.WorldModel         = "models/weapons/w_smg1.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 1
SWEP.SlotPos            = 4

SWEP.DrawAmmo           = true
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = 30
SWEP.Primary.DefaultClip= 30
SWEP.Primary.Ammo       = "SMG1"
SWEP.Primary.Recoil     = 0.25
SWEP.Primary.Damage     = 15
SWEP.Primary.Spread     = 0.03
SWEP.Primary.Delay      = 0.1
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

local shootSound = "weapons/smg1/smg1_fire1.wav"

function SWEP:Initialize()
    self:SetHoldType("smg")
end

function SWEP:PrimaryAttack()

    if self:CanPrimaryAttack() then
        local ply = self:GetOwner()
        ply:EmitSound(shootSound, 100, 100, 0.25)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        ply:SetAnimation(PLAYER_ATTACK1)

        local mult = 1
        if ply:GetModel() == "models/player/police.mdl" then
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
        self:TakePrimaryAmmo(1)

        ply:ViewPunch(Angle(-1 * self.Primary.Recoil, math.random(-0.2, 0.2) * self.Primary.Recoil, 0))
        self:ShootEffects()
    else
        self:Reload()
    end


end

function SWEP:Reload()
    local ply = self:GetOwner()
	self:SetNextPrimaryFire(CurTime() + 1.5)
	self:DefaultReload( ACT_VM_RELOAD )
	ply:SetAnimation(PLAYER_RELOAD)
	self:EmitSound("weapons/smg1/smg1_reload.wav")
    timer.Simple(1.5, function()
        if IsValid(ply) and IsValid(self) then
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