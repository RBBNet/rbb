# Script sem permissionamento
# baixa o diretório
projectname="Nome-do-projeto"
git clone https://github.com/RBBNet/start-network.git
mv start-network $projectname
cd $projectname
# cria os nós especificados.
./rbb-cli node create validator, boot, writer
# define as portas do container
./rbb-cli config set nodes.validator.ports+=[\"10070:8545\"]
./rbb-cli config set nodes.boot.ports+=[\"10071:8545\"]
./rbb-cli config set nodes.writer.ports+=[\"10072:8545\"]
# cria o genesis
./rbb-cli genesis create --validators validator
# desabilita o discovery nos nós especificados
./rbb-cli config set nodes.validator.environment.BESU_DISCOVERY_ENABLED=false
./rbb-cli config set nodes.writer.environment.BESU_DISCOVERY_ENABLED=false
# ajusta os static nodes apontando para o boot
bootkey=$(./rbb-cli config dump | grep 0x | sed -n '2 p' |sed 's/"publicKey": "0x//' | sed 's/",//')
echo "[
\"enode://$(echo $bootkey)@boot:30303\"
]" > volumes/validator/static-nodes.json
echo "[
\"enode://$(echo $bootkey)@boot:30303\"
]" > volumes/writer/static-nodes.json
./rbb-cli config render-templates
docker-compose up -d
docker-compose logs -f
