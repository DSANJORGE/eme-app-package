library openinsitute_core;

class AppSettings {
  String siteroot;
  String catalogId;
  bool https;

  // ponytail: no `mediadb` — upstream carries it, nothing in this fork reads
  // it. The shim only holds what the chat socket URL needs.
  AppSettings({
    required this.siteroot,
    required this.catalogId,
    required this.https,
  });

  factory AppSettings.fromJSON(Map<String, dynamic> json) {
    return AppSettings(
      siteroot: json['siteroot'] ?? '',
      catalogId: json['catalogid'] ?? '',
      https: json['https'] ?? false,
    );
  }
}

class OpenI {
  /// Set by [initialize]; null until then, mirroring the old
  /// Get.put/Get.isRegistered registration semantics.
  static OpenI? instance;

  late AppSettings _settings;

  Future<void> initialize({required Map<String, dynamic> workspaceData}) async {
    _settings = AppSettings.fromJSON(workspaceData);
    instance = this;
  }

  void updateSettings(Map<String, dynamic> workspaceData) {
    _settings = AppSettings.fromJSON(workspaceData);
  }

  AppSettings get settings => _settings;
}
