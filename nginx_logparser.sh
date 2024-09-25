#!/bin/bash

# Путь к каталогу, где находится скрипт
BASEDIR=$(dirname $(realpath "$0"))

echo $BASEDIR

# Необходимые переменные
wwwlog=$BASEDIR/access.log
# Файл блокировки для защиты сценария от повторного запуска
LOCKFILE=$BASEDIR/"file.lock"

TMPFILE=$BASEDIR/"report.tmp"

USER="vagrant"
DOMAIN="localhost"
MAIL=$USER'@'$DOMAIN


N1='10'  # Число IP-адресов с наибольшим количеством запросов
N2='15'  # Число запрашиваемых адресов с наибольшим количеством запросов


function get_ips {
	echo "Список IP адресов:" >> $TMPFILE
	cat $wwwlog | awk '{print $1}'  | sort | uniq -c | sort -rn | head -n $N1 >> $TMPFILE
}	

function get_urls {
	echo "Список запрашиваемых URL:" >> $TMPFILE
	cat $wwwlog | awk '{print $7}'  | sort | uniq -c | sort -rn | head -n $N2 >> $TMPFILE
}

function get_errors {
	echo "Список ошибок:" >> $TMPFILE
	cat $wwwlog  | awk '
			{
				if (match($9,/^5.*/))
					{printf "| %3d | %-12d |%s\n", ++i, $9, $7}
				else
					{}
			}' >> $TMPFILE
}	

function get_status_codes {	
	cat $wwwlog | awk '{print $9}'  | sort | uniq -c | sort -rn | awk '
			BEGIN {
				return_codes[100]="Continue"
				return_codes[101]="Switching Protocols"
				return_codes[102]="Processing"
				return_codes[200]="OK"
				return_codes[201]="Created"
				return_codes[202]="Accepted"
				return_codes[203]="Non-Authoritative Information"
				return_codes[204]="No Content"
				return_codes[205]="Reset Content"
				return_codes[206]="Partial Content"
				return_codes[207]="Multi-Status"
				return_codes[208]="Already Reported"
				return_codes[226]="IM Used"
				return_codes[300]="Multiple Choices"
				return_codes[301]="Moved Permanently"
				return_codes[302]="Moved Temporarily"
				return_codes[302]="Found"
				return_codes[303]="See Other"
				return_codes[304]="Not Modified"
				return_codes[305]="Use Proxy"
				return_codes[307]="Temporary Redirect"
				return_codes[308]="Permanent Redirect"
				return_codes[400]="Bad Request"
				return_codes[401]="Unauthorized"
				return_codes[402]="Payment Required"
				return_codes[403]="Forbidden"
				return_codes[404]="Not Found"
				return_codes[405]="Method Not Allowed"
				return_codes[406]="Not Acceptable"
				return_codes[407]="Proxy Authentication Required"
				return_codes[408]="Request Timeout"
				return_codes[409]="Conflict"
				return_codes[410]="Gone"
				return_codes[411]="Length Required"
				return_codes[412]="Precondition Failed"
				return_codes[413]="Payload Too Large"
				return_codes[414]="URI Too Long"
				return_codes[415]="Unsupported Media Type"
				return_codes[416]="Not Satisfiable"
				return_codes[417]="Expectation Failed"
				return_codes[418]="Im a teapot"
				return_codes[419]="Authentication Timeout"
				return_codes[421]="Misdirected Request"
				return_codes[422]="Unprocessable Entity"
				return_codes[423]="Locked"
				return_codes[424]="Failed Dependency"
				return_codes[426]="Upgrade Required"
				return_codes[428]="Required"
				return_codes[429]="Too Many Requests"
				return_codes[431]="Request Header Fields Too Large"
				return_codes[449]="Retry With"
				return_codes[451]="Unavailable For Legal Reasons"
				return_codes[452]="Bad sended request"
				return_codes[499]="Client Closed Request"
				return_codes[500]="Internal Server Error"
				return_codes[501]="Not Implemented"
				return_codes[502]="Bad Gateway"
				return_codes[503]="Service Unavailable"
				return_codes[504]="Gateway Timeout"
				return_codes[505]="HTTP Version Not Supported"
				return_codes[506]="Variant Also Negotiates"
				return_codes[507]="Insufficient Storage"
				return_codes[508]="Loop Detected"
				return_codes[509]="Bandwidth Limit Exceeded"
				return_codes[510]="Not Extended"
				return_codes[511]="Network Authentication Required"
				return_codes[520]="Unknown Error"
				return_codes[521]="Web Server Is Down"
				return_codes[522]="Connection Timed Out"
				return_codes[523]="Origin Is Unreachable"
				return_codes[524]="A Timeout Occurred"
				return_codes[525]="SSL Handshake Failed"
				return_codes[526]="Invalid SSL Certificate"

				printf "Коды возврата HTML:\n"
			}
			{
				printf " %3d | %-25s | %6d |\n", \
					 $2, return_codes[$2], $1		
			}'  >> $TMPFILE

}

function del_tmp_files {
    if [ -f $TMPFILE ]; then
        rm $TMPFILE
    fi
}

	if [ -f $LOCKFILE ]; then
		echo "Ошибка запуска! Запущена другая копия этого сценария."
		exit -1
	else
		touch $LOCKFILE

    get_ips
    get_urls
    get_errors
    get_status_codes
   
    # Просмотр отчета  
   cat $TMPFILE  
    # Отправка отчета
   cat $TMPFILE | mail -s "REPORT" $MAIL
   
    rm $LOCKFILE
    del_tmp_files
	fi