# Bu makinedeki araç yolları (C:\dev altına kuruldu). Kullanım: . tool/env.sh
export JAVA_HOME='C:\dev\jdk17'
export ANDROID_HOME='C:\dev\android-sdk'
export ANDROID_SDK_ROOT='C:\dev\android-sdk'
export GT_PYTHON="C:/Users/$USERNAME/AppData/Local/Programs/Python/Python312/python.exe"
export PATH="/c/dev/flutter/bin:/c/dev/jdk17/bin:/c/dev/android-sdk/platform-tools:/c/dev/android-sdk/emulator:$PATH"
# protoc PATH üzerinde olmalı ve adıyla verilmeli: chiaki-ng tam yol verilince PATH'i ":" ile birleştiriyor (Windows'ta bozulur).
export GT_PROTOC="protoc"
export PATH="/c/dev/protoc/bin:$PATH"
