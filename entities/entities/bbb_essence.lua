ENT.Type = "anim"
DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Essence"

ENT.Spawnable = true

local models = { -- Average health: 12
    {model = "models/props_phx/misc/soccerball.mdl", health = 10, offset = Vector(0, 0, 65),},
    {model = "models/XQM/Rails/gumball_1.mdl", health = 10, offset = Vector(0, 0, 50),},
    {model = "models/XQM/Rails/trackball_1.mdl", health = 15, offset = Vector(0, 0, 35),},
    {model = "models/Combine_Helicopter/helicopter_bomb01.mdl", health = 20, offset = Vector(0, 0, 35),},
    {model = "models/props_phx/games/chess/white_dama.mdl", health = 5, offset = Vector(0, 0, 65), angle = Angle(90, 0, 0)},
}

local materials = {
    "phoenix_storms/wire/pcb_green",
    "phoenix_storms/wire/pcb_red",
    "phoenix_storms/wire/pcb_blue",
}

if SERVER then

    AddCSLuaFile()

    function ENT:Initialize()
        local modelTable = models[math.random(1, #models)]
        self:SetModel(modelTable.model)
        self:SetMaterial(materials[math.random(1, #materials)])
        self:SetAngles(Angle(0, math.random(1, 360), 0) + (modelTable.angle or Angle(0, 0, 0)))
        timer.Simple(0.1, function() self:SetPos(self:GetPos() +(modelTable.offset or Vector(0, 0, 0))) end)
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
                attacker:GiveMat(1)
                attacker:UpdateScore(3)
            elseif inflictor:GetClass() == "bbb_energyzapper" then
                attacker:UpdateScore(1)
            end
        end

        self:SetHealth(self:Health() - dmg:GetDamage())
        dmg:SetDamage(0)

        if self:Health() <= 0 then
            self:Remove()
            self:EmitSound("ambient/energy/weld"..math.random(1, 2)..".wav")
        else
            self:EmitSound("ambient/energy/spark"..math.random(1, 4)..".wav")
        end
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end