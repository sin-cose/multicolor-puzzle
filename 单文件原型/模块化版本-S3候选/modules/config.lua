-- 01.统一配置：先填入编辑器中实际创建的模板索引；不猜测或填入虚构编号。
local CONFIG = {
    expectedScriptShortName = "levelScript",
    movementSpeed = 360, -- UI 坐标单位/秒，后续可按试玩手感调整
    edgePadding = 56,
    travelerRootName = "TravelerRoot", -- 界面布局中、主脚本宿主下的角色容器名称
    travelerRootSize = 256, -- 空.lua 使用 64×64 网格、每格 4 个 UI 单位
    scene1DialogueX = 0.78, -- 场景1行至屏幕宽度的78%时触发
    scene2DialogueX = 0.18, -- 场景2从左侧走至屏幕宽度的18%时触发
    scene1 = {
        roadCenterStartRatio = 0.5000,
        roadCenterEndRatio = 0.4567,
        roadHalfStartRatio = 0.2950,
        roadHalfEndRatio = 0.1280,
        roadTaperStartRatio = 0.7000,
    },
    scene2 = {
        playerStartXRatio = 0.12,
        bridgeStartXRatio = 0.19,
        bridgeWidthRatio = 0.10,
        bridgeCenterYRatio = 0.4567,
        boardLeftRatio = 0.29,
        boardTopRatio = 0.24,
        boardWidthRatio = 0.54,
        boardHeightRatio = 0.52,
        mainLandLeftRatio = 0.27,
        mainLandTopRatio = 0.20,
        mainLandRightRatio = 0.96,
        mainLandBottomRatio = 0.79,
    },
    puzzle = {
        rows = 6,
        columns = 8,
        grayPalette = {
            { r = 151, g = 153, b = 156 },
            { r = 133, g = 135, b = 138 },
            { r = 162, g = 164, b = 166 },
        },
        accelerationChanges = 19,
        decelerationChanges = 19,
        totalChanges = 91,
        startIntervalSeconds = 0.42,
        minIntervalSeconds = 0.067,
        accelerationPower = 7.5,
        fakeoutPauseSeconds = 0.5,
        fakeoutHoldSeconds = 1.5,
        targetHoldSeconds = 2,
        randomSeed = 73241,
        palette = {
            { code = "P", r = 255, g = 193, b = 193 },
            { code = "R", r = 255, g = 0, b = 0 },
            { code = "Y", r = 255, g = 255, b = 0 },
            { code = "G", r = 0, g = 255, b = 0 },
            { code = "O", r = 255, g = 128, b = 64 },
            { code = "U", r = 255, g = 0, b = 255 },
            { code = "B", r = 0, g = 0, b = 255 },
        },
        fakeoutRows = { "B", "Y", "G", "U", "O", "R" },
        targetRows = { "R", "R", "P", "P", "R", "R" },
    },
    templates = {
        scene1Background = 1073741857, -- 图片控件模板索引；模板内预先配置场景1背景
        scene2Background = 1073741859, -- 图片控件模板索引；模板内预先配置场景2背景
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
    "portraitTraveler",
    "portraitAino",
    "portraitIneffa",
    "speakerText",
    "dialogueText",
    "advanceArea",
}

return { CONFIG = CONFIG, REQUIRED_TEMPLATE_KEYS = REQUIRED_TEMPLATE_KEYS }

