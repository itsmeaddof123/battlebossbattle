-- Configurable variables
local statusW = 400
local statusH = 60
local statusOuter = Color(50, 50, 50, 255)
local statusRound = Color(150, 150, 150, 255) -- COLOR CODE BASED ON ROUND?
local statusHealth = Color(255, 0, 0, 255)
local statusShield = Color(0, 255, 255, 150)
local fullWhite = Color(255, 255, 255, 255)
local partialBlack = Color(20, 20, 20, 200)
local fullBlack = Color(0, 0, 0, 220)
local border = 4
local insW = 250
local insH = 50
local insBuffer = 25
local partialGrey = Color(150, 150, 150, 50)
local partialWhite = Color(255, 255, 255, 50)

-- Status Text
surface.CreateFont("Roboto Big 1", {
    font = "Roboto",
	size = 50,
	weight = 600,
})

-- Instruction Text
surface.CreateFont("Roboto Small 1", {
    font = "Roboto",
	size = 30,
	weight = 350,
})

-- Provides the HUD elements to hide
local hide = {
    CHudHealth = true,
    CHudBattery = true,
    CHudZoom = true,
    CHudWeaponSelection = true,
}

-- Hides HUD elements
hook.Add("HUDShouldDraw", "HideHUD", function(name)
    if hide[name] then return false end
end)

local ply
local roundInit = false

-- Health HUD
hook.Add("HUDPaint", "HUDs", function()
    ply = ply or LocalPlayer()
    local scrW = ScrW()
    local scrH = ScrH()
    local currentRound = playerCache.round

    -- Health, Shield, and Round Timer
    local timeLeft = string.FormattedTime(playerCache.time - math.floor(CurTime()), "%01i:%02i")
    local shield = playerCache.shield
    local maxShield = playerCache.maxShield
    local healthString = tostring(ply:Health()).." / "..tostring(ply:GetMaxHealth())
    draw.RoundedBox(8, 25, scrH - 25 - statusH * 2.2, statusW, statusH * 2.2, statusOuter) -- Outer Box
    draw.RoundedBoxEx(5, 25 + border, scrH - 25 - statusH * 2.2 + border, statusW - border * 2, statusH - border * 2, statusRound, true, true, false, false) -- Round Box
    draw.SimpleTextOutlined(currentRound, "Roboto Big 1", 25 + statusW * 0.02, scrH - 25 - statusH * 1.7, fullWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, fullBlack) -- Round Text
    draw.SimpleTextOutlined(timeLeft, "Roboto Big 1", 25 + statusW * 0.98, scrH - 25 - statusH * 1.7, fullWhite, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, fullBlack) -- Time Text
    draw.RoundedBoxEx(5, 25 + border, scrH - 25 - statusH * 1.2 + border, (statusW - border * 2) * shield / maxShield, statusH * 1.2 - border * 2, statusShield, false, false, true, true) -- Shield Box
    surface.SetDrawColor(statusHealth)
    surface.DrawRect(25 + border, scrH - 25 - statusH * 1.2 + border * 3, (statusW - border * 2) * ply:Health() / ply:GetMaxHealth(), statusH * 1.2 - border * 6) -- Health Box
    draw.SimpleTextOutlined(healthString, "Roboto Big 1", 25 + statusW * 0.5, scrH - 25 - statusH * 0.5 - border, fullWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, fullBlack) -- Health Text

    -- Abilities and Menu Prompts
    local leftKey = string.upper(input.GetKeyName(playerCache.leftToggle))
    local rightKey = string.upper(input.GetKeyName(playerCache.rightToggle))
    if scoreboardCache[ply] and scoreboardCache[ply].boss then
        if currentRound == "Crafting" then
            draw.RoundedBox(10, scrW / 2 - insW - insBuffer, scrH - insH - insBuffer, insW, insH, partialBlack)
            draw.RoundedBox(10, scrW / 2 - insW - insBuffer, scrH - insH - insBuffer, insW * math.min(CurTime() - playerCache.lastAbility, 7) / 7, insH, partialBlack)
            draw.SimpleTextOutlined(leftKey..": Gravity Toss", "Roboto Small 1", (scrW - insW) / 2 - insBuffer, scrH - insH / 2 - insBuffer, fullWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, fullBlack)
            draw.RoundedBox(10, scrW / 2 + insBuffer, scrH - insH - insBuffer, insW, insH, partialBlack)
            draw.RoundedBox(10, scrW / 2 + insBuffer, scrH - insH - insBuffer, insW * math.min(CurTime() - playerCache.lastAbility, 7) / 7, insH, partialBlack)
            draw.SimpleTextOutlined(rightKey..": Slowness Beam", "Roboto Small 1", (scrW + insW) / 2 + insBuffer, scrH - insH / 2 - insBuffer, fullWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, fullBlack)
        elseif (currentRound == "Battle" or currentRound == "Armageddon") then
            draw.RoundedBox(10, scrW / 2 - insW - insBuffer, scrH - insH - insBuffer, insW, insH, partialBlack)
            draw.RoundedBox(10, scrW / 2 - insW - insBuffer, scrH - insH - insBuffer, insW * math.min(CurTime() - playerCache.lastAbility, 7) / 7, insH, partialBlack)
            draw.SimpleTextOutlined(leftKey..": Gravity Pummel", "Roboto Small 1", (scrW - insW) / 2 - insBuffer, scrH - insH / 2 - insBuffer, fullWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, fullBlack)
            draw.RoundedBox(10, scrW / 2 + insBuffer, scrH - insH - insBuffer, insW, insH, partialBlack)
            draw.RoundedBox(10, scrW / 2 + insBuffer, scrH - insH - insBuffer, insW * math.min(CurTime() - playerCache.lastAbility, 7) / 7, insH, partialBlack)
            draw.SimpleTextOutlined(rightKey..": Death Beam", "Roboto Small 1", (scrW + insW) / 2 + insBuffer, scrH - insH / 2 - insBuffer, fullWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, fullBlack)
        end
    else
        if currentRound == "Crafting" then
            draw.RoundedBox(10, scrW / 2 - insW - insBuffer, scrH - insH - insBuffer, insW, insH, partialBlack)
            draw.SimpleTextOutlined(leftKey..": Start Crafting", "Roboto Small 1", (scrW - insW) / 2 - insBuffer, scrH - insH / 2 - insBuffer, fullWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, fullBlack)
            draw.RoundedBox(10, scrW / 2 + insBuffer, scrH - insH - insBuffer, insW, insH, partialBlack)
            draw.SimpleTextOutlined(rightKey..": Start Training", "Roboto Small 1", (scrW + insW) / 2 + insBuffer, scrH - insH / 2 - insBuffer, fullWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, fullBlack)
        elseif (currentRound == "Battle" or currentRound == "Armageddon") then
            draw.RoundedBox(10, (scrW - insW) / 2, scrH - insH - insBuffer, insW, insH, partialBlack)
            draw.SimpleTextOutlined(leftKey.."/"..rightKey..": Consumables", "Roboto Small 1", scrW / 2, scrH - insH / 2 - insBuffer, fullWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, fullBlack)
        end
    end

    -- Weapons
    local weaponsTable = ply:GetWeapons()
    for k, v in ipairs(weaponsTable) do
        local slot = v:GetSlot()
        surface.SetDrawColor(fullBlack)
        surface.DrawRect(scrW - 270, scrH * 0.6 + slot * 50, 250, 40)
        if v == ply:GetActiveWeapon() then
            surface.SetDrawColor(partialWhite)
            surface.DrawRect(scrW - 266, scrH * 0.6 + 4 + slot * 50, 242, 32)
        else
            surface.SetDrawColor(partialGrey)
            surface.DrawRect(scrW - 266, scrH * 0.6 + 4 + slot * 50, 242, 32)
        end
        draw.SimpleTextOutlined(v:GetPrintName(), "Roboto Small 1", scrW - 260, scrH * 0.6 + 20 + slot * 50, fullWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, fullBlack)
    end
end)