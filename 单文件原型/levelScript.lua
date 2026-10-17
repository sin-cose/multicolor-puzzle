--[=[
彩砖剧情原型：单文件版本

当前范围：自由移动、两段场景触发对话、鼠标选择对话选项。
不包含谜题逻辑、电话、提示、设置、存档或结算。

未来拆分建议：本文件按「配置 / 数据 / 控件 / 对话 / 移动 / 生命周期」分区。
迁移到多文件时，优先将“配置与剧情数据”迁入 data，移动规则迁入 world，
对话与控件管理迁入 story/ui；入口仍保留 levelScript.lua。
]=]

-- 01.统一配置：先填入编辑器中实际创建的模板索引；不猜测或填入虚构编号。
local CONFIG = {
    expectedScriptShortName = "levelScript",
    movementSpeed = 360, -- UI 坐标单位/秒，后续可按试玩手感调整
    edgePadding = 56,
    scene1DialogueX = 0.78, -- 场景1行至屏幕宽度的78%时触发
    scene2DialogueX = 0.18, -- 场景2从左侧走至屏幕宽度的18%时触发
    templates = {
        scene1Background = 1073741857, -- 图片控件模板索引；模板内预先配置场景1背景
        scene2Background = 1073741859, -- 图片控件模板索引；模板内预先配置场景2背景
        traveler = 1073741861,         -- 图片控件模板索引；模板内预先配置旅行者形象
        portraitTraveler = 1073741865, -- 图片控件模板索引；模板内预先配置旅行者头像
        portraitAino = 1073741864,     -- 图片控件模板索引；模板内预先配置爱诺头像
        portraitIneffa = 1073741867,   -- 图片控件模板索引；模板内预先配置伊涅芙头像
        portraitNpcOne = 1073741881,          -- 可选图片控件模板索引；场景1“一个人”的头像
        portraitNpcTwo = 1073741882,          -- 可选图片控件模板索引；场景1“另一个人”的头像
        speakerText = 1073741869,      -- 文本框模板索引
        dialogueText = 1073741871,     -- 文本框模板索引
        advanceArea = 1073741873,      -- 光标检测区域模板索引
    },
}

-- nil 值不会保留在 Lua table 中，所以不能用 pairs(CONFIG.templates)
-- 检查是否漏填；这里明确列出每个必填模板键。
local REQUIRED_TEMPLATE_KEYS = {
    "scene1Background",
    "scene2Background",
    "traveler",
    "portraitTraveler",
    "portraitAino",
    "portraitIneffa",
    "speakerText",
    "dialogueText",
    "advanceArea",
}

-- 02.剧情数据：表达（text）及角色表情参数（expression）集中存放。
local STORY = {
    scene1 = {
        { speaker = "旅行者", portrait = "traveler", expression = "疑惑", text = "前面好像有什么人在说话" },
        { speaker = "一个人", portrait = "npcOne", expression = "期待", text = "我们等了这么久了，旅行者怎么还没来" },
        { speaker = "另一个人", portrait = "npcTwo", expression = "平静", text = "不要着急，这条路是前往至冬的必经之路。TA一定会来的。" },
        { speaker = "旅行者", portrait = "traveler", expression = "熟悉", text = "声音好像有点熟悉，过去看看吧" },
    },
    scene2 = {
        { speaker = "爱诺", portrait = "aino", expression = "兴奋", text = "嘿！伊涅芙你快看，旅行者真的来了！" },
        { speaker = "爱诺", portrait = "aino", expression = "不舍", text = "旅行者，我们都知道你要到至冬去了，但是我们都很舍不得你。" },
        { speaker = "爱诺", portrait = "aino", expression = "认真", text = "所以，你只有完成了这道谜题，我们才会放你走。" },
        { speaker = "爱诺", portrait = "aino", expression = "自信", text = "不过你放心，我专门设计的这道题绝对不会为难你的。" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "看到这些地砖了吗！？" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "一旦我启动这个机关，" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "它们就会开始变色！" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "每种颜色都有特殊的作用！" },
        { speaker = "爱诺", portrait = "aino", expression = "认真", text = "红砖不能通过，你不能在上面行走！" },
        { speaker = "爱诺", portrait = "aino", expression = "认真", text = "黄砖是带电的！踩上去就会触电！" },
        { speaker = "爱诺", portrait = "aino", expression = "认真", text = "绿砖是警报砖！一旦踩上去……" },
        { speaker = "爱诺", portrait = "aino", expression = "认真", text = "你就得和伊涅芙打一架！" },
        { speaker = "伊涅芙", portrait = "ineffa", expression = "困惑", text = "O-O？" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "橙色砖是橘子味的，踩上去会使你闻起来很好吃！" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "蓝砖是水，喜欢的话可以游过去" },
        { speaker = "爱诺", portrait = "aino", expression = "警告", text = "但如果你闻起来像橘子，食人鱼会咬你。" },
        { speaker = "爱诺", portrait = "aino", expression = "警告", text = "而且，如果蓝砖的旁边靠着黄砖，" },
        { speaker = "爱诺", portrait = "aino", expression = "警告", text = "跳进水里同样会触电！" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "紫砖特别滑！你会滑向下一块砖！" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "不过地板上滑溜溜的香皂闻起来像柠檬！" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "食人鱼不喜欢这个味道。紫砖连着蓝砖是可以的。" },
        { speaker = "爱诺", portrait = "aino", expression = "介绍", text = "最后，粉红砖。它没有任何作用，你可以随便踩。" },
        { speaker = "爱诺", portrait = "aino", expression = "询问", text = "怎么样！？明白了？？？" },
        { speaker = "爱诺", portrait = "aino", expression = "询问", text = "明白了吗？", choices = {
            { text = "那当然了", branch = "understood" },
            { text = "没", branch = "notUnderstood" },
        } },
    },
    branches = {
        understood = {
            { speaker = "爱诺", portrait = "aino", expression = "开心", text = "太棒了！如果后面忘了可以直接问伊涅芙哦。" },
        },
        notUnderstood = {
            { speaker = "爱诺", portrait = "aino", expression = "尴尬", text = "但是我也记不清了，能背过一遍已经很累了。" },
            { speaker = "爱诺", portrait = "aino", expression = "拜托", text = "这样吧，伊涅芙，你负责提醒旅行者好吗。" },
            { speaker = "伊涅芙", portrait = "ineffa", expression = "答应", text = "好的" },
        },
    },
    finale = {
        { speaker = "爱诺", portrait = "aino", expression = "认真", text = "很好！还有最后一件事……" },
        { speaker = "爱诺", portrait = "aino", expression = "恶作剧", text = "这个谜题，是完全随机的！！！！！！" },
        { speaker = "爱诺", portrait = "aino", expression = "兴奋", text = "是前所未有的，连我都没有见过的谜题！" },
        { speaker = "爱诺", portrait = "aino", expression = "坏笑", text = "嘿嘿，准备好……" },
    },
}

-- 03.运行时状态：本单文件内的共享状态仅由此处持有。
local RUNTIME = {
    host = nil,
    canvasWidth = 0,
    canvasHeight = 0,
    controls = {},
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

    local player = createControl("traveler", "Story_Traveler", 0, -height * 0.12, 88, 128, 0.5, 0.5)
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
    RUNTIME.controls.player = player
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
        log("对话段落结束")
        return
    end

    local line = RUNTIME.queue[RUNTIME.queueIndex]
    if line == nil then return end
    setVisible(RUNTIME.controls.dialogueFrame, true)
    setPortraitFor(line.portrait)
    RUNTIME.controls.speaker.text = line.speaker
    RUNTIME.controls.dialogue.text = line.text
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
    RUNTIME.playerX = -RUNTIME.canvasWidth * 0.42
    RUNTIME.playerY = -RUNTIME.canvasHeight * 0.12
    RUNTIME.controls.background1:SetVisible(false)
    RUNTIME.controls.background2:SetVisible(true)
    RUNTIME.controls.player:SetAnchoredPosition(RUNTIME.playerX, RUNTIME.playerY)
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

local function bindKey(eventDown, eventUp, keyName, direction)
    local downCallback = function()
        if RUNTIME.queue == nil and not RUNTIME.ended then
            RUNTIME.keyHeld[direction] = true
            log("输入按下：" .. keyName .. " -> " .. direction)
        end
        return true
    end
    local upCallback = function()
        RUNTIME.keyHeld[direction] = false
        log("输入抬起：" .. keyName .. " -> " .. direction)
        return true
    end
    RUNTIME.host:AddKeyEventListener(eventDown, downCallback)
    RUNTIME.host:AddKeyEventListener(eventUp, upCallback)
    RUNTIME.callbacks[#RUNTIME.callbacks + 1] = { event = eventDown, callback = downCallback }
    RUNTIME.callbacks[#RUNTIME.callbacks + 1] = { event = eventUp, callback = upCallback }
    log("方向键监听已注册：" .. keyName)
end

local function bindInputs()
    bindKey(Enum.KeyEventType.KeyboardMoveLeftKeyDown, Enum.KeyEventType.KeyboardMoveLeftKeyUp, "A", "left")
    bindKey(Enum.KeyEventType.KeyboardMoveRightKeyDown, Enum.KeyEventType.KeyboardMoveRightKeyUp, "D", "right")
    bindKey(Enum.KeyEventType.KeyboardMoveForwardKeyDown, Enum.KeyEventType.KeyboardMoveForwardKeyUp, "W", "up")
    bindKey(Enum.KeyEventType.KeyboardMoveBackwardKeyDown, Enum.KeyEventType.KeyboardMoveBackwardKeyUp, "S", "down")
    bindKey(Enum.KeyEventType.KeyboardCraftspersonKey38Down, Enum.KeyEventType.KeyboardCraftspersonKey38Up, "←", "left")
    bindKey(Enum.KeyEventType.KeyboardCraftspersonKey39Down, Enum.KeyEventType.KeyboardCraftspersonKey39Up, "→", "right")
    bindKey(Enum.KeyEventType.KeyboardCraftspersonKey36Down, Enum.KeyEventType.KeyboardCraftspersonKey36Up, "↑", "up")
    bindKey(Enum.KeyEventType.KeyboardCraftspersonKey37Down, Enum.KeyEventType.KeyboardCraftspersonKey37Up, "↓", "down")

    local advanceCallback = function()
        advanceDialogue()
    end
    RUNTIME.controls.advance:AddCursorEventListener(Enum.CursorEventType.CursorClick, advanceCallback)
    RUNTIME.callbacks[#RUNTIME.callbacks + 1] = { control = RUNTIME.controls.advance, event = Enum.CursorEventType.CursorClick, callback = advanceCallback }

    local choice1Callback = function() chooseBranch(1) end
    local choice2Callback = function() chooseBranch(2) end
    RUNTIME.controls.choice1:AddCursorEventListener(Enum.CursorEventType.CursorClick, choice1Callback)
    RUNTIME.controls.choice2:AddCursorEventListener(Enum.CursorEventType.CursorClick, choice2Callback)
    RUNTIME.callbacks[#RUNTIME.callbacks + 1] = { control = RUNTIME.controls.choice1, event = Enum.CursorEventType.CursorClick, callback = choice1Callback }
    RUNTIME.callbacks[#RUNTIME.callbacks + 1] = { control = RUNTIME.controls.choice2, event = Enum.CursorEventType.CursorClick, callback = choice2Callback }
    log("鼠标对话推进与选项点击已注册")
end

local function updateMovement(dt)
    if RUNTIME.queue ~= nil or RUNTIME.ended then return end
    local xDirection = (RUNTIME.keyHeld.right and 1 or 0) - (RUNTIME.keyHeld.left and 1 or 0)
    local yDirection = (RUNTIME.keyHeld.up and 1 or 0) - (RUNTIME.keyHeld.down and 1 or 0)
    if xDirection == 0 and yDirection == 0 then return end

    local length = math.sqrt(xDirection * xDirection + yDirection * yDirection)
    xDirection, yDirection = xDirection / length, yDirection / length
    local step = CONFIG.movementSpeed * math.min(dt, 0.05)
    local minX, maxX = -RUNTIME.canvasWidth * 0.5 + CONFIG.edgePadding, RUNTIME.canvasWidth * 0.5 - CONFIG.edgePadding
    local minY, maxY = -RUNTIME.canvasHeight * 0.5 + CONFIG.edgePadding, RUNTIME.canvasHeight * 0.5 - CONFIG.edgePadding
    RUNTIME.playerX = math.max(minX, math.min(maxX, RUNTIME.playerX + xDirection * step))
    RUNTIME.playerY = math.max(minY, math.min(maxY, RUNTIME.playerY + yDirection * step))
    RUNTIME.controls.player:SetAnchoredPosition(RUNTIME.playerX, RUNTIME.playerY)

    if RUNTIME.scene == 1 then
        local normalizedX = (RUNTIME.playerX - minX) / (maxX - minX)
        if not RUNTIME.scene1Triggered and normalizedX >= CONFIG.scene1DialogueX then
            beginScene1Dialogue()
            return
        end
        if RUNTIME.scene1Triggered and normalizedX >= 0.985 then
            enterScene2()
            return
        end
    elseif RUNTIME.scene == 2 and not RUNTIME.scene2Triggered then
        local normalizedX = (RUNTIME.playerX - minX) / (maxX - minX)
        if normalizedX >= CONFIG.scene2DialogueX then beginScene2Dialogue() end
    end
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
        RUNTIME.playerX = -RUNTIME.canvasWidth * 0.42
        RUNTIME.playerY = -RUNTIME.canvasHeight * 0.12
        RUNTIME.controls.player:SetAnchoredPosition(RUNTIME.playerX, RUNTIME.playerY)
        bindInputs()
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
    if not RUNTIME.updateLogged then
        RUNTIME.updateLogged = true
        log("OnUpdate 已运行，dt=" .. tostring(dt))
    end
    updateMovement(dt)
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
