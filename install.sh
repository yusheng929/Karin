echo "开始安装依赖..."

check_command() {
  if ! command -v $1 &> /dev/null
  then
    echo "$1 未安装。"
    return 1
  else
    echo "$1 已安装，跳过。"
    return 0
  fi
}

install_package() {
  if command -v apt &> /dev/null; then
    apt update && apt install -y $1
  elif command -v pacman &> /dev/null; then
    pacman -Sy --noconfirm $1
  else
    echo "不支持的包管理器，退出。"
    exit 1
  fi
  echo "$1 安装完成。"
}

install_nodejs_from_official() {
  echo "开始从官网安装 Node.js..."
  ARCH=$(uname -m)
  NODE_VERSION="18.x"

  if [ "$ARCH" = "x86_64" ]; then
    NODE_DISTRO="linux-x64"
  elif [ "$ARCH" = "aarch64" ]; then
    NODE_DISTRO="linux-arm64"
  else
    echo "不支持的架构: $ARCH"
    exit 1
  fi

  wget "https://nodejs.org/dist/v20.16.0/node-v20.16.0-$NODE_DISTRO.tar.xz"
  tar -C /usr/local --strip-components 1 -xJf "node-v20.16.0-$NODE_DISTRO.tar.xz"
  rm "node-v20.16.0-$NODE_DISTRO.tar.xz"
  echo "Node.js 安装完成。"
}

dependencies=("wget" "git" "pm2" "fonts-wqy*" "ffmpeg" "dialog")

for dep in "${dependencies[@]}"; do
  check_command $dep || install_package $dep
done

if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v | grep -oP 'v\K[0-9]+')
  if [ "$NODE_VERSION" -lt 18 ]; then
    echo "Node.js 版本小于 18，开始更新..."
    apt-get remove -y nodejs || pacman -R nodejs --noconfirm
    install_nodejs_from_official
  else
    echo "Node.js 版本符合要求，跳过更新。"
  fi
else
  echo "Node.js 未安装，开始从官网安装..."
  install_nodejs_from_official
fi

read -p "请输入一个目录用作安装目录 (默认安装到 /root目录下): " install_dir
install_dir=${install_dir:-/root}

if [ -d "$install_dir/Karin" ] && [ -f "$install_dir/Karin/package.json" ]; then
  read -p "当前目录已安装Karin，是否直接启动(Yes/no): " start_choice
  start_choice=${start_choice:-Yes}
  if [[ "$start_choice" =~ ^[Yy](es)?$ ]]; then
    curl -o "$install_dir/Karin.sh" https://install.karin.fun/karin
    bash -c "echo 'cd $install_dir/Karin && bash Karin.sh' > /usr/local/bin/y"
    chmod +x /usr/local/bin/y
    echo "Karin管理脚本已安装完毕，快捷键为 y。"
    exit 0
  else
    read -p "是否覆盖安装(Yes/no): " overwrite_choice
    overwrite_choice=${overwrite_choice:-Yes}
    if [[ "$overwrite_choice" =~ ^[Yy](es)?$ ]]; then
      rm -rf "$install_dir/Karin"
      mkdir -p "$install_dir/Karin"
      cd "$install_dir/Karin"
      pnpm i node-karin && npx init || { npm config set registry https://registry.npmmirror.com; pnpm i node-karin && npx init; }
      curl -o "$install_dir/Karin/Karin.sh" https://install.karin.fun/karin
      bash -c "echo 'cd $install_dir/Karin && bash Karin.sh' > /usr/local/bin/y"
      chmod +x /usr/local/bin/y
      echo "Karin安装完成"
      echo "目录为: $install_dir/Karin"
      echo "快捷键: y"
      exit 0
    else
      echo "退出脚本。"
      exit 0
    fi
  fi
else
  mkdir -p "$install_dir/Karin"
  cd "$install_dir/Karin"
  pnpm i node-karin && npx init || { npm config set registry https://registry.npmmirror.com; pnpm i node-karin && npx init; }
  curl -o "$install_dir/Karin.sh" https://install.karin.fun/karin
  bash -c "echo 'cd $install_dir/Karin && bash Karin.sh' > /usr/local/bin/y"
  chmod +x /usr/local/bin/y
  echo "Karin安装完成"
  echo "目录为: $install_dir/Karin"
  echo "快捷键: y"
  exit 0
fi