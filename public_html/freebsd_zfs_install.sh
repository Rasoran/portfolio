for i in {0..3}; do
    gpart destroy -F ada$i
    gpart create -s gpt ada$i
    gpart add -s 222 -a 4k -t freebsd-boot -l boot$i ada$i
    gpart add -s 8g -a 4k -t freebsd-swap -l swap$i ada$i
    gpart add -a 4k -t freebsd-zfs -l disk$i ada$i
    gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ada$i
    gnop create -S 4096 /dev/gpt/disk$i
done

sleep 5
kldload zfs

sleep 5
# CHANGE THIS LINE AS NEEDED
zpool create -o altroot=/mnt -O canmount=off -m none tank mirror /dev/gpt/disk$i.nop /dev/gpt/disk1.nop

zfs set checksum=fletcher4                                           tank
zfs set atime=off                                                    tank
zfs create   -o mountpoint=none                                      tank/ROOT
zfs create   -o mountpoint=/                                         tank/ROOT/default
zfs create   -o mountpoint=/tmp -o compression=lz4  -o setuid=off   tank/tmp
chmod 1777 /mnt/tmp
zfs create   -o mountpoint=/usr                                      tank/usr
zfs create                                                           tank/usr/local
zfs create   -o mountpoint=/home                     -o setuid=off   tank/home
zfs create   -o compression=lz4                     -o setuid=off   tank/usr/ports
zfs create   -o compression=off      -o exec=off     -o setuid=off   tank/usr/ports/distfiles
zfs create   -o compression=off      -o exec=off     -o setuid=off   tank/usr/ports/packages
zfs create   -o compression=lz4     -o exec=off     -o setuid=off   tank/usr/src
zfs create                                                           tank/usr/obj
zfs create   -o mountpoint=/var                                      tank/var
zfs create   -o compression=lz4     -o exec=off     -o setuid=off   tank/var/crash
zfs create                           -o exec=off     -o setuid=off   tank/var/db
zfs create   -o compression=lz4     -o exec=on      -o setuid=off   tank/var/db/pkg
zfs create                           -o exec=off     -o setuid=off   tank/var/empty
zfs create   -o compression=lz4     -o exec=off     -o setuid=off   tank/var/log
zfs create   -o compression=gzip     -o exec=off     -o setuid=off   tank/var/mail
zfs create                           -o exec=off     -o setuid=off   tank/var/run
zfs create   -o compression=lz4     -o exec=on      -o setuid=off   tank/var/tmp
chmod 1777 /mnt/var/tmp
zpool set bootfs=tank/ROOT/default tank
cat << EOF > /tmp/bsdinstall_etc/fstab
