ENT.Type = "anim"ENT.Type = "anim"
DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Wood"

ENT.Spawnable = true

local models = { -- Average health: 18.5
    {model = "models/props_c17/awning001a.mdl", health = 15, offset = Vector(0, 0, 5), angle = Angle(-50, 0, 0),},
    {model = "models/props_c17/awning002a.mdl", health = 15, offset = Vector(0, 0, 5), angle = Angle(-50, 0, 0),},
    {model = "models/props_c17/FurnitureCouch001a.mdl", health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_c17/FurnitureCouch002a.mdl", health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_interiors/Furniture_Couch01a.mdl", health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_interiors/Furniture_Couch02a.mdl", health = 25, offset = Vector(0, 0, 20),},
    {model = "models/props_combine/breenchair.mdl", health = 12,},
    {model = "models/props_trainstation/traincar_seats001.mdl", health = 30,},
    {model = "models/props_junk/cardboard_box001a.mdl", health = 5, offset = Vector(0, 0, 10),},
    {model = "models/props_junk/cardboard_box003a.mdl", health = 5, offset = Vector(0, 0, 10),},
}

if SERVER then

    AddCSLuaFile()

    function ENT:Initialize()
        local modelTable = models[math.random(1, #models)]
        self:SetModel(modelTable.model)
        self:SetAngles(Angle(0, math.random(1, 360), 0) + (modelTable.angle or Angle(0, 0, 0)))
        timer.Simple(0.1, function()
            self:SetPos(self:GetPos() + (modelTable.offset or Vector(0, 0, 0)))
            self:EmitSound("physics/wood/wood_furniture_impact_soft"..math.random(1, 3)..".wav")
        end)
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
                attacker:GiveMat(3)
                attacker:UpdateScore(3)
            elseif inflictor:GetClass() == "bbb_energyzapper" or inflictor:GetClass() == "bbb_slapbat" then
                attacker:UpdateScore(1)
            end
        end

        self:SetHealth(self:Health() - dmg:GetDamage())
        dmg:SetDamage(0)

        if self:Health() <= 0 then
            self:Remove()
            self:EmitSound("physics/cardboard/cardboard_box_break"..math.random(2, 3)..".wav")
        else
            self:EmitSound("physics/cardboard/cardboard_box_impact_bullet"..math.random(1, 5)..".wav")
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end