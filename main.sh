#!/bin/bash
clear
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
token=$(cat "/root/humancheck/token.properties")
mchat=$(cat "/root/humancheck/mchat.properties")
gendalf=$(cat "/root/humancheck/gendalf.properties")
update=$(cat "/root/humancheck/update.properties")
echo $update 
sleep 5

#Ключи 
#'/Link' - получить ссылку на верификацию
#'/Data' - получить дату аутентификации
#'/Check' - для проверки времени до аутентификации
#'/Pora' - для получения сообщения что аутентификация не пройдена
#'/Update' - обновить бота
#'/On' - включить проверку 
#'/Off' - Выключить проверку
#функция проверки всех переменных бота и чата
function check_parametr
{
	sleep 1
	if [[ "${#mchat}" < "1" ]] ; then
	echo "Не задан ИД чата! Введите ИД чата:"
	fi
	sleep 1
	if [[ "${#token}" < "1" ]] ; then
	echo "Не задан токен бота! Введите токен бота:"
	fi
}

#вызов функции проверки всех переменных бота и чата
check_parametr

#функция которая принимает сообщения от бота
function get_update
{
for (( ;; )); do
var=$( curl -s https://api.telegram.org/bot$token/getUpdates )
text=$(echo "${var}" | jq -r ".result[0].message.text") 
update_id=$( echo "${var}" | jq -r ".result[0].update_id")
let "update_id=${update_id}+1"
chek_text=${text::1}
sleep 2
	if [ "$chek_text" = "/" ]; then
		if	 [ "$text" = "/Link" ]; then
		bash "/root/humancheck/humancheck.sh"  -'/Link'
		elif  [ "$text" = "/Data" ]; then
		bash "/root/humancheck/humancheck.sh"  -'/Data'
   		elif  [ "$text" = "/Update" ]; then
   		update=$update_id
		echo $update > "/root/humancheck/update.properties"
		bash "/root/humancheck/humancheck.sh"  -'/Update'
 		elif  [ "$text" = "/Off" ]; then
		sound='1'
		echo $sound > "/root/humancheck/sound.properties" 
  		curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Уведомления выключены!" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
 		elif  [ "$text" = "/On" ]; then
		sound='0'
		echo $sound > "/root/humancheck/sound.properties" 
  		curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Уведомления включены!" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
		fi
	else 
		echo $text
	fi
sleep 2
curl -s https://api.telegram.org/bot$token/getUpdates?offset=$update_id
done
} 
get_update &
for (( ;; )); do
	sound=$(cat "/root/humancheck/sound.properties")
	if [[ "${sound}" = "0" ]]; then
		#в цикле проверяем сколько часов осталось до аутентификации
		bash "/root/humancheck/humancheck.sh"  -'/Check'
		timehours=$(cat "/root/humancheck/time.properties")
		echo -e "${GREEN} $timehours часов ${NC}"
		#если времени меньше 2 часов переходим на поминутное сканирование
		if [[ "${timehours}" = "1" ]] ; then
			#поминутное сканирование
			for (( ;; )); do
				datatoverif=$(curl -s -X POST http://localhost:9933  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result.Active.expires_at)
				let "datatoverif=${datatoverif}/1000"
				datatoverif=$(TZ='Europe/Moscow' date -d @$datatoverif  +%s )
				datenow=$(TZ='Europe/Moscow' date  +%s)
				let "DIFF=((${datatoverif} - ${datenow})/60)"
				echo  -e "${GREEN} $DIFF минут ${NC} " 
				#если меньше 5 минут
				if [[ "${DIFF}" = "5" ]] ; then
					echo 5 minut
					curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Аутентификация начнется через 5 минут . Ссылку скоро получите" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
				elif [[ "${DIFF}" = "1" ]] ; then
					echo 1 minuta
					curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "До аутентификации 1 минута, через минуту пришлю ссылку" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
					sleep 90
					bash "/root/humancheck/humancheck.sh"  -'/Link'
					for (( ;; )); do
						echo v konecnom cikle
						sleep 300
						datatoverif=$(curl -s -X POST http://localhost:9933  -H "Content-Type: application/json"  -d '{"jsonrpc": "2.0","id": 1,"method": "bioauth_status","params": []}'| jq -r .result)
						echo $datatoverif - до верификацию
						if [[ "${datatoverif}" = "Inactive" ]] ; then
							echo pora
							bash "/root/humancheck/humancheck.sh"  -'/Pora'
						else
							curl -X POST -H 'Content-Type: application/json' -d '{"chat_id": "'"$mchat"'", "text": "Успех!" "disable_notification": false}' https://api.telegram.org/bot$token/sendMessage
							echo  -e "${GREEN} Успех! ${NC} " 
							gendalf='0'
							echo $gendalf > "/root/humancheck/gendalf.properties" 
							break 2
						fi
					done
				fi		
				sleep 60
			done
		fi
	else 
		echo vkluchen mute
	fi
echo vishel! таймаут 300 сек
for (( timer=20; timer>0; timer-- ))
	do
		printf "* sleep for ${RED}%02d${NC} sec\r" $timer
		sleep 1
    done
done
