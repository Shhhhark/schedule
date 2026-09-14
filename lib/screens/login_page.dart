import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../config.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _fetched = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录教务系统'),
        bottom: _progress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                ),
              )
            : null,
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(AppConfig.loginUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          cacheEnabled: false,
          clearCache: true,
          incognito: true,
          userAgent: AppConfig.userAgent,
          useShouldOverrideUrlLoading: true,
        ),
        onProgressChanged: (controller, progress) {
          setState(() => _progress = progress / 100);
        },
        onLoadStop: (controller, url) async {
          if (_fetched) return;
          final urlStr = url?.toString() ?? '';
          if (!urlStr.contains(AppConfig.successUrlKeyword)) return;

          _fetched = true;
          final cookieManager = CookieManager.instance();
          final cookies =
              await cookieManager.getCookies(url: WebUri(AppConfig.loginUrl));
          final cookieHeader =
              cookies.map((c) => '${c.name}=${c.value}').join('; ');

          if (mounted) Navigator.pop(context, cookieHeader);
        },
      ),
    );
  }
}