-- Configurable variables
local scoreW = 850
local scoreH = 850
local topBuffer = 70
local bottomBuffer = 50
local interval = 40
local panelOpen = "panelopen1.wav"
local panelClose = "panelclose1.wav"
local paperColor = Color(255, 255, 150, 255)
local fullRed = Color(255, 50, 25, 255)
local fullBlue = Color(25, 200, 200, 255)
local fullBlack = Color(0, 0, 0, 255)
local scoreboardText = Color(0, 0, 0, 255)
local skull = "menu/skull.png"
local crown = "menu/crown.png"

-- Scoreboard title font
surface.CreateFont("Courier Big 5", {
	font = "Courier New",
	size = 60,
	weight = 800,
    bold = true,
})

-- Scoreboard title font
surface.CreateFont("Courier Small 4", {
	font = "Courier New",
	size = 30,
	weight = 700,
})

-- Scoreboard panel font
surface.CreateFont("Courier Big 4a", {
	font = "Courier New",
	size = 40,
	weight = 300,
})

-- Scoreboard panel font
surface.CreateFont("Courier Big 4b", {
	font = "Courier New",
	size = 50,
	weight = 600,
})

-- Scoreboard footer font
surface.CreateFont("Courier Small 2", {
	font = "Courier New",
	size = 18,
	weight = 750,
})

-- Scoreboard
local function toggleScoreboard(toggle)

    if toggle then

        -- Page turn sound
        surface.PlaySound(panelOpen)

        -- Remove old scoreboard if necessary
        if IsValid(scorePanel) then
            scorePanel:Remove()
        end


        -- Main scoreboard frame
        scorePanel = vgui.Create("DPanel")
        scorePanel:SetSize(scoreW, scoreH)
        scorePanel:Center()
        scorePanel:MakePopup()
        scorePanel:SetKeyboardInputEnabled(false)

        -- Title, red lines, credits footer
        scorePanel.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, paperColor)
            draw.SimpleText("BATTLE BOSS BATTLERS", "Courier Big 5", w / 2, 40, scoreboardText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Gamemode made by add___123", "Courier Small 2", w - 5, h - 5, scoreboardText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
            draw.SimpleText("Name", "Courier Small 4", 200, topBuffer + 5, fullBlack, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Score", "Courier Small 4", 70, topBuffer + 5, fullBlack, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("ms", "Courier Small 4", 3, topBuffer + 5, fullBlack, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetDrawColor(fullRed)
            surface.DrawLine(63, 0, 63, h)
            surface.DrawLine(65, 0, 65, h)
            surface.SetDrawColor(fullBlue)
            surface.DrawLine(0, topBuffer - 2, w, topBuffer - 2)
            surface.DrawLine(0, topBuffer - 1, w, topBuffer - 1)
            surface.DrawLine(0, topBuffer + interval - 2, w, topBuffer + interval - 2)
            surface.DrawLine(0, topBuffer + interval - 1, w, topBuffer + interval - 1)
        end

        -- Scroll panel for player names
        local scrollPanel = vgui.Create("DScrollPanel", scorePanel)
        scrollPanel:SetPos(0, topBuffer + interval)
        scrollPanel:SetSize(scoreW, scoreH - (topBuffer + interval + bottomBuffer))
        scrollBar = scrollPanel:GetVBar()
        scrollBar:SetWide(0)

        -- Ensures all blue row lines get drawn - USE game.MaxPlayers() TO SIMPLY DRAW ALL POSSIBLE PLAYERS?
        local allPlayers = player.GetAll()
        local rowsToMake = math.floor((scoreH - topBuffer - interval - bottomBuffer) / interval)
        if rowsToMake < #allPlayers then
            rowsToMake = #allPlayers
        end

        -- Sets up each player's row
        for i = 1, rowsToMake do
            local ply = allPlayers[i]
            -- If there is a player, make a button for them
            if IsValid(ply) then
                -- If the player wasn't previously cached, cache them
                if not scoreboardCache[ply] then
                    scoreboardCache[ply] = cacheInit()
                end
                local plyButton = vgui.Create("DButton", scrollPanel)
                local playing = scoreboardCache[ply].playing
                local boss = scoreboardCache[ply].boss
                local score = scoreboardCache[ply].score
                local name = ply:Name()
                local ping = ply:Ping()
                local id = ply:SteamID()
                -- SteamID to clipboard on click
                plyButton.DoClick = function()
                    SetClipboardText(id)
                    LocalPlayer():ChatPrint("Copied the SteamID of "..name)
                end
                plyButton:Dock(TOP)
                plyButton:SetSize(scoreW, interval)
                plyButton:SetText("")
                plyButton.Paint = function(self, w, h)
                    draw.SimpleText(name, "Courier Big 4a", 200, -3, fullBlack, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText(tostring(score), "Courier Big 4a", 70, 0, fullBlack, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText(tostring(ping), "Courier Small 2", 3, 3, fullBlack, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    surface.SetDrawColor(fullBlue)
                    surface.DrawLine(0, h - 2, w, h - 2)
                    surface.DrawLine(0, h - 1, w, h - 1)
                end
                if boss then
                    local crownImage = vgui.Create("DImage", plyButton)
                    crownImage:SetPos(scoreW - interval * 2, 1)
                    crownImage:SetSize(interval - 4, interval - 4)
                    crownImage:SetImage(crown)
                end
                if not playing then
                    local skullImage = vgui.Create("DImage", plyButton)
                    skullImage:SetPos(scoreW - interval, 1)
                    skullImage:SetSize(interval - 4, interval - 4)
                    skullImage:SetImage(skull)
                end
            -- If it's not a player, we're only making the panel to draw the line
            else
                local emptyPanel = vgui.Create("DPanel", scrollPanel)
                emptyPanel:Dock(TOP)
                emptyPanel:SetSize(scoreW, interval)
                emptyPanel.Paint = function(self, w, h)
                    surface.SetDrawColor(fullBlue)
                    surface.DrawLine(0, h - 2, w, h - 2)
                    surface.DrawLine(0, h - 1, w, h - 1)
                end
            end

        end

        -- Other blue lines
        scrollBar.Paint = function(self, w, h)
            for i = #allPlayers + 1, linesToDraw do
                surface.DrawLine(0, interval * i, w, interval * i)
                surface.DrawLine(0, interval * i + 1, w, interval * i + 1)
            end
        end
    else
        -- Remove the scoreboard
        if IsValid(scorePanel) then
            scorePanel:Remove()
            surface.PlaySound(panelClose)
        end
    end
end

-- Open scoreboard
hook.Add("ScoreboardShow", "OpenScoreboard", function()
    toggleScoreboard(true)
    return false
end)

-- Close scoreboard
hook.Add("ScoreboardHide", "CloseScoreboard", function()
    toggleScoreboard(false)
end)