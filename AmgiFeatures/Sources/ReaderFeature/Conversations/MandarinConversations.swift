import Foundation

extension Conversation {
    var mandarinLearningFocus: String? {
        guard id.hasPrefix("mandarin-"), let number = Int(id.dropFirst("mandarin-".count)),
              number > 0, number <= MandarinContent.focus.count else { return nil }
        return MandarinContent.focus[number - 1]
    }
    /// Original graded dialogues. The six-level HSK labels describe approximate
    /// difficulty, not a claim that every word belongs to an official word list.
    static let mandarin: [Conversation] = MandarinContent.items.enumerated().map { index, item in
        let lines = item.text.split(separator: "\n").enumerated().compactMap { offset, raw -> Line? in
            let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            return Line(offset % 2, parts[0], parts[1])
        }
        return Conversation(id: "mandarin-\(index + 1)", title: item.title, englishTitle: item.english,
                            symbol: index < 6 ? "person.2" : "bubble.left.and.bubble.right",
                            level: index < 12 ? .beginner : .intermediate, language: "zh-CN",
                            speakers: [.init(name: "林悦", gender: .female), .init(name: "晓天", gender: .male)], lines: lines)
    }
}

private enum MandarinContent {
    static let focus = [
        "最近怎么样？— How have you been?\n后来怎么样了？— How did that turn out?\n虽然…但… connects a difficulty with a positive result.",
        "长高了不少 — grown quite a bit\n轮流 — take turns\n一…就… links events that follow immediately; use follow-up questions to show interest.",
        "总的来说 — overall\n安排时间 — organize your time\n一边…一边… describes simultaneous actions; 却 introduces an unexpected contrast.",
        "正在创业 — starting a company\n边做边学 — learn as you go\n先…再… explains priorities; 等…以后… sets a condition for your next step.",
        "当地人 — local people\n值得再去 — worth going back\n去过 describes experience; 比较 and 每个…都… help compare trips.",
        "留过学 — have studied abroad\n适应环境 — adapt to an environment\n过 marks experience; 说得更自然 uses 得 to describe how well you speak.",
        "要不…？— How about…?\n临时有变化 — a last-minute change\n如果…就… makes a flexible plan without putting pressure on your friend.",
        "还是一样 — still the same\n由房东负责 — the landlord is responsible\n把视频发给你 uses 把 to focus on what happens to the video.",
        "睡不着 — cannot fall asleep\n没什么精神 — low energy\nDescribe duration with 已经…了 and distinguish symptoms from your concerns.",
        "换大一号 — exchange for one size larger\n补差价 — pay the difference\n还没… contrasts with 已经…; 免得 introduces a problem you want to avoid.",
        "原来是这样 — so that explains it\n取件码 — pickup code\n放在… locates an object; 如果…再… explains what you will do if needed.",
        "改签 — change a ticket\n来得及 — have enough time\n先…再… helps you confirm the cost before committing to a change.",
        "结清 — settle the balance\n扣费用 — deduct charges\n其中… specifies part of a group; 至于… shifts to a related issue.",
        "优先顺序 — priorities\n与其…不如… — rather than… it is better to…\nExplain trade-offs with 如果…就需要… instead of making an unrealistic promise.",
        "彼此的节奏 — each other's pace\n互相迁就 — accommodate each other\n不一定 and 我倒觉得 soften disagreement while offering another perspective.",
        "恐怕去不了 — I'm afraid I can't go\n给你压力 — put pressure on you\nAcknowledge the invitation, explain your boundary, then offer an alternative.",
        "来回切换 — switch back and forth\n不一致 — inconsistent\n不只是…还要… separates the obvious need from the deeper one.",
        "冲动做决定 — make an impulsive decision\n定期停下来看看 — pause and reassess regularly\n只有…才… states a necessary condition.",
        "把话说开 — talk things through openly\n语气 — tone of voice\n不是…只是… clarifies your intention without dismissing the other person's feelings.",
        "换乘 — change connections\n余地 — room to maneuver\n首先…其次… organizes priorities; 虽然…但… acknowledges a problem before explaining the solution."
    ]
    struct Item { let title: String; let english: String; let text: String }
    static let items: [Item] = [
        Item(title: "好久不见，最近怎么样？", english: "Catching up with an old friend", text: """
        好久不见！你最近怎么样？感觉你好像特别忙。|Long time no see! How have you been? You seem especially busy.
        是啊，最近事情比较多，不过总的来说还不错。你呢？|Yes, there’s been a lot going on, but overall I’m doing well. How about you?
        我也还好。前一阵子工作太忙，现在终于轻松一点了。|I’m doing well too. Work was really busy for a while, but things have finally eased up.
        那就好。你上次说想换工作，后来怎么样了？|That’s good. Last time you mentioned wanting to change jobs. What happened with that?
        我考虑了很久，最后还是决定先留下来。|I thought about it for a long time and finally decided to stay for now.
        是因为现在的工作有了新的机会吗？|Is that because there are new opportunities at your current job?
        对，老板让我负责一个新项目，我觉得可以试试。|Yes, my boss put me in charge of a new project, and I thought I’d give it a try.
        听起来不错！虽然会忙一点，但应该能学到不少东西。|That sounds good! You’ll be busier, but you should learn a lot.
        我也是这么想的。你最近除了工作，还在忙什么？|That’s what I think too. What have you been doing besides work?
        我一直在学中文，想让自己说得更自然一点。|I’ve been studying Chinese. I want to sound more natural when I speak.
        那我们以后可以多用中文聊天，你不用怕说错。|Then we can chat in Chinese more often. Don’t worry about making mistakes.
        太好了！有时候我知道那个词，就是一下子想不起来。|Great! Sometimes I know a word but just can’t remember it on the spot.
        很正常。慢慢说就行，我也可以换一种说法。|That’s normal. Take your time; I can also say things another way.
        谢谢。跟你聊天比较放松，不像在上课。|Thanks. Chatting with you feels relaxed, unlike being in a class.
        那下周找个时间喝咖啡吧，好好聊聊。|Let’s find time for coffee next week and have a proper catch-up.
        好啊！我看看安排，明天给你发消息。|Sounds good! I’ll check my schedule and message you tomorrow.
        """),
        Item(title: "你儿子最近怎么样？", english: "Asking a friend about family", text: """
        你还记得我儿子吗？他最近开始学游泳了。|Do you remember my son? He’s recently started learning to swim.
        当然记得！他现在多大了？应该长高了不少吧？|Of course! How old is he now? He must have grown a lot.
        已经八岁了，衣服没穿多久就小了。|He’s eight already. He outgrows his clothes in no time.
        时间过得真快。他喜欢游泳吗？|Time really flies. Does he like swimming?
        一开始有点怕水，现在每个周末都问我什么时候去。|He was a little afraid of the water at first, but now he asks every weekend when we’re going.
        看来他已经喜欢上了。是你陪他去，还是他爸爸陪他去？|Sounds like he’s really taken to it. Do you go with him, or does his dad?
        我们轮流陪他去，这样谁都不会太累。|We take turns, so neither of us gets too tired.
        这样挺好的。他在学校过得怎么样？|That sounds sensible. How’s he getting on at school?
        学习还可以，就是有时候做作业不太认真。|His schoolwork is fine, but sometimes he doesn’t concentrate on his homework.
        他是不是一回家就想出去玩？|Does he want to go out and play as soon as he gets home?
        对，他说坐了一天了，想先活动一下。|Exactly. He says he’s been sitting all day and wants to move around first.
        我觉得也有道理。先玩一会儿，再做作业，可能效果更好。|I can see his point. Playing for a while before homework might work better.
        我们正在试这个办法，比每天催他好多了。|We’re trying that now. It’s much better than reminding him constantly.
        那就好。你自己呢？照顾孩子会不会没时间休息？|That’s good. How about you? Do you get any time to rest while looking after him?
        有时候会，所以我最近也给自己安排了一点时间。|Sometimes I don’t, so lately I’ve been setting aside a little time for myself too.
        很重要啊。下次有空一起吃饭，也可以带他来。|That matters. Let’s have a meal sometime—you can bring him along too.
        """),
        Item(title: "工作还顺利吗？", english: "Work, stress and everyday life", text: """
        最近工作还顺利吗？上次听你说有点累。|Has work been going smoothly? Last time you sounded a little tired.
        比前一阵子好多了。我开始把每天要做的事情写下来。|Much better than before. I’ve started writing down what I need to do each day.
        这样是不是更容易安排时间？|Does that make it easier to organize your time?
        对，至少不会一边做这件事，一边担心另一件事。|Yes. At least I’m not worrying about one thing while doing another.
        我也有这个问题，尤其是消息特别多的时候。|I have that problem too, especially when there are lots of messages.
        你一般怎么处理？会马上回复每一条吗？|How do you usually handle that? Do you reply to every message immediately?
        以前会，现在我尽量把需要专心的时间留出来。|I used to. Now I try to set aside time when I can concentrate.
        听起来很有用。我有时候忙了一天，却觉得什么都没做完。|That sounds useful. Sometimes I’m busy all day but feel I haven’t finished anything.
        可能是目标太多了。一天完成一两件重要的事也很好。|Maybe you have too many goals. Finishing one or two important things in a day is good too.
        你说得对。我还需要学会给自己一点时间。|You’re right. I also need to learn to give myself time.
        下班以后呢？你会继续看工作的消息吗？|What about after work? Do you keep checking work messages?
        偶尔会，不过我正在努力减少。你有什么建议？|Sometimes, but I’m trying to cut back. Do you have any suggestions?
        可以先出去走半个小时，不带工作电脑。|You could go for a half-hour walk first, without your work laptop.
        好主意。换个环境，心情应该也会好一点。|Good idea. A change of scene should improve my mood too.
        那今天一起走走吧，边走边聊。|Let’s take a walk together today and chat along the way.
        好啊，正好我也想听听你最近的情况。|Sure. I’d like to hear how you’ve been doing too.
        """),
        Item(title: "我正在创业", english: "Talking about starting my own company", text: """
        你最近在忙什么？好像有一段时间没见到你了。|What have you been up to? I feel like I haven’t seen you in a while.
        我最近正在创业，所以要考虑的事情比较多。|I’m starting my own company, so there’s a lot to think about.
        真的吗？你是什么时候开始有这个想法的？|Really? When did you first start thinking about it?
        这个说来话长，不过现在我已经开始认真做了。|That’s a long story, but I’ve started working on it seriously now.
        自己做公司应该跟以前很不一样吧？|Running your own company must be quite different from before.
        是啊，很多事情都需要自己决定，也需要边做边学。|Yes. I have to make lots of decisions myself and learn as I go.
        你现在最想解决的是什么问题？|What problem do you most want to solve right now?
        我想先弄清楚用户真正需要什么，再决定下一步。|I want to understand what users really need before deciding on the next step.
        这样比较实际。你会直接跟他们聊天吗？|That seems practical. Will you talk to them directly?
        会，我希望多听听他们的想法，别只按照自己的理解做。|Yes. I want to hear their ideas instead of relying only on my own understanding.
        听起来你已经想得挺清楚了。你会不会觉得压力很大？|It sounds like you’ve thought it through. Do you feel a lot of pressure?
        有时候会。不过能做自己的事情，我也觉得很有动力。|Sometimes. But working on something of my own also motivates me.
        如果有我能帮忙的地方，你就告诉我。|If there’s anything I can help with, let me know.
        谢谢！等我整理好想法，想听听你的意见。|Thanks! Once I’ve organized my thoughts, I’d love to hear your opinion.
        没问题。你也别忙得连饭都忘了吃。|Of course. Just don’t get so busy you forget to eat.
        哈哈，我会注意的。你呢？最近有什么新鲜事？|Haha, I’ll watch out for that. What about you? Anything new lately?
        """),
        Item(title: "今年去了哪些地方？", english: "My travels this year", text: """
        听说你今年去了不少地方，都去了哪里？|I heard you’ve traveled quite a bit this year. Where did you go?
        我去了澳大利亚、墨西哥、韩国和日本。|I went to Australia, Mexico, Korea and Japan.
        这么多地方！这些旅行是一起安排的吗？|So many places! Did you plan all those trips together?
        不是一次去完的。要把每次的经历讲清楚，可能得聊很久。|I didn’t visit them all in one trip. It might take a while to tell you about each experience.
        那先说一个吧。你觉得比较这些地方最有意思的是什么？|Then start with one. What do you find most interesting about comparing them?
        我喜欢看看当地人怎么生活，不只是去有名的景点。|I like seeing how local people live, not just visiting famous sights.
        我也是。去普通的市场走走，有时候比看景点更有意思。|Me too. Sometimes walking around an ordinary market is more interesting than sightseeing.
        对，而且可以顺便练习语言，跟人聊几句。|Exactly. You can also practice the language and chat with people a little.
        你在旅行的时候，会提前把每天都安排好吗？|When you travel, do you plan every day in advance?
        我觉得安排一部分就够了，也想给自己留一点自由时间。|I think planning part of it is enough. I like leaving some free time too.
        如果遇到计划突然改变，你会很着急吗？|Do you get anxious if plans suddenly change?
        当然会有一点，但也只能想办法解决，不能一直着急。|A little, of course. But you have to find a solution rather than stay anxious.
        说得也是。这几个地方里，你还想再去哪一个？|That’s true. Which of those places would you like to visit again?
        这个问题不好回答，每个地方都有值得再去看看的东西。|That’s hard to answer. Each place has things worth going back for.
        下次带照片给我看看吧，我也想听听具体的故事。|Show me some photos next time. I’d like to hear the actual stories too.
        好啊！你今年有没有去什么有意思的地方？|Sure! Have you been anywhere interesting this year?
        """),
        Item(title: "在香港留学的时候", english: "Talking about studying abroad in Hong Kong", text: """
        你以前是不是在香港留过学？|Didn’t you study abroad in Hong Kong?
        对，我以前在香港留过学。|Yes, I studied abroad there.
        那你对香港应该挺熟悉的吧？|Then you must know Hong Kong fairly well.
        比第一次去的时候熟悉多了，不过还有很多地方想了解。|Much better than when I first arrived, but there’s still a lot I’d like to learn about.
        留学和短期旅行的感觉有什么不同？|How does studying abroad feel different from a short trip?
        留学的时候要过日常生活，所以会注意到不一样的事情。|When you study abroad, you have to live everyday life, so you notice different things.
        比如买东西、坐车，还有跟同学相处？|Things like shopping, getting around and getting along with classmates?
        对。不只是看看风景，还得慢慢适应新的环境。|Exactly. It isn’t just sightseeing—you have to gradually adjust to a new environment.
        香港很多人说广东话，你现在学的是普通话，对吗？|Lots of people in Hong Kong speak Cantonese. You’re learning Mandarin now, right?
        对，我现在主要练习普通话，想跟别人聊得更自然。|Yes. I’m mainly practicing Mandarin now. I want to chat with people more naturally.
        你最想提高的是听力，还是表达能力？|Do you most want to improve your listening or your ability to express yourself?
        两个都想提高。有时候听懂了，回答却没有那么快。|Both. Sometimes I understand, but can’t respond as quickly.
        那可以多聊你熟悉的话题，比如旅行和工作。|Then you could talk more about familiar topics, like travel and work.
        我也是这么想的。自己的经历比较容易讲，也比较有兴趣。|That’s what I was thinking too. My own experiences are easier and more interesting to talk about.
        以后如果有机会，你还想回香港看看吗？|If you get the chance, would you like to go back to Hong Kong?
        想啊，也想看看以前熟悉的地方现在有什么变化。|Yes. I’d like to see how places I used to know have changed.
        """),
        Item(title: "周末怎么安排？", english: "Making plans without pressure", text: """
        这个周末你有安排吗？我们想找个地方聚一聚。|Do you have plans this weekend? We’d like to get together somewhere.
        星期六下午有点事，晚上应该有时间。你们想做什么？|I have something on Saturday afternoon, but should be free in the evening. What did you have in mind?
        还没决定。要不先吃饭，再去附近走走？|We haven’t decided. How about dinner, then a walk nearby?
        可以，不过我可能会晚到一会儿。|Sure, though I might be a little late.
        没关系。大概几点能到？我好订位子。|No problem. Around what time can you get there? Then I can book a table.
        七点左右。如果事情提前结束，我就早点过去。|Around seven. If I finish early, I’ll come sooner.
        你有没有特别想吃的，或者不能吃的东西？|Is there anything you particularly want to eat, or anything you can’t eat?
        我都可以，找一个方便聊天、不太吵的地方就好。|Anything is fine. Somewhere quiet enough to chat would be good.
        那上次那家怎么样？离地铁站也不远。|How about the place we went to last time? It’s close to the subway too.
        挺好的。不过周末人多，最好提前问一下。|That sounds good. But it gets busy on weekends, so we’d better check ahead.
        好，我来联系。你想不想叫上其他朋友？|Sure, I’ll contact them. Would you like to invite anyone else?
        可以问问小王，他最近好像也想出来放松一下。|We could ask Xiao Wang. I think he’s been wanting to get out and relax too.
        那你问他吧。我订好以后把地址发给你。|Then you ask him. I’ll send you the address once I’ve booked.
        好。如果临时有变化，我一定提前告诉你。|Okay. If anything changes, I’ll definitely let you know in advance.
        不用有压力，大家就是轻松聊聊天。|Don’t feel pressured. We’re just getting together for a relaxed chat.
        那太好了，我正好有不少事情想跟你们分享。|Great. I’ve got quite a few things I’d like to share with you.
        """),
        Item(title: "房间的空调坏了", english: "Explaining a repair problem", text: """
        你好，你说房间的空调有问题，具体是什么情况？|Hello. You said there’s a problem with the air conditioner. What exactly is happening?
        开了以后有声音，但是房间一直不凉快。|It makes a noise when I turn it on, but the room never cools down.
        这个问题是什么时候开始的？|When did this problem start?
        昨天晚上。以前大概十分钟就凉了，昨天等了一个小时也没用。|Last night. It used to cool down in about ten minutes, but yesterday even an hour didn’t help.
        遥控器上的温度和模式都检查过了吗？|Have you checked the temperature and mode on the remote?
        检查过了，也试着关掉再打开，还是一样。|Yes. I also tried turning it off and back on, but it’s still the same.
        明白了。我联系师傅，你今天什么时候在家？|I see. I’ll contact a technician. When will you be home today?
        下午三点以后都在，不过五点半有个线上会议。|Any time after three, but I have an online meeting at five thirty.
        那我问问他能不能三点到四点之间过去。|Then I’ll ask whether he can come between three and four.
        谢谢。修理之前能不能先告诉我大概需要多久？|Thanks. Could you let me know roughly how long the repair will take beforehand?
        可以，等他检查完，我让他跟你说明。|Of course. Once he’s checked it, I’ll ask him to explain.
        还有一个问题，修理费应该由谁来付？|One more question: who should pay for the repair?
        如果是正常使用造成的故障，由房东负责。|If it’s a fault from normal use, the landlord is responsible.
        好的，那我放心了。我可以把视频发给你。|Okay, that puts my mind at ease. I can send you a video.
        麻烦你发一下，这样师傅也能提前了解情况。|Please do. That way the technician can understand the situation in advance.
        没问题。时间确定以后，请给我发个消息。|No problem. Please message me once the time is confirmed.
        """),
        Item(title: "最近总是睡不好", english: "Describing symptoms at a clinic", text: """
        你哪里不舒服？这种情况有多久了？|What’s bothering you? How long has it been happening?
        最近总是睡不好，白天也没什么精神，大概有两个星期了。|I haven’t been sleeping well and feel tired during the day. It’s been about two weeks.
        是很难睡着，还是半夜容易醒？|Is it hard to fall asleep, or do you wake up during the night?
        主要是很难睡着，有时候躺了一个多小时还醒着。|Mainly trouble falling asleep. Sometimes I’m still awake after lying down for over an hour.
        最近生活或者工作有什么变化吗？|Have there been any recent changes in your life or work?
        工作比以前忙，晚上常常还在想第二天的事情。|Work has been busier, and I often keep thinking about the next day at night.
        除了睡不好，还有别的症状吗？|Apart from poor sleep, are there any other symptoms?
        偶尔会头疼，不过不严重。需要做什么检查吗？|I sometimes have a headache, but it isn’t severe. Do I need any tests?
        我先了解一下你的情况，再判断是否需要检查。|Let me understand your situation first, then assess whether tests are needed.
        好的。我需要把平时吃的药告诉你吗？|Okay. Should I tell you about the medicines I usually take?
        需要，包括保健品。有没有药物过敏也请告诉我。|Yes, including supplements. Please also tell me about any medication allergies.
        明白。我把名字记在手机里了，给你看一下。|Understood. I’ve written the names on my phone. Let me show you.
        好。你最担心的是什么？|Okay. What are you most concerned about?
        我担心一直这样会影响工作，也想知道什么时候应该再来。|I’m worried it’ll keep affecting my work. I’d also like to know when I should come back.
        看完以后我会把下一步和复诊安排跟你说清楚。|After the consultation I’ll explain the next steps and follow-up clearly.
        谢谢。如果有我没听懂的地方，可以请你再解释一次吗？|Thank you. If there’s something I don’t understand, could I ask you to explain it again?
        """),
        Item(title: "这件衣服能换吗？", english: "Returning a purchase politely", text: """
        你好，有什么可以帮你的吗？|Hello. How can I help you?
        我前天买了这件衣服，回家以后发现尺码不太合适。|I bought this two days ago and found the size wasn’t quite right when I got home.
        是太大还是太小？|Is it too big or too small?
        肩膀有点紧。我想问问能不能换大一号的。|It’s a bit tight around the shoulders. Could I exchange it for one size larger?
        请问小票还在吗？衣服有没有洗过？|Do you still have the receipt? Has it been washed?
        小票在这里。只试穿过，还没洗，标签也没拆。|Here’s the receipt. I’ve only tried it on; I haven’t washed it or removed the tags.
        那可以换。我帮你查一下还有没有大一号的。|Then we can exchange it. Let me check whether we have the next size up.
        谢谢。如果这个颜色没有，深蓝色也可以。|Thanks. If you don’t have this color, dark blue would be fine too.
        这个颜色没有了，深蓝色还有一件。|We’re out of this color, but we have one left in dark blue.
        我可以先试一下吗？免得换回去还是不合适。|Can I try it on first, so I don’t end up with another one that doesn’t fit?
        当然，试衣间在右边。|Of course. The fitting rooms are on the right.
        这件舒服多了。不过价格跟原来的一样吗？|This one is much more comfortable. Is it the same price as the original?
        一样，不需要补差价。|Yes, there’s no price difference to pay.
        好，那就换这件。还需要办什么手续吗？|Great. I’ll exchange it for this one. Is there anything else I need to do?
        我重新给你打一张小票，请把原来的交给我。|I’ll print you a new receipt. Please give me the original one.
        好的，麻烦你了。谢谢你帮我处理。|Sure. Thanks for helping me sort this out.
        """),
        Item(title: "快递送到哪里了？", english: "Resolving a delivery problem", text: """
        你好，我是快递员，你找我有什么事？|Hello, I’m the delivery driver. How can I help?
        你好，系统显示包裹已经送到了，可是我还没找到。|Hello. The system says my parcel was delivered, but I haven’t found it.
        你看过楼下的快递柜了吗？|Have you checked the parcel lockers downstairs?
        看过了，没有收到取件码，所以不知道在哪个柜子里。|Yes, but I haven’t received a pickup code, so I don’t know which locker it’s in.
        请把单号最后四位告诉我，我查一下。|Please tell me the last four digits of the tracking number. I’ll check.
        是三二六八。收件地址是明月小区三号楼。|It’s 3268. The delivery address is Building 3, Mingyue Residential Community.
        找到了。这个包裹放在门卫那里了，没有放进柜子。|I found it. The parcel was left with the gatekeeper, not in a locker.
        原来是这样。系统上没有写清楚，我以为送错了。|Oh, I see. That wasn’t clear in the system, so I thought it had gone to the wrong place.
        不好意思，今天包裹多，我忘了备注。|Sorry. There were lots of parcels today and I forgot to add a note.
        没关系。以后如果放在别的地方，能不能发条消息？|No problem. Could you message me next time if you leave it somewhere else?
        可以。我现在把具体位置发给你。|Of course. I’ll send you the exact location now.
        谢谢。我下楼看看，如果还是找不到，再联系你。|Thanks. I’ll go downstairs and check. If I still can’t find it, I’ll contact you again.
        好。取的时候告诉门卫你的姓名和手机尾号就行。|Okay. Just give the gatekeeper your name and the last digits of your phone number.
        找到了！刚才放在另一个架子上。|I found it! It was on another shelf.
        那就好，包装有没有破损？|That’s good. Is the packaging damaged at all?
        没有，看起来没问题。谢谢你帮忙确认。|No, it looks fine. Thanks for helping me check.
        """),
        Item(title: "能不能改签？", english: "Changing train tickets", text: """
        你好，请问你要办理什么业务？|Hello. What would you like help with?
        我想把今天下午的车票改到晚上，不知道还有没有票。|I’d like to change my ticket from this afternoon to this evening. Are there any seats left?
        你想几点出发？目的地不变吧？|What time would you like to leave? The destination is the same, right?
        对，还是去上海。七点以后出发比较合适。|Yes, still Shanghai. Leaving after seven would work best.
        七点二十分还有二等座，八点那班只剩一等座了。|There are second-class seats at 7:20. The eight o’clock train only has first-class seats left.
        七点二十分那班几点到？|What time does the 7:20 train arrive?
        九点十分到。你要改成这班吗？|It arrives at 9:10. Would you like to change to that train?
        先等一下。我想确认到站以后还有没有地铁。|One moment. I’d like to check whether the subway will still be running after I arrive.
        可以，你先查一下。余票情况可能会变化。|Sure, take a look. Seat availability may change.
        查好了，应该来得及。改签需要补多少钱？|I’ve checked, and I should have time. How much extra would the change cost?
        我查一下这张票的改签规则和票价差额。|Let me check this ticket’s change rules and the fare difference.
        好的，请先告诉我总共要付多少，再帮我确认。|Okay. Please tell me the total I’d need to pay before confirming it.
        没问题。请把证件给我核对一下。|Of course. Please let me check your ID.
        在这里。改签后原来的座位就取消了，对吗？|Here it is. Once the change is made, the original seat is canceled, right?
        对，办理成功后请以新的车次和座位为准。|Yes. After the change succeeds, use the new train and seat details.
        明白了，谢谢。我会再核对一下出发站。|Understood, thank you. I’ll double-check the departure station too.
        """),
        Item(title: "押金应该怎么退？", english: "Negotiating a rental deposit", text: """
        你准备月底搬走，对吧？我们约个时间检查房间。|You’re planning to move out at the end of the month, right? Let’s arrange an inspection.
        对。我想提前确认一下，押金什么时候能退？|Yes. I’d like to confirm in advance when the deposit can be refunded.
        检查完房间，再结清水电费，就可以处理。|We can process it after inspecting the room and settling the utility bills.
        好的。如果要扣费用，能不能把原因和金额列清楚？|Okay. If there are deductions, could you list the reasons and amounts clearly?
        可以。不过墙上的几处痕迹可能需要处理。|Sure. But a few marks on the wall might need attention.
        其中两处我入住时就有了，当时还拍了照片。|Two of them were already there when I moved in. I took photos at the time.
        那你发给我看看，我们对照一下。|Send them to me and we’ll compare.
        我发过去了。至于书桌旁边那处，我们可以现场确认。|I’ve sent them. As for the one beside the desk, we can check it in person.
        好，这样比较公平。你什么时候方便？|Okay, that seems fair. When are you available?
        周六上午可以。我希望检查的时候把问题一次说清楚。|Saturday morning works. I’d like us to clarify everything during the inspection.
        没问题。如果双方都确认了，我就准备退款。|No problem. Once we’ve both confirmed things, I’ll arrange the refund.
        能不能给一个具体日期？我好安排接下来的费用。|Could you give me a specific date? That would help me plan my upcoming expenses.
        我先核对最后一张账单，周六给你明确答复。|I’ll check the final bill and give you a definite answer on Saturday.
        谢谢。我也会把钥匙和物品清单准备好。|Thanks. I’ll prepare the keys and inventory list too.
        那就周六十点见，有变化提前联系。|Then let’s meet at ten on Saturday. We’ll contact each other in advance if anything changes.
        好的。希望我们把事情顺利处理完。|Okay. I hope we can get everything settled smoothly.
        """),
        Item(title: "这个期限现实吗？", english: "Discussing a work deadline", text: """
        客户希望下周五看到完整版本，你觉得来得及吗？|The client hopes to see the complete version next Friday. Do you think we can make it?
        如果所有功能都要完成，我担心质量没办法保证。|If every feature has to be finished, I’m worried we can’t guarantee the quality.
        你觉得主要的困难在哪里？|Where do you think the main difficulty lies?
        需求还在变化，而且有两部分需要等对方确认。|The requirements keep changing, and two parts are waiting for their confirmation.
        那我们是不是应该先把优先顺序确定下来？|Then should we agree on the priorities first?
        对。与其同时做所有事情，不如先完成最重要的流程。|Yes. Rather than doing everything at once, we should finish the most important flow first.
        如果只做这一部分，下周五能交付吗？|If we only do that part, can we deliver it next Friday?
        可以争取，但需要今天把范围固定下来。|We can aim for that, but we need to fix the scope today.
        我来跟客户沟通，你能把取舍解释清楚吗？|I’ll talk to the client. Can you explain the trade-offs clearly?
        可以。我会写明哪些内容先交，哪些放到下一阶段。|Yes. I’ll specify what we’ll deliver first and what goes into the next stage.
        别忘了说明，这样安排能给客户带来什么好处。|Don’t forget to explain how this approach benefits the client.
        明白。先让他们实际使用，比等一个不稳定的完整版更有价值。|Understood. Letting them actually use it first is more valuable than waiting for an unstable full version.
        如果他们还是坚持原来的范围呢？|What if they still insist on the original scope?
        那就需要讨论延长期限，不能只答应却做不到。|Then we need to discuss extending the deadline. We can’t agree to something we can’t deliver.
        同意。我们先把两个方案准备好。|Agreed. Let’s prepare both options first.
        好，我下午发给你，你看完以后我们再一起调整。|Okay. I’ll send them this afternoon, and we can adjust them together after you’ve reviewed them.
        """),
        Item(title: "朋友之间意见不同", english: "Disagreeing without damaging a friendship", text: """
        我觉得旅行就应该尽量多去几个地方，不然太可惜了。|I think you should visit as many places as possible when traveling, or it’s a wasted opportunity.
        我理解你的想法，不过我更喜欢在一个地方多待几天。|I understand your view, but I prefer staying longer in one place.
        你不会觉得每天都在同一个城市很无聊吗？|Don’t you get bored being in the same city every day?
        不一定。慢一点反而能发现平时容易错过的东西。|Not necessarily. Slowing down can help you discover things you’d otherwise miss.
        可是好不容易出一次远门，我总想多看看。|But when I finally get a chance to travel far away, I always want to see more.
        这也有道理。可能我们对旅行的期待不太一样。|That makes sense too. Maybe we want different things from a trip.
        如果我们一起去，会不会很难安排？|Would it be difficult to plan if we traveled together?
        可以提前说清楚，不必每天都一起行动。|We could discuss it beforehand. We don’t have to do everything together every day.
        分开玩会不会显得不够重视对方？|Would doing things separately seem like we don’t value each other?
        我倒觉得尊重彼此的节奏也很重要。|I actually think respecting each other’s pace matters too.
        这么说也对。那可以选几天一起，几天自由活动。|That’s true. We could spend some days together and have some free days.
        对，晚上再一起吃饭，分享各自看到的东西。|Exactly. Then we could have dinner together and share what we saw.
        听起来比互相迁就一整天轻松多了。|That sounds much easier than accommodating each other all day.
        是啊，意见不同不代表谁对谁错。|Yes. Having different opinions doesn’t mean one of us is right and the other wrong.
        幸好提前聊到了，不然路上可能会有误会。|I’m glad we discussed it beforehand, or we might have misunderstood each other during the trip.
        能直接说出来就好，我们慢慢找适合双方的办法。|It’s good that we can say it openly. We’ll find an approach that suits us both.
        """),
        Item(title: "礼貌地拒绝邀请", english: "Declining an invitation warmly", text: """
        这周末我们要去郊外住两天，你要不要一起？|We’re spending two days out of town this weekend. Would you like to join us?
        谢谢你想到我！听起来很不错，不过这次恐怕去不了。|Thanks for thinking of me! It sounds lovely, but I’m afraid I can’t this time.
        是已经有别的安排了吗？|Do you already have other plans?
        最近事情有点多，我想留一点时间休息和整理。|There’s been a lot going on lately. I want to leave some time to rest and get organized.
        其实出去换个环境也能放松，不再考虑一下吗？|A change of scene can be relaxing too. Won’t you reconsider?
        我知道你的意思，但这周我确实更需要安静地待一待。|I see what you mean, but this week I really need some quiet time.
        明白了，我不是想给你压力，只是很想跟你一起玩。|I understand. I’m not trying to pressure you; I just really wanted to spend time with you.
        我也想跟你们见面。要不下周找一天吃晚饭？|I’d like to see you too. How about dinner one day next week?
        好啊，这样时间短一点，也不会太累。|Sure. That would take less time and wouldn’t be so tiring.
        对，而且可以好好听你们讲这次旅行的事。|Exactly. And I can hear all about your trip.
        那我回来以后联系你，看看哪天合适。|Then I’ll contact you when we get back to find a suitable day.
        好的。如果你们需要推荐餐厅，也可以问我。|Okay. If you need restaurant recommendations, you can ask me too.
        谢谢。你不用因为没来觉得不好意思。|Thanks. You don’t need to feel bad about not coming.
        听你这么说我就放心了，我还怕你以为我不想见你们。|That’s reassuring. I was worried you might think I didn’t want to see you.
        怎么会呢？朋友之间不用每次都答应。|Of course not! Friends don’t have to say yes every time.
        那祝你们玩得开心，回来再聊！|Then have a great time, and we’ll catch up when you’re back!
        """),
        Item(title: "先听听用户怎么说", english: "Learning what a potential customer needs", text: """
        你说想了解我的工作流程，具体想问什么？|You said you wanted to understand my workflow. What would you like to ask?
        我想先听听你最近一次遇到这个问题时，是怎么处理的。|I’d like to hear how you handled this problem the last time it happened.
        一般就是在几个工具之间来回切换，再手动整理结果。|Usually I switch between several tools, then organize the results manually.
        能不能用一个具体例子说明？哪一步最花时间？|Could you give me a specific example? Which step takes the most time?
        核对信息最麻烦，因为不同地方的数据经常不一致。|Checking the information is the hardest part because the data in different places often doesn’t match.
        这种情况大概多久发生一次？|Roughly how often does that happen?
        几乎每周都会遇到，忙的时候一天好几次。|Almost every week. When it’s busy, several times a day.
        如果没及时处理，会有什么影响？|What happens if you don’t deal with it promptly?
        后面的人就没办法继续，有时候还得重新做一遍。|The next person can’t continue, and sometimes we have to do it all over again.
        你之前试过什么解决办法？为什么没有继续用？|What solutions have you tried before? Why didn’t you keep using them?
        试过自动整理，但结果不够可靠，我还是得全部检查。|I tried automatic organization, but the results weren’t reliable enough, so I still had to check everything.
        所以重点不只是节省时间，还要让你能放心使用，对吗？|So the point isn’t just saving time—you also need to trust it. Is that right?
        对。如果省下十分钟，却增加了出错的风险，我不会愿意用。|Exactly. If it saves ten minutes but increases the risk of errors, I wouldn’t want to use it.
        明白。我现在先了解情况，不急着让你接受某个方案。|Understood. I’m just trying to understand the situation, not rush you into a particular solution.
        这样挺好。等你有具体想法了，可以再来找我。|That’s good. You can come back when you have a concrete idea.
        谢谢。我会先整理今天听到的内容，再确认有没有理解错。|Thanks. I’ll organize what I heard today, then check whether I’ve misunderstood anything.
        """),
        Item(title: "为什么想换一种生活？", english: "Talking about priorities and change", text: """
        你最近好像在重新考虑以后的生活，是什么让你有这个想法？|You seem to be reconsidering how you want to live. What led you to that?
        我发现自己一直很忙，却很少问这些事情是不是我真正想做的。|I realized I’m always busy but rarely ask whether these are things I actually want to do.
        我有时候也这样。别人觉得不错的选择，不一定适合自己。|I feel that sometimes too. A choice other people think is good may not suit you.
        对。但真的要改变，又会担心失去现在拥有的东西。|Exactly. But when it comes to changing, I worry about losing what I already have.
        你最担心的是收入不稳定，还是别人不理解？|Are you most worried about unstable income, or people not understanding?
        两方面都有。我想给自己一个机会，也不想冲动做决定。|Both. I want to give myself a chance without making an impulsive decision.
        也许不需要一下子全改，可以先做一个小尝试。|Maybe you don’t need to change everything at once. You could start with a small experiment.
        这个办法比较实际。先看看真实的感受，再决定要不要继续。|That seems practical. See how it actually feels before deciding whether to continue.
        你有没有想过，用什么标准判断这次尝试值不值得？|Have you thought about how you’ll judge whether the experiment is worthwhile?
        除了结果，我还想看看自己有没有学到东西，是否愿意继续投入。|Besides the outcome, I want to see whether I learn something and want to keep investing effort.
        这样就不会只因为一次不顺利，就觉得整个选择都错了。|Then one setback won’t make you feel the whole decision was wrong.
        是啊。我也需要接受，有些问题只有开始以后才会有答案。|Yes. I also need to accept that some questions can only be answered after I start.
        不管怎样，你可以定期停下来看看，而不是一直硬撑。|Either way, you can pause and reassess regularly instead of forcing yourself to keep going.
        谢谢。跟你聊完，我觉得没必要马上把所有事情想明白。|Thanks. After talking to you, I feel I don’t need to figure everything out immediately.
        对，先把下一步走稳就好。|Exactly. Just take the next step carefully.
        那我先从一个小目标开始，下次见面再告诉你进展。|Then I’ll start with a small goal and tell you how it goes next time we meet.
        """),
        Item(title: "遇到误会怎么解释？", english: "Clearing up a misunderstanding", text: """
        昨天我给你发消息，你一直没回，我还以为你生气了。|You didn’t reply to my messages yesterday. I thought you were upset.
        不好意思，让你误会了。我当时在处理一件事情，后来忘了回复。|Sorry for the misunderstanding. I was dealing with something and forgot to reply afterward.
        我知道你忙，只是前一天我们刚好有点意见不同。|I know you’re busy. It’s just that we’d disagreed about something the day before.
        我明白，所以你把两件事联系起来了，对吗？|I see, so you connected the two things, right?
        对。我不想一直猜，就直接问你了。|Yes. I didn’t want to keep guessing, so I asked you directly.
        你这样问很好。我没有因为那件事生气。|I’m glad you asked. I wasn’t upset about that.
        那就好。不过你当时说话有点急，我确实不太舒服。|That’s good. But you sounded a little impatient at the time, and it did bother me.
        谢谢你告诉我。我当时着急把意思说清楚，没注意自己的语气。|Thanks for telling me. I was eager to explain myself and didn’t notice my tone.
        我不是要求你一定同意我，只是希望我们能慢慢说。|I’m not asking you to agree with me. I just hope we can talk things through calmly.
        可以。下次如果我又说得太急，你可以提醒我。|Of course. If I sound impatient again, you can remind me.
        我也会直接说自己的感受，不让你猜。|I’ll also tell you how I feel instead of making you guess.
        这样好多了。至于昨天的消息，我现在认真看一下。|That’s much better. As for yesterday’s messages, I’ll read them properly now.
        不急，主要是想跟你确认周末的时间。|No rush. I mainly wanted to confirm the time for the weekend.
        那我们还是按原来的安排，星期天下午见？|Then shall we stick to the original plan and meet Sunday afternoon?
        好。把话说开以后，我轻松多了。|Yes. I feel much better now that we’ve talked openly.
        我也是。谢谢你愿意直接跟我聊。|Me too. Thanks for being willing to talk to me directly.
        """),
        Item(title: "旅行计划突然变了", english: "Handling a disrupted trip together", text: """
        刚收到通知，我们原来订的那班车取消了。|I just got a notification: the service we booked has been canceled.
        先别着急。通知里有没有说明可以改到哪一班？|Don’t panic. Does the notice say which service we can change to?
        可以改到明天上午，但这样会影响酒店和后面的安排。|We can change to tomorrow morning, but that would affect the hotel and our later plans.
        那我们先把必须处理的事情列出来，别同时乱改。|Then let’s list what needs dealing with before changing everything at once.
        首先是今晚住哪里，其次是明天能不能赶上活动。|First, where to stay tonight; second, whether we can make tomorrow’s activity.
        活动能不能改时间？如果可以，我们就不用那么赶。|Can we reschedule the activity? If so, we won’t have to rush so much.
        我来联系主办方，你帮忙看看其他交通方式，好吗？|I’ll contact the organizer. Could you check other transport options?
        没问题。我们先确定预算，免得临时买了特别贵的票。|Sure. Let’s agree on a budget first so we don’t buy an extremely expensive ticket in a panic.
        对。如果只是晚半天，多花太多钱可能不值得。|Right. If we’re only half a day late, spending a lot extra might not be worth it.
        我查到了另一条路线，需要换乘，但今天能到。|I found another route. It requires a connection, but we could arrive today.
        中间留的时间够吗？我怕一趟晚点，后面都赶不上。|Is there enough time between services? I’m worried one delay would make us miss the rest.
        只有二十分钟，我觉得风险有点高，不太建议。|Only twenty minutes. I think that’s a bit risky and wouldn’t recommend it.
        主办方回复了，可以改到明天下午。|The organizer replied: we can move the activity to tomorrow afternoon.
        那就轻松多了。我们改明早的车，再确认今晚的住宿。|That makes things easier. Let’s take tomorrow morning’s service and confirm tonight’s accommodation.
        好。我会把新的安排发给你，我们再检查一遍。|Okay. I’ll send you the new plan, and we can check it once more.
        辛苦了。虽然计划变了，但我们还是能把问题解决。|Thanks for handling that. The plan changed, but we can still sort things out.
        """),
    ]
}
