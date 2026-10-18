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
    puzzlePassed = {
        { speaker = "伊涅芙", portrait = "ineffa", expression = "开心", text = "恭喜你通过了这个考验" },
        { speaker = "伊涅芙", portrait = "ineffa", expression = "告别", text = "我要去告诉爱诺这个消息了，再见旅行者" },
    },
}

return STORY

