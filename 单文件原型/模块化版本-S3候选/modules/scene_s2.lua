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
    s1Land = { 129, 163, 219 },
    s1LandEdge = { 158, 184, 227 },
    s1Clearing = { 113, 134, 178 },
    s1ClearingEdge = { 82, 105, 143 },
    s1Cliff = { 52, 55, 61 },
    s1CliffDark = { 41, 44, 50 },
    s1CliffLight = { 99, 102, 108 },
    s1SpeckDark = { 111, 143, 200 },
    s1SpeckLight = { 168, 189, 231 },
    s1TreeTrunk = { 73, 53, 46 },
    s1TreeDark = { 41, 68, 77 },
    s1TreeMid = { 54, 89, 102 },
    s1TreeLight = { 111, 141, 163 },
    s1TreeSnow = { 212, 225, 239 },
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

local function samplePath(points, xRatio)
    if xRatio <= points[1][1] then return points[1][2] end
    for index = 1, #points - 1 do
        local left = points[index]
        local right = points[index + 1]
        if xRatio <= right[1] then
            local t = (xRatio - left[1]) / (right[1] - left[1])
            return left[2] + (right[2] - left[2]) * t
        end
    end
    return points[#points][2]
end

local function addScene1Band(runtime, createRect, prefix, startX, endX, topPath, bottomPath, color, segments)
    for index = 1, segments do
        local left = startX + (endX - startX) * (index - 1) / segments
        local right = startX + (endX - startX) * index / segments
        local top = samplePath(topPath, (left + right) * 0.5)
        local bottom = samplePath(bottomPath, (left + right) * 0.5)
        if bottom > top then
            addScene1Rect(runtime, createRect, prefix .. tostring(index), left, top,
                right - left + 0.001, bottom - top, color)
        end
    end
end

local function addScene1Edge(runtime, createRect, prefix, startX, endX, path, color, segments)
    for index = 1, segments do
        local left = startX + (endX - startX) * (index - 1) / segments
        local right = startX + (endX - startX) * index / segments
        local y = samplePath(path, (left + right) * 0.5)
        addScene1Rect(runtime, createRect, prefix .. tostring(index), left, y,
            right - left + 0.001, 0.006, color)
    end
end

local function addScene1Speck(runtime, createRect, index, xRatio, yRatio, scale)
    local width = 0.014 * scale
    local height = 0.005 * scale
    addScene1Rect(runtime, createRect, "S1_Speck_" .. tostring(index),
        xRatio - width * 0.5, yRatio, width, height, COLORS.s1SpeckDark)
    addScene1Rect(runtime, createRect, "S1_Speck_" .. tostring(index) .. "_Light",
        xRatio - width * 0.22, yRatio - height * 0.70, width * 0.55, height * 0.42,
        COLORS.s1SpeckLight)
end

local function addScene1Tree(runtime, createRect, index, xRatio, baseY, scale)
    local trunkWidth = 0.011 * scale
    local trunkHeight = 0.032 * scale
    addScene1Rect(runtime, createRect, "S1_Tree_" .. tostring(index) .. "_Trunk",
        xRatio - trunkWidth * 0.5, baseY - trunkHeight, trunkWidth, trunkHeight, COLORS.s1TreeTrunk)
    local tiers = {
        { 0.090, 0.035, 0.040, COLORS.s1TreeDark },
        { 0.072, 0.040, 0.066, COLORS.s1TreeMid },
        { 0.054, 0.046, 0.092, COLORS.s1TreeLight },
        { 0.035, 0.046, 0.125, COLORS.s1TreeSnow },
    }
    for tier, item in ipairs(tiers) do
        local width = item[1] * scale
        local height = item[2] * scale
        local y = baseY - item[3] * scale
        addScene1Rect(runtime, createRect, "S1_Tree_" .. tostring(index) .. "_Tier" .. tostring(tier),
            xRatio - width * 0.5, y, width, height, item[4])
    end
end

function Scene.BuildScene1(runtime, config, createRect)
    runtime.scene1Art = {}
    local landTop = { { 0.025, 0.129 }, { 0.488, 0.129 }, { 0.651, 0.382 } }
    local landBottom = { { 0.025, 0.817 }, { 0.506, 0.817 }, { 0.651, 0.556 } }
    local clearingTop = {
        { 0.025, 0.376 }, { 0.350, 0.376 }, { 0.390, 0.382 }, { 0.435, 0.388 },
        { 0.470, 0.387 }, { 0.511, 0.391 }, { 0.561, 0.386 }, { 0.573, 0.401 },
    }
    local clearingBottom = {
        { 0.025, 0.569 }, { 0.127, 0.573 }, { 0.217, 0.569 }, { 0.304, 0.574 },
        { 0.390, 0.570 }, { 0.468, 0.572 }, { 0.538, 0.562 }, { 0.573, 0.547 },
    }

    addScene1Rect(runtime, createRect, "S1_Abyss", 0, 0, 1, 1, COLORS.abyss)

    -- Broad cliff face and the two-tone hanging blocks.
    addScene1Rect(runtime, createRect, "S1_LowerCliffFace", 0.025, 0.817, 0.772, 0.105, COLORS.s1Cliff)
    addScene1Rect(runtime, createRect, "S1_LowerCliffLip", 0.025, 0.817, 0.772, 0.006, COLORS.s1CliffLight)
    local teeth = { 0.058, 0.145, 0.233, 0.323, 0.414, 0.505, 0.596, 0.691, 0.752 }
    for index, left in ipairs(teeth) do
        local width = index % 2 == 0 and 0.048 or 0.043
        local top = index % 2 == 0 and 0.862 or 0.878
        local height = index % 3 == 0 and 0.114 or 0.092
        addScene1Rect(runtime, createRect, "S1_LowerCliffBlock_" .. tostring(index), left, top,
            width, height, COLORS.s1CliffDark)
    end

    -- The sloped wall follows the land contour, preventing a black gap at the narrowing.
    local sideTop = { { 0.506, 0.817 }, { 0.526, 0.793 }, { 0.562, 0.720 },
        { 0.590, 0.656 }, { 0.618, 0.597 }, { 0.651, 0.556 }, { 0.694, 0.572 } }
    addScene1Band(runtime, createRect, "S1_SlopeCliff_", 0.506, 0.694, sideTop,
        { { 0.506, 1.0 }, { 0.694, 1.0 } }, COLORS.s1Cliff, 28)
    addScene1Band(runtime, createRect, "S1_RightCliff_", 0.651, 0.797,
        { { 0.651, 0.556 }, { 0.797, 0.556 } }, { { 0.651, 1.0 }, { 0.797, 1.0 } },
        COLORS.s1Cliff, 18)

    -- Blue plateau and rear landing.
    addScene1Band(runtime, createRect, "S1_Land_", 0.025, 0.651, landTop, landBottom, COLORS.s1Land, 40)
    addScene1Rect(runtime, createRect, "S1_RearLand", 0.649, 0.382, 0.148, 0.187, COLORS.s1Land)
    addScene1Edge(runtime, createRect, "S1_LandTopEdge_", 0.025, 0.488,
        { { 0.025, 0.129 }, { 0.488, 0.129 } }, COLORS.s1LandEdge, 2)
    addScene1Edge(runtime, createRect, "S1_LandBottomEdge_", 0.025, 0.506,
        { { 0.025, 0.817 }, { 0.506, 0.817 } }, COLORS.s1LandEdge, 2)
    addScene1Rect(runtime, createRect, "S1_RearLandEdge", 0.649, 0.382, 0.148, 0.006, COLORS.s1LandEdge)

    -- Large alternate-color clearing, clipped by its own top and bottom contours.
    addScene1Band(runtime, createRect, "S1_Clearing_", 0.025, 0.573, clearingTop, clearingBottom,
        COLORS.s1Clearing, 34)
    addScene1Edge(runtime, createRect, "S1_ClearingTopEdge_", 0.025, 0.573, clearingTop,
        COLORS.s1ClearingEdge, 34)
    addScene1Edge(runtime, createRect, "S1_ClearingBottomEdge_", 0.025, 0.573, clearingBottom,
        COLORS.s1ClearingEdge, 34)

    local specks = {
        { 0.065, 0.202, 1.0 }, { 0.149, 0.256, 0.72 }, { 0.235, 0.187, 0.82 },
        { 0.333, 0.287, 0.68 }, { 0.393, 0.216, 0.92 }, { 0.474, 0.324, 0.70 },
        { 0.555, 0.313, 0.62 }, { 0.630, 0.424, 0.76 }, { 0.715, 0.424, 0.66 },
        { 0.761, 0.518, 0.80 }, { 0.067, 0.629, 0.72 }, { 0.154, 0.707, 0.84 },
        { 0.243, 0.644, 0.64 }, { 0.329, 0.751, 0.78 }, { 0.415, 0.638, 0.70 },
        { 0.468, 0.731, 0.62 }, { 0.564, 0.669, 0.76 }, { 0.648, 0.727, 0.66 },
    }
    for index, item in ipairs(specks) do
        addScene1Speck(runtime, createRect, index, item[1], item[2], item[3])
    end

    addScene1Tree(runtime, createRect, 1, 0.444, 0.206, 1.28)
    addScene1Tree(runtime, createRect, 2, 0.259, 0.206, 1.28)
    addScene1Tree(runtime, createRect, 3, 0.199, 0.995, 0.66)
    addScene1Tree(runtime, createRect, 4, 0.531, 0.995, 0.88)
    addScene1Tree(runtime, createRect, 5, 0.625, 0.995, 0.70)

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
