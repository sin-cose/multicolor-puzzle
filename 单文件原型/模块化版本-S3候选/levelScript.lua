--[=[
彩砖剧情原型：单文件版本

当前范围：自由移动、两段场景触发对话、鼠标选择对话选项、S3 彩砖演出与通行。
不包含电话、提示、设置、存档或结算。

未来拆分建议：本文件按「配置 / 数据 / 控件 / 对话 / 移动 / 生命周期」分区。
迁移到多文件时，优先将“配置与剧情数据”迁入 data，移动规则迁入 world，
对话与控件管理迁入 story/ui；入口仍保留 levelScript.lua。
]=]

local SharedConfig = require("s3_candidate.modules.config")
local STORY = require("s3_candidate.modules.story_data")
local MOVEMENT = require("s3_candidate.modules.movement")
local SCENE = require("s3_candidate.modules.scene_s2")
local CONFIG = SharedConfig.CONFIG
local REQUIRED_TEMPLATE_KEYS = SharedConfig.REQUIRED_TEMPLATE_KEYS

-- 03.运行时状态：本单文件内的共享状态仅由此处持有。
local RUNTIME = {
    host = nil,
    canvasWidth = 0,
    canvasHeight = 0,
    controls = {},
    puzzleTiles = {},
    puzzlePalette = {},
    puzzleBoardWidth = 0,
    puzzleBoardLeft = 0,
    puzzleBoardRight = 0,
    puzzleBoardTop = 0,
    puzzleTileHeight = 0,
    puzzlePhase = nil,
    puzzleTimer = 0,
    puzzleChangeIndex = 1,
    puzzleRandomSeed = 0,
    movementLocked = false,
    travelerRoot = nil, -- 由界面布局提供，不由本脚本创建或销毁
    keyHeld = { left = false, right = false, up = false, down = false },
    scene = 1,
    playerX = 0,
    playerY = 0,
    scene1Triggered = false,
    scene2Triggered = false,
    queue = nil,
    queueIndex = 0,
    choosing = false,
    branchQueue = nil,
    ended = false,
    started = false,
    updateLogged = false,
    callbacks = {},
}

local function log(message)
    print("[StoryPrototype] " .. tostring(message))
end

local function isPositiveInteger(value)
    return type(value) == "number" and value > 0 and value % 1 == 0
end

local function validateHostAndScript()
    -- 必须先从 script.object 取得宿主控件；不要先查找或创建其他控件。
    if script == nil then
        printerr("[StoryPrototype] 当前脚本实例 script 不可用")
        return false
    end
    RUNTIME.host = script.object
    if RUNTIME.host == nil or RUNTIME.host.alive == false then
        printerr("[StoryPrototype] script.object 宿主控件不可用")
        return false
    end

    local actualPath = tostring(script.path or "")
    local actualShortName = actualPath:gsub("\\", "/"):match("([^/]+)$") or actualPath
    actualShortName = actualShortName:gsub("%.lua$", "")
    if actualShortName ~= CONFIG.expectedScriptShortName then
        printerr("[StoryPrototype] 脚本名称不符，期望=" .. CONFIG.expectedScriptShortName .. "，实际=" .. actualShortName)
        return false
    end

    -- script.object 是 API 提供的当前脚本宿主；不要再用 GetScripts() 返回值
    -- 与全局 script 做对象相等比较。运行时包装对象可能不是同一 Lua 引用，造成误判。
    log("已取得当前脚本宿主：脚本=" .. actualShortName
        .. "，控件=" .. tostring(RUNTIME.host.name)
        .. "，控件运行时ID=" .. tostring(RUNTIME.host.id))
    return true
end

local function validateTemplateConfig()
    for _, name in ipairs(REQUIRED_TEMPLATE_KEYS) do
        local templateIndex = CONFIG.templates[name]
        if not isPositiveInteger(templateIndex) then
            printerr("[StoryPrototype] 模板索引尚未填写或无效：" .. name .. "；请在 CONFIG.templates 中填写编辑器实际编号")
            return false
        end
    end
    return true
end

local function anchor(control, minX, minY, maxX, maxY, x, y, width, height)
    control:SetAnchorMin(minX, minY)
    control:SetAnchorMax(maxX, maxY)
    control:SetAnchoredPosition(x, y)
    control:SetSizeDelta(width, height)
end

local function createControl(templateKey, name, x, y, width, height, anchorX, anchorY)
    local control = game.InstantiateClientUIControl(CONFIG.templates[templateKey], RUNTIME.host)
    if control == nil then
        error("创建控件失败：" .. name .. "（模板=" .. templateKey .. "）")
    end
    control.name = name
    if anchorX ~= nil then
        anchor(control, anchorX, anchorY, anchorX, anchorY, x, y, width, height)
    end
    control:SetActive(true)
    RUNTIME.controls[name] = control
    log("控件创建成功：" .. name .. " / 模板=" .. tostring(CONFIG.templates[templateKey]))
    return control
end

local function configureImage(control, width, height, x, y, fullScreen)
    if fullScreen then
        anchor(control, 0, 0, 1, 1, 0, 0, 0, 0)
    else
        anchor(control, 0.5, 0.5, 0.5, 0.5, x, y, width, height)
    end
end

local function createSceneRect(name, leftRatio, topRatio, widthRatio, heightRatio, rgb)
    local control = game.InstantiateClientUIControl(CONFIG.templates.speakerText, RUNTIME.host)
    if control == nil then error("创建场景图形失败：" .. name) end
    control.name = name
    control:SetPivot(0.5, 0.5)
    control:SetAnchorMin(0.5, 0.5)
    control:SetAnchorMax(0.5, 0.5)
    control:SetSizeDelta(RUNTIME.canvasWidth * widthRatio, RUNTIME.canvasHeight * heightRatio)
    control:SetAnchoredPosition(
        RUNTIME.canvasWidth * (leftRatio + widthRatio * 0.5 - 0.5),
        RUNTIME.canvasHeight * (0.5 - topRatio - heightRatio * 0.5))
    control.text = ""
    control.fontSize = 1
    control.fontColor = Color.FromRGBA(0, 0, 0, 0)
    control.enableOutline = false
    control.bgColor = Color.FromRGB(rgb[1], rgb[2], rgb[3])
    control:SetActive(true)
    control:SetVisible(false)
    RUNTIME.controls[name] = control
    return control
end

local function createPuzzleBoard()
    local puzzle = CONFIG.puzzle
    local scene = CONFIG.scene2
    RUNTIME.puzzleBoardWidth = RUNTIME.canvasWidth * scene.boardWidthRatio
    RUNTIME.puzzleTileHeight = RUNTIME.canvasHeight * scene.boardHeightRatio / puzzle.rows
    RUNTIME.puzzleBoardLeft = RUNTIME.canvasWidth * (scene.boardLeftRatio - 0.5)
    RUNTIME.puzzleBoardRight = RUNTIME.puzzleBoardLeft + RUNTIME.puzzleBoardWidth
    RUNTIME.puzzleBoardTop = RUNTIME.canvasHeight * (0.5 - scene.boardTopRatio)

    for _, color in ipairs(puzzle.palette) do
        RUNTIME.puzzlePalette[color.code] = Color.FromRGB(color.r, color.g, color.b)
    end
    local grayColors = {}
    for index, color in ipairs(puzzle.grayPalette) do
        grayColors[index] = Color.FromRGB(color.r, color.g, color.b)
    end
    SCENE.Build(RUNTIME, CONFIG, createSceneRect)

    local tileWidth = RUNTIME.puzzleBoardWidth / puzzle.columns
    for row = 1, puzzle.rows do
        for column = 1, puzzle.columns do
            local index = (row - 1) * puzzle.columns + column
            local tile = game.InstantiateClientUIControl(CONFIG.templates.speakerText, RUNTIME.host)
            if tile == nil then error("创建彩砖控件失败：第 " .. tostring(row) .. " 行第 " .. tostring(column) .. " 列") end

            local name = "Puzzle1_Tile_" .. tostring(index)
            RUNTIME.controls[name] = tile
            tile:SetVisible(false)
            tile.name = name
            tile:SetPivot(0.5, 0.5)
            tile:SetAnchorMin(0.5, 0.5)
            tile:SetAnchorMax(0.5, 0.5)
            tile:SetSizeDelta(tileWidth, RUNTIME.puzzleTileHeight)
            local x = RUNTIME.puzzleBoardLeft + tileWidth * (column - 0.5)
            local y = RUNTIME.puzzleBoardTop - RUNTIME.puzzleTileHeight * (row - 0.5)
            tile:SetAnchoredPosition(x, y)
            tile.text = ""
            tile.fontSize = 1
            tile.fontColor = Color.FromRGBA(0, 0, 0, 0)
            tile.enableOutline = false
            tile.bgColor = grayColors[((row + column) % #grayColors) + 1]
            tile:SetActive(true)
            tile:SetVisible(false)
            tile:SetAsLastSibling()
            RUNTIME.puzzleTiles[index] = tile
        end
    end

    SCENE.SetVisible(RUNTIME, false)
    log("灰度谜题与场景底图创建完成：6 行 × 8 列；坐标共用场景比例")
end

local function randomizePuzzleTiles()
    local palette = CONFIG.puzzle.palette
    for _, tile in ipairs(RUNTIME.puzzleTiles) do
        RUNTIME.puzzleRandomSeed = (RUNTIME.puzzleRandomSeed * 48271) % 2147483647
        local color = palette[(RUNTIME.puzzleRandomSeed % #palette) + 1]
        tile.bgColor = RUNTIME.puzzlePalette[color.code]
    end
end

local function showPuzzleRows(rowColors)
    local columns = CONFIG.puzzle.columns
    for row, code in ipairs(rowColors) do
        local color = RUNTIME.puzzlePalette[code]
        local first = (row - 1) * columns + 1
        for index = first, first + columns - 1 do
            RUNTIME.puzzleTiles[index].bgColor = color
        end
    end
end

local function getPuzzleChangeInterval(changeIndex)
    local puzzle = CONFIG.puzzle
    if changeIndex > puzzle.accelerationChanges then return puzzle.minIntervalSeconds end
    local progress = (changeIndex - 1) / (puzzle.accelerationChanges - 1)
    return puzzle.minIntervalSeconds
        + (puzzle.startIntervalSeconds - puzzle.minIntervalSeconds) * (1 - progress) ^ puzzle.accelerationPower
end

local function updatePuzzlePerformance(dt)
    if RUNTIME.scene ~= 3 then return end
    local phase = RUNTIME.puzzlePhase
    if phase ~= "random" and phase ~= "pause" and phase ~= "fakeout" and phase ~= "target" then return end

    RUNTIME.puzzleTimer = RUNTIME.puzzleTimer + dt
    if phase == "random" then
        if RUNTIME.puzzleTimer >= getPuzzleChangeInterval(RUNTIME.puzzleChangeIndex) then
            RUNTIME.puzzleTimer = 0
            randomizePuzzleTiles()
            RUNTIME.puzzleChangeIndex = RUNTIME.puzzleChangeIndex + 1
            if RUNTIME.puzzleChangeIndex > CONFIG.puzzle.totalChanges then
                RUNTIME.puzzlePhase = "pause"
            end
        end
    elseif phase == "pause" and RUNTIME.puzzleTimer >= CONFIG.puzzle.fakeoutPauseSeconds then
        RUNTIME.puzzleTimer = 0
        RUNTIME.puzzlePhase = "fakeout"
        showPuzzleRows(CONFIG.puzzle.fakeoutRows)
    elseif phase == "fakeout" and RUNTIME.puzzleTimer >= CONFIG.puzzle.fakeoutHoldSeconds then
        RUNTIME.puzzleTimer = 0
        RUNTIME.puzzlePhase = "target"
        showPuzzleRows(CONFIG.puzzle.targetRows)
    elseif phase == "target" and RUNTIME.puzzleTimer >= CONFIG.puzzle.targetHoldSeconds then
        RUNTIME.puzzleTimer = 0
        RUNTIME.puzzlePhase = "ready"
        RUNTIME.movementLocked = false
        RUNTIME.keyHeld.left, RUNTIME.keyHeld.right = false, false
        RUNTIME.keyHeld.up, RUNTIME.keyHeld.down = false, false
        log("彩砖演出结束；开放粉色两行移动")
    end
end

local function setVisible(control, visible)
    if control ~= nil and control.alive then control:SetVisible(visible) end
end

local function buildUI()
    local width, height = game.GetUICanvasSize()
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
        error("无法取得有效画布尺寸")
    end
    RUNTIME.canvasWidth, RUNTIME.canvasHeight = width, height
    log("画布尺寸：" .. tostring(width) .. " x " .. tostring(height))

    RUNTIME.host.showCursor = true
    local background1 = createControl("scene1Background", "Story_Scene1_Background")
    configureImage(background1, 0, 0, 0, 0, true)
    background1:SetAsFirstSibling()

    local background2 = createControl("scene2Background", "Story_Scene2_Background")
    configureImage(background2, 0, 0, 0, 0, true)
    background2:SetAsFirstSibling()
    setVisible(background2, false)

    -- TravelerRoot 是界面布局中的直接子容器，空.lua 挂载在其上并在内部绘制角色。
    -- 只移动这个容器，不销毁它；它及其色块由布局和空.lua 自己管理。
    local player = RUNTIME.host:GetChild(CONFIG.travelerRootName)
    if player == nil or player.alive == false then
        error("找不到角色容器：" .. CONFIG.travelerRootName .. "；请在主脚本宿主下创建同名直接子容器，并将空.lua 挂载到该容器")
    end
    RUNTIME.travelerRoot = player
    player:SetAnchorMin(0.5, 0.5)
    player:SetAnchorMax(0.5, 0.5)
    player:SetSizeDelta(CONFIG.travelerRootSize, CONFIG.travelerRootSize)
    player:SetAnchoredPosition(0, -height * 0.12)
    player:SetActive(true)
    player:SetAsLastSibling()
    log("已连接像素角色容器：" .. CONFIG.travelerRootName .. "；由空.lua 绘制")

    createPuzzleBoard()
    player:SetAsLastSibling()

    -- 深色对话框位于头像、名字、台词和选项之下，贯穿整个对话区域。
    local dialogueFrame = createControl("dialogueText", "Story_Dialogue_Frame", 0, -height * 0.295, width * 0.92, height * 0.40, 0.5, 0.5)
    dialogueFrame.text = ""
    dialogueFrame.bgColor = Color.FromRGBA(18, 18, 24, 235)
    dialogueFrame:SetAsLastSibling()
    setVisible(dialogueFrame, false)

    local portraitTraveler = createControl("portraitTraveler", "Story_Portrait_Traveler", -width * 0.35, -height * 0.235, 120, 130, 0.5, 0.5)
    local portraitAino = createControl("portraitAino", "Story_Portrait_Aino", -width * 0.35, -height * 0.235, 120, 130, 0.5, 0.5)
    local portraitIneffa = createControl("portraitIneffa", "Story_Portrait_Ineffa", -width * 0.35, -height * 0.235, 120, 130, 0.5, 0.5)
    portraitTraveler:SetAsLastSibling()
    portraitAino:SetAsLastSibling()
    portraitIneffa:SetAsLastSibling()

    local portraitNpcOne, portraitNpcTwo
    if isPositiveInteger(CONFIG.templates.portraitNpcOne) then
        portraitNpcOne = createControl("portraitNpcOne", "Story_Portrait_NPC_One", -width * 0.35, -height * 0.235, 120, 130, 0.5, 0.5)
        portraitNpcOne:SetAsLastSibling()
    else
        log("未配置可选头像 portraitNpcOne；场景1‘一个人’将只显示名称")
    end
    if isPositiveInteger(CONFIG.templates.portraitNpcTwo) then
        portraitNpcTwo = createControl("portraitNpcTwo", "Story_Portrait_NPC_Two", -width * 0.35, -height * 0.235, 120, 130, 0.5, 0.5)
        portraitNpcTwo:SetAsLastSibling()
    else
        log("未配置可选头像 portraitNpcTwo；场景1‘另一个人’将只显示名称")
    end

    setVisible(portraitTraveler, false)
    setVisible(portraitAino, false)
    setVisible(portraitIneffa, false)
    setVisible(portraitNpcOne, false)
    setVisible(portraitNpcTwo, false)

    local speaker = createControl("speakerText", "Story_Speaker", -width * 0.35, -height * 0.37, width * 0.24, 36, 0.5, 0.5)
    speaker.fontSize = 22
    speaker.fontColor = Color.FromRGB(255, 255, 255)
    speaker.bgColor = Color.FromRGBA(0, 0, 0, 0)
    speaker.horizontalAlignment = Enum.TextHorizontalAlignment.Middle
    speaker.verticalAlignment = Enum.TextVerticalAlignment.Middle
    speaker.text = ""
    speaker:SetAsLastSibling()
    setVisible(speaker, false)

    local dialogue = createControl("dialogueText", "Story_Dialogue", width * 0.105, -height * 0.285, width * 0.62, height * 0.22, 0.5, 0.5)
    dialogue.fontSize = 30
    dialogue.fontColor = Color.FromRGB(255, 255, 255)
    dialogue.bgColor = Color.FromRGBA(0, 0, 0, 0)
    dialogue.horizontalAlignment = Enum.TextHorizontalAlignment.Left
    dialogue.verticalAlignment = Enum.TextVerticalAlignment.Middle
    dialogue.text = ""
    dialogue:SetAsLastSibling()
    setVisible(dialogue, false)

    local advance = createControl("advanceArea", "Story_AdvanceArea", 0, -height * 0.34, width * 0.78, height * 0.18, 0.5, 0.5)
    advance.raycastTarget = true
    advance:SetAsLastSibling()
    setVisible(advance, false)

    -- 选项用文本框绘制可见底色和文字，另用透明光标检测区域承接点击，
    -- 不依赖预设按钮模板的图像/文字状态配置，也不需要按钮子控件。
    local choice1Label = createControl("speakerText", "Story_Choice_1_Label", -width * 0.20, -height * 0.43, width * 0.30, 56, 0.5, 0.5)
    local choice2Label = createControl("speakerText", "Story_Choice_2_Label", width * 0.20, -height * 0.43, width * 0.30, 56, 0.5, 0.5)
    for _, label in ipairs({ choice1Label, choice2Label }) do
        label.fontSize = 22
        label.fontColor = Color.FromRGB(255, 255, 255)
        label.bgColor = Color.FromRGBA(42, 42, 54, 235)
        label.enableOutline = true
        label.outlineColor = Color.FromRGB(0, 0, 0)
        label.horizontalAlignment = Enum.TextHorizontalAlignment.Middle
        label.verticalAlignment = Enum.TextVerticalAlignment.Middle
    end
    choice1Label.text = "那当然了"
    choice2Label.text = "没"
    choice1Label:SetAsLastSibling()
    choice2Label:SetAsLastSibling()
    setVisible(choice1Label, false)
    setVisible(choice2Label, false)

    local choice1Area = createControl("advanceArea", "Story_Choice_1_ClickArea", -width * 0.20, -height * 0.43, width * 0.30, 56, 0.5, 0.5)
    local choice2Area = createControl("advanceArea", "Story_Choice_2_ClickArea", width * 0.20, -height * 0.43, width * 0.30, 56, 0.5, 0.5)
    choice1Area.raycastTarget, choice2Area.raycastTarget = true, true
    choice1Area:SetAsLastSibling()
    choice2Area:SetAsLastSibling()
    setVisible(choice1Area, false)
    setVisible(choice2Area, false)

    RUNTIME.controls.background1 = background1
    RUNTIME.controls.background2 = background2
    RUNTIME.controls.dialogueFrame = dialogueFrame
    RUNTIME.controls.portraitTraveler = portraitTraveler
    RUNTIME.controls.portraitAino = portraitAino
    RUNTIME.controls.portraitIneffa = portraitIneffa
    RUNTIME.controls.portraitNpcOne = portraitNpcOne
    RUNTIME.controls.portraitNpcTwo = portraitNpcTwo
    RUNTIME.controls.speaker = speaker
    RUNTIME.controls.dialogue = dialogue
    RUNTIME.controls.advance = advance
    RUNTIME.controls.choice1Label = choice1Label
    RUNTIME.controls.choice2Label = choice2Label
    RUNTIME.controls.choice1 = choice1Area
    RUNTIME.controls.choice2 = choice2Area
    log("界面创建完成")
end

local function setPortraitFor(portraitKey)
    -- 对话播放期间只切换显隐，不反复创建角色肖像控件。
    setVisible(RUNTIME.controls.portraitTraveler, portraitKey == "traveler")
    setVisible(RUNTIME.controls.portraitAino, portraitKey == "aino")
    setVisible(RUNTIME.controls.portraitIneffa, portraitKey == "ineffa")
    setVisible(RUNTIME.controls.portraitNpcOne, portraitKey == "npcOne")
    setVisible(RUNTIME.controls.portraitNpcTwo, portraitKey == "npcTwo")
end

local function hideChoices()
    setVisible(RUNTIME.controls.choice1Label, false)
    setVisible(RUNTIME.controls.choice2Label, false)
    setVisible(RUNTIME.controls.choice1, false)
    setVisible(RUNTIME.controls.choice2, false)
    setVisible(RUNTIME.controls.advance, true)
    RUNTIME.choosing = false
end

local startDialogue
local enterPuzzleScene

local function showCurrentLine()
    if RUNTIME.queue == nil or RUNTIME.queueIndex > #RUNTIME.queue then
        RUNTIME.queue = nil
        RUNTIME.queueIndex = 0
        hideChoices()
        setVisible(RUNTIME.controls.dialogueFrame, false)
        setVisible(RUNTIME.controls.speaker, false)
        setVisible(RUNTIME.controls.dialogue, false)
        setPortraitFor(nil)
        setVisible(RUNTIME.controls.advance, false)
        RUNTIME.keyHeld.left, RUNTIME.keyHeld.right = false, false
        RUNTIME.keyHeld.up, RUNTIME.keyHeld.down = false, false
        if RUNTIME.branchQueue then
            local nextQueue = RUNTIME.branchQueue
            RUNTIME.branchQueue = nil
            startDialogue(nextQueue)
            return
        end
        if RUNTIME.scene == 2 and RUNTIME.scene2Triggered then
            enterPuzzleScene()
            return
        end
        log("对话段落结束")
        return
    end

    local line = RUNTIME.queue[RUNTIME.queueIndex]
    if line == nil then return end
    RUNTIME.controls.dialogueFrame:SetAsLastSibling()
    setVisible(RUNTIME.controls.dialogueFrame, true)
    setPortraitFor(line.portrait)
    local portraitControl = line.portrait and RUNTIME.controls["portrait" .. line.portrait:sub(1, 1):upper() .. line.portrait:sub(2)]
    if portraitControl and portraitControl.alive then portraitControl:SetAsLastSibling() end
    RUNTIME.controls.speaker.text = line.speaker
    RUNTIME.controls.dialogue.text = line.text
    RUNTIME.controls.speaker:SetAsLastSibling()
    RUNTIME.controls.dialogue:SetAsLastSibling()
    setVisible(RUNTIME.controls.speaker, true)
    setVisible(RUNTIME.controls.dialogue, true)
    log("对话行 " .. tostring(RUNTIME.queueIndex) .. ": " .. line.speaker .. " / 表情=" .. tostring(line.expression))

    if line.choices then
        RUNTIME.choosing = true
        setVisible(RUNTIME.controls.advance, false)
        setVisible(RUNTIME.controls.choice1Label, true)
        setVisible(RUNTIME.controls.choice2Label, true)
        setVisible(RUNTIME.controls.choice1, true)
        setVisible(RUNTIME.controls.choice2, true)
        log("显示文本框选项：那当然了 / 没；等待鼠标选择")
    else
        hideChoices()
    end
    RUNTIME.controls.advance:SetAsLastSibling()
    if line.choices then
        RUNTIME.controls.choice1Label:SetAsLastSibling()
        RUNTIME.controls.choice2Label:SetAsLastSibling()
        RUNTIME.controls.choice1:SetAsLastSibling()
        RUNTIME.controls.choice2:SetAsLastSibling()
    end
end

startDialogue = function(lines)
    RUNTIME.queue = lines
    RUNTIME.queueIndex = 1
    log("进入对话段，共 " .. tostring(#lines) .. " 行")
    showCurrentLine()
end

local function advanceDialogue()
    if RUNTIME.queue == nil or RUNTIME.choosing then return end
    RUNTIME.queueIndex = RUNTIME.queueIndex + 1
    showCurrentLine()
end

local function chooseBranch(choiceIndex)
    if not RUNTIME.choosing or RUNTIME.queue == nil then return end
    local line = RUNTIME.queue[RUNTIME.queueIndex]
    local choice = line and line.choices and line.choices[choiceIndex]
    if choice == nil then return end
    log("玩家选择：" .. choice.text)
    hideChoices()
    RUNTIME.branchQueue = choice.branch == "understood" and STORY.branches.understood or STORY.branches.notUnderstood
    -- choice 行消耗后接所选分支；分支结束后自动接入本段结尾台词。
    RUNTIME.queueIndex = RUNTIME.queueIndex + 1
    RUNTIME.queue = {}
    startDialogue(RUNTIME.branchQueue)
    RUNTIME.branchQueue = STORY.finale
end

local function beginScene1Dialogue()
    RUNTIME.scene1Triggered = true
    RUNTIME.keyHeld.left, RUNTIME.keyHeld.right = false, false
    RUNTIME.keyHeld.up, RUNTIME.keyHeld.down = false, false
    log("触发场景1靠右区域对话")
    startDialogue(STORY.scene1)
end

local function enterScene2()
    RUNTIME.scene = 2
    local scene = CONFIG.scene2
    RUNTIME.playerX = RUNTIME.canvasWidth * (scene.playerStartXRatio - 0.5)
    RUNTIME.playerY = RUNTIME.canvasHeight * (0.5 - scene.bridgeCenterYRatio)
    RUNTIME.controls.background1:SetVisible(false)
    RUNTIME.controls.background2:SetVisible(false)
    SCENE.SetVisible(RUNTIME, true)
    for _, tile in ipairs(RUNTIME.puzzleTiles) do tile:SetVisible(true) end
    RUNTIME.travelerRoot:SetAnchoredPosition(RUNTIME.playerX, RUNTIME.playerY)
    RUNTIME.scene2Triggered = false
    log("场景切换：scene1 -> scene2；旅行者已放置在场景2左侧")
end

local function beginScene2Dialogue()
    RUNTIME.scene2Triggered = true
    RUNTIME.keyHeld.left, RUNTIME.keyHeld.right = false, false
    RUNTIME.keyHeld.up, RUNTIME.keyHeld.down = false, false
    log("触发场景2靠左区域对话")
    startDialogue(STORY.scene2)
end

enterPuzzleScene = function()
    RUNTIME.scene = 3
    RUNTIME.controls.background2:SetVisible(false)
    SCENE.SetVisible(RUNTIME, true)
    RUNTIME.movementLocked = true
    RUNTIME.puzzlePhase = "random"
    RUNTIME.puzzleTimer = 0
    RUNTIME.puzzleChangeIndex = 1
    RUNTIME.puzzleRandomSeed = CONFIG.puzzle.randomSeed
    RUNTIME.keyHeld.left, RUNTIME.keyHeld.right = false, false
    RUNTIME.keyHeld.up, RUNTIME.keyHeld.down = false, false
    RUNTIME.playerX = RUNTIME.puzzleBoardLeft - CONFIG.travelerRootSize * 0.5
    RUNTIME.playerY = RUNTIME.puzzleBoardTop - RUNTIME.puzzleTileHeight * 3.5
    RUNTIME.travelerRoot:SetAnchoredPosition(RUNTIME.playerX, RUNTIME.playerY)
    randomizePuzzleTiles()
    log("场景2剧情结束，进入 S3；角色位于第4行第1格左侧并锁定移动")
end

local function cleanup()
    for _, item in ipairs(RUNTIME.callbacks) do
        if item.control and item.control.alive then
            item.control:RemoveCursorEventListener(item.event, item.callback)
        elseif RUNTIME.host and RUNTIME.host.alive then
            RUNTIME.host:RemoveKeyEventListener(item.event, item.callback)
        end
    end
    RUNTIME.callbacks = {}
    for _, control in pairs(RUNTIME.controls) do
        if control and control.alive then game.DestroyClientUIControl(control) end
    end
    RUNTIME.controls = {}
    log("清理完成")
end

-- 04.生命周期：每个回调只处理自身职责。
function OnInit()
    -- validateHostAndScript 的第一项实际操作就是读取 script.object。
    if not validateHostAndScript() then
        RUNTIME.ended = true
        return
    end
    log("OnInit：script.object 与入口脚本挂载关系检查完成")
    log("OnInit 完成")
end

function OnStart()
    log("OnStart：验证模板配置并创建界面")
    if RUNTIME.ended or not RUNTIME.host then
        printerr("[StoryPrototype] OnStart 中止：宿主控件未就绪")
        return
    end
    if not validateTemplateConfig() then
        RUNTIME.ended = true
        return
    end
    local ok, err = pcall(function()
        buildUI()
        MOVEMENT.SetInitialPosition(RUNTIME, CONFIG)
        MOVEMENT.BindInputs(RUNTIME, {
            advanceDialogue = advanceDialogue,
            chooseBranch = chooseBranch,
        }, log)
        -- 显式开启逐帧回调，确保按键状态会被 OnUpdate 消费并转换为位移。
        script:EnableUpdate(true)
        RUNTIME.started = true
        log("OnStart 完成：场景1已就绪，逐帧更新已开启，使用 WASD 自由移动")
    end)
    if not ok then
        printerr("[StoryPrototype] 初始化失败：" .. tostring(err))
        cleanup()
        RUNTIME.ended = true
    end
end

function OnEnable()
    log("OnEnable：脚本启用")
end

function OnUpdate(dt)
    if not RUNTIME.started or RUNTIME.ended then return end
    if type(dt) ~= "number" or math.isnan(dt) or math.isinf(dt) or dt <= 0 then return end
    if not RUNTIME.updateLogged then
        RUNTIME.updateLogged = true
        log("OnUpdate 已运行，dt=" .. tostring(dt))
    end
    updatePuzzlePerformance(dt)
    MOVEMENT.Update(RUNTIME, CONFIG, dt, {
        beginScene1Dialogue = beginScene1Dialogue,
        enterScene2 = enterScene2,
        beginScene2Dialogue = beginScene2Dialogue,
        puzzlePassed = function() startDialogue(STORY.puzzlePassed) end,
    })
end

function OnDisable()
    log("OnDisable：清除按键状态，暂停移动")
    RUNTIME.keyHeld.left, RUNTIME.keyHeld.right = false, false
    RUNTIME.keyHeld.up, RUNTIME.keyHeld.down = false, false
end

function OnDestroy()
    log("OnDestroy：移除事件监听并销毁本脚本创建的控件")
    cleanup()
end

