#!/bin/bash

apt update && apt install ruby-full && gem install lolcat
cat << 'EOF' | lolcat -a -s 100 -F 0.023 -S 130
 ____    ____    ____
/\  _`\ /\  _`\ /\  _`\
\ \ \L\ \ \ \L\ \ \ \L\ \
 \ \ ,  /\ \  _ <\ \  _ <'
  \ \ \\ \\ \ \L\ \ \ \L\ \
   \ \_\ \_\ \____/\ \____/
 ______/\__/\/___/  \/___/
/\  __`\/\ \
\ \ \/\ \ \ \____   ____    __  _ __  __  __    __  _ __
 \ \ \ \ \ \ '__`\ /',__\ /'__`/\`'__/\ \/\ \ /'__`/\`'__\
  \ \ \_\ \ \ \L\ /\__, `/\  __\ \ \/\ \ \_/ /\  __\ \ \/
   \ \_____\ \_,__\/\____\ \____\ \_\ \ \___/\ \____\ \_\
    \/_____/\/___/ \/___/ \/____/\/_/  \/__/  \/____/\/_/

EOF




#curl -sL https://github.com/RBBNet/start-network/releases/download/v0.4.1%2Bpermv1/start-network.tar.gz | tar xz
#cd start-network
#./rbb-cli node create observer
#./rbb-cli config set nodes.observer.ports+=[\"8545:8545\"]
#./rbb-cli config set nodes.observer.address=\"<IP-Externo-observer>:30303\"