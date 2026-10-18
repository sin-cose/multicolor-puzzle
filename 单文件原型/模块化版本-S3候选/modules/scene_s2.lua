local Scene = {}

local COLORS = {
    abyss = { 5, 6, 9 },
    land = { 129, 163, 219 },
    landEdge = { 158, 184, 227 },
    bridge = { 175, 123, 37 },
    bridgePlank = { 156, 109, 34 },
    cliff = { 52, 55, 61 },
    cliffDark = { 42, 45, 50 },
    cliffLight = { 99, 102, 108 },
    boardRim = { 180, 181, 183 },
    boardShadow = { 32, 33, 37 },
    s1Road = { 129, 163, 219 },
    s1RoadEdge = { 142, 172, 217 },
    s1Field = { 52, 55, 61 },
    s1FieldDark = { 41, 44, 50 },
    s1FieldLine = { 63, 66, 72 },
    s1GrassDark = { 100, 120, 82 },
    s1GrassLight = { 142, 162, 110 },
    s1Stone = { 105, 113, 119 },
    s1StoneLight = { 157, 164, 165 },
}

local function addRect(runtime, createRect, name, left, top, width, height, color)
    local control = createRect(name, left, top, width, height, color)
    runtime.sceneArt[#runtime.sceneArt + 1] = control
    return control
end

local function addScene1Rect(runtime, createRect, name, left, top, width, height, color)
    local control = createRect(name, left, top, width, height, color)
    runtime.scene1Art[#runtime.scene1Art + 1] = control
    return control
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function scene1RoadShape(config, xRatio)
    local p = config.scene1
    local taper = clamp((xRatio - p.roadTaperStartRatio) / (1 - p.roadTaperStartRatio), 0, 1)
    local center = p.roadCenterStartRatio + (p.roadCenterEndRatio - p.roadCenterStartRatio) * taper
    local half = p.roadHalfStartRatio + (p.roadHalfEndRatio - p.roadHalfStartRatio) * taper
    return center, half
end

local function addScene1Grass(runtime, createRect, index, xRatio, yRatio, scale, flip)
    local dir = flip and -1 or 1
    local stemWidth = 0.0042 * scale
    local stemHeight = 0.030 * scale
    local base = yRatio + 0.009 * scale
    addScene1Rect(runtime, createRect, "S1_Grass_" .. tostring(index) .. "_A",
        xRatio - 0.006 * dir * scale, base - stemHeight, stemWidth, stemHeight, COLORS.s1GrassDark)
    addScene1Rect(runtime, createRect, "S1_Grass_" .. tostring(index) .. "_B",
        xRatio + 0.002 * dir * scale, base - stemHeight * 1.18, stemWidth, stemHeight * 1.18, COLORS.s1GrassLight)
    addScene1Rect(runtime, createRect, "S1_Grass_" .. tostring(index) .. "_C",
        xRatio + 0.009 * dir * scale, base - stemHeight * 0.78, stemWidth * 0.8, stemHeight * 0.78, COLORS.s1GrassDark)
end

local function addScene1Stone(runtime, createRect, index, xRatio, yRatio, scale)
    local width = 0.020 * scale
    local height = 0.014 * scale
    addScene1Rect(runtime, createRect, "S1_Stone_" .. tostring(index),
        xRatio - width * 0.5, yRatio - height * 0.5, width, height, COLORS.s1Stone)
    addScene1Rect(runtime, createRect, "S1_Stone_" .. tostring(index) .. "_Highlight",
        xRatio - width * 0.30, yRatio - height * 0.42, width * 0.52, height * 0.40,
        COLORS.s1StoneLight)
end

function Scene.BuildScene1(runtime, config, createRect)
    runtime.scene1Art = {}
    addScene1Rect(runtime, createRect, "S1_Field", 0, 0, 1, 1, COLORS.s1Field)
    addScene1Rect(runtime, createRect, "S1_FieldTop", 0, 0, 1, 0.167, COLORS.s1FieldDark)
    addScene1Rect(runtime, createRect, "S1_FieldBottom", 0, 0.833, 1, 0.167, COLORS.s1FieldDark)
    for index = 1, 4 do
        local y = 0.038 + (index - 1) * 0.042
        addScene1Rect(runtime, createRect, "S1_TopStrata_" .. tostring(index), 0, y, 1, 0.004, COLORS.s1FieldLine)
        addScene1Rect(runtime, createRect, "S1_BottomStrata_" .. tostring(index), 0, 0.858 + (index - 1) * 0.042,
            1, 0.004, COLORS.s1FieldLine)
    end

    local segmentCount = 32
    for index = 1, segmentCount do
        local left = (index - 1) / segmentCount
        local width = 1 / segmentCount + 0.001
        local center, half = scene1RoadShape(config, left + width * 0.5)
        local top = center - half
        local bottom = center + half
        addScene1Rect(runtime, createRect, "S1_Road_" .. tostring(index), left, top, width, bottom - top, COLORS.s1Road)
        addScene1Rect(runtime, createRect, "S1_RoadTopEdge_" .. tostring(index), left, top, width, 0.007, COLORS.s1RoadEdge)
        addScene1Rect(runtime, createRect, "S1_RoadBottomEdge_" .. tostring(index), left, bottom - 0.007, width, 0.007, COLORS.s1RoadEdge)
        local cliffHeight = math.min(0.13, 1 - bottom)
        if cliffHeight > 0 then
            addScene1Rect(runtime, createRect, "S1_CliffFace_" .. tostring(index), left, bottom, width, cliffHeight, COLORS.s1Field)
            addScene1Rect(runtime, createRect, "S1_CliffLip_" .. tostring(index), left, bottom, width, 0.009, COLORS.cliffLight)
        end
    end

    local grass = {
        { 0.056, -0.142, 1.24, false }, { 0.166, 0.140, 1.04, true },
        { 0.269, -0.173, 1.32, false }, { 0.378, 0.162, 1.08, true },
        { 0.494, -0.147, 1.14, false }, { 0.597, 0.158, 1.10, true },
        { 0.688, -0.125, 1.06, false }, { 0.803, 0.100, 0.92, true },
        { 0.906, -0.084, 0.86, false },
    }
    for index, item in ipairs(grass) do
        local center, half = scene1RoadShape(config, item[1])
        addScene1Grass(runtime, createRect, index, item[1], center + item[2], item[3], item[4])
    end

    local stones = {
        { 0.106, -0.076, 1.02 }, { 0.219, 0.080, 1.12 }, { 0.341, -0.047, 0.84 },
        { 0.450, 0.107, 0.96 }, { 0.547, -0.078, 1.04 }, { 0.647, 0.064, 0.90 },
        { 0.753, -0.062, 0.82 }, { 0.856, 0.053, 0.76 }, { 0.947, -0.038, 0.68 },
    }
    for index, item in ipairs(stones) do
        local center = scene1RoadShape(config, item[1])
        addScene1Stone(runtime, createRect, index, item[1], center + item[2], item[3])
    end

    for _, control in ipairs(runtime.scene1Art) do control:SetVisible(false) end
end

function Scene.SetScene1Visible(runtime, visible)
    for _, control in ipairs(runtime.scene1Art or {}) do
        if control and control.alive then control:SetVisible(visible) end
    end
end

function Scene.Build(runtime, config, createRect)
    runtime.sceneArt = {}
    local p = config.scene2
    local cliffWidths = { 0.9, 1.1, 0.8, 1.05, 0.95, 1.12, 0.86, 1.08, 0.92, 1.04, 0.84, 1.14, 0.94, 1.0 }
    local cliffHeights = { 0.055, 0.082, 0.061, 0.094, 0.068, 0.088, 0.052, 0.091, 0.063, 0.084, 0.057, 0.096, 0.066, 0.079 }
    local segmentWidth = 0.69 / #cliffWidths

    addRect(runtime, createRect, "S2_Abyss", 0, 0, 1, 1, COLORS.abyss)

    -- The narrow vertical face and stepped lower edge make the land read as a raised platform.
    addRect(runtime, createRect, "S2_MainCliffSide", 0.25, 0.20, 0.02, 0.59, COLORS.cliffDark)
    addRect(runtime, createRect, "S2_MainCliffFace", 0.27, 0.78, 0.69, 0.10, COLORS.cliff)
    addRect(runtime, createRect, "S2_MainCliffLip", 0.27, 0.775, 0.69, 0.005, COLORS.cliffLight)
    for index, widthFactor in ipairs(cliffWidths) do
        local left = 0.27 + (index - 1) * segmentWidth
        local shade = index % 2 == 0 and COLORS.cliffDark or COLORS.cliff
        addRect(runtime, createRect, "S2_CliffTooth_" .. tostring(index), left, 0.86,
            segmentWidth * widthFactor, cliffHeights[index], shade)
    end

    addRect(runtime, createRect, "S2_StartCliffFace", 0.04, 0.53, 0.16, 0.055, COLORS.cliff)
    local startToothHeights = { 0.045, 0.07, 0.052, 0.08, 0.048, 0.068, 0.055 }
    for index, height in ipairs(startToothHeights) do
        local segmentWidth = 0.16 / #startToothHeights
        local shade = index % 2 == 0 and COLORS.cliffDark or COLORS.cliff
        addRect(runtime, createRect, "S2_StartCliffTooth_" .. tostring(index),
            0.04 + (index - 1) * segmentWidth, 0.575, segmentWidth + 0.001, height, shade)
    end

    addRect(runtime, createRect, "S2_MainLand", 0.27, 0.20, 0.69, 0.59, COLORS.land)
    addRect(runtime, createRect, "S2_MainLandEdge", 0.27, 0.20, 0.69, 0.006, COLORS.landEdge)
    addRect(runtime, createRect, "S2_StartLand", 0.04, 0.39, 0.16, 0.14, COLORS.land)
    addRect(runtime, createRect, "S2_StartLandEdge", 0.04, 0.39, 0.16, 0.006, COLORS.landEdge)

    local bridgeHeight = p.boardHeightRatio / config.puzzle.rows
    local bridgeTop = p.bridgeCenterYRatio - bridgeHeight * 0.5
    addRect(runtime, createRect, "S2_Bridge", p.bridgeStartXRatio, bridgeTop,
        p.bridgeWidthRatio, bridgeHeight, COLORS.bridge)
    for index = 1, 3 do
        local plankX = p.bridgeStartXRatio + p.bridgeWidthRatio * index / 4
        addRect(runtime, createRect, "S2_BridgePlank_" .. tostring(index), plankX - 0.0007,
            bridgeTop, 0.0014, bridgeHeight, COLORS.bridgePlank)
    end

    local rim = 0.003
    addRect(runtime, createRect, "S2_PuzzleShadow", p.boardLeftRatio - rim * 1.5,
        p.boardTopRatio - rim * 2, p.boardWidthRatio + rim * 3,
        p.boardHeightRatio + rim * 4, COLORS.boardShadow)
    addRect(runtime, createRect, "S2_PuzzleRim", p.boardLeftRatio - rim,
        p.boardTopRatio - rim, p.boardWidthRatio + rim * 2,
        p.boardHeightRatio + rim * 2, COLORS.boardRim)

    for _, control in ipairs(runtime.sceneArt) do control:SetVisible(false) end
end

function Scene.SetVisible(runtime, visible)
    for _, control in ipairs(runtime.sceneArt or {}) do
        if control and control.alive then control:SetVisible(visible) end
    end
end

return Scene
