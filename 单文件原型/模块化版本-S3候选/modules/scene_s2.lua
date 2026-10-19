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

local function makeLinearPath(startX, endX, startY, endY, steps)
    local points = {}
    for index = 0, steps do
        local t = index / steps
        points[#points + 1] = {
            startX + (endX - startX) * t,
            startY + (endY - startY) * t,
        }
    end
    return points
end

local function addScene1Band(runtime, createRect, prefix, startX, endX, topPath, bottomPath, color, segments)
    for index = 1, segments do
        local left = startX + (endX - startX) * (index - 1) / segments
        local right = startX + (endX - startX) * index / segments
        local topLeft = samplePath(topPath, left)
        local topRight = samplePath(topPath, right)
        local bottomLeft = samplePath(bottomPath, left)
        local bottomRight = samplePath(bottomPath, right)
        local top = math.min(topLeft, topRight) - 0.001
        local bottom = math.max(bottomLeft, bottomRight) + 0.001
        if bottom > top then
            addScene1Rect(runtime, createRect, prefix .. tostring(index), left, top,
                right - left + 0.005, bottom - top, color)
        end
    end
end

local function addScene1Edge(runtime, createRect, prefix, startX, endX, path, color, segments)
    for index = 1, segments do
        local left = startX + (endX - startX) * (index - 1) / segments
        local right = startX + (endX - startX) * index / segments
        local y = math.min(samplePath(path, left), samplePath(path, right)) - 0.001
        addScene1Rect(runtime, createRect, prefix .. tostring(index), left, y,
            right - left + 0.001, 0.008, color)
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
    addScene1Rect(runtime, createRect, "S1_Abyss", 0, 0, 1, 1, COLORS.abyss)

    -- A single cliff face sits directly under the straight road, matching the
    -- block structure used by the second scene.
    addScene1Rect(runtime, createRect, "S1_UnderRoadCliffFace", 0, 0.817,
        0.712375, 0.183, COLORS.s1Cliff)
    addScene1Rect(runtime, createRect, "S1_UnderRoadCliffLip", 0, 0.817,
        0.708, 0.008, COLORS.s1CliffLight)
    local leftBlocks = { { 0.024, 0.883, 0.046, 0.100 }, { 0.095, 0.867, 0.050, 0.116 },
        { 0.171, 0.883, 0.048, 0.100 } }
    for index, block in ipairs(leftBlocks) do
        addScene1Rect(runtime, createRect, "S1_LeftCliffBlock_" .. tostring(index),
            block[1], block[2], block[3], block[4], COLORS.s1CliffDark)
    end

    -- The left extension and straight road are one continuous surface.
    -- The extra width intentionally overlaps the transition to hide hairline gaps.
    addScene1Rect(runtime, createRect, "S1_MainLand", 0, 0.129,
        0.712375, 0.688, COLORS.s1Land)
    addScene1Edge(runtime, createRect, "S1_MainLandTopEdge", 0, 0.712375,
        { { 0, 0.129 }, { 0.712375, 0.129 } }, COLORS.s1LandEdge, 1)
    -- Match the transition endpoints to the two adjacent surfaces. This keeps
    -- the arithmetic stair steps continuous without a second highlight at either end.
    local transitionStart = 0.708
    local transitionEnd = 0.852
    local transitionSteps = 16
    local landTop = makeLinearPath(transitionStart, transitionEnd, 0.129, 0.382, transitionSteps)
    local landBottom = makeLinearPath(transitionStart, transitionEnd, 0.817, 0.556, transitionSteps)
    addScene1Band(runtime, createRect, "S1_RoadTransition_", transitionStart, transitionEnd,
        landTop, landBottom, COLORS.s1Land, 16)
    addScene1Edge(runtime, createRect, "S1_RoadTransitionTopEdge_", transitionStart, transitionEnd,
        landTop, COLORS.s1LandEdge, 16)
    addScene1Rect(runtime, createRect, "S1_RearLand", transitionEnd, 0.382,
        1 - transitionEnd, 0.187, COLORS.s1Land)
    addScene1Rect(runtime, createRect, "S1_RearLandEdge", transitionEnd, 0.382,
        1 - transitionEnd, 0.006, COLORS.s1LandEdge)
    addScene1Rect(runtime, createRect, "S1_NarrowEndCliffFace", transitionEnd, 0.556,
        1 - transitionEnd, 0.183, COLORS.s1Cliff)
    addScene1Rect(runtime, createRect, "S1_NarrowEndCliffLip", transitionEnd, 0.556,
        1 - transitionEnd, 0.008, COLORS.s1CliffLight)

    -- Keep the whole small path in one control to remove the broken-up look.
    addScene1Rect(runtime, createRect, "S1_ClearingSurface", 0, 0.376,
        0.779625, 0.193, COLORS.s1Clearing)
    addScene1Edge(runtime, createRect, "S1_ClearingTopEdge", 0, 0.779625,
        { { 0, 0.376 }, { 0.779625, 0.376 } }, COLORS.s1ClearingEdge, 1)
    addScene1Edge(runtime, createRect, "S1_ClearingBottomEdge", 0, 0.779625,
        { { 0, 0.569 }, { 0.779625, 0.569 } }, COLORS.s1ClearingEdge, 1)

    -- The lower cliff follows the land's lower contour and stays parallel to it.
    local cliffTop = { { 0.228125, 0.817 }, { transitionStart, 0.817 } }
    local cliffTopTransition = makeLinearPath(transitionStart, transitionEnd,
        0.817, 0.556, transitionSteps)
    for index = 2, #cliffTopTransition do
        cliffTop[#cliffTop + 1] = cliffTopTransition[index]
    end
    local cliffBottom = { { 0.228125, 1.0 }, { transitionStart, 1.0 } }
    local cliffBottomTransition = makeLinearPath(transitionStart, transitionEnd,
        1.0, 0.739, transitionSteps)
    for index = 2, #cliffBottomTransition do
        cliffBottom[#cliffBottom + 1] = cliffBottomTransition[index]
    end
    addScene1Band(runtime, createRect, "S1_LowerCliffTransition_", transitionStart, transitionEnd,
        cliffTop, cliffBottom, COLORS.s1Cliff, 16)
    addScene1Edge(runtime, createRect, "S1_LowerCliffTransitionLip_", transitionStart, transitionEnd,
        cliffTop, COLORS.s1CliffLight, 16)
    -- Blocks 10 and 11 are centered on the lower edge of the narrow-end
    -- cliff face: 0.556 + 0.183 = 0.739.
    local teeth = { { 0.256, 0.883, 0.045, 0.100 }, { 0.341, 0.867, 0.050, 0.116 },
        { 0.430, 0.883, 0.049, 0.100 }, { 0.531, 0.871, 0.052, 0.109 },
        { 0.632, 0.884, 0.050, 0.100 }, { 0.737, 0.871, 0.052, 0.109 },
        { 0.842, 0.689, 0.050, 0.100 }, { 0.913, 0.6845, 0.052, 0.109 } }
    for index, block in ipairs(teeth) do
        addScene1Rect(runtime, createRect, "S1_LowerCliffBlock_" .. tostring(index),
            block[1], block[2], block[3], block[4], COLORS.s1CliffDark)
    end

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

    addScene1Tree(runtime, createRect, 1, 0.092, 0.206, 1.10)
    addScene1Tree(runtime, createRect, 2, 0.277, 0.206, 1.15)
    addScene1Tree(runtime, createRect, 3, 0.462, 0.206, 1.28)
    addScene1Tree(runtime, createRect, 4, 0.647, 0.206, 1.28)
    addScene1Tree(runtime, createRect, 5, 0.402, 1.0, 0.66)
    addScene1Tree(runtime, createRect, 6, 0.734, 1.0, 0.88)
    addScene1Tree(runtime, createRect, 7, 0.828, 1.0, 0.70)

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
