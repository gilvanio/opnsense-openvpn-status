# Opnsense openvpn status

Exibição dos usuários conectados no openvpn instalado do Opnsense no grafana.

O envio dos dados será feita de forma segura (criptografada), através do https.

Neste projeto estou utilizando 

* OPNsense 21.1.7 (deve funcionar em versões anteriores)
* shell bash
* influxDB 18 (instalado no mesmo servidor do grafana)
* Grafana 9
* RockyLinux 8.5

## Configurações no OPNSense

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

## Configuração do OpenVPN

Nas configurações do openvpn, na sessão **Advanced configuration** adicionar 

**status /var/log/openvpn-status.log 30**

**status-version 2**

### Instalação do Grafana

https://grafana.com/docs/grafana/latest/setup-grafana/installation/

### Instalação do InfluxDB 1.8
Neste laboratório o **grafana** e o **influxDB** foram instalados no mesmo servidor RockyLinux 8.5 (ou qualquer sabor linux de sua preferência)



