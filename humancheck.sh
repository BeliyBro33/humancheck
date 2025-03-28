#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
sleep 1
token=$(cat "/root/humancheck/token.properties")
mchat=$(cat "/root/humancheck/mchat.properties")
schat='-1001500189369'
stoken='5434189022:AAFRApdxpp9kahgO5C6OTUyyxxBarEqSUnU'
name=$(cat "/root/.humanode/workspaces/default/workspace.json" | jq -r .nodename)
ip=$(wget -qO - eth0.me)
gendalf=$(cat "/root/humancheck/gendalf.properties")

#функция отправки сообщений
function sendMessage()
{
if [[ "${1}" = "1" ]]; then
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Аутентификация не пройдена!" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
		sleep 1
		if [[ "${gendalf}" = "0" ]]; then
		curl -F chat_id=$mchat -F document=@"/root/humancheck/notactive.gif" https://api.telegram.org/bot$token/sendDocument
		gendalf='1'
		echo $gendalf > "/root/humancheck/gendalf.properties" 
		fi
elif  [[ "${1}" = "2" ]] ; then
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$schat"'", "text": "Тревога! Тревога! Волк унес зайчат (статус не получен) '"$ip"' '"$name"'" "disable_notification": false}' https://api.telegram.org/bot$stoken/sendMessage
elif  [[ "${1}" = "3" ]] ; then
	datatoverif=$(curl -s -X POST http://localhost:9944  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result)
	if [[ "${datatoverif}" = "Inactive" ]] ; then
		message=1
		sendMessage $message
	elif  [[ "${datatoverif}" < "1" ]] ; then
		message=2
		sendMessage $message
	else 
	timeverif=$(curl -s -X POST http://localhost:9944  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result.Active.expires_at)
	let "timeverif=${timeverif}/1000"
	timeverif=$(TZ='Europe/Moscow' date -d @$timeverif   +%d%t%B%t%T )
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Следующая аутентификации будет '"$timeverif"'" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
	fi
fi
}

#функция проверки времени до аутентификации
function  time_do_verif
{ 
	datatoverif=$(curl -s -X POST http://localhost:9944  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result)
	if [[ "${datatoverif}" = "Inactive" ]] ; then
		message=1
		sendMessage $message
	elif  [[ "${datatoverif}" < "1" ]] ; then
		message=2
		sendMessage $message
	else 
		datatoverif=$(curl -s -X POST http://localhost:9944  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result.Active.expires_at)
		let "datatoverif=${datatoverif}/1000"
		datatoverif=$(TZ='Europe/Moscow' date -d @$datatoverif  +%s )
		sleep 1
		datenow=$(TZ='Europe/Moscow' date  +%s)
		let "DIFF=((${datatoverif} - ${datenow})/3600)" #60 -минут 3600 -часов
		echo $DIFF > "/root/humancheck/time.properties" 
	fi
}

#функция обновления
function  update
{ 
update=$(cat "/root/humancheck/update.properties")
if [[ "${update}" > "0" ]] ; then
 rm -r  "/root/humancheck/main.sh"
 rm -r  "/root/humancheck/humancheck.sh"
 rm -r  "/root/humancheck/update.properties"
  echo "try to update"
  sleep 1
  cd "/root/humancheck/"
  sleep 1
  git checkout
  git reset --hard
   sleep 2
  git pull
  sleep 2
  cd -
  chmod +x "/root/humancheck/main.sh"
echo "Done"
curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Обновление выполнено!" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
sleep 2
curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "щас рестартну" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
sleep 2
curl -s https://api.telegram.org/bot$token/getUpdates?offset=$update
sudo systemctl restart human
fi
}

#функция для отправки ссылки на утентификацию
function send_verif_link
{
cd "/root/.humanode/workspaces/default/"
tunel=$(./humanode-websocket-tunnel) &
link=$(./humanode-peer bioauth  auth-url --rpc-url-ngrok-detect --chain chainspec.json) 
if  [[ "${link}" > "1" ]] ; then
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Cсылка на аутентификацию - '"$link"'" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
else 
	curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Тунель не открыт" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
fi
}



case "$1" in 
-'/Data') sendMessage 3;;
-'/Link') send_verif_link;;
-'/Check') time_do_verif;;
-'/Pora') sendMessage 1;;
-'/Update') update;;
*) echo bezkey;;
esac

sleep 2

