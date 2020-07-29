if SERVER then
    AddCSLuaFile()
end

SWEP.Author             = "add___123"
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Medkit"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/c_medkit.mdl"
SWEP.WorldModel         = "models/weapons/w_medkit.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 1
SWEP.SlotPos            = 6

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Damage     = 0
SWEP.Primary.Delay      = 1.5
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

function SWEP:Initialize()
    self:SetHoldType("knife")
end

function SWEP:PrimaryAttack()

    local ply = self:GetOwner()

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local mult = 1
    if ply:GetModel() == "models/payday2/units/medic_player.mdl" then
        mult = 1.2
    end

    if ply:Health() ~= ply:GetMaxHealth() then
        ply:SetHealth(math.Clamp(ply:Health() + 5 * mult, ply:Health(), ply:GetMaxHealth()))
        ply:EmitSound("items/medshot4.wav", 100, 100, 0.5)
    else
        ply:EmitSound("items/medshotno1.wav")
    end

end

function SWEP:CanSecondaryAttack()
    return false
end