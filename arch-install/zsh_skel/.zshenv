export TERM=xterm-256color
export EDITOR=/usr/bin/vim
export CURL_SSL_BACKEND=secure-transport
export GOPATH="$HOME/go"

export PATH=$PATH:$GOPATH/bin

go_paths=(
  "/usr/lib/go"
  "/usr/local/go"
)
for p in ${go_paths[@]}; do
  if [ -d $p ]; then
    export GOROOT=$p
    break
  fi
done

java_paths=(
  "/opt/android-studio/jre"
  "/Applications/Android Studio.app/Contents/jre/jdk/Contents/home"
)
for p in ${java_paths[@]}; do
  if [ -d $p ]; then
    export JAVA_HOME=$p
    break
  fi
done

android_paths=(
  "$HOME/Android/Sdk"
  "$HOME/Library/Android/sdk"
)
for p in ${android_paths[@]}; do
  if [ -d $p ]; then
    export ANDROID_HOME=$p
    break
  fi
done

export PATH=$GOROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH
export CLICOLOR=YES # MacOS