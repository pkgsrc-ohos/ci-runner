#!/bin/sh
set -e

# 下载一些命令行工具，并将它们软链接到 /bin 目录中
cd /opt
echo "coreutils 9.10
busybox 1.37.0
grep 3.12
gawk 5.3.2
tar 1.35
gzip 1.14
diffutils 3.12
vim 9.2.0150
openssh 10.2p1
git 2.53.0
python 3.14.4" >/tmp/tools.txt
while read -r name ver; do
    curl -fLO https://github.com/Harmonybrew/ohos-$name/releases/download/$ver/$name-$ver-ohos-arm64.tar.gz
done </tmp/tools.txt
ls | grep tar.gz$ | xargs -n 1 tar -zxf
rm -rf *.tar.gz /tmp/tools.txt
ln -sf $(pwd)/*-ohos-arm64/bin/* /bin/

# 下载 ohos-sdk
sdk_download_url="https://cidownload.openharmony.cn/version/Master_Version/ohos-sdk-public_ohos/20260330_020501/version-Master_Version-ohos-sdk-public_ohos-20260330_020501-ohos-sdk-public_ohos.tar.gz"
curl -fSL -o ohos-sdk.tar.gz $sdk_download_url
mkdir /opt/ohos-sdk
tar -zxf ohos-sdk.tar.gz -C /opt/ohos-sdk
rm -f ohos-sdk.tar.gz
cd /opt/ohos-sdk/ohos
busybox unzip -q native-*.zip
busybox unzip -q toolchains-*.zip
rm -f *.zip
cd - >/dev/null

# 官方打出来的包存在软链接实体化的问题。规避一下，自己处理掉，避免镜像体积膨胀。
cd /opt/ohos-sdk/ohos/native/llvm/bin
echo "clang clang-15
clang++ clang-15
clang-cl clang-15
clang-cpp clang-15
ld64.lld lld
ld.lld lld
lld-link lld
llvm-addr2line llvm-symbolizer
llvm-lib llvm-ar
llvm-ranlib llvm-ar
llvm-readelf llvm-readobj
llvm-strip llvm-objcopy" > /tmp/links.txt
while read -r link target; do
    rm -f $link
    ln -s $target $link
done < /tmp/links.txt
rm /tmp/links.txt
cd - >/dev/null

# 把 llvm 里面的命令封装一份放到 /bin 目录下，只封装必要的工具。
# 为了照顾 clang （clang 软链接到其他目录使用会找不到 sysroot），
# 对所有命令统一用这种封装的方案，而非软链接。
essential_tools="clang
clang++
clang-cpp
ld.lld
lldb
llvm-addr2line
llvm-ar
llvm-cxxfilt
llvm-nm
llvm-objcopy
llvm-objdump
llvm-ranlib
llvm-readelf
llvm-size
llvm-strings
llvm-strip"
for executable in $essential_tools; do
    cat <<EOF > /bin/$executable
#!/bin/sh
exec /opt/ohos-sdk/ohos/native/llvm/bin/$executable "\$@"
EOF
    chmod 0755 /bin/$executable
done

# 签名工具软链接到 /bin 目录下
ln -s /opt/ohos-sdk/ohos/toolchains/lib/binary-sign-tool /bin/binary-sign-tool

# 对 llvm 进行软链接，生成 cc、gcc、ld、binutils
cd /bin
ln -s clang cc
ln -s clang gcc
ln -s clang++ c++
ln -s clang++ g++
ln -s clang-cpp cpp
ln -s ld.lld ld
ln -s llvm-addr2line addr2line
ln -s llvm-ar ar
ln -s llvm-cxxfilt c++filt
ln -s llvm-nm nm
ln -s llvm-objcopy objcopy
ln -s llvm-objdump objdump
ln -s llvm-ranlib ranlib
ln -s llvm-readelf readelf
ln -s llvm-size size
ln -s llvm-strip strip
cd - >/dev/null

# 预置阿里云 SDK
python3 -m pip install --upgrade pip
python3 -m pip install alibabacloud_oss_v2 alibabacloud_cdn20180510

# 生成常用的 rc 文件
cat <<EOF > /root/.mkshrc
alias ls="ls --color=auto"
alias grep="grep --color=auto"
EOF
