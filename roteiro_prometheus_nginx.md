# Roteiro de configuração do nó de monitoração Prometheus com MTLs e Nginx.

## Observações 
Foram utilizados os seguintes softwares/ferramentas: Docker- compose, Openssl, apache2-utils e SO Ubuntu Server( Caso for utilizar distribuições Linux e ferramentas diferentes, deve adaptar ao seu ambiente)

### Passo 1. Baixar o repositorio rbb-monitoracao no (https://github.com/RBBNet/rbb-monitoracao): 
~~~~
git clone https://github.com/RBBNet/rbb-monitoracao
~~~~
### Passo 2. Gerar o Certificados:
~~~~
cd rbb-monitoracao/nginx/certs/
~~~~
#### 2.1. Gerar chave privada:
~~~shell
openssl genrsa -out chave-privada.key 4096
~~~
#### 2.2. **Criar uma solicitação de assinatura de certificado (CSR):**  

Alterar os campos conforme seu ambiente: C=país, ST=estado, L=cidade, O=Oraganização, CN=IP do seu Servidor 

**Exemplo:** 
~~~~
openssl req -new -key chave-privada.key -out pedido.csr -subj "/C=BR/ST=DF/L=Brasilia/O=DATAPREV- RBB/CN=192.168.x.x"
~~~~
* Ou pode utilizar o comando sem o -subj e preencher as informações manualmente* 
~~~~
openssl req -new -key chave-privada.key -out pedido.csr
~~~~
#### 2.3. **Gerar o certificado autoassinado:** 

**A validade do certificado fica a critério, mas recomendamos 2 anos.** 
~~~~
openssl x509 -req -days 730 -in pedido.csr -signkey chave-privada.key -out certificado.pem
~~~~

### Passo 3 Faça o Downloads ou copie o conteudo dos certificados das Organizações disponivel no (https://github.com/RBBNet/participantes/tree/main/lab/certificados)

#### 3.1. caso  for copiar o conteúdo dos certificados, deve criar o arquivo client.crt e colar o conteúdo dos certificados dentro do arquivo, um abaixo do outro, conforme o exemplo abaixo
~~~~
touch client.pem
~~~~
~~~~
vim client.pem
~~~~
*Exemplo*
~~~~
root@prometheus:/home/dili/rbb-monitoracao/nginx/certs# cat client.pem

-----BEGIN CERTIFICATE-----
MIIFNzCCAx8CFE1T0oAdwo5kgb+edmgRA6Fu+35SMA0GCSqGSIb3DQEBCwUAMFgx
CzAJBgNVBAYTAkJSMQswCQYDVQQIDAJERjERMA8GA1UEBwwIQnJhc2lsaWExEDAO
BgNVBAoMB0RUUC1SQkIxFzAVBgNVBAMMDjE5Mi4xNjguMzUuMTAxMB4XDTI1MDYy
NzEyNDkxNloXDTI3MDYyNzEyNDkxNlowWDELMAkGA1UEBhMCQlIxCzAJBgNVBAgM
AkRGMREwDwYDVQQHDAhCcmFzaWxpYTEQMA4GA1UECgwHRFRQLVJCQjEXMBUGA1UE
AwwOMTkyLjE2OC4zNS4xMDEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
AQDQvT+3XcFhd7KWo+9eteMFPn1Gdf6gIrCK6LIcPtlXgeY7Xv6TcpKOwYVGc2Kv
jL5wfHekqzomS+kQb6QNWWCPGfTBYauN8mxRTTHMYxDW+sHe5Ab+sCIv53LShEcU
bsH9cmvcVfx6LZ4OKDUb3wbwRUxl3kjGqWLEI+KUV6YoRGB5vhlNtpY3qbf+rKlB
iV1bNTZutjDRYRGQsqG7fGpTNcJ0A5exPO6p4Q0GudVgNheGRqDjNBA21Vb9R+ld
snH+WvmD1rJWHtQwZ15VOGepO5rQxNojjEkrYEA41r8Y5VNFL+2odcE5xTPVY+rb
VBKFhzm4FMlFqG2rCoAm36o9oT/objq937AmAxhNcb6TbYyOSZsPQrZJ/EIuMMGS
kHzvVwIuvV4UX4VBQgfVvQN2xDOAcucG0vMQLzsrytkyPIkihLUfYj5QtdLUqmjj
ksyN0nYpB7TvFVYFoiQj/98zDd0TEdZsVUlswyJj3iuTRbEyUHsddwO+98oTJ4pt
Y93gBo2mYw3st0wfjFmwoS3y8U+FcTSJVHAq6vIER6ecXbYPzRAbG2rEcpzB1h35
rUmTIUg69uzMIa5aycONjj7TjJzskloOYXmuX00MEW8YS6DBaW8HK858bMmJWKad
qd/esKLCxwrQVct2z94sXFj9R53khIh9YguyA4UxLEKDNwIDAQABMA0GCSqGSIb3
DQEBCwUAA4ICAQCfGY/xB+EThkF1ptLE+wQ676IbSVx3/8qZOJrc/NNyAav504kL
wGKDJrxSILwEJ0p/buS5ttI5u/+DGKC45fCNk/gSQRU3B3yXR4zYjwf0WxNWjiiF
YWI+6bTPOWp2UqJY1fMGz6rlTGK2PyHK02I816scwg64cbk7BTtp8tI1uXR0owOD
zwy4cGw9/vq+AtTlIiuUC+nc4N2g/bqRbhK1MbfgOksJDOvBrpBO6F64j49DMpPX
8ccAHRVmVAn3vFsE/PUisSOdvqRQKIPzQZLtwyurAJV5IXZ3+ggfUvVfJcFrYzzq
/C/+6+yrJSNhCRTUcvvvuQvYvCn2yijWY/MRJ6N/tpAUeNKJI98yBDUVU1uykUjY
PZiqfOrCm0lKW0nyme91ZrHjrA+EyDkAnHodN8S7EUXETItBNUBTobiz8ikZrNSC
RRYKp3TA87XhPwqaj5RX1+LNppCMdOAGkZ0bDh0h7YpD5OFkpgrKrvHWer4I0fm0
Y5nqWHDl9aXesbvWYcDHp59UbUXcR3jVf4RP3zhDNmMxvIZTPQTzCPkMibVDuOCz
pkEavNSH9MDIRwo0hoyftVsE/sLgBCZ2ghL6P92DTp/o83BmuqiHw/h+Z066eahQ
P2IfyAvB4qGa8u8ik92V5yokxnba0OgTkflLBAsu7e2hoMycW10nueyTDh==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
BIIFNzCCAx8CFE1T0oAdwo5kgb+edmgRA6Fu+35SMA0GCSqGSIb3DQEBCwUAMFgx
CzAJBgNVBAYTAkJSMQswCQYDVQQIDAJERjERMA8GA1UEBwwIQnJhc2lsaWExEDAO
BgNVBAoMB0RUUC1SQkIxFzAVBgNVBAMMDjE5Mi4xNjguMzUuMTAxMB4XDTI1MDYy
NzEyNDkxNloXDTI3MDYyNzEyNDkxNlowWDELMAkGA1UEBhMCQlIxCzAJBgNVBAgM
AkRGMREwDwYDVQQHDAhCcmFzaWxpYTEQMA4GA1UECgwHRFRQLVJCQjEXMBUGA1UE
AwwOMTkyLjE2OC4zNS4xMDEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
AQDQvT+3XcFhd7KWo+9eteMFPn1Gdf6gIrCK6LIcPtlXgeY7Xv6TcpKOwYVGc2Kv
jL5wfHekqzomS+kQb6QNWWCPGfTBYauN8mxRTTHMYxDW+sHe5Ab+sCIv53LShEcU
bsH9cmvcVfx6LZ4OKDUb3wbwRUxl3kjGqWLEI+KUV6YoRGB5vhlNtpY3qbf+rKlB
iV1bNTZutjDRYRGQsqG7fGpTNcJ0A5exPO6p4Q0GudVgNheGRqDjNBA21Vb9R+ld
snH+WvmD1rJWHtQwZ15VOGepO5rQxNojjEkrYEA41r8Y5VNFL+2odcE5xTPVY+rb
VBKFhzm4FMlFqG2rCoAm36o9oT/objq937AmAxhNcb6TbYyOSZsPQrZJ/EIuMMGS
kHzvVwIuvV4UX4VBQgfVvQN2xDOAcucG0vMQLzsrytkyPIkihLUfYj5QtdLUqmjj
ksyN0nYpB7TvFVYFoiQj/98zDd0TEdZsVUlswyJj3iuTRbEyUHsddwO+98oTJ4pt
Y93gBo2mYw3st0wfjFmwoS3y8U+FcTSJVHAq6vIER6ecXbYPzRAbG2rEcpzB1h35
rUmTIUg69uzMIa5aycONjj7TjJzskloOYXmuX00MEW8YS6DBaW8HK858bMmJWKad
qd/esKLCxwrQVct2z94sXFj9R53khIh9YguyA4UxLEKDNwIDAQABMA0GCSqGSIb3
DQEBCwUAA4ICAQCfGY/xB+EThkF1ptLE+wQ676IbSVx3/8qZOJrc/NNyAav504kL
wGKDJrxSILwEJ0p/buS5ttI5u/+DGKC45fCNk/gSQRU3B3yXR4zYjwf0WxNWjiiF
YWI+6bTPOWp2UqJY1fMGz6rlTGK2PyHK02I816scwg64cbk7BTtp8tI1uXR0owOD
zwy4cGw9/vq+AtTlIiuUC+nc4N2g/bqRbhK1MbfgOksJDOvBrpBO6F64j49DMpPX
8ccAHRVmVAn3vFsE/PUisSOdvqRQKIPzQZLtwyurAJV5IXZ3+ggfUvVfJcFrYzzq
/C/+6+yrJSNhCRTUcvvvuQvYvCn2yijWY/MRJ6N/tpAUeNKJI98yBDUVU1uykUjY
PZiqfOrCm0lKW0nyme91ZrHjrA+EyDkAnHodN8S7EUXETItBNUBTobiz8ikZrNSC
RRYKp3TA87XhPwqaj5RX1+LNppCMdOAGkZ0bDh0h7YpD5OFkpgrKrvHWer4I0fm0
Y5nqWHDl9aXesbvWYcDHp59UbUXcR3jVf4RP3zhDNmMxvIZTPQTzCPkMibVDuOCz
pkEavNSH9MDIRwo0hoyftVsE/sLgBCZ2ghL6P92DTp/o83BmuqiHw/h+Z066eahQ
P2IfyAvB4qGa8u8ik92V5yokxnba0OgTkflLBAsu7e2hoMycW10nueyTDg==
-----END CERTIFICATE-----

root@prometheus:/home/dili/rbb-monitoracao/nginx/certs#
~~~~
#### 3.2. caso faça o Download dos certificados, deve concatenar todos em um unico arquivo client.crt

**Exemplo**
~~~~
cat  cert_dataprev.pem  cert_bndes.pem cert_cnpq.pem >> client.pem
~~~~
#### 3.3. Dar permissão aos certificados e chave
~~~~
sudo chmod 644 *
~~~~
### Passo 4. Configuração do arquivo Docker Compose.
**LEIA os comentários no arquivo docker-compose.yml, caso for necessario adapta para seu ambiente.**

*No diretorio rbb-monitoracao*

~~~~
sudo vim docker-compose.yml
~~~~ 

### Passo 5. Configuração do prometheus.yml:
**LEIA os comentários no arquivo prometheus.yml e adapta para seu ambiente.**
~~~~
cd prometheus/
~~~~
~~~~
sudo vim prometheus.yml
~~~~

### Passo 6. Configuração do nginx.conf:
**LEIA os comentários no arquivo nginx.conf e adapta para seu ambiente.**
~~~~
cd ..
~~~~
~~~~
cd nginx/
~~~~
~~~~
sudo vim nginx.conf
~~~~

### Passo 7. Criar o Arquivo .htpasswd, com as credenciais usuário e senha para autenticação web:
~~~~
cd ..
~~~~
*No diretorio rbb-monitoracao$*
~~~~
sudo apt install apache2-utils 
~~~~
~~~~
sudo htpasswd -c nginx/.htpasswd admin
~~~~
Substitua admin pelo nome de usuário desejado.

### Conclusão

Após configurar os arquivos, suba os containers 
~~~~
sudo docker-compose up -d
~~~~
~~~~
sudo docker ps # Verificar se os containers subiu
~~~~
~~~~
sudo docker-compose logs #caso de erro, verifique os logs do Nginx e Prometheus* .
~~~~

Se os containers estiverem OK, acesse a interface web do Prometheus (exemplo: https://192.168.x.x/)  verifique o estado dos alvos (menu *Status -> Targets*), bem como algumas métricas (ex: no menu *Graph*, digite como expressão `ethereum_blockchain_height`). Disponibilize seu certificado no repositório Git:https://github.com/RBBNet/participantes/tree/main/lab/certificados
Em seguida, avise as organizações participantes para que configurem o seu certificado nos respectivos Prometheus. Conforme cada participante for configurando corretamente, o status deverá aparecer como UP, como mostrado na imagem abaixo. Além disso, o seu Prometheus deverá ser capaz de coletar as métricas dos demais.

![image](https://github.com/user-attachments/assets/2d0bd820-681a-4525-9ed6-5e58485f113b)

