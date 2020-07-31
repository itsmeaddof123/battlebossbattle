-- Configurable variables
local interval = 55 -- Originally meant to be configurable but I think changing it might break stuff at this point
local textureColor = Color(110, 90, 80, 255)
local outlineColor = Color(75, 50, 0, 255)
local gridColor = Color(255, 255, 255, 10)
local panelFill = Color(225, 200, 150, 255)
local statFill = Color(175, 150, 125, 255)
local craftButtonColor = Color(200, 200, 200, 25)
local fullRed = Color(225, 25, 50, 255)
local fullGreen = Color(25, 200, 25, 255)
local fullWhite = Color(255, 255, 255, 255)
local fullBlack = Color(0, 0, 0, 255)
local partialBlack = Color(20, 20, 20, 200)
local hoveredColor = Color(255, 255, 255, 5)
local selectedColor = Color(255, 255, 255, 15)
local panelOpen = "panelopen2.wav"
local panelClose = "panelclose1.wav"
local craftSuccess = "buttons/button6.wav"
local trainSuccess = "buttons/blip1.wav"
local consumeSuccess = "npc/barnacle/barnacle_gulp2.wav"
local failure = "npc/roller/code2.wav"
local itemSelect = "buttons/button15.wav"
-- New UI
local lightGrey = Color(200, 200, 200, 75)
local solidGrey = Color(75, 75, 75, 255)
local lightBlue = Color(25, 75, 150, 150)
local solidWhite = Color(255, 255, 255, 255)
local solidBlack = Color(0, 0, 0, 255)

-- Item Title
surface.CreateFont("Courier Big 1", {
    font = "Courier New",
	size = interval * 1.05,
	weight = 750,
    bold = true,
})

-- Material Count
surface.CreateFont("Courier Big 2", {
	font = "Courier New",
	size = interval,
	weight = 750,
})

-- Item Description
surface.CreateFont("Courier Small 1", {
    font = "Courier New",
	size = interval * 0.65,
	weight = 750,
    italic = true,
})

-- Scoreboard footer font
surface.CreateFont("Courier Small 3", {
	font = "Courier New",
	size = interval * 0.5,
	weight = 750,
    italic = true,
})

-- New UI
-- F1 Menu font
surface.CreateFont("F1 Menu 1", {
    font = "Courier New",
    size = 25,
    weight = 650,
})

-- F1 Menu font
surface.CreateFont("F1 Menu 2", {
    font = "Courier New",
    size = 45,
    weight = 750,
})

-- F1 Menu font
surface.CreateFont("F1 Menu 3", {
    font = "Courier New",
    size = 20,
    weight = 500,
})

------------------------------------
--[[     MAIN CRAFTING MENU     ]]--
------------------------------------

-- Used for menu toggle
local lastCatId = -1
local lastItemId = -1

-- Item selection
local function selectItem(itemId, itemTable, catId)
    -- If there is an old itemPanel, remove it
    if IsValid(itemPanel) then
        itemPanel:Remove()
    end
    -- If clicked on a new item, open the new item
    if lastItemId ~= itemId and IsValid(catPanel) then
        surface.PlaySound(itemSelect)
        lastItemId = itemId
        itemPanel = vgui.Create("DPanel", catPanel)
        itemPanel:SetPos(interval * 3, interval * 3.2)
        itemPanel:SetSize(interval * 12, interval * 6)
        itemPanel.Paint = function(self, w, h) end
        local itemText = vgui.Create("DPanel", itemPanel)
        itemText:SetPos(interval * 0.25, 0)
        itemText:SetSize(interval * 8.5, interval * 6)
        itemText.Paint = function(self, w, h)
            draw.RoundedBox(interval * 0.2, 0, 0, w, h, outlineColor)
            draw.RoundedBox(interval * 0.2, 3, 3, w - 6, h - 6, panelFill)
            for i = 1, 4 do
                surface.SetDrawColor(outlineColor)
                surface.DrawLine(interval * 0.2, interval * 2.2 + i, w - interval * 0.2, interval * 2.2 + i)
            end
        end
        -- Item name
        local selectedName = vgui.Create("DLabel", itemText)
        selectedName:SetFont("Courier Big 1")
        selectedName:SetText(itemTable.name)
        selectedName:SetTextColor(fullBlack)
        selectedName:SetWrap(true)
        selectedName:SetAutoStretchVertical(true)
        selectedName:SetPos(interval * 0.2, 0.2)
        selectedName:SetWide(interval * 8.3)
        selectedName.Paint = function(self, w, h) end
        -- Item info
        local selectedDesc = vgui.Create("DLabel", itemText)
        selectedDesc:SetFont("Courier Small 1")
        selectedDesc:SetText(itemTable.desc)
        selectedDesc:SetTextColor(fullBlack)
        selectedDesc:SetWrap(true)
        selectedDesc:SetPos(interval * 0.1, interval * 2.4)
        selectedDesc:SetWide(interval * 8.5)
        selectedDesc:SetAutoStretchVertical(true)
        selectedDesc.Paint = function(self, w, h) end
        -- Sets up the cost panel
        local costList = vgui.Create("DPanel", itemPanel)
        costList:SetPos(interval * 9.25, interval * 0)
        costList:SetSize(interval * 2.5, interval * 4)
        local costTable = itemTable.cost
        local cost_i = 0
        local displayTable = {}
        for i, v in ipairs(craftingTable.materials) do
            if costTable[i] and costTable[i] > 0 then
                table.insert(displayTable, {cost = costTable[i], itemId = i})
                local costImage = vgui.Create("DImage", costList)
                costImage:SetPos(interval * 0.1, interval * cost_i)
                costImage:SetSize(interval, interval)
                costImage:SetImage(v)
                cost_i = cost_i + 1
            end
        end
        costList.Paint = function(self, w, h)
            draw.RoundedBox(interval * 0.2, 0, 0, w, h, outlineColor)
            draw.RoundedBox(interval * 0.2, 3, 3, w - 6, h - 6, panelFill)
            for i, v in ipairs(displayTable) do
                if v.cost <= playerCache.mats[v.itemId] then
                    draw.SimpleText(tostring(v.cost), "Courier Big 2", interval * 1.2, interval * (-0.5 + i), fullGreen, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText(tostring(v.cost), "Courier Big 2", interval * 1.2, interval * (-0.5 + i), fullRed, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            end
        end
        -- Item crafting
        local craftButton = vgui.Create("DImageButton", itemPanel)
        craftButton:SetPos(interval * 9, interval * 4)
        craftButton:SetSize(interval * 3, interval * 2)
        craftButton:SetImage("menu/craft.png")
        craftButton.Paint = function(self, w, h) 
            if self:IsHovered() then
                draw.RoundedBox(interval * 0.2, interval * 0.5, 0, w * 2 / 3, h, hoveredColor)
            end
        end
        function craftButton:DoClick()
            net.Start("CraftAttempt")
            net.WriteInt(catId, 16)
            net.WriteInt(itemId, 16)
            net.SendToServer()
        end
    else
        -- Reset toggle
        lastItemId = -1
    end
 end
 
-- Category selection
local function selectCat(catId, catTable)
    -- If there is an old items display, remove it
    if IsValid(catPanel) then
        catPanel:Remove()
    end
    -- If clicked on a new category, open the new category
    if lastCatId ~= catId and IsValid(craftingInner) then
        surface.PlaySound(itemSelect)
        lastCatId = catId
        lastItemId = -1
        catPanel = vgui.Create("DPanel", craftingInner)
        catPanel:SetPos(0, interval * 2.8)
        catPanel:SetSize(interval * 18, interval * 10.2)
        -- Draws each non-intersecting selection line
        catPanel.Paint = function(self, w, h)
            surface.SetDrawColor(fullWhite)
            for i = 1, 6 do
                local x_0 = interval * 0.2 * i + interval * 3 * catId - interval * 2.2
                local y_0 = 0
                local x_1 = interval * 2 * (i + 1)
                local y_1 = interval * 1.2 - math.abs(i - catId) * interval * 0.2
                local y_2 = interval * 1.4
                surface.DrawLine(x_0, y_0, x_0, y_1)
                surface.DrawLine(x_0, y_1, x_1, y_1)
                surface.DrawLine(x_1, y_1, x_1, y_2)
            end
        end
        for k, v in ipairs(catTable) do
            if type(v) == "table" then
                local itemButton = vgui.Create("DImageButton", catPanel)
                itemButton:SetPos(interval * 2 * (k + 0.5), interval * 1.2)
                itemButton:SetSize(interval * 2, interval * 2)
                itemButton:SetImage(v["image"])
                itemButton.Paint = function(self, w, h)
                    if lastItemId == k then
                        draw.RoundedBox(interval * 0.2, 0, 0, w, h, selectedColor)
                    elseif self:IsHovered() then
                        draw.RoundedBox(interval * 0.2, 0, 0, w, h, hoveredColor)
                    end
                end
                function itemButton:DoClick()
                    selectItem(k, v, catId)
                end
            end
        end
    else
        -- Reset toggle
        lastCatId = -1
    end
end

-- Open crafting menu
function toggleCrafting(toggle)
    
    if timer.Exists("togglebuffer") then
        return
    else
        timer.Create("togglebuffer", 0.1, 1, function() timer.Remove("togglebuffer") end)
    end

    -- Open a new crafting menu
    if toggle then
        toggleCraft = true
        lastCatId = -1
        lastItemId = -1

        -- Remove old crafting frame
        if IsValid(craftingPanel) then
            craftingPanel:Remove()
        end

        -- Close the training menu
        toggleTrain = false
        if IsValid(trainingPanel) then
            trainingPanel:Remove()
        end
        net.Start("TrainClosed")
        net.SendToServer()

        -- Page open sound
        surface.PlaySound(panelOpen)

        -- Main crafting frame
        craftingPanel = vgui.Create("DPanel")
        craftingPanel:SetSize(interval * 18.6, interval * 12.6)
        craftingPanel:Center()
        craftingPanel:MakePopup()
        craftingPanel:SetKeyboardInputEnabled(false)

        -- Background and scratch lines
        local linesTable = {}
        for i = 1, 100 do
            local lineTable = {math.random(0, craftingPanel:GetWide()), math.random(0, craftingPanel:GetTall())}
            table.insert(lineTable, lineTable[1] + math.random(-0.2 * interval, 0.2 * interval))
            table.insert(lineTable, lineTable[2] + math.random(0.5 * interval, 1.5 * interval))
            table.insert(linesTable, lineTable)
        end
        craftingPanel.Paint = function(self, w, h)
            draw.RoundedBox(interval * 0.2, 0, 0, w, h, outlineColor)
            draw.RoundedBox(interval * 0.2, interval * 0.06, interval * 0.06, w - interval * 0.12, h - interval * 0.12, textureColor)
            surface.SetDrawColor(outlineColor)
            for i = interval / 4 - 1, w, interval * 1.2 do
                surface.DrawLine(i - 1, 3, i - 1, h - 3)
                surface.DrawLine(i, 3, i, h - 3)
                surface.DrawLine(i + 1, 3, i + 1, h - 3)
            end
            surface.SetDrawColor(outlineColor)
            for k, v in ipairs(linesTable) do
                surface.DrawLine(v[1], v[2], v[3], v[4])
                surface.DrawLine(v[1] + 1, v[2], v[3] + 1, v[4])
            end
        end

        -- Makes a secondary panel so we don't have to worry about the border offsets
        craftingInner = vgui.Create("DPanel", craftingPanel)
        craftingInner:SetSize(interval * 18, interval * 12)
        craftingInner:Center()
        craftingInner.Paint = function(self, w, h) end

        -- Sets up the materials panel
        local matsList = vgui.Create("DPanel", craftingInner)
        matsList:SetPos(interval * 0.25, interval * 6)
        matsList:SetSize(interval * 2.5, interval * 6)
        matsList.Paint = function(self, w, h)
            draw.RoundedBox(interval * 0.2, 0, 0, w, h, outlineColor)
            draw.RoundedBox(interval * 0.2, 3, 3, w - 6, h - 6, panelFill)
            for i, v in ipairs(playerCache.mats or {"0", "0", "0", "0", "0", "0"}) do
                draw.SimpleText(tostring(v), "Courier Big 2", interval * 1.2, interval * (-0.5 + i), fullBlack, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        -- Makes each material image
        for i, v in ipairs(craftingTable.materials) do
            local materialImage = vgui.Create("DImage", matsList)
            materialImage:SetPos(interval * 0.1, interval * (i - 1))
            materialImage:SetSize(interval, interval)
            materialImage:SetImage(v)
        end

        -- Sets up the consumables panel
        local consumableList = vgui.Create("DPanel", craftingInner)
        consumableList:SetPos(interval * 15.25, interval * 6)
        consumableList:SetSize(interval * 2.5, interval * 6)
        consumableList.Paint = function(self, w, h)
            draw.RoundedBox(interval * 0.2, 0, 0, w, h, outlineColor)
            draw.RoundedBox(interval * 0.2, 3, 3, w - 6, h - 6, panelFill)
            for i, v in ipairs(playerCache.consumable or {"0", "0", "0", "0", "0", "0"}) do
                draw.SimpleText(tostring(v), "Courier Big 2", interval * 1.2, interval * (-0.5 + i), fullBlack, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        -- Makes each consumable image
        for i, v in ipairs(craftingTable.items[6]) do
            local consumableImage = vgui.Create("DImage", consumableList)
            consumableImage:SetPos(interval * 0.1, interval * (i - 1))
            consumableImage:SetSize(interval, interval)
            consumableImage:SetImage(v.image)
        end

        --Makes each category button
        for i, v in ipairs(craftingTable.items) do
            local categoryButton = vgui.Create("DImageButton", craftingInner)
            categoryButton:SetPos(interval * 3 * (i - 1), 0)
            categoryButton:SetSize(interval * 3, interval * 3)
            categoryButton:SetImage(v["image"])
            categoryButton.Paint = function(self, w, h)
                if lastCatId == i then
                    draw.RoundedBox(interval * 0.2, interval * 0.1, interval * 0.1, w - interval * 0.2, h - interval * 0.2, selectedColor)
                elseif self:IsHovered() then
                    draw.RoundedBox(interval * 0.2, interval * 0.1, interval * 0.1, w - interval * 0.2, h - interval * 0.2, hoveredColor)
                end
            end
            function categoryButton:DoClick()
                selectCat(i, v)
            end
        end
    -- Close any existing crafting menu
    else
        toggleCraft = false
        if IsValid(craftingPanel) then
            craftingPanel:Remove()
            surface.PlaySound(panelClose)
        end
    end
end

------------------------------------
--[[     MAIN TRAINING MENU     ]]--
------------------------------------

local lastStatId = -1
local statNames = {"Max Health", "Max Shield", "Ranged Strength", "Melee Strength", "Defense", "Speed & Jump"}

-- Opens the training menu
function toggleTraining(toggle)
    
    if timer.Exists("togglebuffer") then
        return
    else
        timer.Create("togglebuffer", 0.1, 1, function() timer.Remove("togglebuffer") end)
    end

    if toggle then
        toggleTrain = true

        -- Close the old training menu
        if IsValid(trainingPanel) then
            trainingPanel:Remove()
        end

        -- Remove the crafting frame
        toggleCraft = false
        if IsValid(craftingPanel) then
            craftingPanel:Remove()
        end

        -- Page open sound
        surface.PlaySound(panelOpen)

        -- Main crafting frame
        trainingPanel = vgui.Create("DPanel")
        trainingPanel:SetSize(interval * 11.4, interval * 8)
        trainingPanel:Center()
        trainingPanel:MakePopup()
        trainingPanel:SetKeyboardInputEnabled(false)

        -- Background and scratch lines
        local linesTable = {}
        for i = 1, 100 do
            local lineTable = {math.random(0, trainingPanel:GetWide()), math.random(0, trainingPanel:GetTall())}
            table.insert(lineTable, lineTable[1] + math.random(-0.2 * interval, 0.2 * interval))
            table.insert(lineTable, lineTable[2] + math.random(0.5 * interval, 1.5 * interval))
            table.insert(linesTable, lineTable)
        end
        trainingPanel.Paint = function(self, w, h)
            draw.RoundedBox(interval * 0.2, 0, 0, w, h, outlineColor)
            draw.RoundedBox(interval * 0.2, interval * 0.06, interval * 0.06, w - interval * 0.12, h - interval * 0.12, textureColor)
            surface.SetDrawColor(outlineColor)
            for i = interval / 4 - 1, w, interval * 1.2 do
                surface.DrawLine(i - 1, 3, i - 1, h - 3)
                surface.DrawLine(i, 3, i, h - 3)
                surface.DrawLine(i + 1, 3, i + 1, h - 3)
            end
            surface.SetDrawColor(outlineColor)
            for k, v in ipairs(linesTable) do
                surface.DrawLine(v[1], v[2], v[3], v[4])
                surface.DrawLine(v[1] + 1, v[2], v[3] + 1, v[4])
            end
        end

        -- Sets up the header instructions
        local trainingHeader = vgui.Create("DPanel", trainingPanel)
        trainingHeader:SetPos(interval * 0.2, interval * 0.2)
        trainingHeader:SetSize(interval * 11, interval * 1.3)
        trainingHeader.Paint = function(self, w, h)
            draw.RoundedBox(interval * 0.2, 0, 0, w, h, outlineColor)
            draw.RoundedBox(interval * 0.2, 3, 3, w - 6, h - 6, panelFill)
        end
        -- Header instructions
        local trainingDesc = vgui.Create("DLabel", trainingHeader)
        trainingDesc:SetFont("Courier Small 1")
        trainingDesc:SetText("Select a stat to begin training")
        trainingDesc:SetTextColor(fullBlack)
        trainingDesc:SetWrap(true)
        trainingDesc:SetPos(interval * 0.1, interval * 0.1)
        trainingDesc:SetSize(interval * 10.8, interval * 1)
        trainingDesc.Paint = function(self, w, h) end
        -- Stat panels
        for i = 1, 6 do
            local statPanel = vgui.Create("DPanel", trainingPanel)
            statPanel:SetPos(interval * 0.2, interval * (0.7 + i))
            statPanel:SetSize(interval * 11, interval)
            statPanel.Paint = function(self, w, h)
                surface.SetDrawColor(fullBlack)
                surface.DrawRect(interval * 4, h / 4, interval * 7 * playerCache.stats[i] / 50, h / 2)
                surface.SetDrawColor(statFill)
                surface.DrawRect(interval * 4 - 3, h / 4 + 3, interval * 7 * playerCache.stats[i] / 50, h / 2 - 6)
                draw.SimpleText(math.floor(playerCache.stats[i]), "Courier Small 2", interval * (4 + 7 * playerCache.stats[i] / 50) - 5, h / 2, fullBlack, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            local statButton = vgui.Create("DButton", statPanel)
            statButton:SetPos(0, interval * 0.1)
            statButton:SetSize(interval * 4, interval * 0.8)
            statButton:SetText("")
            statButton.Paint = function(self, w, h)
            draw.RoundedBox(interval * 0.2, 0, 0, w, h, outlineColor)
            draw.RoundedBox(interval * 0.2, 3, 3, w - 6, h - 6, statFill)
            draw.SimpleText(statNames[i], "Courier Small 3", w / 2, h / 2, fullBlack, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            function statButton:DoClick()
                net.Start("TrainAttempt")
                net.WriteInt(i, 16)
                net.SendToServer()
            end
        end
    else
        -- Close the training menu
        toggleTrain = false
        if IsValid(trainingPanel) then
            trainingPanel:Remove()
            surface.PlaySound(panelClose)
        end
        net.Start("TrainClosed")
        net.SendToServer()
    end
    -- When training closes, send a net message to the server
end

---------------------------------------
--[[     MAIN CONSUMABLES MENU     ]]--
---------------------------------------

local panelWidth = 12
local itemWidth = 3
function toggleConsumables(toggle)
    if toggle then
        -- Close the consumable menu
        if IsValid(consumablesPanel) then
            consumablesPanel:Remove()
        end

        -- Main panel
        consumablesPanel = vgui.Create("DPanel")
        consumablesPanel:SetSize(interval * panelWidth, interval * panelWidth)
        consumablesPanel:Center()
        consumablesPanel:MakePopup()
        consumablesPanel:SetKeyboardInputEnabled(false)
        consumablesPanel.Paint = function(self, w, h) end

        -- Consumable buttons
        for i = 1, 6 do
            local consumable = vgui.Create("DButton", consumablesPanel)
            consumable:SetSize(interval * itemWidth, interval * itemWidth)
            consumable:SetPos((math.cos(math.pi * (i - 1) / 3) * (panelWidth - itemWidth) / 2 + (panelWidth - itemWidth) / 2) * interval, (math.sin(math.pi * (i - 1) / 3) * (panelWidth - itemWidth) / 2 + (panelWidth - itemWidth) / 2) * interval)
            consumable:SetText("")
            consumable.Paint = function(self, w, h)
                draw.RoundedBox(interval, 0, 0, w, h, partialBlack)
                --draw.RoundedBox(interval, 5, 5, w - 10, h - 10, panelFill)
            end
            function consumable:DoClick()
                net.Start("ConsumeAttempt")
                net.WriteInt(i, 16)
                net.SendToServer()
            end
            local consumableImage = vgui.Create("DImage", consumable)
            consumableImage:SetPos(consumable:GetWide() * 0.1, consumable:GetTall() * 0.1)
            consumableImage:SetSize(consumable:GetWide() * 0.8, consumable:GetTall() * 0.8)
            consumableImage:SetImage(craftingTable.items[6][i].image)
        end
    else
        -- Close the consumable menu
        if IsValid(consumablesPanel) then
            consumablesPanel:Remove()
        end
    end
end

-- Intro page titles
local titleText = {
    "Battle Boss Battle",
    "Crafting",
    "Loadouts",
    "Battle",
    "Armageddon",
    "Scoring",
    "Battle Boss",
    "Crafting",
    "Battle and Armageddon",
}

-- Intro page bodies
local bodyText = {
    "In this three-round fight, you start with nothing and fight your way to claiming the title of the Battle Boss!\n\nPrepare your loadout in the Crafting Round, compete for domination in the Battle Round, and fight for your life in the Amargeddon Round.\n\nShould you outperform all others, you will be crowned Battle Boss!",
    "During the Crafting Round, punch props to gain raw materials. With these, you can craft up to five different equipment pieces and stock up on six types of consumables to use during the Battle Round.\n\nIn addition, you can also train six different skills to raise your stats,\n\nOnce the Battle Round begins, you'll receive your loadout!",
    "Each equipment slot has six items to choose from. Mix and match as you please, but if you craft five items of the same class, you'll unlock extra buffs!\n\nAside from the six main classes, there are four secret classes that you just might be able to unlock if you experiment during the Crafting Round!",
    "When the Battle Round starts, you'll receive your loadout to start fighting.\n\nYou can join the brawl against the powerful Battle Boss or take advantage of the chaos to strike other players!\n\nYour shield will absorb any damage you take, but if you're not careful your enemies might break through!",
    "When the Armageddon Round begins, an ever-increasing toxicity will take over the battlefield, slowly killing everyone and destroying the obstacles.\n\nSurvive for as long as you can in this final showdown! The last player standing will receive a big point bonus!",
    "After the fighting is all over, the crowning of the next Battle Boss will take place.\n\nYour score - determined by how much you collected, crafted and trained, how many players you killed and eliminated, how long you survived, and more, will be used to find a winner.\n\nIf you win, you will be crowned Battle Boss!",
    "As the Battle Boss, all of your stats will be increased: Health, Shield, Strength, Defense, Speed, and Jumping Power.\n\nYou will receive special weapons and special abilities. You will have a different role to take on in the game.\n\nIt's your chance to show everyone why you're the Battle Boss!",
    "In the Crafting Round, you have a Slap Bat which will let you launch players away from their materials, and an Energy Zapper to destroy materials.\n\nYou also get the Gravity Toss to throw players around and the Slowness Beam to stop them in their tracks.\n\nDo everything you can to slow down their progress!",
    "In the Battle and Armageddon Rounds, you have an upgraded Smack Bat and Energy Burster to attack players and destroy any obstacles they hide behind!\n\nYour abilities are also upgraded to Gravity Pummel and the Death Beam to help you conquer the battlefield.\n\nIt's your time to shine!",
}

local playerModels = {
    "Random Model",
    "Citizen 1",
    "Citizen 2",
    "Citizen 3",
    "Citizen 4",
    "Citizen 5",
    "Citizen 6",
    "Citizen 7",
    "Citizen 8",
    "Rebel 1",
    "Rebel 2",
    "Rebel 3",
    "Rebel 4",
    "Rebel 5",
    "Rebel 6",
    "Rebel 7",
    "Rebel 8",
}

local f1Width = 700
local f1Height = 500
function toggleF1Menu(toggle)

    if timer.Exists("f1buffer") then
        return
    else
        timer.Create("f1buffer", 0.1, 1, function() timer.Remove("f1buffer") end)
    end

    if toggle then
        toggleF1 = true
        -- Close the old f1 menu
        if IsValid(f1Panel) then
            f1Panel:Remove()
        end

        -- Main panel
        f1Panel = vgui.Create("DPanel")
        f1Panel:SetSize(f1Width + 20, f1Height + 20)
        f1Panel:Center()
        f1Panel:MakePopup()
        f1Panel:SetKeyboardInputEnabled(false)
        f1Panel.Paint = function(self, w, h)
            draw.RoundedBox(20, 0, 0, w, h, lightGrey)
        end

        -- Inner panel
        local f1Inner = vgui.Create("DPanel", f1Panel)
        f1Inner:SetSize(f1Width, f1Height)
        f1Inner:Center()
        f1Inner.Paint = function(self, w, h)
            draw.RoundedBox(15, 0, 0, w, h, lightBlue)
        end

        -- Close button
        local f1Close = vgui.Create("DImageButton", f1Inner)
        f1Close:SetSize(16, 16)
        f1Close:SetPos(f1Width * 0.98 - 16, 5)
        f1Close.Paint = function(self, w, h)
            draw.RoundedBox(3, 0, 0, w, h, solidGrey)
        end
        f1Close:SetImage("icon16/cross.png")
        function f1Close:DoClick()
            toggleF1 = false
            -- Close the old f1 menu
            if IsValid(f1Panel) then
                f1Panel:Remove()
            end
        end

        -- Tabs
        local f1Tabs = vgui.Create("DPropertySheet", f1Inner)
        f1Tabs:SetSize(f1Width * 0.96, f1Height * 0.93)
        f1Tabs:SetPos(f1Width * 0.02, f1Height * 0.05)
        local tabsWidth = f1Width * 0.96
        local tabsHeight = f1Height * 0.93

        -- Intro tab
        local f1Intro = vgui.Create("DPanel", f1Tabs)
        local introPage = 1
        f1Tabs:AddSheet("Intro", f1Intro, "icon16/comments.png")
        f1Intro:SetSize(tabsWidth, tabsHeight)
        f1Intro.Paint = function(self, w, h)
            draw.RoundedBox(5, 0, h * 0.1, w, h * 0.9, solidBlack)
        end

        local titles = {}
        local bodies = {}

        -- Ceates the intro pages
        for i = 1, #titleText do
            -- Intro page content
            local introTitle = vgui.Create("DLabel", f1Intro)
            introTitle:SetWide(tabsWidth * 0.94)
            introTitle:SetAutoStretchVertical(true)
            introTitle:SetPos(tabsWidth * 0.03, tabsHeight * 0.12)
            introTitle:SetFont("F1 Menu 2")
            introTitle:SetText(titleText[i])
            introTitle:SetTextColor(solidWhite)
            introTitle:SetWrap(true)
            table.insert(titles, introTitle)
            local introBody = vgui.Create("DLabel", f1Intro)
            introBody:SetWide(tabsWidth * 0.94)
            introBody:SetAutoStretchVertical(true)
            introBody:SetPos(tabsWidth * 0.03, tabsHeight * 0.24)
            introBody:SetFont("F1 Menu 1")
            introBody:SetText(bodyText[i])
            introBody:SetTextColor(solidWhite)
            introBody:SetWrap(true)
            table.insert(bodies, introBody)
            if i != introPage then
                introTitle:Hide()
                introBody:Hide()
            end
        end

        -- Moves to the previous page
        local leftButton = vgui.Create("DButton", f1Intro)
        leftButton:SetSize(tabsWidth * 0.15, tabsHeight * 0.08)
        leftButton:SetPos(tabsWidth * 0.25, 0)
        leftButton:SetTextColor(solidWhite)
        leftButton:SetText("Previous")
        leftButton.Paint = function(self, w, h)
            draw.RoundedBox(5, 0, 0, w, h, solidGrey)
        end
        function leftButton:DoClick()
            if introPage > 1 then
                titles[introPage]:Hide()
                bodies[introPage]:Hide()
                introPage = introPage - 1
                titles[introPage]:Show()
                bodies[introPage]:Show()
            end
        end

        -- Tells which page is up
        local pageLabel = vgui.Create("DPanel", f1Intro)
        pageLabel:SetSize(tabsWidth * 0.1, tabsHeight * 0.08)
        pageLabel:SetPos(tabsWidth * 0.45, 0)
        pageLabel.Paint = function(self, w, h)
            draw.SimpleText(tostring(introPage).." / "..tostring(#titleText), "F1 Menu 1", w / 2, h / 2, solidBlack, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Moves to the next page
        local rightButton = vgui.Create("DButton", f1Intro)
        rightButton:SetSize(tabsWidth * 0.15, tabsHeight * 0.08)
        rightButton:SetPos(tabsWidth * 0.6, 0)
        rightButton:SetTextColor(solidWhite)
        rightButton:SetText("Next")
        rightButton.Paint = function(self, w, h)
            draw.RoundedBox(5, 0, 0, w, h, solidGrey)
        end
        function rightButton:DoClick()
            if introPage < #titleText then
                titles[introPage]:Hide()
                bodies[introPage]:Hide()
                introPage = introPage + 1
                titles[introPage]:Show()
                bodies[introPage]:Show()
            end
        end

        -- Settings tab
        local f1Settings = vgui.Create("DPanel", f1Tabs)
        f1Tabs:AddSheet("Settings", f1Settings, "icon16/wrench.png")
        f1Settings.Paint = function(self, w, h) end

        -- Settings panel
        local settingsPanel = vgui.Create("DPanel", f1Settings)
        settingsPanel:Dock(BOTTOM)
        settingsPanel:SetTall(tabsHeight * 0.9)
        settingsPanel.Paint = function(self, w, h)
            draw.RoundedBox(5, 0, 0, w, h, solidGrey)
        end
        local settingsWidth = settingsPanel:GetWide()
        local settingsHeight = settingsPanel:GetTall()

        -- Default model label
        local modelLabel = vgui.Create("DLabel", settingsPanel)
        modelLabel:SetWide(500)
        modelLabel:SetAutoStretchVertical(true)
        modelLabel:SetPos(25, 25)
        modelLabel:SetFont("F1 Menu 3")
        modelLabel:SetTextColor(solidWhite)
        modelLabel:SetText("Default playermodel")
        modelLabel:SetWrap(true)

        -- Default model choice
        local modelChoice = vgui.Create("DComboBox", settingsPanel)
        modelChoice:SetSize(250, 25)
        modelChoice:SetPos(25, 50)
        modelChoice:SetValue(playerCache.defaultModel)
        for k, v in ipairs(playerModels) do
            modelChoice:AddChoice(v)
        end
        modelChoice.OnSelect = function(self, index, value)
            playerCache.defaultModel = playerModels[index]
            net.Start("DefaultModelChoice")
            net.WriteInt(index - 1, 16)
            net.SendToServer()
        end

        -- Default model label
        local transitionLabel = vgui.Create("DLabel", settingsPanel)
        transitionLabel:SetWide(500)
        transitionLabel:SetAutoStretchVertical(true)
        transitionLabel:SetPos(50, 97)
        transitionLabel:SetFont("F1 Menu 3")
        transitionLabel:SetTextColor(solidWhite)
        transitionLabel:SetText("Play a ding when the round changes")
        transitionLabel:SetWrap(true)

        -- Toggle round transition noises
        local transitionCheck = vgui.Create("DCheckBox", settingsPanel)
        transitionCheck:SetPos(25, 100)
        transitionCheck:SetValue(playerCache.playTransitions)
        function transitionCheck:OnChange(bool)
            playerCache.playTransitions = bool
        end

        -- Toggle music label
        local songsLabel = vgui.Create("DLabel", settingsPanel)
        songsLabel:SetWide(500)
        songsLabel:SetAutoStretchVertical(true)
        songsLabel:SetPos(50, 147)
        songsLabel:SetFont("F1 Menu 3")
        songsLabel:SetTextColor(solidWhite)
        songsLabel:SetText("Play music in Crafting and Battle")
        songsLabel:SetWrap(true)

        -- Toggle round transition noises
        local songsCheck = vgui.Create("DCheckBox", settingsPanel)
        songsCheck:SetPos(25, 150)
        songsCheck:SetValue(playerCache.playSongs)
        function songsCheck:OnChange(bool)
            playerCache.playSongs = bool
        end

        -- Music volume label
        local volumeLabel = vgui.Create("DLabel", settingsPanel)
        volumeLabel:SetWide(500)
        volumeLabel:SetAutoStretchVertical(true)
        volumeLabel:SetPos(25, 197)
        volumeLabel:SetFont("F1 Menu 3")
        volumeLabel:SetTextColor(solidWhite)
        volumeLabel:SetText("Adjust the volume of the music")
        volumeLabel:SetWrap(true)

        -- Music volume slider
        local volumeSlider = vgui.Create("DNumSlider", settingsPanel)
        volumeSlider:SetPos(-390, 180)
        volumeSlider:SetSize(1000, 100)
        volumeSlider:SetMin(0)
        volumeSlider:SetMax(100)
        volumeSlider:SetValue(playerCache.songVolume * 100)
        volumeSlider:SetDecimals(0)
        volumeSlider.OnValueChanged = function( self, value )
            playerCache.songVolume = math.Clamp(value / 100, 0, 1)
        end

        -- Spectate label
        local spectateLabel = vgui.Create("DLabel", settingsPanel)
        spectateLabel:SetWide(500)
        spectateLabel:SetAutoStretchVertical(true)
        spectateLabel:SetPos(50, 247)
        spectateLabel:SetFont("F1 Menu 3")
        spectateLabel:SetTextColor(solidWhite)
        spectateLabel:SetText("Spectate only")
        spectateLabel:SetWrap(true)

        -- Toggle round transition noises
        local spectateCheck = vgui.Create("DCheckBox", settingsPanel)
        spectateCheck:SetPos(25, 250)
        spectateCheck:SetValue(playerCache.spectateOnly)
        function spectateCheck:OnChange(bool)
            playerCache.spectateOnly = bool
            net.Start("TogglePlayable")
            net.WriteBool(bool)
            net.SendToServer()
        end
    else
        toggleF1 = false
        -- Close the f1 menu
        if IsValid(f1Panel) then
            f1Panel:Remove()
            -- Play sound?
        end
    end
end

---------------------------------
--[[     MENU NETWORKING     ]]--
---------------------------------

net.Receive("CraftResult", function(len)
    if net.ReadBool() then
        surface.PlaySound(craftSuccess)
        local catId = net.ReadInt(16)
        local itemId = net.ReadInt(16)
        if catId and itemId then
            LocalPlayer():ChatPrint("Successfully crafted: "..craftingTable.items[catId][itemId].name)
        end
        if catId != 6 and IsValid(catPanel) then
            catPanel:Remove()
            lastCatId = -1
        end
    else
        surface.PlaySound(failure)
        LocalPlayer():ChatPrint(net.ReadString())
    end
end)

net.Receive("TrainResult", function(len)
    if not net.ReadBool() then
        surface.PlaySound(failure)
        LocalPlayer():ChatPrint(net.ReadString())
    end
end)

net.Receive("ConsumeResult", function(len)
    if net.ReadBool() then
        surface.PlaySound(consumeSuccess)
        LocalPlayer():ChatPrint("Successfully consumed: "..craftingTable.items[6][net.ReadInt(16)].name)
    else
        surface.PlaySound(failure)
        LocalPlayer():ChatPrint(net.ReadString())
    end
end)