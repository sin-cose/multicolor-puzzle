-- 角色移动与输入监听。共享运行状态由 levelScript.lua 持有并作为参数传入。
local Movement = {}

-- Scene geometry is authored in normalized canvas coordinates. Keep the
-- player's center slightly inside each exposed edge so it cannot stand over
-- the abyss; the narrow S2 bridge intentionally uses the same small inset.
local WALKABLE_EDGE_MARGIN = 0.003
local SCENE_TRANSITION_EDGE_GAP = 20

local function insideRect(x, y, left, top, right, bottom, margin)
    return x >= left + margin and x <= right - margin
        and y >= top + margin and y <= bottom - margin
end

local function isScene1Walkable(x, y)
    local margin = WALKABLE_EDGE_MARGIN

    -- Main land and straight road: S1_MainLand in scene_s2.lua.
    if insideRect(x, y, 0, 0.129, 0.712375, 0.817, margin) then return true end

    -- The connecting road narrows along the same linear contours used by
    -- S1_RoadTransition_*; its two endpoints meet the main and rear land.
    if x >= 0.708 and x <= 0.852 then
        local t = (x - 0.708) / (0.852 - 0.708)
        local top = 0.129 + (0.382 - 0.129) * t
        local bottom = 0.817 + (0.556 - 0.817) * t
        if y >= top + margin and y <= bottom - margin then return true end
    end

    -- Rear landing and the broad clearing are separate visible walkable areas.
    -- Do not inset the shared x edge: the transition road must meet this
    -- platform without a margin-sized gap.
    if x >= 0.852 and x <= 1 - margin
        and y >= 0.382 + margin and y <= 0.569 - margin then return true end
    if insideRect(x, y, 0, 0.376, 0.779625, 0.569, margin) then return true end
    return false
end

local function isScene1FootprintWalkable(x, y, runtime, config)
    -- Use a smaller support footprint in the narrow passage while still
    -- checking its edges so the character does not stand over the cliff.
    local supportSize = config.travelerRootSize * 0.25
    local halfWidth = supportSize / runtime.canvasWidth
    local halfHeight = supportSize / runtime.canvasHeight
    if x + halfWidth < 0.852 - WALKABLE_EDGE_MARGIN then
        return isScene1Walkable(x, y)
    end

    -- The rear landing is narrower than the other S1 surfaces. Keep the
    -- character footprint over its connected land; cap the vertical support
    -- inset to half the landing's half-height so the path remains traversable
    -- at common UI canvas sizes.
    if x + halfWidth >= 0.852 - WALKABLE_EDGE_MARGIN then
        local landingHalfHeight = (0.569 - 0.382) * 0.5 - WALKABLE_EDGE_MARGIN
        halfHeight = math.min(halfHeight, landingHalfHeight * 0.5)
    end

    for _, offsetX in ipairs({ -halfWidth, halfWidth }) do
        for _, offsetY in ipairs({ -halfHeight, halfHeight }) do
            if not isScene1Walkable(x + offsetX, y + offsetY) then return false end
        end
    end
    return true
end

local function isScene2Walkable(x, y, config)
    local margin = WALKABLE_EDGE_MARGIN
    local scene = config.scene2
    local bridgeHeight = scene.boardHeightRatio / config.puzzle.rows
    local bridgeTop = scene.bridgeCenterYRatio - bridgeHeight * 0.5
    local bridgeBottom = scene.bridgeCenterYRatio + bridgeHeight * 0.5

    return insideRect(x, y, 0.04, 0.39, 0.20, 0.53, margin)
        or insideRect(x, y, scene.bridgeStartXRatio, bridgeTop,
            scene.bridgeStartXRatio + scene.bridgeWidthRatio, bridgeBottom, margin)
        or insideRect(x, y, scene.boardLeftRatio, 0.20,
            scene.boardLeftRatio + scene.boardWidthRatio, 0.79, margin)
end

local function isWalkable(runtime, config, x, y)
    local ratioX = 0.5 + x / runtime.canvasWidth
    local ratioY = 0.5 - y / runtime.canvasHeight
    if runtime.scene == 1 then
        return isScene1FootprintWalkable(ratioX, ratioY, runtime, config)
    end
    if runtime.scene == 2 then return isScene2Walkable(ratioX, ratioY, config) end
    if runtime.scene == 3 then
        -- S3 retains S2's land/bridge as its base terrain. The tile-row rule
        -- applies only while the character is on the colored board itself.
        local scene, puzzle = config.scene2, config.puzzle
        local margin = WALKABLE_EDGE_MARGIN
        local bridgeRight = scene.bridgeStartXRatio + scene.bridgeWidthRatio
        local bridgeHeight = scene.boardHeightRatio / puzzle.rows
        local bridgeTop = scene.bridgeCenterYRatio - bridgeHeight * 0.5
        local bridgeBottom = scene.bridgeCenterYRatio + bridgeHeight * 0.5
        local boardLeft = scene.boardLeftRatio

        -- S2's independently inset bridge and board rectangles leave a tiny
        -- gap at their shared edge. Stitch that seam only in S3 so the board
        -- is reachable without changing S2's existing movement boundaries.
        local onBridgeBoardSeam = math.abs(bridgeRight - boardLeft) <= margin * 2
            and ratioX >= boardLeft - margin and ratioX <= boardLeft + margin
            and ratioY >= bridgeTop + margin and ratioY <= bridgeBottom - margin
        local onMainLand = insideRect(ratioX, ratioY,
            scene.boardLeftRatio, scene.mainLandTopRatio,
            scene.mainLandRightRatio, scene.mainLandBottomRatio, margin)
        if not isScene2Walkable(ratioX, ratioY, config)
            and not onBridgeBoardSeam and not onMainLand then
            return false
        end

        local boardRight = scene.boardLeftRatio + scene.boardWidthRatio
        if ratioX >= boardLeft + margin and ratioX <= boardRight - margin then
            local tileHeight = scene.boardHeightRatio / puzzle.rows
            -- The target is the full height of rows 3 and 4, not the
            -- narrow band between their center lines.
            local pinkRowsTop = scene.boardTopRatio + tileHeight * 2
            local pinkRowsBottom = scene.boardTopRatio + tileHeight * 4
            return ratioY >= pinkRowsTop and ratioY <= pinkRowsBottom
        end
        return true
    end
    return true
end

local function moveAcrossWalkableSurface(runtime, config, deltaX, deltaY)
    local startX, startY = runtime.playerX, runtime.playerY
    local largestRatioStep = math.max(
        math.abs(deltaX) / runtime.canvasWidth,
        math.abs(deltaY) / runtime.canvasHeight
    )
    -- Small samples prevent a fast frame from skipping across a narrow gap.
    local samples = math.max(1, math.ceil(largestRatioStep / 0.005))
    local lastX, lastY = startX, startY
    for index = 1, samples do
        local t = index / samples
        local nextX = startX + deltaX * t
        local nextY = startY + deltaY * t
        if not isWalkable(runtime, config, nextX, nextY) then break end
        lastX, lastY = nextX, nextY
    end
    runtime.playerX, runtime.playerY = lastX, lastY
    return lastX ~= startX or lastY ~= startY
end

function Movement.GetBounds(runtime, config)
    local halfCharacter = config.travelerRootSize * 0.5
    local minX = -runtime.canvasWidth * 0.5 + halfCharacter + config.edgePadding
    local maxX = runtime.canvasWidth * 0.5 - halfCharacter - config.edgePadding
    local minY = -runtime.canvasHeight * 0.5 + halfCharacter + config.edgePadding
    local maxY = runtime.canvasHeight * 0.5 - halfCharacter - config.edgePadding
    return minX, maxX, minY, maxY
end

function Movement.SetInitialPosition(runtime, config)
    local minX, maxX = Movement.GetBounds(runtime, config)
    runtime.playerX = minX + (maxX - minX) * 0.08
    runtime.playerY = -runtime.canvasHeight * 0.12
    runtime.travelerRoot:SetAnchoredPosition(runtime.playerX, runtime.playerY)
end

local function bindKey(runtime, eventDown, eventUp, keyName, direction, log)
    local downCallback = function()
        if runtime.queue == nil and not runtime.ended and not runtime.movementLocked then
            runtime.keyHeld[direction] = true
            log("输入按下：" .. keyName .. " -> " .. direction)
        end
        return true
    end
    local upCallback = function()
        runtime.keyHeld[direction] = false
        log("输入抬起：" .. keyName .. " -> " .. direction)
        return true
    end
    runtime.host:AddKeyEventListener(eventDown, downCallback)
    runtime.host:AddKeyEventListener(eventUp, upCallback)
    runtime.callbacks[#runtime.callbacks + 1] = { event = eventDown, callback = downCallback }
    runtime.callbacks[#runtime.callbacks + 1] = { event = eventUp, callback = upCallback }
    log("方向键监听已注册：" .. keyName)
end

function Movement.BindInputs(runtime, handlers, log)
    bindKey(runtime, Enum.KeyEventType.KeyboardMoveLeftKeyDown, Enum.KeyEventType.KeyboardMoveLeftKeyUp, "A", "left", log)
    bindKey(runtime, Enum.KeyEventType.KeyboardMoveRightKeyDown, Enum.KeyEventType.KeyboardMoveRightKeyUp, "D", "right", log)
    bindKey(runtime, Enum.KeyEventType.KeyboardMoveForwardKeyDown, Enum.KeyEventType.KeyboardMoveForwardKeyUp, "W", "up", log)
    bindKey(runtime, Enum.KeyEventType.KeyboardMoveBackwardKeyDown, Enum.KeyEventType.KeyboardMoveBackwardKeyUp, "S", "down", log)
    bindKey(runtime, Enum.KeyEventType.KeyboardCraftspersonKey38Down, Enum.KeyEventType.KeyboardCraftspersonKey38Up, "←", "left", log)
    bindKey(runtime, Enum.KeyEventType.KeyboardCraftspersonKey39Down, Enum.KeyEventType.KeyboardCraftspersonKey39Up, "→", "right", log)
    bindKey(runtime, Enum.KeyEventType.KeyboardCraftspersonKey36Down, Enum.KeyEventType.KeyboardCraftspersonKey36Up, "↑", "up", log)
    bindKey(runtime, Enum.KeyEventType.KeyboardCraftspersonKey37Down, Enum.KeyEventType.KeyboardCraftspersonKey37Up, "↓", "down", log)

    local advanceCallback = function() handlers.advanceDialogue() end
    runtime.controls.advance:AddCursorEventListener(Enum.CursorEventType.CursorClick, advanceCallback)
    runtime.callbacks[#runtime.callbacks + 1] = { control = runtime.controls.advance, event = Enum.CursorEventType.CursorClick, callback = advanceCallback }

    local choice1Callback = function() handlers.chooseBranch(1) end
    local choice2Callback = function() handlers.chooseBranch(2) end
    runtime.controls.choice1:AddCursorEventListener(Enum.CursorEventType.CursorClick, choice1Callback)
    runtime.controls.choice2:AddCursorEventListener(Enum.CursorEventType.CursorClick, choice2Callback)
    runtime.callbacks[#runtime.callbacks + 1] = { control = runtime.controls.choice1, event = Enum.CursorEventType.CursorClick, callback = choice1Callback }
    runtime.callbacks[#runtime.callbacks + 1] = { control = runtime.controls.choice2, event = Enum.CursorEventType.CursorClick, callback = choice2Callback }
    log("鼠标对话推进与选项点击已注册")
end

function Movement.Update(runtime, config, dt, handlers)
    if runtime.queue ~= nil or runtime.ended or runtime.movementLocked then return end
    local xDirection = (runtime.keyHeld.right and 1 or 0) - (runtime.keyHeld.left and 1 or 0)
    local yDirection = (runtime.keyHeld.up and 1 or 0) - (runtime.keyHeld.down and 1 or 0)
    if xDirection == 0 and yDirection == 0 then return end

    local length = math.sqrt(xDirection * xDirection + yDirection * yDirection)
    xDirection, yDirection = xDirection / length, yDirection / length
    local step = config.movementSpeed * math.min(dt, 0.05)

    if runtime.scene == 3 then
        local minX, maxX, minY, maxY = Movement.GetBounds(runtime, config)
        local nextX = math.max(minX, math.min(maxX, runtime.playerX + xDirection * step))
        local nextY = math.max(minY, math.min(maxY, runtime.playerY + yDirection * step))
        if not moveAcrossWalkableSurface(runtime, config,
            nextX - runtime.playerX, nextY - runtime.playerY) then return end
        runtime.travelerRoot:SetAnchoredPosition(runtime.playerX, runtime.playerY)
        if runtime.playerX >= runtime.puzzleBoardRight then
            runtime.movementLocked = true
            runtime.puzzlePhase = "passed"
            runtime.keyHeld.left, runtime.keyHeld.right = false, false
            runtime.keyHeld.up, runtime.keyHeld.down = false, false
            handlers.puzzlePassed()
        end
        return
    end

    local minX, maxX, minY, maxY = Movement.GetBounds(runtime, config)
    local movementMinX, movementMaxX = minX, maxX
    local halfCharacter = config.travelerRootSize * 0.5
    if runtime.scene == 1 then
        movementMaxX = runtime.canvasWidth * 0.5 - halfCharacter - SCENE_TRANSITION_EDGE_GAP
    elseif runtime.scene == 2 then
        movementMinX = -runtime.canvasWidth * 0.5 + halfCharacter + SCENE_TRANSITION_EDGE_GAP
    end
    local nextX = math.max(movementMinX, math.min(movementMaxX, runtime.playerX + xDirection * step))
    local nextY = math.max(minY, math.min(maxY, runtime.playerY + yDirection * step))
    if not moveAcrossWalkableSurface(runtime, config,
        nextX - runtime.playerX, nextY - runtime.playerY) then return end
    runtime.travelerRoot:SetAnchoredPosition(runtime.playerX, runtime.playerY)

    if runtime.scene == 1 then
        local normalizedX = (runtime.playerX - minX) / (maxX - minX)
        if not runtime.scene1Triggered and normalizedX >= config.scene1DialogueX then
            handlers.beginScene1Dialogue()
            return
        end
        if runtime.scene1Triggered and runtime.playerX >= movementMaxX then
            handlers.enterScene2()
            return
        end
    elseif runtime.scene == 2 then
        if runtime.playerX <= movementMinX then
            handlers.enterScene1()
            return
        end
        if not runtime.scene2Triggered then
            local normalizedX = (runtime.playerX - minX) / (maxX - minX)
            if normalizedX >= config.scene2DialogueX then handlers.beginScene2Dialogue() end
        end
    end
end

return Movement
