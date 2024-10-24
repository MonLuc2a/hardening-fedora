#!/bin/bash

# Configuration des permissions des fichiers cron
chmod 700 /etc/crontab
chmod 700 /etc/cron.monthly
chmod 700 /etc/cron.weekly
chmod 700 /etc/cron.daily
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.d
chmod 700 /etc/cron.deny

# Activer et démarrer firewalld
systemctl enable firewalld
systemctl start firewalld

# Définir la politique par défaut du pare-feu sur "drop"
sudo firewall-cmd --set-default=drop

# Ajouter des protocoles pour IPv6 si nécessaire
sudo firewall-cmd --add-protocol=ipv6-icmp --permanent
sudo firewall-cmd --add-service=dhcpv6-client --permanent

# Mettre à jour et redémarrer pour Secure Boot
sudo dnf update -y
sudo reboot

# Installer des extensions et applications nécessaires
sudo dnf install -y ublock-origin keepassXC ffmpeg mozilla-openh264 lynis timeshift rkhunter gnome-tweaks usbguard

# Configurer rkhunter
sudo rkhunter --propupd
sudo rkhunter --update
sudo rkhunter --check --sk

# Auditer le système avec Lynis
sudo lynis audit system

# Désactiver et masquer les services inutiles
services=(pcscd.socket pcscd.service cups wpa_supplicant.service ModemManager.service bluetooth.service avahi-daemon.service nis-domainname.service sssd.service sssd-kcm.service rpcbind.service gssproxy.service nfs-client.target)
for service in "${services[@]}"; do
  sudo systemctl disable --now $service
  sudo systemctl mask $service
done

# Modifier les paramètres de logind.conf
sudo bash -c 'echo -e "NAutoVTs=0\nReserveVT=N" >> /etc/systemd/logind.conf'

# Créer un fichier de blacklist pour les modules inutiles
sudo bash -c 'cat <<EOF > /etc/modprobe.d/custom-blacklist.conf
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
EOF'

# Modifier les paramètres de sysctl
sudo bash -c 'cat <<EOF > /etc/sysctl.d/99-sysctl.conf
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
EOF'

# Appliquer les paramètres sysctl
sudo sysctl -p

# Désactiver IPv6 si nécessaire
sudo grubby --update-kernel=ALL --args="ipv6.disable=1"

# Configurer NetworkManager pour la confidentialité IPv6
sudo bash -c 'echo -e "[connection]\nipv6.ip6-privacy=2" >> /etc/NetworkManager/NetworkManager.conf'

# Modifier les limites de sécurité
sudo bash -c 'echo -e "hard core 0" >> /etc/security/limits.conf'

# Modifier l'ID de la machine
sudo bash -c 'echo "b08dfa6083e7567a1921a715000001fb" > /var/lib/dbus/machine-id'
sudo bash -c 'echo "b08dfa6083e7567a1921a715000001fb" > /etc/machine-id'

# Configurer le nom d'hôte
sudo bash -c 'echo -e "192.168.1.123 fedora fedora.local\n127.0.1.1 fedora fedora.local" >> /etc/hosts'

# Supprimer le compilateur
sudo rm /usr/bin/as

# Configurer les permissions des fichiers cron
sudo chmod 700 /etc/crontab
sudo chmod 700 /etc/cron.{monthly,weekly,daily,hourly,d}

# Configurer usbguard
sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf
