# Roteiro de configuração do ambiente Prometheus e Nginx.

## Observações 

Esse  roteiro   foi  elaborado  para  adaptar  o  Nginx  com  ajustes  de  segurança,   junto  ao  Prometheus, disponibilizado no Github da RBB. 

Testes, Configurações, Certificados  etc.  foram utilizados os seguintes softwares/ferramentas: Docker- compose, Openssl, apache2-utils e SO ubuntu Server( Caso for utilizar distribuições Linux e ferramentas diferentes, devem adaptar ao seu cenário)

Certificados dos clientes devem ser concatenados em um único arquivo .crt ou .pem
Comando para concatenar*:  *cat  cert\_dataprev.crt  cert\_bndes.crt cert\_cnpq.crt >> certificado\_client.crt* 
OU editar o arquivo *certificado\_client.crt e cola a chave publica do certificado do client* 

### Passo 1: Na pasta onde esta o prometheus, criar as pastas e arquivos: 

**/rbb-monitoracao$** 
~~~shell
sudo mkdir nginx  
cd nginx
~~~
**/rbb-monitoracao /nginx$**  
~~~shell
sudo mkdir certs logs
sudo touch nginx.conf 
cd logs
~~~
**/rbb-monitoracao /logs$**  
~~~shell
sudo touch error.log access.log
~~~

*Obs: as pastas e arquivos podem ser criadas no local de sua preferência, desde que esteja apontas no volume no docker-compose.yml*
Obter o repositório:

### Passo 2 Gerar o Certificados na pasta *certs

*cd nginx/certs* 

1. **Gerar chave privada:**
~~~shell
openssl genrsa -out chave-privada.key 4096
~~~
2. **Criar uma solicitação de assinatura de certificado (CSR):**  

alterar os campos destacados 

*openssl req -new -key chave-privada.key -out pedido.csr -subj "/C=BR/ST=Estado/L=Cidade/O=MinhaEmpresa/CN=192.168.1.10"* 

**Exemplo:** *openssl req -new -key chave-privada.key -out pedido.csr -subj "/C=BR/ST=DF/L=Brasilia/O=DATAPREV- RBB/CN=192.168.1.1"* 

*Também pode utilizar o comando sem o -subj e preencher as informações manualmente* 

3. **Gerar o certificado autoassinado:** 

**A validade do certificado fica a critério, mas recomendamos 2 anos.** 

*openssl x509 -req -days 730 -in pedido.csr -signkey chave-privada.key -out certificado.crt* 

4. **Dar permissão aos certificados e chaves** *sudo chmod 644 \**
   
### Passo 4 Configuração do Docker Compose:**

 *Link repositório com  indentação:[ https://github.com/adinaldops/Roteiro-conf-prometheus-nginx- rbb/tree/7a278661ac7e9af6ac190b330aa53e577ea0a089* ](https://github.com/adinaldops/Roteiro-conf-prometheus-nginx-rbb/tree/7a278661ac7e9af6ac190b330aa53e577ea0a089)*

   *cd /rbb-monitoracao$*  

   *sudo vim docker-compose.yml* 

Conteúdo do arquivo `docker-compose.yml` utilizado:
~~~yaml
version: '3'
   services: 
    prometheus:                # Define o serviço Prometheus 
     image: my-prometheus 
     command: --config.file=/etc/prometheus/prometheus.yml 
     volumes: 
      - ./prometheus:/etc/prometheus 
      - ./nginx/certs:/etc/prometheus/certs 
     networks:                # Define as redes em que o serviço será inserido 
      - monitoracao          # Adiciona o Prometheus à rede "monitoracao" 
      # Removendo a exposição direta da porta 9090 para evitar acesso direto 
      # ports: 
      # 9090:9090 
    nginx: 
     image: nginx:latest 
     ports: 
      -'8443:8443'          # Exposição da porta 8443 para acesso do prometheus client 
      - "443:443"            # Exposição da porta 443 para acesso WEB 
     volumes: 
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro 
      - ./nginx/certs:/etc/nginx/certs:ro            # Monta o diretório de certificados do Nginx 
      - ./nginx/logs/access.log:/var/log/nginx/access.log  # Monta o log de acesso do Nginx 
      - ./nginx/logs/error.log:/var/log/nginx/error.log    # Monta o log de erros do Nginx 
      - ./nginx/.htpasswd:/etc/nginx/.htpasswd:ro          # Monta o arquivo de autenticação básica como somente leitura 
     networks: 
      - monitoracao 
  networks: 
   monitoracao:               # Declara a rede "monitoracao" para comunicação interna entre os serviços 
~~~

### Passo 6: Configuração do prometheus.yml:

**Adicionar:** scheme: https, tls\_config e remover o basic auth** 

Caso for adicionar as configurações no mesmo servidor da rede LAB, deve adicionar  um novo job, ex: *job\_name: rbb-federado2,* e manter a configuração atual até que todos os Participes esteja UP, e voltar ao passo anterior e expor a porta 9090. Caso contrário, adicionar as configurações ate a linha 37 

*Link repositório com  indentação:[ https://github.com/adinaldops/Roteiro-conf-prometheus-nginx- rbb/tree/7a278661ac7e9af6ac190b330aa53e577ea0a089* ](https://github.com/adinaldops/Roteiro-conf-prometheus-nginx-rbb/tree/7a278661ac7e9af6ac190b330aa53e577ea0a089)*

*sudo vim prometheus/prometheus.yml*

~~~yaml
*global:* 

`  `*scrape\_interval: 15s* 

`  `*evaluation\_interval: 15s* 

- *Rule files specifies a list of globs. Rules and alerts are read from* 
- *all matching files.* 

  *rule\_files:* 

- */etc/prometheus/rules.yml* 
- *rules/\*.yml* 

*scrape\_configs:* 

- *Job para coletar as métricas de outras organizações.* 
- *Inclua aqui os alvos das outras organizações (Prometheus expostos).* 
- *job\_name: rbb-federado2* 

`    `*honor\_labels: false* 

`    `*metrics\_path: '/federate'* 

`    `*scheme: https* 

`    `*tls\_config:                                          # Configurações de TLS para comunicação segura       cert\_file: /etc/prometheus/certs/certificado.crt   # Caminho para o certificado* 

`      `*key\_file: /etc/prometheus/certs/chave-privada.key  # Caminho para a chave privada* 

`      `*insecure\_skip\_verify: true                         # Ignora a verificação do certificado* 

`    `*params:* 

`      `*'match[]':* 

- *'{job="rbb"}'* 

`    `*static\_configs:* 

- *targets: [ '200.178.27.8:8443']       # Prometheus DILI* 

`        `*labels:* 

`          `*organization: 'DILI'* 

- *targets: [ '34.95.98.2:8443' ]       # Prometheus CPqD* 

`        `*labels:* 

`          `*organization: 'CPqD'* 

`    `*metric\_relabel\_configs:* 

- *source\_labels: ["exported\_instance"]* 

`      `*target\_label: "instance"* 

- *source\_labels: ["exported\_organization"]* 

`      `*target\_label: "organization"* 

- *action: "labeldrop"* 

`      `*regex: "^exported\_.\*"* 

- *Job para coletar as métricas de outras organizações.* 
- *Inclua aqui os alvos das outras organizações (Prometheus expostos).* 
- *job\_name: rbb-federado* 

`    `*honor\_labels: false* 

`    `*metrics\_path: '/federate'* 

`    `*basic\_auth:* 

`      `*username: 'admin'* 

`      `*password: '@#$%prometheus'                # aqui pode ser usado <password\_file>* 

`    `*params:* 

`      `*'match[]':* 

- *'{job="rbb"}'* 

`    `*static\_configs:* 

- *targets: [ '34.9.21.17:9090' ]  # Prometheus CPqD* 

`        `*labels:* 

`          `*organization: 'CPqD'* 

- *targets: [ '280.523.19.18:9090']        # Prometheus BNDES* 

`        `*labels:* 

`          `*organization: 'BNDES'*    
~~~

### Passo 7: Configuração do Nginx (nginx.conf)

Adaptar as configurações para seu cenário, como fingerprint, server\_name, as linhas SSL O fingerprint a ser configurado, deve ser o do certificado do client 

Exemplo:  *openssl x509 -noout -fingerprint -in certificadoBNDES.crt | sed 's/://g' | awk -F= '{print $2}'* Resultado*: 67A9334D6E24D6B0C0E5AC9A9ED1C46C9ADDC6CB* 

*Link repositório com  indentação:[ https://github.com/adinaldops/Roteiro-conf-prometheus-nginx- rbb/tree/7a278661ac7e9af6ac190b330aa53e577ea0a089* ](https://github.com/adinaldops/Roteiro-conf-prometheus-nginx-rbb/tree/7a278661ac7e9af6ac190b330aa53e577ea0a089)*

*/rbb-monitoracao$  
sudo vim nginx.conf* 

~~~shell
*http {* 

`    `*#Mapa para verificar fingerprints* 

`    `*map\_hash\_bucket\_size 128;                         # Define o tamanho do bucket para a estrutura map* 

`    `*map $ssl\_client\_fingerprint $valid\_fingerprint {  # Mapeia fingerprints de clientes para verificação* 

`        `*default 0;                                    # Valor padrão 0 (não autorizado)* 

`        `*"C630DDA093F857752A7ABDDA386916DE727F582F" 1; # Fingerprint Certificado DATAPREV         "662BD214203168E90637B728A92611F152FF9C08" 1; # Fingerprint Certificado BNDES* 

`        `*"2573C939EAA2E3CDE8A8216A4B93F8B70540941B" 1; # Fingerprint Certificado ...* 

`    `*}* 

- *Bloco de servidor para a interface web (sem mTLS, com autenticação básica)* 

`    `*server {* 

`        `*listen 443 ssl;                                   # Escuta na porta 443 (HTTPS)* 

`        `*server\_name 192.168.35.101;                       # Nome do servidor/IP* 

`        `*ssl\_protocols TLSv1.2 TLSv1.3;                    # Define os protocolos TLS permitidos* 

`        `*ssl\_certificate /etc/nginx/certs/bserver.crt;     # Caminho do certificado do servidor* 

`        `*ssl\_certificate\_key /etc/nginx/certs/bserver.key; # Caminho da chave do certificado do servidor* 

`        `*location / {                                                     # Bloco de localização para a interface web do Prometheus             proxy\_pass http://prometheus:9090/;                          # Proxy para o Prometheus na porta 9090* 

`            `*proxy\_redirect off;                                          # Desativa redirecionamento de proxy* 

`            `*proxy\_set\_header Host $host;                                 # Define cabeçalho Host* 

`            `*proxy\_set\_header X-Real-IP $remote\_addr;                     # Define cabeçalho X-Real-IP* 

`            `*proxy\_set\_header X-Forwarded-For $proxy\_add\_x\_forwarded\_for; # Define cabeçalho X-Forwarded-For* 

`            `*proxy\_set\_header X-Forwarded-Proto $scheme;                  # Define cabeçalho X-Forwarded-Proto* 

- *Headers de segurança* 

`            `*add\_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always; # Ativa HSTS* 

`            `*add\_header X-Content-Type-Options "nosniff" always;                                # Evita sniffing de tipo de conteúdo* 

`            `*add\_header X-Frame-Options "DENY" always;                                          # Bloqueia frames para prevenção de clickjacking* 

- *Autenticação básica para a interface web* 

`            `*auth\_basic "Restricted Access";            # Título para autenticação básica* 

`            `*auth\_basic\_user\_file /etc/nginx/.htpasswd; # Caminho do arquivo de autenticação* 

`        `*}* 

`    `*}* 

- *Bloco de servidor para scraping de métricas com mTLS* 

`    `*server {* 

`        `*listen 8443 ssl;* 

`        `*server\_name 192.168.35.101;* 

`        `*ssl\_protocols TLSv1.2 TLSv1.3;* 

`        `*ssl\_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384'; # Define os algoritmos de cifra* 

`        `*ssl\_prefer\_server\_ciphers on;                                            # Prefere os cifradores do servidor* 

`        `*ssl\_certificate /etc/nginx/certs/certificado.crt;                        # Caminho do certificado do servidor* 

`        `*ssl\_certificate\_key /etc/nginx/certs/chave-privada.key;                  # Caminho da chave do certificado do servidor* 

`        `*ssl\_client\_certificate /etc/nginx/certs/client.crt;                      # Caminho do certificado da CA cliente* 

`        `*ssl\_verify\_client on;                                                    # Ativa mTLS (mutual TLS)* 

`        `*#ssl\_verify\_depth 5;                                                     # Define a profundidade de verificação de certificadosa* 

- *Verificação do fingerprint* 

`        `*if ($valid\_fingerprint = 0) { # Condicional para verificar a validade do fingerprint do cliente* 

`            `*return 403;               # Retorna 403 se o fingerprint não for válido* 

`        `*}* 

- *Bloco de localização para o endpoint de scraping* 

`        `*location /federate {* 

`            `*proxy\_pass http://prometheus:9090/federate;* 

`            `*proxy\_set\_header Host $host;* 

`            `*proxy\_set\_header X-Real-IP $remote\_addr;* 

`            `*proxy\_set\_header X-Forwarded-For $proxy\_add\_x\_forwarded\_for;* 

`            `*proxy\_set\_header X-Forwarded-Proto $scheme;* 

- *Headers de segurança* 

`            `*add\_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;* 

`            `*add\_header X-Content-Type-Options "nosniff" always;* 

`            `*add\_header X-Frame-Options "DENY" always;* 

- *Sem autenticação básica para permitir o scraping de métricas (autenticação é autorizada via certificado)* 

`        `*}* 

`    `*}* 

*}* 

*events {}* 
~~~

### Passo 8: Criando o Arquivo .htpasswd, com as credenciais de usuário e senha para autenticação básica web:

*rbb-monitoracao$* 

*sudo apt install apache2-utils* 

*sudo htpasswd -c nginx/.htpasswd admin* 

Substitua admin pelo nome de usuário desejado. O Nginx utilizará esse arquivo para validar os acessos com 

autenticação básica.

## Conclusão

Após configurar os arquivos, suba os containers com o comando: 

*sudo docker-compose down # remover contêineres* 

*sudo docker-compose up -d # iniciar os contêineres definidos no arquivo docker-compose.yml sudo docker ps # Verificar  os  contêineres*  

*sudo docker-compose logs # caso de erro verifique os logs do Nginx e Prometheus* .

