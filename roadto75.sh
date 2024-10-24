#!/bin/bash


echo "Mise à jour du système..."
dnf update -y

echo "Activation et configuration du pare-feu..."
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --set-default=drop
firewall-cmd --add-protocol=ipv6-icmp --permanent
firewall-cmd --add-service=dhcpv6-client --permanent
firewall-cmd --reload

echo "Installation des outils de base..."
dnf install -y vim git curl

echo "Activation de SELinux en mode enforcing..."
setenforce 1
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

echo "Installation et configuration de Fail2Ban..."
dnf install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

echo "Configuration de SSH..."
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

echo "Installation de Lynis pour les audits de sécurité..."
dnf install -y lynis

echo "Installation de ClamAV pour la protection contre les malwares..."
dnf install -y clamav clamav-update
freshclam
systemctl enable clamd
systemctl start clamd

echo "Configuration de la journalisation locale..."
mkdir -p /var/log/local_logs
cat <<EOF > /etc/rsyslog.d/local-logs.conf
*.* /var/log/local_logs/all.log
EOF
systemctl restart rsyslog

echo "Configuration de la rotation des logs..."
cat <<EOF > /etc/logrotate.d/local-logs
/var/log/local_logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root utmp
    sharedscripts
    postrotate
        /bin/systemctl reload rsyslog > /dev/null 2>/dev/null || true
    endscript
}
EOF

echo "Installation et configuration de Firefox..."
dnf install -y firefox
firefox -new-tab "about:config" &
sleep 5
firefox -new-tab "https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/" &
sleep 5

echo "Installation des dépôts RPM Fusion et Flathub..."
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Installation des applications choisies..."
dnf install -y keepassxc ffmpeg mozilla-openh264
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub org.gnome.Extensions
flatpak install -y flathub org.gnome.Tweaks

echo "Configuration de Firefox pour la sécurité..."
firefox -new-tab "about:config" &
sleep 5
firefox -new-tab "https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/" &
sleep 5

echo "Installation et configuration de BleachBit, KeePassXC, FreeTube, Mullvad..."
dnf install -y bleachbit keepassxc
flatpak install -y flathub io.freetubeapp.FreeTube
flatpak install -y flathub net.mullvad.MullvadVPN

echo "Installation et configuration de Timeshift et RKHunter..."
dnf install -y timeshift rkhunter
rkhunter --propupd
rkhunter --update
rkhunter --check --sk

echo "Configuration de GNOME Tweaks..."
dnf install -y gnome-tweaks
gnome-tweaks

echo "Désactivation de la mise en veille profonde (suspend to RAM)..."
grubby --args="mem_sleep_default=s2idle" --update-kernel=ALL

echo "Renforcement de PAM et SSSD..."
authselect select sssd with-faillock without-nullok with-pamaccess

echo "Désactivation des services inutilisés..."
systemctl disable --now pcscd.socket pcscd.service cups wpa_supplicant.service ModemManager.service bluetooth.service avahi-daemon.service nis-domainname.service sssd.service sssd-kcm.service rpcbind.service gssproxy.service nfs-client.target
systemctl mask cups avahi-daemon.service bluetooth.service nis-domainname.service sssd.service sssd-kcm.service rpcbind.service gssproxy.service wpa_supplicant.service ModemManager.service nfs-client.target rpc-gssd.service rpc-statd.service rpc-statd-notify.service nfsdcld.service nfs-mountd.service nfs-idmapd.service
systemctl daemon-reload

echo "Désactivation de SSH si non utilisé..."
systemctl mask sshd.service

echo "Désactivation des terminaux tty..."
sed -i 's/^#NAutoVTs=.*/NAutoVTs=0/' /etc/systemd/logind.conf
sed -i 's/^#ReserveVT=.*/ReserveVT=N/' /etc/systemd/logind.conf
systemctl restart systemd-logind

echo "Blacklisting des modules inutilisés..."
cat <<EOF > /etc/modprobe.d/custom-blacklist.conf
install dccp /bin/false
install sctp /bin/false
install rds /bin/false
install tipc /bin/false
install n-hdlc /bin/false
install ax25 /bin/false
install netrom /bin/false
install x25 /bin/false
install rose /bin/false
install decnet /bin/false
install econet /bin/false
install af_802154 /bin/false
install ipx /bin/false
install appletalk /bin/false
install psnap /bin/false
install p8023 /bin/false
install p8022 /bin/false
install can /bin/false
install atm /bin/false
install cramfs /bin/false
install freevxfs /bin/false
install jffs2 /bin/false
install hfs /bin/false
install hfsplus /bin/false
install squashfs /bin/false
install udf /bin/false
install cifs /bin/true
install nfs /bin/true
install nfsv3 /bin/true
install nfsv4 /bin/true
install ksmbd /bin/true
install gfs2 /bin/true
install vivid /bin/false
install bluetooth /bin/false
install btusb /bin/false
install uvcvideo /bin/false
install firewire-core /bin/false
install thunderbolt /bin/false
install snd_hda_intel /bin/false
EOF

echo "Configuration des paramètres sysctl..."
cat <<EOF > /etc/sysctl.d/99-sysctl.conf
fs.suid_dumpable = 0
fs.protected_fifos = 2
fs.protected_regular = 2
kernel.dmesg_restrict = 1
dev.tty.ldisc_autoload = 0
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 2
kernel.unprivileged_bpf_disabled = 1
kernel.sysrq = 0
kernel.perf_event_paranoid = 3
kernel.core_pattern = |/bin/false
vm.unprivileged_userfaultfd = 0
kernel.kexec_load_disabled = 1
kernel.printk = 3 3 3 3
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 3
net.core.bpf_jit_harden = 2
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_all = 1
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0
net.ipv4.tcp_fack = 0
net.ipv4.tcp_rfc1337 = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF
sysctl --system

echo "Script de renforcement de sécurité terminé. Veuillez redémarrer