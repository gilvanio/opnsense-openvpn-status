# Opnsense openvpn status

Exibição dos usuários conectados no openvpn instalado do Opnsense no grafana.

O envio dos dados será feita de forma segura (criptografada), através do https.

Neste projeto estou utilizando 

* OPNsense 21.1.7 (deve funcionar em versões anteriores)
* shell bash
* influxDB 18 (instalado no mesmo servidor do grafana)
* Grafana 9

## Configurações no OpnSense

### Instalar o shell bash 

- Verificando se o bash está instalado

`# cat /etc/shells | grep bash`

- Instalando o bash

`# pkg install bash`

### Copiar os arquivos

* opnsense_openvpn_status.sh copiar para /usr/local/bin/

`# cp -a opnsense_openvpn_status.sh /usr/local/bin/`

* opnsense_openvpn_status.conf copiar para /usr/local/etc/

`# cp -a opnsense_openvpn_status.conf /usr/local/etc/`

* opnsense-status-cron copiar para /etc/cron.d/

`# cp -a opnsense-status-cron /etc/cron.d/` 

