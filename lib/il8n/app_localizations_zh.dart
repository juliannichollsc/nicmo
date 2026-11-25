// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get email => '邮箱';

  @override
  String get enterYourEmail => '请输入邮箱';

  @override
  String get password => '密码';

  @override
  String get enterYourPassword => '请输入密码';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get login => '登录';

  @override
  String get dontHaveAccountSignUp => '还没有账号？注册';

  @override
  String get name => '名字';

  @override
  String get enterYourName => '请输入名字';

  @override
  String get lastName => '姓氏';

  @override
  String get enterYourLastName => '请输入姓氏';

  @override
  String get phone => '电话';

  @override
  String get enterYourPhone => '请输入电话';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get enterYourConfirmPassword => '请输入确认密码';

  @override
  String get alreadyHaveAccountLogin => '已经有账号？登录';

  @override
  String get register => '注册';

  @override
  String get verifyYourEmail => '验证邮箱';

  @override
  String get verificationCodeSent => '我们已向你的邮箱发送验证码';

  @override
  String get verify => '验证';

  @override
  String get resendCode => '重新发送验证码';

  @override
  String get notificationsEnabled => '通知已开启';

  @override
  String get notificationsDisabled => '通知已关闭';

  @override
  String get couldNotOpenLink => '无法打开链接';

  @override
  String get appearance => '外观';

  @override
  String get darkMode => '深色模式';

  @override
  String get on => '开启';

  @override
  String get off => '关闭';

  @override
  String get notifications => '通知';

  @override
  String get pushNotifications => '推送通知';

  @override
  String get receiveAppAlerts => '接收应用提醒';

  @override
  String get general => '通用';

  @override
  String get language => '语言';

  @override
  String get english => '英语';

  @override
  String get spanish => '西班牙语';

  @override
  String get german => '德语';

  @override
  String get mandarin => '中文（普通话）';

  @override
  String get about => '关于';

  @override
  String get aboutVersion => '版本 1.0.0';

  @override
  String get linkedIn => 'LinkedIn';

  @override
  String get julianNichollsC => 'Julian Nicholls C';

  @override
  String get menu => '菜单';

  @override
  String get home => '首页';

  @override
  String get settings => '设置';

  @override
  String get profile => '个人资料';

  @override
  String get map => '地图';

  @override
  String get lightMode => '浅色模式';

  @override
  String get darkModeMenu => '深色模式';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get takeAPhoto => '拍照';

  @override
  String get route => '到';

  @override
  String get start => '从';

  @override
  String get travel => '开始导航';

  @override
  String get metroTitle => '麦德林地铁';

  @override
  String get whereTo => '你要去哪里？';

  @override
  String get whereToHint => '输入地址、地点或车站';

  @override
  String get originHint => '出发地';

  @override
  String get destinationHint => '目的地';

  @override
  String get myLocation => '我的位置';

  @override
  String get cancel => '取消';

  @override
  String get findRoutes => '查找路线';

  @override
  String get searchingRoutes => '正在寻找最佳路线…';

  @override
  String get noRoutes => '未找到此行程的路线';

  @override
  String get routeError => '规划行程时出错';

  @override
  String get locationUnavailable => '无法获取位置';

  @override
  String get startTrip => '开始行程';

  @override
  String get recommended => '推荐';

  @override
  String get fewestTransfers => '换乘最少';

  @override
  String get leastWalking => '步行最少';

  @override
  String get alternatives => '备选路线';

  @override
  String minutesShort(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String transfersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '换乘 $count 次',
    );
    return '$_temp0';
  }

  @override
  String walkDistance(int meters) {
    return '步行 $meters 米';
  }

  @override
  String walkTo(String place) {
    return '步行至 $place';
  }

  @override
  String boardTowards(String line, String terminal) {
    return '乘坐 $line，往 $terminal 方向';
  }

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 站',
    );
    return '$_temp0';
  }

  @override
  String getOffAt(String station) {
    return '在 $station 下车';
  }

  @override
  String waitAbout(int minutes) {
    return '等待约 $minutes 分钟';
  }

  @override
  String get tripStarting => '行程开始';

  @override
  String get nextStep => '下一步';

  @override
  String get previousStep => '上一步';

  @override
  String stepOf(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get arrived => '您已到达！';

  @override
  String get endTrip => '结束行程';

  @override
  String get approximateRoute => '近似路线';

  @override
  String get modeMetro => '地铁';

  @override
  String get modeTram => '有轨电车';

  @override
  String get modeCable => '缆车';

  @override
  String get modeBus => '公交';

  @override
  String get modeWalk => '步行';

  @override
  String lineName(String id) {
    return '$id 线';
  }

  @override
  String metroplusLine(String number) {
    return 'Metroplús $number 号线';
  }

  @override
  String feederRoute(String code) {
    return '接驳线路 $code';
  }

  @override
  String get clear => '清除';

  @override
  String get findBestRoute => '查找最佳路线';

  @override
  String placeNotFound(String query) {
    return '未找到“$query”';
  }

  @override
  String get swapPlaces => '交换起点和终点';

  @override
  String get centerOnMe => '以我的位置为中心';

  @override
  String get skip => '跳过';

  @override
  String get approximateLocation => '大致位置';

  @override
  String walkToBusStreet(String line) {
    return '步行至 $line 经过的街道';
  }

  @override
  String get boardOnStreet => '在路边上车（招手停车）';

  @override
  String getOffNear(String place) {
    return '在 $place 附近下车';
  }

  @override
  String get yourDestination => '目的地';

  @override
  String impreciseLocation(int meters) {
    return '您的位置不精确（±$meters 米）。请在地图上调整。';
  }

  @override
  String get adjust => '调整';

  @override
  String get movePinOrigin => '移动地图以放置 A 点（起点）';

  @override
  String get movePinDestination => '移动地图以放置 B 点（终点）';

  @override
  String get confirmPoint => '确认位置';

  @override
  String get placeOnMap => '在地图上标记位置';

  @override
  String get systemLanguage => '跟随系统语言';

  @override
  String get menuSubtitle => '畅行阿布拉谷';

  @override
  String get menuSectionTravel => '出行';

  @override
  String get menuSectionLines => '线路';

  @override
  String get goByCar => '改为乘车';

  @override
  String get walkInstead => '步行';

  @override
  String rideHailTo(String service, String place) {
    return '乘坐 $service 前往 $place';
  }

  @override
  String rideHailRequest(String from, String to) {
    return '从 $from 叫车到 $to';
  }

  @override
  String rideHailDetail(int minutes, int wait, String km) {
    return '乘车 $minutes 分钟（含约 $wait 分钟等车）· $km 公里';
  }

  @override
  String destinationCopied(String service) {
    return '目的地已复制：请粘贴到 $service';
  }

  @override
  String appNotOpened(String service) {
    return '无法打开 $service';
  }

  @override
  String busStreetOf(String line) {
    return '$line 经过的街道';
  }

  @override
  String get yourStart => '出发地';

  @override
  String get modeCar => '汽车';

  @override
  String get appTagline => '你的城市出行路线';

  @override
  String get onboardingTitle1 => '告诉我们你要去哪里';

  @override
  String get onboardingBody1 => '输入地址、选择车站，或在地图上标记 A 点和 B 点。';

  @override
  String get onboardingTitle2 => '最佳组合';

  @override
  String get onboardingBody2 => 'Nicmo 组合地铁、有轨电车、缆车、公交和步行，并提供备选路线。';

  @override
  String get onboardingTitle3 => '一步一步出行';

  @override
  String get onboardingBody3 => '在地图上跟随每一步，需要时可将步行换成 Uber 或 inDrive。';

  @override
  String get next => '下一步';

  @override
  String get getStarted => '开始使用';

  @override
  String get showAllLines => '显示所有线路';

  @override
  String get createdBy => '开发者';

  @override
  String get change => '更改';

  @override
  String get languageHint => '点击选择其他语言';

  @override
  String destinationSent(String service) {
    return '目的地已发送到 $service';
  }

  @override
  String carTo(String place) {
    return '乘车前往 $place';
  }

  @override
  String get requestWith => '用以下应用叫车';

  @override
  String get groupMetroplus => 'Metroplús';

  @override
  String get groupFeeder => '接驳公交';

  @override
  String get allTransport => '全部交通';

  @override
  String get transportOnMap => '地图上的交通';

  @override
  String get linesTitle => '线路';

  @override
  String get searchLines => '搜索线路或街区';

  @override
  String linesCount(int count) {
    return '$count 条线路';
  }

  @override
  String stopsOnRoute(int count) {
    return '$count 个站点';
  }

  @override
  String get noLinesFound => '没有匹配的线路';

  @override
  String get feederRoutesNote => '带你前往车站的公交。路线和站点：麦德林地铁开放数据。';

  @override
  String get seeAllLines => '查看全部线路';

  @override
  String get shareLocation => '分享我的位置';

  @override
  String get shareTripTitle => '分享我的行程';

  @override
  String get shareTripHint => '将发送一个包含你当前位置的 Google 地图链接。';

  @override
  String get shareOtherApps => '其他应用';

  @override
  String shareMessage(String destination, int minutes, String link) {
    return '我正在用 Nicmo 前往 $destination，大约 $minutes 分钟后到达。我在这里：$link';
  }

  @override
  String get whatsAppUnavailable => '无法打开 WhatsApp';

  @override
  String get groupBus => '城市公交';

  @override
  String get familyMetro => '地铁系统';

  @override
  String get familyBuses => '公交';

  @override
  String busRoute(String code) {
    return '$code 路公交';
  }

  @override
  String get busRoutesNote =>
      '公共交通公交车，沿街招手即停。线路由麦德林市政府和伊塔圭市政府（都市区线路）发布。上车前请核对线路牌。';

  @override
  String moveAround(String place) {
    return '畅行$place';
  }

  @override
  String get citiesTitle => '城市';

  @override
  String get changeCity => '切换城市';

  @override
  String get cityPickTitle => '你要在哪个城市出行？';

  @override
  String get cityPickBody => '手机上只保存你所在城市的地图和线路。出行时可随时添加其他城市。';

  @override
  String get cityChooseFirst => '请选择一个城市以继续';

  @override
  String get cityCurrent => '当前城市';

  @override
  String get cityActive => '你的城市';

  @override
  String get cityExplore => '更多城市';

  @override
  String get citySearch => '搜索城市';

  @override
  String get cityNoMatch => '没有匹配的城市';

  @override
  String get cityAvailable => '线路可用';

  @override
  String get citySoon => '即将推出';

  @override
  String citySoonNote(String city) {
    return '我们正在准备$city的线路。你已经可以使用地图并搜索地点。';
  }

  @override
  String get cityGo => '前往';

  @override
  String get cityActivate => '添加';

  @override
  String get cityRemove => '移除';

  @override
  String cityRemoveTitle(String city) {
    return '移除$city？';
  }

  @override
  String cityRemoveBody(String city, String size) {
    return '将删除该城市的离线地图（$size）。你可以随时重新添加。';
  }

  @override
  String cityRemoved(String city) {
    return '已移除$city，空间已释放';
  }

  @override
  String cityAdded(String city) {
    return '已添加$city：使用时会保存其地图';
  }

  @override
  String cityOfflineMap(String size) {
    return '离线地图：$size';
  }

  @override
  String get cityOfflineEmpty => '离线地图：使用时自动保存';

  @override
  String get cityHere => '你在这里';

  @override
  String cityNowIn(String city) {
    return '现在位于$city';
  }

  @override
  String get cityKeepsOffline => '只有已启用的城市会在手机上保存地图';

  @override
  String get termsTitle => '条款和条件';

  @override
  String get termsSummary => '简要说明';

  @override
  String termsUpdated(String date) {
    return '更新于 $date';
  }

  @override
  String get termsAcceptNotice => '继续即表示你接受';

  @override
  String get termsUnderstood => '知道了';

  @override
  String get cityPickBodySingle =>
      '目前 Nicmo 覆盖麦德林及整个阿武拉谷：地铁、缆车、有轨电车和公交。更多城市即将上线。';

  @override
  String get citySceneMedellin => '永恒之春的城市';

  @override
  String get citySceneBogota => '离星星近 2600 米';

  @override
  String get citySceneCali => '世界萨尔萨之都';

  @override
  String get citySceneBarranquilla => '狂欢节：亲身体验，尽情享受';

  @override
  String get citySceneCartagena => '加勒比海畔的英雄之城';

  @override
  String get citySceneBucaramanga => '公园之城，美丽之城';

  @override
  String get cityScenePereira => '位于咖啡产区的中心';

  @override
  String get citySceneColombia => '哥伦比亚，美丽之国';
}
