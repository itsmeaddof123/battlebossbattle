-- This file handles the spawning of material entities via the navmesh

navCenters = navCenters or {}
spawnedMaterials = spawnedMaterials or {}
minDistance = minDistance or 1500
minNavs = minNavs or 100

-- Types of material entities
local materials = {
    "bbb_essence",
    "bbb_stone",
    "bbb_fur",
    "bbb_metal",
    "bbb_wood",
    "bbb_water",
}

function InitializeSpawns(retrying)

    if #navCenters >= minNavs then return end

    local allNavs = navmesh.GetAllNavAreas()

    if not allNavs then
        if timer.Exists("waitfornavmesh") then return end
        timer.Create("waitfornavmesh", 3, 0, function()
            InitializeSpawns()
        end)
        return
    else
        timer.Remove("waitfornavmesh")
    end

    navCenters = {}

    -- If this isn't the first attempt, lower the minimum distance between CNavAreas
    if retrying then
        if minDistance >= 500 then
            minNavs = minNavs - 3
            minDistance = minDistance - 100
        elseif minDistance >= 100 then
            print("This map may be too small for the game!")
            minDistance = minDistance - 100
            minNavs = minNavs - 5
        else
            print("This map isn't suitable for the game!")
            return
        end
        print("Reducing min dist between navs to "..tostring(minDistance).." and min navs to "..tostring(minNavs))
    end

    -- Checks ever CNavArea on the map
    for i, possibleNav in ipairs(allNavs) do
        if not possibleNav:IsUnderwater() then
            local suitable = true
            -- Compares each one to each CNavArea already in navCenters
            for j, suitableCenter in ipairs(navCenters) do
                -- If it's far enough from the rest, add it to navCenters
                if possibleNav:GetCenter():Distance(suitableCenter) <= minDistance then
                    suitable = false
                end
            end
            if suitable then
                table.insert(navCenters, possibleNav:GetCenter())
                -- Once we have enough navs we can end the loop
                if #navCenters >= minNavs then
                    break 
                end
            end
        end
    end

    print(tostring(#navCenters).."/"..tostring(minNavs).." needed nav centers found")
    if #navCenters < minNavs then
        timer.Simple(0.25, function() InitializeSpawns(true) end)
    end
end

-- Prevents a round from starting before the suitable navs are chosen
function SpawnsSelected()
    return #navCenters == minNavs
end

-- Each entity has a different average material output. Because of this, we want more of certain entities to spawn.
-- We can calculate that with the following algorithm

-- The average number of materials per entity, calculated from each respective entity script
-- Numbers added on reduce the frequency of material spawning for balancing
local matsPerEnt = {
    bbb_essence = 1.2 + 0.15,
    bbb_stone = 2.2,
    bbb_fur = 1.85,
    bbb_metal = 2.5 - 0.25,
    bbb_wood = 1.75,
    bbb_water = 1.55,
}

-- Uses for calculations
local totalPerEnt = 0
for k, v in pairs(matsPerEnt) do
    totalPerEnt = totalPerEnt + v
end

-- Weights material distributions
local weightedMats = {}
for k, v in pairs(matsPerEnt) do
    weightedMats[k] = totalPerEnt / v
end

-- Total weight
local totalWeight = 0
for k, v in pairs(weightedMats) do
    totalWeight = totalWeight + v
end

-- Spawns materials randomly in the region based on how many players there are
local function SpawnRegion(navCenter, matName, numberOfEnts)
    -- Gets nearby navmeshes
    local navTable = navmesh.Find(navCenter, minDistance / 1.5, 250, 100)
    while numberOfEnts >= 1 and #navTable >= 1 do
        numberOfEnts = numberOfEnts - 1
        local navKey = math.random(1, #navTable)
        local nav = navTable[navKey]
        -- Remove smaller navs so they don't get picked again
        if nav:GetSizeX() < 100 then table.remove(navTable, navKey) end
        local spawnPoint = nav:GetRandomPoint()
        local mat = ents.Create(matName)
        if IsValid(mat) then
            table.insert(spawnedMaterials, mat)
            mat:SetPos(spawnPoint)
            mat:Spawn()
        end
    end

    -- Spawn an obstacle entity once those are made along with the region?
end

-- Starts the loop to spawn all the materials
function SpawnMaterials()
    -- Removes old materials
    RemoveMaterials()
    local numberOfEnts = math.Clamp(math.ceil(BBB.estimatedPlaying), 6, 10)
    for i, navCenter in ipairs(navCenters) do
        -- Picks a random material to spawn using a weighted algorithm
        local loopTotal = totalWeight
        local chosenWeight = math.random(0, loopTotal)
        for mat, weight in pairs(weightedMats) do
            loopTotal = loopTotal - weight
            if chosenWeight >= loopTotal then
                -- Delays the spawning of each region to prevent a lag spike
                timer.Simple(i * 0.1, function() SpawnRegion(navCenter, mat, numberOfEnts) end)
                break
            end
        end
    end
end

function RemoveMaterials()
    for i, v in ipairs(spawnedMaterials) do
        if IsValid(v) then
            v:Remove()
        end
    end
    spawnedMaterials = {}
end