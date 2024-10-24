#!/bin/bash

# Configuration des permissions des fichiers cron
chmod 600 /etc/at.deny
chmod 600 /etc/cron.deny
chmod 600 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /etc/cron.daily/
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.weekly
chmod 700 /etc/cron.monthly

# Activer et démarrer firewalld
systemctl enable firewalld
systemctl start firewalld

# Définir la politique par défaut du pare-feu sur "drop"
firewall-cmd --set-default-zone=drop
firewall-cmd --permanent --add-service=ssh
firewall-cmd --add-protocol=ipv6-icmp --permanent
firewall-cmd --add-service=dhcpv6-client --permanent
firewall-cmd --reload

# Installer et configurer Fail2Ban
dnf install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Configurer SSH
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Mettre à jour et redémarrer pour Secure Boot
dnf update -y

# Ajouter les dépôts RPM Fusion
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Installer des extensions et applications nécessaires
dnf install -y keepassxc ffmpeg mozilla-openh264 lynis timeshift rkhunter gnome-tweaks usbguard clamav clamav-update

# Configurer rkhunter
rkhunter --propupd
rkhunter --update
rkhunter --check --sk

# Configurer ClamAV
freshclam
systemctl enable clamd
systemctl start clamd

# Désactiver et masquer les services inutiles
services=(pcscd.socket pcscd.service cups wpa_supplicant.service ModemManager.service bluetooth.service avahi-daemon.service nis-domainname.service sssd.service sssd-kcm.service rpcbind.service gssproxy.service nfs-client.target)
for service in "${services[@]}"; do
  systemctl disable --now $service
  systemctl mask $service
done

# Modifier les paramètres de logind.conf
echo -e "NAutoVTs=0\nReserveVT=N" >> /etc/systemd/logind.conf

# Créer un fichier de blacklist pour les modules inutiles
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

# Modifier les paramètres de sysctl
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
kernel.core_pattern = /bin/false
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

# Appliquer les paramètres sysctl
sysctl -p

# Désactiver IPv6 si nécessaire
grubby --update-kernel=ALL --args="ipv6.disable=1"

# Configurer NetworkManager pour la confidentialité IPv6
echo -e "[connection]\nipv6.ip6-privacy=2" >> /etc/NetworkManager/NetworkManager.conf

# Modifier les limites de sécurité
echo -e "hard core 0" >> /etc/security/limits.conf

# Modifier l'ID de la machine
echo "b08dfa6083e7567a1921a715000001fb" > /var/lib/dbus/machine-id
echo "b08dfa6083e7567a1921a715000001fb" > /etc/machine-id

# Configurer le nom d'hôte
local_ip=$(ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1)
hostname=$(hostname)
echo -e "$local_ip $hostname $hostname.local\n127.0.1.1 $hostname $hostname.local" >> /etc/hosts

# Supprimer le compilateur
rm /usr/bin/as

# Configurer les umask pour les nouveaux fichiers
echo "ulimit -S -c 0 > /dev/null 2>&1" >> /etc/profile
echo "umask 077" >> /etc/profile /etc/login.defs /etc/init.d/functions

# Configurer usbguard
systemctl enable usbguard
systemctl start usbguard
usbguard generate-policy | tee /etc/usbguard/rules.conf

# Configuration de YESCRYPT_COST_FACTOR
sed -i 's/^#\(YESCRYPT_COST_FACTOR\).*/\1 10/' /etc/login.defs

echo "Script de renforcement de sécurité terminé. Veuillez redémarrer votre système pour appliquer toutes les modifications."
