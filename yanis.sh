# Renforcement du noyau
sysctl -w dev.tty.ldisc_autoload=0
echo "dev.tty.ldisc_autoload=0" | tee -a /etc/sysctl.conf
sysctl -w fs.protected_fifos=2
echo "fs.protected_fifos=2" | tee -a /etc/sysctl.conf
sysctl -w fs.protected_regular=2
echo "fs.protected_regular=2" | tee -a /etc/sysctl.conf
sysctl -w fs.suid_dumpable=0
echo "fs.suid_dumpable=0" | tee -a /etc/sysctl.conf
sysctl -w kernel.kptr_restrict=2
echo "kernel.kptr_restrict=2" | tee -a /etc/sysctl.conf
sysctl -w kernel.modules_disabled=1
echo "kernel.modules_disabled=1" | tee -a /etc/sysctl.conf
sysctl -w kernel.sysrq=0
echo "kernel.sysrq=0" | tee -a /etc/sysctl.conf
sysctl -w kernel.unprivileged_bpf_disabled=1
echo "kernel.unprivileged_bpf_disabled=1" | tee -a /etc/sysctl.conf
sysctl -w kernel.yama.ptrace_scope=1
echo "kernel.yama.ptrace_scope=1" | tee -a /etc/sysctl.conf
sysctl -w net.ipv4.conf.all.accept_redirects=0
echo "net.ipv4.conf.all.accept_redirects=0" | tee -a /etc/sysctl.conf
sysctl -w net.ipv4.conf.all.log_martians=1
echo "net.ipv4.conf.all.log_martians=1" | tee -a /etc/sysctl.conf
sysctl -w net.ipv4.conf.all.send_redirects=0
echo "net.ipv4.conf.all.send_redirects=0" | tee -a /etc/sysctl.conf
sysctl -w net.ipv4.conf.default.accept_redirects=0
echo "net.ipv4.conf.default.accept_redirects=0" | tee -a /etc/sysctl.conf
sysctl -w net.ipv4.conf.default.log_martians=1
echo "net.ipv4.conf.default.log_martians=1" | tee -a /etc/sysctl.conf
sysctl -w net.ipv6.conf.all.accept_redirects=0
echo "net.ipv6.conf.all.accept_redirects=0" | tee -a /etc/sysctl.conf
sysctl -w net.ipv6.conf.default.accept_redirects=0
echo "net.ipv6.conf.default.accept_redirects=0" | tee -a /etc/sysctl.conf

# Gestion des droits
chmod 600 /etc/at.deny
chmod 600 /etc/cron.deny
chmod 600 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /etc/cron.daily/
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.weekly
chmod 700 /etc/cron.monthly

# Réseau
echo "Configuration du pare-feu..."
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --set-default-zone=drop
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

echo "Installation et configuration de Fail2Ban..."
dnf install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

echo "Configuration de SSH..."
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Malware
echo "Installation de ClamAV pour la protection contre les malwares..."
dnf install -y clamav clamav-update
freshclam
systemctl enable clamd
systemctl start clamd

# Application des paramètres sysctl
sysctl -p

# Mise à jour du noyau pour appliquer les paramètres de sécurité
grubby --update-kernel=ALL --args="module.sig_enforce=1"
grubby --update-kernel=ALL --args="ipv6.disable=1"

# Configuration de NetworkManager pour IPv6
echo -e "[connection]\nipv6.ip6-privacy=2" | tee -a /etc/NetworkManager/NetworkManager.conf

# Configuration des limites de sécurité
echo "hard core 0" | tee -a /etc/security/limits.conf

# Modification de l'ID de la machine
echo "b08dfa6083e7567a1921a715000001fb" | tee /var/lib/dbus/machine-id /etc/machine-id

# Configuration du fichier hosts
local_ip=$(ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1)
hostname=$(hostname)
echo -e "$local_ip $hostname $hostname.local\n127.0.1.1 $hostname $hostname.local" | tee -a /etc/hosts

# Suppression du compilateur
rm /usr/bin/as

# Configuration des umask pour les nouveaux fichiers
echo "ulimit -S -c 0 > /dev/null 2>&1" | tee -a /etc/profile
echo "umask 077" | tee -a /etc/profile /etc/login.defs /etc/init.d/functions

# Configuration des permissions des fichiers cron
chmod 700 /etc/crontab
chmod 700 /etc/cron.monthly
chmod 700 /etc/cron.weekly
chmod 700 /etc/cron.daily
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.d
chmod 700 /etc/cron.deny

# Installation et configuration de USBGuard
dnf install -y usbguard
usbguard generate-policy | tee /etc/usbguard/rules.conf

# Configuration de SSHD
echo "Configuration de SSHD..."
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Configuration de YESCRYPT_COST_FACTOR
sed -i 's/^#\(YESCRYPT_COST_FACTOR\).*/\1 10/' /etc/login.defs

echo "Script de renforcement de sécurité terminé. Veuillez redémarrer votre système pour appliquer toutes les modifications."
