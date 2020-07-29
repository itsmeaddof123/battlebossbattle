if SERVER then
    AddCSLuaFile()
end

SWEP.Author             = "add___123"
SWEP.PrintName          = "Battle Fists"
SWEP.Instructions       = ""

SWEP.ViewModel          = "models/weapons/c_arms.mdl"
SWEP.WorldModel         = ""
SWEP.ViewModelFlip      = false 
SWEP.UseHands           = true

SWEP.Weight             = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false

SWEP.Slot               = 0
SWEP.SlotPos            = 7

SWEP.DrawAmmo           = false
SWEP.DrawCrosshair      = true

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

SWEP.Primary.ClipSize   = -1
SWEP.Primary.DefaultClip= -1
SWEP.Primary.Damage     = 25
SWEP.Primary.Delay      = 0.5
SWEP.Primary.Ammo       = "none"
SWEP.Primary.Automatic  = true

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Automatic= true

SWEP.ShouldDropOnDie    = false

local swingSound = "WeaponFrag.Throw"

function SWEP:Initialize()
    self:SetHoldType("fist")
end

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 1, "NextIdle")
end

function SWEP:UpdateNextIdle()
	local vm = self.Owner:GetViewModel()
	self:SetNextIdle(CurTime() + vm:SequenceDuration() / vm:GetPlaybackRate())
end

function SWEP:PrimaryAttack(right)

    local ply = self:GetOwner()
    ply:SetAnimation(PLAYER_ATTACK1)

    local anim = "fists_left"
    if right then anim = "fists_right" end

    local vm = ply:GetViewModel()
	vm:SendViewModelMatchingSequence(vm:LookupSequence(anim))

    ply:EmitSound(swingSound)
    self:UpdateNextIdle()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

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
        if SERVER then ply:EmitSound("physics/body/body_medium_impact_hard"..math.random(1, 6)..".wav") end
        if SERVER and IsValid(target) then
            local damage = DamageInfo()
            damage:SetDamage(self.Primary.Damage)
            damage:SetDamageType(DMG_SLASH)
            damage:SetAttacker(ply)
            target:TakeDamageInfo(damage)
        end
    end

    ply:LagCompensation(false)
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack(true)
end

function SWEP:Deploy()
    local speed = GetConVarNumber("sv_defaultdeployspeed")
    local vm = self.Owner:GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
    vm:SetPlaybackRate(speed)

    self:SetNextPrimaryFire(CurTime() + vm:SequenceDuration() / speed)
    self:SetNextSecondaryFire(CurTime() + vm:SequenceDuration() / speed)
    self:UpdateNextIdle()

    return true
end

function SWEP:Think()
	local vm = self.Owner:GetViewModel()
	local idletime = self:GetNextIdle()

    if idletime > 0 and CurTime() > idletime then
		vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_idle_0"..tostring(math.random(1, 2))))
		self:UpdateNextIdle()
	end
end

function SWEP:CanSecondaryAttack()
    return false
end