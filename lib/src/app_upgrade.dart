import 'dart:async';
import 'dart:io';

import 'package:app_installer/app_installer.dart';

import 'app_info_bean.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';

import 'download_qiu.dart';

class AppUpgradeParam {
  final int newVersionCode;
  final bool forceUpdate; //强制更新
  final Function(Function updateClick, Function ignoreUpdateClick)? onUpdate;
  final Widget Function(Function updateClick, Function ignoreUpdateClick)?
      updateDialogBuilder;
  final String marketChannel; //当前包市场渠道
  final List<MarketsType> markets; //目前支持的应用市场
  final String? updateContentText; //更新内容
  final String? apkDownloadUrl; //
  final String? appOfficialWebsite; //android应用官网
  final String? appStoreId; //ios 应用商店地址
  final Widget? apkDownloadWidget;
  final Widget? browserDownloadWidget; //浏览器下载

  ///
  /**
   *  @param marketChannel 市场渠道
      # 默认
      default || ''空字符串 || null
      # 小米 xiaomi
      # 腾讯 yingyongbao
      # 华为 huawei
      # Oppo oppo
      # Vivo vivo

   */

  ///
  AppUpgradeParam(
      {required this.newVersionCode,
      this.forceUpdate = false,
      this.onUpdate,
      this.updateDialogBuilder,
      this.marketChannel = '',
      this.updateContentText,
      this.apkDownloadUrl,
      this.markets = const [],
      this.appOfficialWebsite,
      this.apkDownloadWidget,
      this.browserDownloadWidget,
      this.appStoreId});
}

enum MarketsType { xiaomi, yingyongbao, huawei, oppo, vivo, samsung, def }

enum _LoadingState { loading, loadComplete, notLoaded }

const _mapMarketsType2Name = {
  MarketsType.yingyongbao: "应用宝",
  MarketsType.xiaomi: "小米应用商店",
  MarketsType.huawei: "华为应用商店",
  MarketsType.oppo: "oppo应用商店",
  MarketsType.vivo: "vivo应用商店",
  MarketsType.samsung: "三星应用商店",
};

class AppUpgrade {
  static AppUpgrade? _instance;

  static _LoadingState _loadingState = _LoadingState.notLoaded;

  static get instance => _instance ??= AppUpgrade._();

  static AppUpgradeParam _upgradeParam = AppUpgradeParam(newVersionCode: -1);
  static Map<String, dynamic>? _extra;

  AppUpgrade._();

  ///
  /**
   *  @param marketChannel 市场渠道
      # 默认
      default || ''空字符串 || null
      # 小米 xiaomi
      # 腾讯 yingyongbao
      # 华为 huawei
      # Oppo oppo
      # Vivo vivo

   */

  ///
  static checkUpdate(
      {required BuildContext context,
      required AppUpgradeParam upgradeParam,
      Map<String, dynamic>? extra,
      bool recheck = false}) async {
    _upgradeParam = upgradeParam;
    _extra = extra;
    await _initVersion();
    bool needUpdate = nowVersion < upgradeParam.newVersionCode; //是否提示更新
    if (needUpdate && await _notIgnoreUpdate(upgradeParam.newVersionCode)) {
      ///
      if (upgradeParam.onUpdate != null) {
        upgradeParam.onUpdate?.call(() {
          _update.call(context);
        }, () {
          _ignoreUpdate.call();
        });
      } else {
        showDialog(
            context: context,
            barrierDismissible: !upgradeParam.forceUpdate,
            builder: (context) {
              return upgradeParam.updateDialogBuilder?.call(() {
                    _update.call(context);
                  }, () {
                    _ignoreUpdate.call();
                  }) ??
                  _defaultDialogWidget(context);
            });
      }
    } else if (recheck) {
      showDialog(
          context: context,
          builder: (context) {
            return const Text("已经是最新版本");
          });
    }
  }

  static int nowVersion = -1;
  static String deviceId = '';
  static String packageName = '';
  static PackageInfo? _packageInfo;

  // final AndroidDeviceInfo? _androidInfo;

  static Future<int> _initVersion() async {
    if (nowVersion > 0) return nowVersion;
    try {
      var packageInfo = await PackageInfo.fromPlatform();
      _packageInfo = packageInfo;
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.androidId ?? '';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }
      nowVersion = int.parse(packageInfo.buildNumber);
      packageName = packageInfo.packageName;
      return nowVersion;
    } catch (e) {
      print("应用信息：获取异常e=$e");
      return -2;
    }
  }

  ///
  /**
   *
      "应用宝": "com.tencent.android.qqdownloader",
      "小米应用商店": "com.xiaomi.market",
      "华为应用商店": "com.huawei.appmarket",
      "oppo应用商店": "com.oppo.market",
      "vivo应用商店": "com.bbk.appstore",
      "三星应用商店": "com.sec.android.app.samsungapps",
      链接：https://www.jianshu.com/p/cfb7f212a5a2
   */

  ///
  ///用户点击更新调用此方法
  static void _update(BuildContext context) async {
    print("用户点击更新调用此方法");
    if (Platform.isAndroid) {
      print("用户点击更新调用此方法isAndroid");

      ///设备是否安装指定的应用商店？没有商店跳转浏览器官网页面()

      /// 目前支持的应用市场前提下 依据设备 制造商 判断跳转 对应的应用市场app内容页面

      /// 针对多个设备安装多个应用市场情况，优先跳转"当前包市场渠道"对应的应用市场
      _showBottomSelection(context, await _getAppList());
    } else if (Platform.isIOS) {
      _lunchTo("https://apps.apple.com/cn/app/id${_upgradeParam.appStoreId}",
          errorMessage: "打开App Store失败");
    } else {
      print("未知平台更新");
    }
  }

  ///忽略此版本更新调用此方法
  static void _ignoreUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("AppUpgrade_${_upgradeParam.newVersionCode}", false);
  }

  static Widget _defaultDialogWidget(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text(
        "版本更新",
      ),
      content: Text("${_upgradeParam.updateContentText}",
          textAlign: TextAlign.left,
          style: const TextStyle(height: 1.5, fontSize: 14)),
      actions: [
        Visibility(
          visible: !_upgradeParam.forceUpdate,
          child: ElevatedButton(
            onPressed: () {
              _closeUpdateDialog(context);
            },
            child: const Text("取消"),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _update(context);
          },
          child: const Text("更新"),
        ),
        Visibility(
          visible: !_upgradeParam.forceUpdate,
          child: ElevatedButton(
            onPressed: () {
              _ignoreUpdate();
              _closeUpdateDialog(context);
            },
            child: const Text("忽略这个版本"),
          ),
        ),
      ],
    );
  }

  static Future<bool> _notIgnoreUpdate(int newVersionCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("AppUpgrade_$newVersionCode") ?? true;
  }

  static const _map = {
    MarketsType.yingyongbao: "com.tencent.android.qqdownloader",
    MarketsType.xiaomi: "com.xiaomi.market",
    MarketsType.huawei: "com.huawei.appmarket",
    MarketsType.oppo: "com.oppo.market",
    MarketsType.vivo: "com.bbk.appstore",
    MarketsType.samsung: "com.sec.android.app.samsungapps",
  };

  static const _mapMarket = {
    MarketsType.yingyongbao: "market://details?id=",
    MarketsType.xiaomi: "mimarket://details?id=",
    MarketsType.huawei: "appmarket://details?id=",
    MarketsType.oppo: "oppomarket://details?packagename=",
    MarketsType.vivo: "vivomarket://details?id=",
    MarketsType.samsung: "samsungapps://ProductDetails/",
  };

  static List<AppInfoBean>? _apps;

  static Future<List<AppInfoBean>> _getAppList() async {
    if (_apps != null) return _apps!;
    List<AppInfoBean> apps = [];
    for (var i in _map.entries) {
      if (_upgradeParam.markets.contains(i.key)) {
        Application? app = await DeviceApps.getApp(i.value, true);
        if (app != null) {
          apps.add(AppInfoBean(
              appName: _mapMarketsType2Name[i.key],
              appIcon: (app as ApplicationWithIcon).icon,
              application: app,
              marketsType: i.key));
        }
      }
    }
    _apps = apps;
    return apps;
  }

  static void _showBottomSelection(
      BuildContext context, List<AppInfoBean> apps) {
    print("${apps.length} ${(7 / 4).floor()}");
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 15, top: 20),
          child: SizedBox(
            height: 100 * ((apps.length + 2) / 4).ceil().toDouble(),
            child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 20,
                    childAspectRatio: 70 / 69),
                itemCount: apps.length + 2,
                itemBuilder: (context, index) {
                  if (index == apps.length + 2 - 1) {
                    return _apkDownloadWidget(context,
                        apkDownloadUrl: _upgradeParam.apkDownloadUrl!);
                  }
                  if (index == apps.length + 2 - 2) {
                    return InkWell(
                        onTap: () async {
                          // 其他 urlLunch 到浏览器查看
                          _lunchTo(_upgradeParam.apkDownloadUrl!,
                              errorMessage: "打开浏览器更新失败");
                        },
                        child: _upgradeParam.browserDownloadWidget ??
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[350],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  height: 50,
                                  width: 50,
                                  child: const Icon(
                                    Icons.computer,
                                    size: 35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text("浏览器下载",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xff313a43))),
                              ],
                            ));
                  }
                  var app = apps[index];
                  return InkWell(
                    onTap: () async {
                      var market =
                          "${_mapMarket[app.marketsType]}${_extra?["testPackageName"] ?? packageName}";
                      _lunchTo(market, errorMessage: "打开应用市场失败");
                    },
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SizedBox(
                            height: 50,
                            width: 50,
                            child: (app.appIcon == null
                                ? const SizedBox()
                                : Image.memory(app.appIcon!)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(app.appName ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xff313a43))),
                      ],
                    ),
                  );
                }),
          ),
        );
      },
      context: context,
    );
  }

  static _lunchTo(String url, {String errorMessage = '启动失败'}) async {
    bool ok = await canLaunch(url);
    if (ok) {
      bool success = await launch(url);
      if (!success) {
        print("$errorMessage$url");
        _showToast(errorMessage);
      }
    } else {
      print("$errorMessage！$url");
      _showToast("$errorMessage！");
    }
  }

  static Dio? _dio;

  static Dio get _downloadDio {
    if (_dio != null) {
      return _dio!;
    }
    _dio = Dio();
    _dio!.interceptors.add(LogInterceptor());
    return _dio!;
  }

  static Widget _apkDownloadWidget(BuildContext context,
      {required String apkDownloadUrl}) {
    return InkWell(
        onTap: () async {
          ///权限
          // if (!await Permission.storage.request().isGranted) {
          //   print('需要读写手机存储权限才能下载新版本安装包');
          //   return;
          // }
          var savePath = (await getTemporaryDirectory()).path;
          // var savePath = (await getExternalStorageDirectories(
          //         type: StorageDirectory.downloads))!
          //     .first
          //     .path;
          assert(
              apkDownloadUrl.contains('/') && apkDownloadUrl.contains('.apk'));
          var fileName = apkDownloadUrl.split('/').last;
          File apkFile = File("$savePath/${_packageInfo?.appName}/$fileName");
          _showToast("准备下载");
          if (_loadingState == _LoadingState.loadComplete &&
              !apkFile.existsSync()) {
            _loadingState = _LoadingState.notLoaded;
          }
          if (_loadingState == _LoadingState.loading) {
            _showToast("${_packageInfo?.appName} 后台下载更新中($_updateProgress)...");
            return;
          } else if (_loadingState == _LoadingState.notLoaded) {
            ///下载
            var cancelToken = CancelToken();
            Navigator.of(context).pop();
            _closeUpdateDialog(context);
            try {
              if (apkFile.existsSync()) {
                apkFile.deleteSync();
              }
              if (!apkFile.existsSync()) {
                print("开始下载中${apkFile.path}");
                _showToast("${_packageInfo?.appName} 后台下载更新...");
                _loadingState = _LoadingState.loading;
                _showDownloadProgressWidget(context, 0);
                await _downloadDio.download(
                  apkDownloadUrl,
                  apkFile.path,
                  onReceiveProgress: _extra?["onReceiveProgress"] ??
                      (received, total) {
                        if (total != -1) {
                          var nowProgress = (received / total);
                          if (nowProgress.toStringAsFixed(2) !=
                              _updateProgress.toStringAsFixed(2)) {
                            _updateProgress = nowProgress;
                            _showDownloadProgressWidget(
                                context, _updateProgress);
                          }
                        } else {}
                      },
                  cancelToken: cancelToken,
                );
              }
              _loadingState = _LoadingState.loadComplete;

              ///开始安装
              print("开始安装${apkFile.path}");
              AppInstaller.installApk(apkFile.path).then((value) {
                print("安装器打开成功");
                return value;
              });
            } catch (e) {
              print(e);
              _showToast("下载失败,请检查网络连接后重试");
              apkFile.deleteSync();
              _loadingState = _LoadingState.notLoaded;
            } finally {
              _updateProgress = 0;
              _dismissProgressWidget();
              _loadingState = _LoadingState.notLoaded;
            }
          }
        },
        child: _upgradeParam.apkDownloadWidget ??
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  height: 50,
                  width: 50,
                  child: const Icon(
                    Icons.download,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 8),
                const Text("app内下载",
                    style: TextStyle(fontSize: 12, color: Color(0xff313a43))),
              ],
            ));
  }

//  更新进度
  static double _updateProgress = 0;
  static StreamController<double>? streamController;

  static void _showToast(String s) {
    print(s);
    if (_extra?["showToast"] != null) {
      _extra?["showToast"](s);
    }
  }

  static void _closeUpdateDialog(BuildContext context) {
    if (!_upgradeParam.forceUpdate) {
      Navigator.of(context).pop();
    }
  }

  static OverlayEntry? overlayEntry;

  static double overlayWidth = 50;
  static Offset offset = Offset.zero;

  static void _showDownloadProgressWidget(
      BuildContext context, double progress) {
    streamController ??= StreamController<double>();
    if (!streamController!.isClosed) {
      streamController!.sink.add(progress);
    }
    if (overlayEntry != null) {
      return;
    }
    overlayEntry ??= OverlayEntry(
        builder: (BuildContext context) => GestureDetector(
              onDoubleTap: () {
                _dismissProgressWidget();
              },
              child: DraggableButtonWidget(
                streamController: streamController!,
              ),
            ));
    print('添加弹框');
    Overlay.of(context)?.insert(overlayEntry!);
  }

  ///关闭悬浮按钮
  static void _dismissProgressWidget() {
    overlayEntry?.remove();
    overlayEntry = null;
    streamController = null;
  }
}

class DraggableButtonWidget extends StatefulWidget {
  final String? title;
  final Function? onTap;
  final double btnSize;
  final Color? btnColor;
  final StreamController<double> streamController;

  const DraggableButtonWidget(
      {Key? key,
      this.title,
      this.onTap,
      this.btnSize = 66,
      this.btnColor,
      required this.streamController})
      : super(key: key);

  @override
  _DraggableButtonWidgetState createState() =>
      _DraggableButtonWidgetState(streamController);
}

class _DraggableButtonWidgetState extends State<DraggableButtonWidget> {
  double left = 30;
  double top = 100;
  late double screenWidth;
  late double screenHeight;

  final StreamController<double> streamController;

  _DraggableButtonWidgetState(this.streamController);

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    ///默认点击事件
    var tap = () {};
    Widget w;
    Color primaryColor = widget.btnColor ?? Theme.of(context).primaryColor;
    primaryColor = primaryColor.withOpacity(0.6);
    w = GestureDetector(
      onTap: widget.onTap as void Function()? ?? tap,
      onPanUpdate: _dragUpdate,
      child: Container(
        width: widget.btnSize,
        height: widget.btnSize,
        color: primaryColor,
        child: Material(
          child: Center(
            child: StreamBuilder<double>(
                stream: streamController.stream,
                builder: (context, snapshot) {
                  var value = snapshot.data ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      WaterContainerWidget(
                        color: primaryColor,
                        waterLevel: value,
                        size: widget.btnSize,
                      ),
                      Text(
                        (value * 100).toStringAsFixed(0) + "%",
                        style: const TextStyle(wordSpacing: 32),
                      ),
                    ],
                  );
                }),
            // child: Material(child: Text('data=')),
          ),
        ),
      ),
    );

    ///圆形
    w = ClipRRect(
      borderRadius: BorderRadius.circular(widget.btnSize / 2),
      child: w,
    );

    ///计算偏移量限制
    if (left < 1) {
      left = 1;
    }
    if (left > screenWidth - widget.btnSize) {
      left = screenWidth - widget.btnSize;
    }

    if (top < 1) {
      top = 1;
    }
    if (top > screenHeight - widget.btnSize) {
      top = screenHeight - widget.btnSize;
    }
    w = Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(left: left, top: top),
      child: w,
    );
    return w;
  }

  _dragUpdate(DragUpdateDetails detail) {
    Offset offset = detail.delta;
    left = left + offset.dx;
    top = top + offset.dy;
    setState(() {});
  }
}
