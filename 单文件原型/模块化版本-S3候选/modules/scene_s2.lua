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
}

local function addRect(runtime, createRect, name, left, top, width, height, color)
    local control = createRect(name, left, top, width, height, color)
    runtime.sceneArt[#runtime.sceneArt + 1] = control
    return control
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
