local topW = 650
local topH = 200
local topBuffer = 25
local topSpeed = 300
local sideW = 400
local sideH = 120
local sideBuffer = 25
local sideSpeed = 500
local partialBlack = Color(0, 0, 0, 200)
local partialWhite = Color(255, 255, 255, 200)
local fullBlack = Color(0, 0, 0, 255)
local fullWhite = Color(255, 255, 255, 255)
local panelOpen1 = "panelopen3.wav"
local panelClose1 = "panelclose1.wav"
local panelOpen2 = "panelopen4.wav"

-- Item Description
surface.CreateFont("Courier Big 3", {
    font = "Courier New",
	size = 35,
	weight = 600,
    italic = true,
})

-- Removes the current message
local function removeTop()
    if IsValid(topOuter) then
        -- Panel open sound
        surface.PlaySound(panelClose1)
        topOuter:MoveTo((ScrW() - topW) / 2, topH * -1, (topH + topBuffer) / topSpeed, 0, -1, function() topOuter:Remove() end)
    end
end

-- Displays a new small message
function messageTop(arg)
    -- Makes way for the new message
    if IsValid(topOuter) then
        topOuter:Remove()
        timer.Remove("removetop")
    end

    if scoreboardCache[LocalPlayer()] and scoreboardCache[LocalPlayer()].playing or playerCache.round == "Crafting" then
        -- Panel open sound
        surface.PlaySound(panelOpen1)
        -- Outer panel
        topOuter = vgui.Create("DPanel")
        topOuter:SetSize(topW, topH)
        topOuter:SetPos((ScrW() - topW) / 2, topH * - 1)
        topOuter:MoveTo((ScrW() - topW) / 2, topBuffer, (topH + topBuffer) / topSpeed)
        topOuter.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, fullBlack)
        end
        -- Inner panel
        local topInner= vgui.Create("DPanel", topOuter)
        topInner:SetSize(topW - 8, topH - 8)
        topInner:SetPos(4, 4)
        topInner.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, fullWhite)
        end
        -- Label
        local topMessage = vgui.Create("DLabel", topInner)
        topMessage:SetWide(topW - 10)
        topMessage:SetPos(5, 5)
        topMessage:SetFont("Courier Big 3")
        topMessage:SetText(arg)
        topMessage:SetTextColor(fullBlack)
        topMessage:SetWrap(true)
        topMessage:SetAutoStretchVertical(true)
        topMessage.Paint = function(self, w, h) end

        timer.Create("removetop", 8, 1, removeTop)
    end
end

local function removeSide()
    if IsValid(sideOuter) then
        -- Panel open sound
        surface.PlaySound(panelClose1)
        sideOuter:MoveTo(sideW * -1, sideBuffer, (sideW + sideBuffer) / sideSpeed, 0, -1, function() sideOuter:Remove() end)
    end
end

function messageSide(arg)
    -- Makes way for the new message
    if IsValid(sideOuter) then
        sideOuter:Remove()
        timer.Remove("removeside")
    end

    -- Panel open sound
    surface.PlaySound(panelOpen2)
    -- Outer panel
    sideOuter = vgui.Create("DPanel")
    sideOuter:SetSize(sideW, sideH)
    sideOuter:SetPos(sideW * -1, sideBuffer)
    sideOuter:MoveTo(sideBuffer, sideBuffer, (sideW + sideBuffer) / sideSpeed)
    sideOuter.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, fullBlack)
    end
    -- Inner panel
    local sideInner= vgui.Create("DPanel", sideOuter)
    sideInner:SetSize(sideW - 8, sideH - 8)
    sideInner:SetPos(4, 4)
    sideInner.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, fullWhite)
    end
    -- Label
    local sideMessage = vgui.Create("DLabel", sideInner)
    sideMessage:SetWide(sideW - 8)
    sideMessage:SetPos(4, 4)
    sideMessage:SetFont("Courier Small 1")
    sideMessage:SetText(arg)
    sideMessage:SetTextColor(fullBlack)
    sideMessage:SetWrap(true)
    sideMessage:SetAutoStretchVertical(true)
    sideMessage.Paint = function(self, w, h) end
    -- Removal function
    timer.Create("removeside", 6, 1, removeSide)
end