# Powered by https://zenn.dev/ignorant/articles/wsl2_alpine_docker

FROM alpine:latest

# システムの更新
RUN apk update && apk upgrade --no-cache && apk add --no-cache tzdata sudo curl git
RUN sudo apk add --no-cache libgcc libstdc++ 

# タイムゾーンの設定(Asia/Tokyo)
RUN install -Dm 644 /usr/share/zoneinfo/Asia/Tokyo /etc/zoneinfo/Asia/Tokyo
RUN echo "export TZ='Asia/Tokyo'" >> /etc/profile.d/timezone.sh
RUN apk del tzdata

# sudo の設定
RUN echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel

# 作業ユーザ＝の追加，bash を使用
RUN apk add --no-cache bash bash-completion
RUN adduser -h /home/wsluser -s /bin/bash --disabled-password wsluser  # vscode はユーザ名，適宜変更
RUN adduser wsluser wheel        # vscode はユーザ名，適宜変更

# docker 関連のインストール
RUN apk add --no-cache docker openrc
RUN addgroup wsluser docker      # vscode はユーザ名，適宜変更

# wsl.conf の設定
RUN cat <<EOF > /etc/wsl.conf
[user]
default=wsluser

[interop]
appendWindowsPath=true

[boot]
command = "/usr/bin/env -i /usr/bin/unshare --pid --mount-proc --fork --propagation private -- sh -c 'exec /sbin/init'"
EOF

# OpenRC,Docker の設定
# runlevel default に登録
RUN rc-update add docker default
RUN rc-update show default

RUN echo '%wheel ALL=(ALL) NOPASSWD: /usr/bin/nsenter' >> /etc/sudoers.d/wheel
RUN cat <<"EOF" > /etc/profile.d/wsl-init.sh
#!/bin/bash

# Get PID of /sbin/init
sleep 1
pid="$(ps -o pid,args | awk '$2 ~ /\/sbin\/init/ {print $1}')"

# Run WSL service script
if [ "$pid" -ne 1 ]; then
  # Export ENV variables
  if [ "$USER" != "root" ]; then
    [ -f "$HOME/.openrc.env" ] && rm "$HOME/.openrc.env"
    export > "$HOME/.openrc.env"
  fi

  echo "Entering /sbin/init PID: $pid"
  exec sudo /usr/bin/nsenter -p -m -t "${pid}" -- su - "$USER"
fi

# Import ENV variables
if [ -f "$HOME/.openrc.env" ]; then
  set -a
  source "$HOME/.openrc.env"
  set +a
  rm "$HOME/.openrc.env"
fi
EOF