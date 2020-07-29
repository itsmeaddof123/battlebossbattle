if SERVER then
    AddCSLuaFile()
end

SWEP.Author             = "add___123"
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Speed Sac"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/c_bugbait.mdl"
SWEP.WorldModel         = "models/weapons/w_bugbait.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 1
SWEP.SlotPos            = 2

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Damage     = 0
SWEP.Primary.Delay      = 0
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Automatic  = false

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

function SWEP:Initialize()
    self:SetHoldType("melee")
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local ply = self:GetOwner()
    if timer.Exists("speedsac"..ply:SteamID64()) then return end

    local mult = 1
    if ply:GetModel() == "models/auditor/lotr/warriordude.mdl" then
        mult = 1.2
    end
            
    ply:SetWalkSpeed(ply:GetWalkSpeed() + 100 * mult)
    ply:SetRunSpeed(ply:GetRunSpeed() + 100 * mult)
    ply:EmitSound("npc/antlion_grub/agrub_squish1.wav")
    ply:ChatPrint("Your skin soaks up the juices and you feel yourself grow faster!")

    timer.Create("speedsac"..ply:SteamID64(), 10, 1, function()
        if GetRound() == "Battle" or GetRound() == "Armageddon" then
            ply:SetWalkSpeed(ply:GetWalkSpeed() - 100 * mult)
            ply:SetRunSpeed(ply:GetRunSpeed() - 100 * mult)
            ply:EmitSound("npc/antlion_grub/agrub_squish3.wav")
            ply:ChatPrint("You feel the effects of the speed sac wearing off...")
        end
    end)
end

function SWEP:CanSecondaryAttack()
    return false
end