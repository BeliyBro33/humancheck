rm -r  "/root/humancheck/humancheck.sh" &&  rm -r "/root/humancheck/main.sh"

git clone https://github.com/BeliyBro33/humancheck.git

chmod +x "/root/humancheck/main.sh"

mchat=""

token=""

echo -e $mchat	> "/root/humancheck/mchat.properties"

echo -e $token	> "/root/humancheck/token.properties"




sudo mv /root/human.service /etc/systemd/system


sudo tee <<EOF >/dev/null /etc/systemd/journald.conf

Storage=persistent

EOF

sudo systemctl restart systemd-journald

sudo systemctl daemon-reload

sudo systemctl enable human

sudo systemctl restart human



sudo systemctl stop human

systemctl status human

journalctl -u human-f
