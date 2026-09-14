/// 教务系统接口配置
/// ⚠️ 必须按你所在学校抓包替换以下字段
class AppConfig {
  // 教务系统登录页（WebView 会加载这个地址）
  static const String loginUrl =
      'https://你的学校教务系统/xtgl/login_slogin.html';

  // 登录成功后 URL 中会出现的关键字，用于判断登录完成
  // 常见：index_initMenu、framework、index
  static const String successUrlKeyword = 'index_initMenu';

  // 正方课表查询接口（返回 JSON）
  static const String scheduleApiUrl =
      'https://你的学校教务系统/kbcx/xskbcx_cxXsgrkb.html?gnmkdm=N2151';

  // 课表接口的 Referer
  static const String referer =
      'https://你的学校教务系统/kbcx/xskbcx_cxXsgrkb.html?gnmkdm=N2151';

  // 建议与 WebView 的 UA 保持一致
  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Mobile Safari/537.36';

  // 学年、学期（xqm=3 第一学期，xqm=12 第二学期）
  static const String xnm = '2024';
  static const String xqm = '3';
}