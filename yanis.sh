# Renforcement du noyau
sudo sysctl -w dev.tty.ldisc_autoload=0
echo "dev.tty.ldisc_autoload=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w fs.protected_fifos=2
echo "fs.protected_fifos=2" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w fs.protected_regular=2
echo "fs.protected_regular=2" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w fs.suid_dumpable=0
echo "fs.suid_dumpable=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w kernel.kptr_restrict=2
echo "kernel.kptr_restrict=2" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w kernel.modules_disabled=1
echo "kernel.modules_disabled=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w kernel.sysrq=0
echo "kernel.sysrq=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w kernel.unprivileged_bpf_disabled=1
echo "kernel.unprivileged_bpf_disabled=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w kernel.yama.ptrace_scope=1
echo "kernel.yama.ptrace_scope=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
echo "net.ipv4.conf.all.accept_redirects=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.log_martians=1
echo "net.ipv4.conf.all.log_martians=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.log_martians=1
echo "net.ipv4.conf.all.log_martians=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.send_redirects=0
echo "net.ipv4.conf.all.send_redirects=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
echo "net.ipv4.conf.default.accept_redirects=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.log_martians=1
echo "net.ipv4.conf.default.log_martians=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.all.accept_redirects=0
echo "net.ipv6.conf.all.accept_redirects=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.default.accept_redirects=0
echo "net.ipv6.conf.default.accept_redirects=0" | sudo tee -a /etc/sysctl.conf

#gestion des droits

chmod 600 /etc/at.deny
chmod 600 /etc/cron.deny
chmod 600 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /etc/cron.daily/
chmod 700 /etc/cron.daily
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.weekly
chmod 700 /etc/cron.monthly

#Réseau

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

#malware

echo "Installation de ClamAV pour la protection contre les malwares..."
dnf install -y clamav clamav-update
freshclam
systemctl enable clamd
systemctl start clamd

