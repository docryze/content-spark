import '../constants/app_enums.dart';

/// 热点话题数据模型
class HotTopic {
  final int rank;
  final String title;
  final HotSource source;
  final ContentCategory category;
  final String hotValue; // 热度值描述（如 "1234万"）
  final String? tag; // 标签（如 "爆"、"新"、"热"）
  final DateTime fetchedAt;

  HotTopic({
    required this.rank,
    required this.title,
    required this.source,
    required this.category,
    this.hotValue = '',
    this.tag,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();
}

/// 热点数据服务 — 模拟数据，20条/来源
class HotTopicsService {
  /// 获取指定来源的热点列表
  List<HotTopic> getTopics(HotSource source) {
    return _mockData[source] ?? [];
  }

  /// 获取所有来源的热点
  Map<HotSource, List<HotTopic>> getAllTopics() => _mockData;

  /// 按品类筛选
  List<HotTopic> getTopicsByCategory(HotSource source, ContentCategory category) {
    return getTopics(source).where((t) => t.category == category).toList();
  }

  /// 模拟延迟获取（模拟网络请求）
  Future<List<HotTopic>> fetchTopics(HotSource source, {Duration delay = const Duration(milliseconds: 600)}) async {
    await Future.delayed(delay);
    return getTopics(source);
  }

  // ==================== 模拟数据 ====================

  static final Map<HotSource, List<HotTopic>> _mockData = {
    // ========== 微博热搜 ==========
    HotSource.weibo: [
      HotTopic(rank: 1, title: '某顶流官宣恋情', source: HotSource.weibo, category: ContentCategory.entertainment, hotValue: '5821万', tag: '爆'),
      HotTopic(rank: 2, title: '今年高考作文题出炉', source: HotSource.weibo, category: ContentCategory.education, hotValue: '4392万', tag: '热'),
      HotTopic(rank: 3, title: '苹果WWDC发布新系统', source: HotSource.weibo, category: ContentCategory.tech, hotValue: '3876万', tag: '新'),
      HotTopic(rank: 4, title: '某网红直播间翻车', source: HotSource.weibo, category: ContentCategory.entertainment, hotValue: '3241万', tag: '热'),
      HotTopic(rank: 5, title: '一线城市二手房成交量暴涨', source: HotSource.weibo, category: ContentCategory.finance, hotValue: '2987万', tag: '热'),
      HotTopic(rank: 6, title: '夏日清冷感妆容教程', source: HotSource.weibo, category: ContentCategory.beauty, hotValue: '2754万', tag: '新'),
      HotTopic(rank: 7, title: '某明星机场穿搭出圈', source: HotSource.weibo, category: ContentCategory.fashion, hotValue: '2543万', tag: '热'),
      HotTopic(rank: 8, title: '年轻人为什么不爱吃外卖了', source: HotSource.weibo, category: ContentCategory.food, hotValue: '2312万', tag: ''),
      HotTopic(rank: 9, title: 'A股三大指数集体上涨', source: HotSource.weibo, category: ContentCategory.finance, hotValue: '2198万', tag: ''),
      HotTopic(rank: 10, title: '某综艺嘉宾争吵片段', source: HotSource.weibo, category: ContentCategory.entertainment, hotValue: '2087万', tag: '热'),
      HotTopic(rank: 11, title: '日本核污水排海最新进展', source: HotSource.weibo, category: ContentCategory.tech, hotValue: '1965万', tag: ''),
      HotTopic(rank: 12, title: '宠物狗坐地铁被拒引争议', source: HotSource.weibo, category: ContentCategory.pet, hotValue: '1834万', tag: ''),
      HotTopic(rank: 13, title: '某品牌奶茶新品测评', source: HotSource.weibo, category: ContentCategory.food, hotValue: '1723万', tag: '新'),
      HotTopic(rank: 14, title: '博士毕业送外卖引热议', source: HotSource.weibo, category: ContentCategory.workplace, hotValue: '1654万', tag: ''),
      HotTopic(rank: 15, title: '去云南避暑的人太多了', source: HotSource.weibo, category: ContentCategory.travel, hotValue: '1543万', tag: ''),
      HotTopic(rank: 16, title: '新晋爸爸体验产后康复', source: HotSource.weibo, category: ContentCategory.emotion, hotValue: '1432万', tag: '热'),
      HotTopic(rank: 17, title: '某游戏新角色pv播放破亿', source: HotSource.weibo, category: ContentCategory.game, hotValue: '1321万', tag: '新'),
      HotTopic(rank: 18, title: '北京暴雨橙色预警', source: HotSource.weibo, category: ContentCategory.travel, hotValue: '1210万', tag: ''),
      HotTopic(rank: 19, title: '某运动品牌联名款秒空', source: HotSource.weibo, category: ContentCategory.fitness, hotValue: '1098万', tag: '新'),
      HotTopic(rank: 20, title: '某家居博主改造出租屋走红', source: HotSource.weibo, category: ContentCategory.home, hotValue: '987万', tag: ''),
    ],

    // ========== 百度热搜 ==========
    HotSource.baidu: [
      HotTopic(rank: 1, title: '2026年全国高考作文题目汇总', source: HotSource.baidu, category: ContentCategory.education, hotValue: '4967万', tag: '热'),
      HotTopic(rank: 2, title: '央行宣布降息降准', source: HotSource.baidu, category: ContentCategory.finance, hotValue: '4231万', tag: '热'),
      HotTopic(rank: 3, title: '某手机品牌发布折叠屏新品', source: HotSource.baidu, category: ContentCategory.tech, hotValue: '3892万', tag: '新'),
      HotTopic(rank: 4, title: '国产大飞机C929首飞成功', source: HotSource.baidu, category: ContentCategory.tech, hotValue: '3654万', tag: '爆'),
      HotTopic(rank: 5, title: '某电视剧大结局收视率破纪录', source: HotSource.baidu, category: ContentCategory.entertainment, hotValue: '3210万', tag: '热'),
      HotTopic(rank: 6, title: '多地出台育儿补贴新政策', source: HotSource.baidu, category: ContentCategory.baby, hotValue: '2987万', tag: ''),
      HotTopic(rank: 7, title: '某新能源车续航突破1200公里', source: HotSource.baidu, category: ContentCategory.tech, hotValue: '2765万', tag: '新'),
      HotTopic(rank: 8, title: '网红餐厅后厨乱象曝光', source: HotSource.baidu, category: ContentCategory.food, hotValue: '2543万', tag: '热'),
      HotTopic(rank: 9, title: 'ChatGPT最新版本能力评测', source: HotSource.baidu, category: ContentCategory.tech, hotValue: '2432万', tag: '热'),
      HotTopic(rank: 10, title: '某城市落户政策大放开', source: HotSource.baidu, category: ContentCategory.finance, hotValue: '2198万', tag: ''),
      HotTopic(rank: 11, title: '高考志愿填报指南2026', source: HotSource.baidu, category: ContentCategory.education, hotValue: '2087万', tag: '新'),
      HotTopic(rank: 12, title: '某基金经理年化收益超50%', source: HotSource.baidu, category: ContentCategory.finance, hotValue: '1976万', tag: ''),
      HotTopic(rank: 13, title: '空调清洗不当导致全家生病', source: HotSource.baidu, category: ContentCategory.home, hotValue: '1865万', tag: ''),
      HotTopic(rank: 14, title: '某综艺素人嘉宾火了', source: HotSource.baidu, category: ContentCategory.entertainment, hotValue: '1754万', tag: ''),
      HotTopic(rank: 15, title: '全国多地高温预警', source: HotSource.baidu, category: ContentCategory.fitness, hotValue: '1643万', tag: ''),
      HotTopic(rank: 16, title: '某运动APP推出AI私教功能', source: HotSource.baidu, category: ContentCategory.fitness, hotValue: '1532万', tag: '新'),
      HotTopic(rank: 17, title: '成都一社区食堂爆火', source: HotSource.baidu, category: ContentCategory.food, hotValue: '1421万', tag: ''),
      HotTopic(rank: 18, title: '电竞入选亚运会正式项目', source: HotSource.baidu, category: ContentCategory.game, hotValue: '1310万', tag: '热'),
      HotTopic(rank: 19, title: '某景区实行预约制限流', source: HotSource.baidu, category: ContentCategory.travel, hotValue: '1198万', tag: ''),
      HotTopic(rank: 20, title: '职场PUA典型案例引热议', source: HotSource.baidu, category: ContentCategory.workplace, hotValue: '1087万', tag: ''),
    ],

    // ========== 知乎热榜 ==========
    HotSource.zhihu: [
      HotTopic(rank: 1, title: '如何评价2026年高考作文题的出题思路', source: HotSource.zhihu, category: ContentCategory.education, hotValue: '3210万', tag: '热'),
      HotTopic(rank: 2, title: '月薪3万在一线城市是什么水平', source: HotSource.zhihu, category: ContentCategory.workplace, hotValue: '2876万', tag: '热'),
      HotTopic(rank: 3, title: '如何评价苹果最新发布的AI功能', source: HotSource.zhihu, category: ContentCategory.tech, hotValue: '2654万', tag: '新'),
      HotTopic(rank: 4, title: '年轻人应该先买房还是先投资', source: HotSource.zhihu, category: ContentCategory.finance, hotValue: '2432万', tag: '热'),
      HotTopic(rank: 5, title: '有哪些让你觉得「人间值得」的瞬间', source: HotSource.zhihu, category: ContentCategory.emotion, hotValue: '2198万', tag: ''),
      HotTopic(rank: 6, title: '计算机专业还值得读吗2026版', source: HotSource.zhihu, category: ContentCategory.education, hotValue: '2087万', tag: ''),
      HotTopic(rank: 7, title: '为什么越来越多年轻人养猫不生孩子', source: HotSource.zhihu, category: ContentCategory.pet, hotValue: '1976万', tag: ''),
      HotTopic(rank: 8, title: '程序员35岁之后真的会失业吗', source: HotSource.zhihu, category: ContentCategory.workplace, hotValue: '1865万', tag: ''),
      HotTopic(rank: 9, title: '一个人旅行是什么体验', source: HotSource.zhihu, category: ContentCategory.travel, hotValue: '1754万', tag: ''),
      HotTopic(rank: 10, title: '为什么大家都在推荐极简装修', source: HotSource.zhihu, category: ContentCategory.home, hotValue: '1643万', tag: ''),
      HotTopic(rank: 11, title: '怎样看待某游戏的抽卡概率争议', source: HotSource.zhihu, category: ContentCategory.game, hotValue: '1532万', tag: '热'),
      HotTopic(rank: 12, title: '有哪些平价护肤品效果堪比大牌', source: HotSource.zhihu, category: ContentCategory.beauty, hotValue: '1421万', tag: '新'),
      HotTopic(rank: 13, title: '在家健身和去健身房哪个更有效', source: HotSource.zhihu, category: ContentCategory.fitness, hotValue: '1310万', tag: ''),
      HotTopic(rank: 14, title: '如何评价最新一季的某脱口秀', source: HotSource.zhihu, category: ContentCategory.entertainment, hotValue: '1198万', tag: ''),
      HotTopic(rank: 15, title: '夏天有什么清爽不油腻的穿搭推荐', source: HotSource.zhihu, category: ContentCategory.fashion, hotValue: '1087万', tag: '新'),
      HotTopic(rank: 16, title: '有哪些值得推荐的深夜食堂', source: HotSource.zhihu, category: ContentCategory.food, hotValue: '976万', tag: ''),
      HotTopic(rank: 17, title: '宝宝入园前需要做哪些准备', source: HotSource.zhihu, category: ContentCategory.baby, hotValue: '865万', tag: ''),
      HotTopic(rank: 18, title: '2026年有什么值得关注的科技趋势', source: HotSource.zhihu, category: ContentCategory.tech, hotValue: '754万', tag: ''),
      HotTopic(rank: 19, title: '如何跟父母解释自己的职业', source: HotSource.zhihu, category: ContentCategory.emotion, hotValue: '643万', tag: ''),
      HotTopic(rank: 20, title: '基金定投三年终于回本了', source: HotSource.zhihu, category: ContentCategory.finance, hotValue: '532万', tag: ''),
    ],

    // ========== 抖音热榜 ==========
    HotSource.douyin: [
      HotTopic(rank: 1, title: '挑战一天只花10块钱', source: HotSource.douyin, category: ContentCategory.food, hotValue: '6543万', tag: '爆'),
      HotTopic(rank: 2, title: '某网红夫妻官宣离婚', source: HotSource.douyin, category: ContentCategory.entertainment, hotValue: '5876万', tag: '爆'),
      HotTopic(rank: 3, title: '夏日冰饮合集100种做法', source: HotSource.douyin, category: ContentCategory.food, hotValue: '4321万', tag: '热'),
      HotTopic(rank: 4, title: '挑战7天瘦5斤跟练计划', source: HotSource.douyin, category: ContentCategory.fitness, hotValue: '3987万', tag: '新'),
      HotTopic(rank: 5, title: '大学生宿舍改造前后对比', source: HotSource.douyin, category: ContentCategory.home, hotValue: '3654万', tag: '热'),
      HotTopic(rank: 6, title: '某明星直播带货3亿销售额', source: HotSource.douyin, category: ContentCategory.entertainment, hotValue: '3432万', tag: '热'),
      HotTopic(rank: 7, title: '高考完第一件事做什么', source: HotSource.douyin, category: ContentCategory.education, hotValue: '3210万', tag: '新'),
      HotTopic(rank: 8, title: '猫咪迷惑行为大赏', source: HotSource.douyin, category: ContentCategory.pet, hotValue: '2987万', tag: ''),
      HotTopic(rank: 9, title: '街拍达人的夏季穿搭公式', source: HotSource.douyin, category: ContentCategory.fashion, hotValue: '2765万', tag: '新'),
      HotTopic(rank: 10, title: '新手化妆从0开始教程', source: HotSource.douyin, category: ContentCategory.beauty, hotValue: '2543万', tag: '热'),
      HotTopic(rank: 11, title: '某地夜市摊位月入5万引热议', source: HotSource.douyin, category: ContentCategory.food, hotValue: '2432万', tag: ''),
      HotTopic(rank: 12, title: '应届生简历怎么写才不被秒拒', source: HotSource.douyin, category: ContentCategory.workplace, hotValue: '2198万', tag: ''),
      HotTopic(rank: 13, title: '某手游新赛季更新内容曝光', source: HotSource.douyin, category: ContentCategory.game, hotValue: '2087万', tag: '新'),
      HotTopic(rank: 14, title: '带宝宝逛超市的崩溃日常', source: HotSource.douyin, category: ContentCategory.baby, hotValue: '1976万', tag: ''),
      HotTopic(rank: 15, title: '情侣旅行省钱攻略', source: HotSource.douyin, category: ContentCategory.travel, hotValue: '1865万', tag: '新'),
      HotTopic(rank: 16, title: '某品牌防晒霜实测翻车', source: HotSource.douyin, category: ContentCategory.beauty, hotValue: '1754万', tag: '热'),
      HotTopic(rank: 17, title: '普通人理财从基金定投开始', source: HotSource.douyin, category: ContentCategory.finance, hotValue: '1643万', tag: ''),
      HotTopic(rank: 18, title: '盘点2026最值得去的旅行地', source: HotSource.douyin, category: ContentCategory.travel, hotValue: '1532万', tag: ''),
      HotTopic(rank: 19, title: '某电竞选手退役直播泪崩', source: HotSource.douyin, category: ContentCategory.game, hotValue: '1421万', tag: '热'),
      HotTopic(rank: 20, title: '异地恋三年终于见面了', source: HotSource.douyin, category: ContentCategory.emotion, hotValue: '1310万', tag: ''),
    ],
  };
}
