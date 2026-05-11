#!/bin/bash
_PACKAGE=advsophish
_VERSION=3.2.0
_ARCH=all
PKG_NAME="${_PACKAGE}_${_VERSION}_${_ARCH}.deb"

if [[ ! -e "scripts/launch.sh" ]]; then
    echo "Missing scripts/launch.sh"
    exit 1
fi

if [[ ${1,,} == "termux" || $(uname -o) == *'Android'* ]]; then
    _depend="ncurses-utils, proot, resolv-conf, "
    _bin_dir="data/data/com.termux/files/"
    _opt_dir="data/data/com.termux/files/usr/"
else
    _bin_dir="usr/"
    _opt_dir="usr/"
fi
_depend+="curl, php, unzip"
_bin_dir+="bin"
_opt_dir+="opt/${_PACKAGE}"

rm -rf build_env
mkdir -p build_env/{DEBIAN,$_bin_dir,$_opt_dir}
cp scripts/launch.sh build_env/$_bin_dir/AdvSophish
chmod 755 build_env/$_bin_dir/AdvSophish
cp -r .github .sites dashboard LICENSE README.md AdvSophish.sh build_env/$_opt_dir/
cat > build_env/DEBIAN/control <<EOF
Package: $_PACKAGE
Version: $_VERSION
Architecture: $_ARCH
Maintainer: mahi-cyberaware
Depends: $_depend
Homepage: https://github.com/mahi-cyberaware/AdvSophish
Description: Advanced phishing framework with dashboard, obfuscation & 35+ templates.
EOF
cat > build_env/DEBIAN/prerm <<'EOF'
#!/bin/bash
rm -rf /opt/advsophish /data/data/com.termux/files/usr/opt/advsophish
exit 0
EOF
chmod 755 build_env/DEBIAN/{control,prerm}
dpkg-deb --build build_env $PKG_NAME
rm -rf build_env
