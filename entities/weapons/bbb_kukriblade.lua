if SERVER then
    AddCSLuaFile()
    resource.AddFile("models/weapons/v_kukr1_t.mdl")
    resource.AddFile("models/weapons/w_kukr1_ct.mdl")
    resource.AddFile("models/weapons/w_kukr1_t.mdl")
    resource.AddFile("materials/models/weapons/v_models/knife_t/mesh.vmt")
    resource.AddFile("materials/models/weapons/v_models/knife_t/mesh_norm.vtf")
    resource.AddFile("materials/models/weapons/v_models/knife_t/t1.vmt")
    resource.AddFile("materials/models/weapons/v_models/knife_t/t1_normal.vtf")
    resource.AddFile("materials/models/weapons/w_models/w_knife_t/mesh.vmt")
    resource.AddFile("materials/models/weapons/w_models/w_knife_t/plasticknife.vtf")
    resource.AddFile("materials/models/weapons/w_models/w_knife_t/t1.vtf")
end

SWEP.Author             = "add___123"
SWEP.Base               = "weapon_base"
SWEP.PrintName          = "Kukri Blade"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/v_kukr1_t.mdl"
SWEP.WorldModel         = "models/weapons/w_kukr1_t.mdl"
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 0
SWEP.SlotPos            = 2

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Damage     = 100
SWEP.Primary.Delay      = 1
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= false

SWEP.ShouldDropOnDie    = false

local swingSound = Sound("Weapon_Crowbar.Single")

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
            local mult = 1
            if ply:GetModel() == "models/auditor/lotr/warriordude.mdl" then
                mult = 1.2
            end
            
            local damage = DamageInfo()
            damage:SetDamage(self.Primary.Damage * mult)
            damage:SetDamageType(DMG_SLASH)
            damage:SetAttacker(ply)
            target:TakeDamageInfo(damage)
            ply:EmitSound("ambient/machines/slicer"..math.random(1, 4)..".wav")
        elseif SERVER then 
            ply:EmitSound("ambient/machines/slicer"..math.random(1, 4)..".wav")
        end
    else
        self.Weapon:SendWeaponAnim(ACT_VM_MISSCENTER)
        if SERVER then ply:EmitSound(swingSound) end
    end

    ply:LagCompensation(false)

end

function SWEP:CanSecondaryAttack()
    return false
end