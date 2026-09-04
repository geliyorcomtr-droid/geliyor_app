{{flutter_js}}
{{flutter_build_config}}

if (_flutter.buildConfig && _flutter.buildConfig.builds) {
  var cacheBust = '{{CACHE_BUST}}';
  for (var i = 0; i < _flutter.buildConfig.builds.length; i++) {
    var build = _flutter.buildConfig.builds[i];
    if (build.mainJsPath && build.mainJsPath.indexOf('?') < 0) {
      build.mainJsPath = build.mainJsPath + '?v=' + cacheBust;
    }
  }
}

_flutter.loader.load();
