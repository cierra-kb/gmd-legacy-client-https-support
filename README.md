# gmd-legacy-client-https-support
A standalone mod (for Android) that modifies Geometry Dash's version of CURL to add HTTPS support to the game.
This can *hypothetically* work up to 1.9, however, as of writing (January 11, 2026), only 1.4 has been tested.

## Installation
1. Go to the [latest release](https://github.com/cierra-kb/gmd-legacy-client-https-support/releases/latest) and
download the appropriate version that matches with the architecture of libgame.so/libcocos2dcpp.so.
For armeabi and armeabi-v7a, download `secnet-arm.7z`. For x86, download `secnet-x86.7z`.
2. Extract the downloaded archive(s) from the release and copy all files from secnet-${arch}/lib/* into the
corresponding lib folder in the apk. Files from secnet-arm/lib/ should be placed on lib/armeabi and lib/armeabi-v7a (if present).
Files from secnet-x86/lib/ should be placed on lib/x86.
3. Modify the APK's smali code to load libsecnet.so. This is usually done by placing the following code where libgame.so/libcocos2dcpp.so
is already loaded, but it is recommended to just do this on GeometryJump's (`Lcom/robtopx/geometryjump/GeometryJump`) class initializer (`static constructor <clinit>()V`)
```
    const-string v0, "secnet"
    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V
```

## Notes
- URLs with "http://" are automatically replaced with "https://".
- By default, the mod assumes the server can accept HTTPS connections. This can be changed by passing `-DCHECK_SERVER_SUPPORT=ON` when configuring the project with cmake.
- When `-DCHECK_SERVER_SUPPORT=ON` is passed to cmake, the mod can fallback to the initial URL when the server does not accept HTTPS connections.
- By default, sending requests via plain HTTP will fail because the mod assumes the server to have a certificate (which can be changed by passing
`-DALLOW_INSECURE_CONNECTIONS=ON` during configuration)

## License
Copyright 2026 cierra-kb. Use, distribution, and modification are subject to the Boost Software License, Version 1.0.
See [LICENSE](./LICENSE) file in the project root or a copy at https://www.boost.org/LICENSE_1_0.txt
