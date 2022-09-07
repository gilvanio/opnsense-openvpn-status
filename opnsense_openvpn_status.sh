#!/usr/local/bin/bash
#
# Plugin name : opnsense_openvpn_status.sh
# Versao      : 1.2
# Escrito por : Gilvanio Moura <gilvaniomoura@gmail.com> 17/08/2022 11:35
#
# Modificacoes :
#
# O objetivo deste script coletar as informacoes dos usuarios conectados
#  2 - Common Name
#  3 - Real Address
#  4 - Virtual Address
#  6 - Bytes Received
#  7 - Bytes Sent
#  8 - Connected Since
#  9 - Connected Since (time_t)
# 10 - Username
# extra - LoginTime : timestamp para calculo do tempo de conexao

# Execucao a cada 1 minuto no cron
# 
# Pre-requisito
#==============
# 1 - shell bash
#-----------
# pkg install bash
#
# 2 - inflxdb 18 instalado (em outro servidor)
#
# Sugestao
#=========
# 1 - nivel log status openvpn : status-version 2 (separacao de campos por virgula)
# 2 - copiar arquivo de configuracao para : /usr/local/etc/opnsense_openvpn_status.conf
# 3 - copiar script para /usr/local/bin/opnsense_openvpn_status.sh
#

# binarios
curlBin=$( which curl )

if [ -e /usr/local/etc/opnsense_openvpn_status.conf ]
then
    . /usr/local/etc/opnsense_openvpn_status.conf
else
    echo "Arquivo [/usr/local/etc/opnsense_openvpn_status.conf] nao existe, parando execucao"
    exit 0
fi

for logName in $arqLog 
do
    if [ -e $dirLog/$logName ]
    then
	timets=$( date +"%s" )
	DATA+="$( cat $dirLog/$logName | grep "^CLIENT_LIST" | awk -F"," -v LoginTime=$timets '{print $2"\" \RealAddress=\""$3"\",VirtualAddress=\""$4"\",BytesReceived=\""$6"\",BytesSent=\""$7"\",ConnectedSince=\""$8"\",ConnectedSince_t=\""$9"\",LoginTime=\""LoginTime"\",Username=\""$10 }' | sed "s/^/${measurement},CommonName=\"/;s/$/\"/" )" 

    else
	echo "arquivo [$dirLog/$logName] nao existe" 
    fi
done

## descomentar para debbug
#echo ${DATA}

$curlBin -i -L -k -s -w \"%{http_code}\" -s -XPOST "${urlInflux}" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json" --data-binary "${DATA}" 
exit 0

