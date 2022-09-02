import 'dart:typed_data';
import 'package:device_apps/device_apps.dart';
import '../app_upgrade_package.dart';

class AppInfoBean {
  String? appName;
  Uint8List? appIcon;
  Application? application;
  MarketsType marketsType;

  AppInfoBean(
      {this.appName,
      this.appIcon,
      this.application,
      required this.marketsType});

  factory AppInfoBean.fromJson(Map<String, dynamic> json) {
    var m = AppInfoBean(marketsType: MarketsType.def);
    return m.fromJson(json) ?? m;
  }

  AppInfoBean? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    var data = AppInfoBean(marketsType: MarketsType.def);
    data.appName = json['appName'];
    data.appIcon = json['appIcon'];
    data.application = json['application'];
    data.marketsType = json['marketsType'];
    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['appName'] = appName;
    data['appIcon'] = appIcon;
    data['marketsType'] = marketsType;
    if (application != null) {
      data['application'] = application;
    }
    return data;
  }
}


