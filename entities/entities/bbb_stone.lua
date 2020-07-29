ENT.Type = "anim"
DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Stone"

ENT.Spawnable = true

local models = { -- Average health: 22
    {model = "models/props_c17/gravestone001a.mdl",         health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_c17/gravestone002a.mdl",         health = 25, offset = Vector(0, 0, 25),},
    {model = "models/props_c17/gravestone003a.mdl",         health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_c17/gravestone004a.mdl",         health = 25, offset = Vector(0, 0, 15),},
    {model = "models/props_c17/FurnitureSink001a.mdl",      health = 15, offset = Vector(0, 0, 20),},
    {model = "models/props_c17/concrete_barrier001a.mdl",   health = 30,},
    {model = "models/props_c17/display_cooler01a.mdl",      health = 20,},
    {model = "models/props_c17/gravestone_cross001b.mdl",   health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_c17/gravestone_statue001a.mdl",  health = 25, offset = Vector(0, 0, 70),},
    {model = "models/props_combine/breenbust.mdl",          health = 5, offset = Vector(0, 0, 15),},
}

if SERVER then

    AddCSLuaFile()

    function ENT:Initialize()
        local modelTable = models[math.random(1, #models)]
        self:SetModel(modelTable.model)
        self:SetAngles(Angle(0, math.random(1, 360), 0) + (modelTable.angle or Angle(0, 0, 0)))
        timer.Simple(0.1, function() self:SetPos(self:GetPos() + (modelTable.offset or Vector(0, 0, 0))) end)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetHealth(modelTable.health)
    end

    function ENT:OnTakeDamage(dmg)
        local attacker = dmg:GetAttacker()
        local inflictor = dmg:GetInflictor()

        if IsValid(inflictor) and IsValid(attacker) then
            if inflictor:GetClass() == "bbb_craftingfists" then
                attacker:GiveMat(2)
                attacker:UpdateScore(3)
            elseif inflictor:GetClass() == "bbb_energyzapper" then
                attacker:UpdateScore(1)
            end
        end

        self:SetHealth(self:Health() - dmg:GetDamage())
        dmg:SetDamage(0)

        if self:Health() <= 0 then
            self:Remove()
            self:EmitSound("physics/concrete/concrete_break"..math.random(2, 3)..".wav")
        else
            self:EmitSound("physics/concrete/concrete_block_impact_hard"..math.random(1, 3)..".wav")
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end