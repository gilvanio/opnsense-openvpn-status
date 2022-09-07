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

```
status /var/log/openvpn-status.log 30
status-version 2
```

## Instalação do Grafana

https://grafana.com/docs/grafana/latest/setup-grafana/installation/

## Instalação do InfluxDB 1.8

Neste laboratório o **grafana** e o **influxDB 1.8** foram instalados no mesmo servidor RockyLinux 8.5 (poderá reproduzir as mesmas configurações em qualquer sabor linux de sua preferência)

Estou o usando a **versão 1.8** do **Influxdb**, para versões mais novas a partir das versões **2.x**, a tabela(comparando com um sgbd relacional) muda de **measurement** para **bucket** e outras configurações.

### Adicionando o repositório influxdb 1.8 no RockyLinux 8.5

```
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF
```
```
dnf -y install influxdb

InfluxDB Repository - RHEL 8                                                                                                                                                                                   43 kB/s |  38 kB     00:00    
Última verificação de data de vencimento de metadados: 0:00:01 atrás em sáb 27 ago 2022 13:16:57 -03.
Dependências resolvidas.
==============================================================================================================================================================================================================================================
 Pacote                                                    Arquitetura                                             Versão                                                     Repositório                                               Tamanho
==============================================================================================================================================================================================================================================
Instalando:
 influxdb                                                  x86_64                                                  1.8.10-1                                                   influxdb                                                   52 M

Resumo da transação
==============================================================================================================================================================================================================================================
Instalar  1 Pacote

Tamanho total do download: 52 M
Tamanho depois de instalado: 52 M
Baixando pacotes:
influxdb-1.8.10.x86_64.rpm                                                                                                                                                                                    7.5 MB/s |  52 MB     00:06    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                         7.5 MB/s |  52 MB     00:06     
InfluxDB Repository - RHEL 8                                                                                                                                                                                  6.3 kB/s | 3.0 kB     00:00    
Importando chave GPG 0x2582E0C5:
ID de usuário     : "InfluxDB Packaging Service <support@influxdb.com>"
 Impressão digital: 05CE 1508 5FC0 9D18 E99E FB22 684A 14CF 2582 E0C5
A partir de       : https://repos.influxdata.com/influxdb.key
Chave importada com sucesso
Executando verificação da transação
Verificação de transação completa.
Executando teste de transação
Êxito no teste de transação.
Executando a transação
  Preparando          :                                                                                                                                                                                                                   1/1 
  Executando scriptlet: influxdb-1.8.10-1.x86_64                                                                                                                                                                                          1/1 
  Instalando          : influxdb-1.8.10-1.x86_64                                                                                                                                                                                          1/1 
  Executando scriptlet: influxdb-1.8.10-1.x86_64                                                                                                                                                                                          1/1 
Created symlink /etc/systemd/system/influxd.service → /usr/lib/systemd/system/influxdb.service.
Created symlink /etc/systemd/system/multi-user.target.wants/influxdb.service → /usr/lib/systemd/system/influxdb.service.

  Verificando         : influxdb-1.8.10-1.x86_64                                                                                                                                                                                          1/1 

Instalados:
  influxdb-1.8.10-1.x86_64                                                                                                                                 

Concluído!
```
### Criando certificado autoassinado

**Certificados autoassinados aumentam a segurança na transmissão dos dados, mas não impedem que outro servidor se passe pelo servidor de destino**

```
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/influxdb-selfsigned.key -out /etc/ssl/influxdb-selfsigned.crt -days <DIAS DA VALIDADE>
```
**DIAS DA VALIDADE** será o tempo de validade do certificado, após este prazo o certificado ficará inválido.

## Configurando o influxdb

Editar o arquivo de configuração : **/etc/influxdb/influxdb.conf**, localizar a sessão **[http]** de acordo com o exemplo abaixo

```
[http]
  enabled = true
  bind-address = ":8086"
  auth-enabled = true
  log-enabled = true
  write-tracing = false
  pprof-enabled = true
  pprof-auth-enabled = true
  debug-pprof-enabled = false
  ping-auth-enabled = true
  https-enabled = true
  https-certificate = "/etc/ssl/influxdb-selfsigned.crt"
  https-private-key = "/etc/ssl/influxdb-selfsigned.key"

```


