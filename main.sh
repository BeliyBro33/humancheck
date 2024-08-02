#!/bin/bash
token=$(sudo cat "${HOME}/humancheck/token.properties")
#Ключи 
#'/Ссылка' - получить ссылку на верификацию
#'/КогдаВериф?' - получить ссылку на верификацию
#
#
#
#
#
#

#функция проверки всех переменных бота и чата
function check_parametr
{
	sleep 1
	if [[ "${token}" < "1" ]] ; then
	echo "Не задан токен бота! Введите токен бота:"
	read token 
	echo -e $token	> "/root/humancheck/token.properties"
	fi
}

#вызов функции проверки всех переменных бота и чата
check_parametr


function get_update
{
var=$( curl -s https://api.telegram.org/bot$token/getUpdates )
count=$( echo "${var}" | jq '.result | length' )
if [ $count -gt 0 ]
then
for (( i=0; i < count; i++ ))
{
text[$i]=$( echo "${var}" | jq ".result[$i].message.text" | tr -d \")
chek_text=${text::1}
echo $chek_text
sleep 2
	if [[$chek_text == б*]]
	then
		echo sendm
	fi


echo ${text[$i]}
update_id[$i]=$( echo "${var}" | jq ".result[$i].update_id")
echo ${update_id[$i]} 
sleep 2
#curl -s https://api.telegram.org/bot$token/getUpdates?offset=$update_id
}
fi
} 







#get_update



key='/КогдаВериф?'

bash "/root/humancheck/humancheck.sh"  -$key
sleep 5

key='/Ссылка?'

bash "/root/humancheck/humancheck.sh"  -$key