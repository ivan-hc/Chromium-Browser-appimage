#!/bin/sh

APP=chromium

# TEMPORARY DIRECTORY
mkdir -p tmp
cd ./tmp || exit 1

# DOWNLOAD APPIMAGETOOL
if ! test -f ./appimagetool; then
	wget -q "$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')" -O appimagetool
	chmod a+x ./appimagetool
fi

# DOWNLOAD THE SNAP PACKAGE
if ! test -f ./*.snap; then
	wget -q "$(curl -H 'Snap-Device-Series: 16' http://api.snapcraft.io/v2/snaps/info/chromium --silent | sed 's/[()",{} ]/\n/g' | grep "^http" | head -1)"
fi

# EXTRACT THE SNAP PACKAGE AND CREATE THE APPIMAGE
unsquashfs -f ./*.snap
mkdir -p "$APP".AppDir
VERSION=$(cat ./squashfs-root/snap/*.yaml | grep "^version" | head -1 | cut -c 10-)

mv ./squashfs-root/etc ./"$APP".AppDir/
mv ./squashfs-root/lib ./"$APP".AppDir/
mv ./squashfs-root/usr ./"$APP".AppDir/
mv ./squashfs-root/*.png ./"$APP".AppDir/
mv ./squashfs-root/bin/*.desktop ./"$APP".AppDir/
sed -i 's#/chromium.png#chromium#g' ./"$APP".AppDir/*.desktop

cat >> ./"$APP".AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export UNION_PRELOAD="${HERE}"
export PATH="${HERE}"/usr/bin/:"${HERE}"/usr/sbin/:"${HERE}"/usr/games/:"${PATH}"
export LD_LIBRARY_PATH="${HERE}"/usr/lib/:"${HERE}"/usr/lib/i386-linux-gnu/:"${HERE}"/usr/lib/x86_64-linux-gnu/:"${HERE}"/lib/:"${HERE}"/lib/i386-linux-gnu/:"${HERE}"/lib/x86_64-linux-gnu/:"${LD_LIBRARY_PATH}"
export PYTHONPATH="${HERE}"/usr/share/pyshared/:"${HERE}"/usr/lib/python*/:"${PYTHONPATH}"
export PYTHONHOME="${HERE}"/usr/:"${HERE}"/usr/lib/python*/
export XDG_DATA_DIRS="${HERE}"/usr/share/:"${XDG_DATA_DIRS}"
exec ${HERE}/usr/lib/chromium*/chrome "$@"
EOF
chmod a+x ./"$APP".AppDir/AppRun

ARCH=x86_64 VERSION=$(./appimagetool -v | grep -o '[[:digit:]]*') ./appimagetool -s ./"$APP".AppDir
cd ..
mv ./tmp/*.AppImage ./Chromium-"$VERSION"-x86_64.AppImage
