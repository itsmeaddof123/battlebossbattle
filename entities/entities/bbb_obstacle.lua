ENT.Type = "anim"
DEFINE_BASECLASS("base_anim")

ENT.PrintName = "Obstacle"

ENT.Spawnable = true

local models = {
    {model = "models/props_building_details/Storefront_Template001a_Bars.mdl", health = 100, offset = Vector(0, 0, 30), angle = Angle(0, 0, 90)},
    {model = "models/props_combine/combine_window001.mdl", health = 150, offset = Vector(0, 0, 30), angle = Angle(0, 0, 90)},
    {model = "models/props_junk/TrashDumpster01a.mdl", health = 250, offset = Vector(0, 0, 25), angle = Angle(0, 0, 0)},
    {model = "models/props_lab/blastdoor001c.mdl", health = 300, offset = Vector(0, 0, 0), angle = Angle(0, 0, 0)},
    {model = "models/props_interiors/VendingMachineSoda01a.mdl", health = 150, offset = Vector(0, 0, 25), angle = Angle(90, 0, 0)},
    {model = "models/props_lab/servers.mdl", health = 100, offset = Vector(0, 0, 0), angle = Angle(0, 0, 0)},
    {model = "models/hunter/triangles/2x2x2.mdl", health = 250, offset = Vector(0, 0, 40), angle = Angle(0, 0, 0)},
    {model = "models/hunter/blocks/cube1x3x1.mdl", health = 250, offset = Vector(0, 0, 20), angle = Angle(0, 0, 0)},
    {model = "models/hunter/plates/plate2x5.mdl", health = 100, offset = Vector(0, 0, 30), angle = Angle(70, 0, 0)},
    {model = "models/props_phx/trains/tracks/track_2x.mdl", health = 300, offset = Vector(0, 0, 45), angle = Angle(0, 0, 90)},
    {model = "models/hunter/tubes/tube2x2x1c.mdl", health = 250, offset = Vector(0, 0, 20), angle = Angle(0, 0, 0)},
    {model = "models/hunter/tubes/tube2x2x2b.mdl", health = 250, offset = Vector(0, 0, 40), angle = Angle(0, 0, 0)},
    {model = "models/XQM/CoasterTrack/slope_45_2.mdl", health = 250, offset = Vector(0, 0, 30), angle = Angle(0, 0, 90)},
    {model = "models/hunter/blocks/cube2x4x025.mdl", health = 150, offset = Vector(0, 0, 40), angle = Angle(0, 0, 70)},
    {model = "models/props_junk/TrashDumpster02.mdl", health = 300, offset = Vector(0, 0, 40), angle = Angle(0, 0, 0)},
    {model = "models/props_wasteland/kitchen_fridge001a.mdl", health = 200, offset = Vector(0, 0, 15), angle = Angle(0, 0, 90)},
}

if SERVER then

    AddCSLuaFile()

    function ENT:Initialize()
        local modelTable = models[math.random(1, #models)]
        self:SetModel(modelTable.model)
        self:SetMaterial("phoenix_storms/plastic")
        self:SetAngles(Angle(math.random(-5, 5), math.random(1, 360), math.random(-5, 5)) + (modelTable.angle or Angle(0, 0, 0)))
        timer.Simple(0.1, function()
            self:SetPos(self:GetPos() +(modelTable.offset or Vector(0, 0, 0)))
            self:EmitSound("ambient/materials/rock"..math.random(1, 4)..".wav", 100, 100, 2.5)
        end)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetHealth(modelTable.health)
    end

    function ENT:OnTakeDamage(dmg)
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