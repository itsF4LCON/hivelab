#!/bin/sh
# Builds the v86 image: a 32-bit Alpine box with its root filesystem served over 9p.
# Run as root, or unprivileged with: unshare --map-auto --map-root-user sh image/build.sh
# Output (build/vm): bzImage, initrd.img, fs.json, fs/<sha256>
set -eu

ALPINE=3.24.2
here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
work=${WORK:-$repo/build/image}
out=${1:-$repo/build/vm}
root=$work/root
tarball=$work/alpine-minirootfs-$ALPINE-x86.tar.gz

mkdir -p "$work"
[ -f "$tarball" ] || curl -sfL -o "$tarball" "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE%.*}/releases/x86/alpine-minirootfs-$ALPINE-x86.tar.gz"
rm -rf "$root" "$out"
mkdir -p "$root" "$out"
tar -xzf "$tarball" -C "$root"

python3 "$repo/gen/build.py" "$repo/challenges" "$root/opt/lab" >/dev/null
mkdir -p "$root/tmp/box" "$root/opt/lab/daily" "$root/opt/lab/inbox"
cp -r "$repo/box/." "$here/rootfs/." "$root/tmp/box/"
cp /etc/resolv.conf "$root/etc/resolv.conf"

setarch i686 chroot "$root" /usr/bin/env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin sh -eu -c '
cd /tmp/box
sh install.sh >/dev/null
apk add --no-cache -q linux-virt busybox-static
install -D -m 755 lab-boot /usr/local/sbin/lab-boot
install -D -m 755 autologin /usr/local/sbin/autologin
install -m 644 inittab /etc/inittab
echo server >/etc/hostname
printf "127.0.0.1 localhost\n127.0.1.1 server\n" >/etc/hosts
rm -rf /tmp/box /var/cache/apk/* /etc/resolv.conf
'

rm -rf "$root/dev" && mkdir -m 755 "$root/dev"
kver=$(ls "$root/lib/modules")
init=$work/initramfs
rm -rf "$init"
mkdir -p "$init/bin" "$init/lib/modules" "$init/sysroot" "$init/proc" "$init/sys" "$init/dev"
cp "$root/bin/busybox.static" "$init/bin/busybox"
for m in fs/netfs/netfs net/9p/9pnet net/9p/9pnet_virtio fs/9p/9p; do
	gzip -dc "$root/lib/modules/$kver/kernel/$m.ko.gz" >"$init/lib/modules/$(basename "$m").ko"
done
install -m 755 "$here/initramfs-init" "$init/init"
(cd "$init" && find . | cpio -o -H newc --quiet | gzip -9) >"$out/initrd.img"
cp "$root/boot/vmlinuz-virt" "$out/bzImage"
rm -rf "$root/boot"

python3 "$here/tools/fs2json.py" --out "$out/fs.json" "$root"
mkdir -p "$out/fs"
python3 "$here/tools/copy-to-sha256.py" "$root" "$out/fs"
echo "files: $(ls "$out/fs" | wc -l), size: $(du -sh "$out" | cut -f1)"
