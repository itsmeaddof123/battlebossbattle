ENT.Type = "anim"
DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Wood"

ENT.Spawnable = true

local models = { -- Average health: 17.5
    {model = "models/props_c17/FurnitureDrawer001a.mdl", health = 10, offset = Vector(0, 0, 25),},
    {model = "models/props_c17/FurnitureChair001a.mdl", health = 15, offset = Vector(0, 0, 20),},
    {model = "models/props_c17/FurnitureDrawer001a_Chunk01.mdl", health = 15, offset = Vector(0, 0, 5), angle = Angle(30, 0, 70),},
    {model = "models/props_c17/FurnitureDrawer001a_Chunk02.mdl", health = 15, offset = Vector(0, 0, 10), angle = Angle(30, 0, 70),},
    {model = "models/props_c17/FurnitureDrawer002a.mdl", health = 20, offset = Vector(0, 0, 15),},
    {model = "models/props_c17/FurnitureDrawer003a.mdl", health = 20, offset = Vector(0, 0, 25),},
    {model = "models/props_c17/FurnitureDresser001a.mdl", health = 30, offset = Vector(0, 0, 35),},
    {model = "models/props_c17/FurnitureTable001a.mdl", health = 15, offset = Vector(0, 0, 15),},
    {model = "models/props_c17/FurnitureTable002a.mdl", health = 15, offset = Vector(0, 0, 15),},
    {model = "models/props_c17/FurnitureTable003a.mdl", health = 15, offset = Vector(0, 0, 12),},
    {model = "models/props_interiors/Furniture_shelf01a.mdl", health = 25, offset = Vector(0, 0, 40),},
    {model = "models/props_trainstation/bench_indoor001a.mdl", health = 15, offset = Vector(0, 0, 20),},
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
                attacker:GiveMat(5)
                attacker:UpdateScore(3)
            elseif inflictor:GetClass() == "bbb_energyzapper" then
                attacker:UpdateScore(3)
            end
        end

        self:SetHealth(self:Health() - dmg:GetDamage())
        dmg:SetDamage(0)

        if self:Health() <= 0 then
            self:Remove()
            self:EmitSound("physics/wood/wood_crate_break"..math.random(1, 3)..".wav")
        else
            self:EmitSound("physics/wood/wood_box_impact_hard"..math.random(1, 3)..".wav")
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end