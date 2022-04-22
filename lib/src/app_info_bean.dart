import 'dart:typed_data';

import 'package:device_apps/device_apps.dart';

class AppInfoBean {
  String? appName;
  Uint8List? appIcon;
  Application? application;

  AppInfoBean({this.appName, this.appIcon, this.application});

  factory AppInfoBean.fromJson(Map<String, dynamic> json) {
    var m = AppInfoBean();
    return m.fromJson(json) ?? m;
  }

  AppInfoBean? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    var data = AppInfoBean();
    data.appName = json['appName'];
    data.appIcon = json['appIcon'];
    data.application = json['application'];
    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['appName'] = this.appName;
    data['appIcon'] = this.appIcon;
    if (this.application != null) {
      data['application'] = this.application;
    }
    return data;
  }
}
