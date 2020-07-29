ENT.Type = "anim"
DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Metal"

ENT.Spawnable = true

local models = { -- Average health: 25
    {model = "models/props_c17/Lockers001a.mdl", health = 25, offset = Vector(0, 0, 25),},
    {model = "models/props_c17/furnitureStove001a.mdl", health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_c17/FurnitureWashingmachine001a.mdl", health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_c17/FurnitureFireplace001a.mdl", health = 30, offset = Vector(0, 0, 40),},
    {model = "models/props_c17/tv_monitor01.mdl", health = 20, offset = Vector(0, 0, 10),},
    {model = "models/props_c17/TrapPropeller_Engine.mdl", health = 25, offset = Vector(0, 0, 15),},
    {model = "models/props_combine/combine_intmonitor001.mdl", health = 30},
    {model = "models/props_combine/combine_interface001.mdl", health = 25},
    {model = "models/props_combine/CombineThumper002.mdl", health = 35},
    {model = "models/props_combine/health_charger001.mdl", health = 20, offset = Vector(0, 0, 2), angle = Angle(-90, 0, 0),},
    {model = "models/props_junk/MetalBucket02a.mdl", health = 20, offset = Vector(0, 0, 10),},
    {model = "models/props_interiors/Radiator01a.mdl", health = 20, offset = Vector(0, 0, 20),},
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
                attacker:GiveMat(4)
                attacker:UpdateScore(3)
            elseif inflictor:GetClass() == "bbb_energyzapper" then
                attacker:UpdateScore(3)
            end
        end

        self:SetHealth(self:Health() - dmg:GetDamage())
        dmg:SetDamage(0)

        if self:Health() <= 0 then
            self:Remove()
            self:EmitSound("physics/metal/metal_box_break"..math.random(1, 2)..".wav")
        else
            self:EmitSound("physics/metal/metal_box_impact_bullet"..math.random(1, 3)..".wav")
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end