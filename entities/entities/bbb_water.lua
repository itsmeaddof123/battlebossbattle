ENT.Type = "anim"
DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Water"

ENT.Spawnable = true

local models = { -- Average health: 15.5
    {model = "models/props_junk/garbage_milkcarton001a.mdl", health = 20, offset = Vector(0, 0, 8),},
    {model = "models/props_junk/garbage_milkcarton002a.mdl", health = 20, offset = Vector(0, 0, 8),},
    {model = "models/props_junk/garbage_plasticbottle001a.mdl", health = 20, offset = Vector(0, 0, 8),},
    {model = "models/props_junk/garbage_plasticbottle002a.mdl", health = 20, offset = Vector(0, 0, 8),},
    {model = "models/props_junk/garbage_plasticbottle003a.mdl", health = 20, offset = Vector(0, 0, 8),},
    {model = "models/props_junk/PopCan01a.mdl", health = 20, offset = Vector(0, 0, 5),},
    {model = "models/props_junk/watermelon01.mdl", health = 20, offset = Vector(0, 0, 8),},
    {model = "models/props_junk/glassjug01.mdl", health = 20, offset = Vector(0, 0, 5),},
    {model = "models/props_borealis/bluebarrel001.mdl", health = 40, offset = Vector(0, 0, 25),},
    {model = "models/props_c17/oildrum001.mdl", health = 40},
}

if SERVER then

    AddCSLuaFile()

    function ENT:Initialize()
        local modelTable = models[math.random(1, #models)]
        self:SetModel(modelTable.model)
        self:SetAngles(Angle(0, math.random(1, 360), 0) + (modelTable.angle or Angle(0, 0, 0)))
        timer.Simple(0.1, function()
            self:SetPos(self:GetPos() + (modelTable.offset or Vector(0, 0, 0)))
            self:EmitSound("ambient/water/drip"..math.random(1, 4)..".wav")
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
                attacker:GiveMat(6)
                attacker:UpdateScore(3)
            elseif inflictor:GetClass() == "bbb_energyzapper" or inflictor:GetClass() == "bbb_slapbat" then
                attacker:UpdateScore(1)
            end
        end

        self:SetHealth(self:Health() - dmg:GetDamage())
        dmg:SetDamage(0)

        if self:Health() <= 0 then
            self:Remove()
            self:EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(3, 4)..".wav")
        else
            self:EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(1, 2)..".wav")
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end