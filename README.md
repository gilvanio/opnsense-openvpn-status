# Opnsense openvpn status

Exibição dos usuários conectados no openvpn instalado no Opnsense no grafana.

O envio dos dados será feita de forma segura (criptografada), através do https.

Neste projeto estou utilizando

* OPNsense 21.1.7 (deve funcionar em versões anteriores)
* shell bash
* influxDB 18 (instalado no mesmo servidor do grafana)
* Grafana 9.x
* RockyLinux 8.5

## Configurações no OPNSense

### Instalar o shell bash 

- Verificando se o bash está instalado

`# cat /etc/shells | grep bash`

- Instalando o bash

`# pkg install bash`

### Copiar os arquivos

* opnsense_openvpn_status.sh copiar para /usr/local/bin/

`# scp -p opnsense_openvpn_status.sh root@<IP FIREWALL>:/usr/local/bin/`

* opnsense_openvpn_status.conf copiar para /usr/local/etc/

`# scp -p opnsense_openvpn_status.conf root@<IP FIREWALL>:/usr/local/etc/`

* opnsense-status-cron copiar para /etc/cron.d/

`# scp -p opnsense-status-cron root@<IP FIREWALL>:/etc/cron.d/` 

## Configurando o OpenVPN

Nas configurações do openvpn, na sessão **Advanced configuration** adicionar :

```
status /var/log/openvpn-status.log 30
status-version 2
```
A opção : **status-version 2**, define que o delimitador dos campos será a vírgula

![image](https://user-images.githubusercontent.com/7004964/189235808-3afb347b-1137-4b62-ab30-6bb373913bb6.png)

Não esqueça de salvar

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
**Liberar porta 8086/tcp**

Caso firewalld esteja em execução, será necessário liberar a porta 
```
firewall-cmd --permanent --add-port=8086/tcp
firewall-cmd --reload
firewall-cmd --list-ports
8086/tcp
```
**Ativar na inicialização e iniciar o serviço**

```
systemctl enable influxd
systemctl start influxd
systemctl status influxd
```
### Criando certificado ssl autoassinado

**Certificados autoassinados aumentam a segurança na transmissão dos dados, mas não impedem que outro servidor se passe pelo servidor de destino**

```
openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/<NOME_ARQUIVO>.key -out /etc/ssl/<NOME_ARQUIVO>.crt -days <DIAS DA VALIDADE>

openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/ssl/influxdb-selfsigned.key -out /etc/ssl/influxdb-selfsigned.crt -days 3650
Generating a RSA private key
...........+++++
..........................................+++++
writing new private key to '/etc/ssl/influxdb-selfsigned.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:BR   <-- país
State or Province Name (full name) []:PE   <-- estado
Locality Name (eg, city) [Default City]:Recife  <-- cidade
Organization Name (eg, company) [Default Company Ltd]:Gilvanio Moura Linux <-- Nome da empresa
Organizational Unit Name (eg, section) []:infraestrutura   <-- setor
Common Name (eg, your name or your server's hostname) []:lab-influxdb  <-- nome do servidor
Email Address []:gilvaniomoura@gmail.com   <-- seu email
```
### Modificando as permissões e mudando o dono/grupo

```
chmod 644 /etc/ssl/influxdb/influxdb-selfsigned.crt
chmod 600 /etc/ssl/influxdb/influxdb-selfsigned.key 
chown influxdb:influxdb /etc/ssl/influxdb/selfsigned.*
```
### Configurando o influxdb

Com o editor de sua preferência editar o arquivo de configuração : **/etc/influxdb/influxdb.conf**, localizar a sessão **[http]** de acordo com o exemplo abaixo

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
**Reiniciar o serviço influxd**
```
systemctl restart influxd
```
**Se as configurações forem bem sucedidas não deverá haver erro**

### Primeiro acesso ao influxdb

No primeiro acesso será necessário a criação do usuário **admin**, para depois criar os demais, o banco e as permissões.

Como na configuração foi definida com a opção **https-enabled = true** o acesso deverá ser feito com ssl

**influx -ssl -unsafeSsl -host localhost**

```
]# influx -ssl -unsafeSsl -host localhost
Connected to https://localhost:8086 version 1.8.10
InfluxDB shell version: 1.8.10
```

### Criando o usuário admin

```
> CREATE USER admin WITH PASSWORD '<SENHA>' WITH ALL PRIVILEGES
> quit
```
observação : a senha terá que está entre **aspas simples**

A partir de agora todo acesso terá que ser autenticado pois no arquivo de configuração **/etc/influxdb/influxdb.conf**, a opção **auth-enabled = true**  para desabilitar modifique para **false** e reinicie o influx : **systemctl restart influxd**

Após criar o usuário **admin**, sair com o comando **quit** e conectar novamente, mas desta vez para executar qualquer comando será necessário a autenticação após conectar usando o comando **auth**, **usuário** e **senha**, executar o comando **SHOW USERS**, para testar a permissão.

```
]# influx -ssl -unsafeSsl -host localhost
influx -ssl -unsafeSsl -host localhost
Connected to https://localhost:8086 version 1.8.10
InfluxDB shell version: 1.8.10
> auth
username: admin
password: <SENHA>
> 
>SHOW USERS
user     admin
----     -----
admin    true
```
Antes de criar os outros usuários será necessário criar o banco de dados, pois o usuário **opnsense** será concedido a permissão de gravação.

### Criando banco de dados infraestrutura(a sua escolha)
```
> CREATE DATABASE "infraestrutura"
```
- Listando os bancos
```
> SHOW DATABASES
name: databases
name
----
_internal
infraestrutura
```
### Criando o usuário **grafana** 
O usuário **grafana** terá perfil de **admin** para poder conectar ao banco influxdb
O usuário **opnsense** terá perfil de **WRITE** para gravar os dados no banco influxdb

```
> CREATE USER "grafana" WITH PASSWORD '<SENHA>' WITH ALL PRIVILEGES
> SHOW USERS
user     admin
----     -----
admin    true
grafana  true
> 
```

- Criando o usuário **opnsense** e conceder permissão

```
> CREATE USER "opnsense" WITH PASSWORD '<SENHA>'
> SHOW USERS
user     admin
----     -----
admin     true
grafana   true
opnsense  false

```
- Conceder permissão ao usuário **opnsense** para o banco de dados criado, no nosso exemplo **infraestrutura**
```
> GRANT WRITE ON "infraestrutura" TO "opnsense"
>
```
- Checando as permissões do usuário **opnsense**

```
> SHOW GRANTS FOR "opnsense"
database       privilege
--------       ---------
infraestrutura WRITE
> 
```
## Com os usuários criados e permissões concedidas, banco de dados criado, iremos criar o measurement(tabela)

Se não existir uma **tabela(measurement)** ao tentar conectar o grafana ao banco dará um erro e não conectará ao banco
script quem irá enviar os dados.

* Acessando o banco de dados [infraestrutura] e listando os measurements(tabelas)
```
]# influx -ssl -unsafeSsl -host localhost
influx -ssl -unsafeSsl -host localhost
Connected to https://localhost:8086 version 1.8.10
InfluxDB shell version: 1.8.10
> auth
username: admin
password: <SENHA>
> USE infraestrutura
Using database infraestrutura
> SHOW MEASUREMENTS (o measurement será criado na primeira conexão de envio dos dados)
```
**Se o arquivo de log foi criado no opnsense (/var/log/opnsense-status.log deverá existir dados no arquivo), execute o script /usr/local/bin/opnsense_openvpn_status.sh** no opnsense e checar no influxdb

```
# cat /var/log/openvpn-status.log | grep "^CLIENT_LIST"
CLIENT_LIST,client01,200.XX.XX.XX:33491,10.41.1.6,,164309,44171,Thu Sep  8 17:26:43 2022,1662668803,client01,68,1
CLIENT_LIST,client02,170.XX.XX.XX:33317,10.41.1.10,,182848,44732,Thu Sep  8 17:24:31 2022,1662668671,client02,67,0
```

```
# /usr/local/bin/opnsense_openvnp_status.sh
HTTP/1.1 204 No Content
Content-Type: application/json
Request-Id: 89adcb47-2fc7-11ed-a666-005056aa98e8
X-Influxdb-Build: OSS
X-Influxdb-Version: 1.8.10
X-Request-Id: 89adcb47-2fc7-11ed-a666-005056aa98e8
Date: Thu, 08 Sep 2022 22:42:37 GMT
```
Código **204** indica que houve êxito ao gravar no banco

```
> USE infraestrutura
Using database infraestrutura
> SHOW MEASUREMENTS (o measurement será criado na primeira conexão de envio dos dados)
openvpn-status
> SELECT * FROM "openvpn-status"
name: openvpn-status
time                BytesReceived BytesSent CommonName   ConnectedSince           ConnectedSince_t LoginTime  RealAddress         Username   VirtualAddress
----                ------------- --------- ----------   --------------           ---------------- ---------  -----------         --------   --------------
1661798280096523136 248472        65136     "client01"   Mon Aug 29 12:11:27 2022 1661785887       1661798280 170.xx.xx.xx:33334  client01   10.41.1.10
```
![image](https://user-images.githubusercontent.com/7004964/188971335-d6e136e7-8d5d-4385-a7ee-84f9fc90502e.png)

### Configurar o grafana para conectar ao influxdb

Acessar Configuration --> Data sources

![image](https://user-images.githubusercontent.com/7004964/188973083-d1886847-0f50-4b7c-a21d-a32c7cec5ac5.png)

Adicionar um data source influxdb

![image](https://user-images.githubusercontent.com/7004964/188973597-f5c5105b-9775-4ed9-91d6-59ced97b250f.png)

![image](https://user-images.githubusercontent.com/7004964/188973772-8944bd5f-dcaa-452f-9c07-dcae451aff34.png)

![image](https://user-images.githubusercontent.com/7004964/188974527-d255c6fe-7cf3-40d3-9b97-60d4b491faed.png)

![image](https://user-images.githubusercontent.com/7004964/188976645-705c1a62-d3dc-4451-b6cb-ade8ccf8595d.png)


