-- 角色移动与输入监听。共享运行状态由 levelScript.lua 持有并作为参数传入。
local Movement = {}

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
        local topPinkRowCenter = runtime.puzzleBoardTop - runtime.puzzleTileHeight * 2.5
        local bottomPinkRowCenter = runtime.puzzleBoardTop - runtime.puzzleTileHeight * 3.5
        local halfCharacter = config.travelerRootSize * 0.5
        runtime.playerX = math.max(runtime.puzzleBoardLeft - halfCharacter,
            math.min(runtime.puzzleBoardRight + halfCharacter, runtime.playerX + xDirection * step))
        runtime.playerY = math.max(bottomPinkRowCenter,
            math.min(topPinkRowCenter, runtime.playerY + yDirection * step))
        runtime.travelerRoot:SetAnchoredPosition(runtime.playerX, runtime.playerY)
        if runtime.playerX >= runtime.puzzleBoardRight + halfCharacter then
            runtime.movementLocked = true
            runtime.puzzlePhase = "passed"
            runtime.keyHeld.left, runtime.keyHeld.right = false, false
            runtime.keyHeld.up, runtime.keyHeld.down = false, false
            handlers.puzzlePassed()
        end
        return
    end

    local minX, maxX, minY, maxY = Movement.GetBounds(runtime, config)
    runtime.playerX = math.max(minX, math.min(maxX, runtime.playerX + xDirection * step))
    runtime.playerY = math.max(minY, math.min(maxY, runtime.playerY + yDirection * step))
    runtime.travelerRoot:SetAnchoredPosition(runtime.playerX, runtime.playerY)

    if runtime.scene == 1 then
        local normalizedX = (runtime.playerX - minX) / (maxX - minX)
        if not runtime.scene1Triggered and normalizedX >= config.scene1DialogueX then
            handlers.beginScene1Dialogue()
            return
        end
        if runtime.scene1Triggered and normalizedX >= 0.985 then
            handlers.enterScene2()
            return
        end
    elseif runtime.scene == 2 and not runtime.scene2Triggered then
        local normalizedX = (runtime.playerX - minX) / (maxX - minX)
        if normalizedX >= config.scene2DialogueX then handlers.beginScene2Dialogue() end
    end
end

return Movement
