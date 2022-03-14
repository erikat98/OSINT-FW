#!/usr/bin/env bash
set -e
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

OS_ID='unknown'
OS_VERSION_ID='unknown'
SUPPORTED='false'


function check_docker_dependencies (){
    echo "Checking if docker docker-compose are installed"
    set +e
    DOCKER="$(command -v docker)"
    DOCKER_COMPOSE="$(command -v docker-compose)"
    set -e
    if [ ! -z "${DOCKER}" ] &&  [ ! -z "${DOCKER_COMPOSE}" ] ; then
        echo "Commands docker and docker-compose detect."
        echo "Skipping Dependency Installation."
        exit 0
    fi
}

function install_centos (){
    echo "CentOS 7.x/8.x Install"
    echo "Installing Base CentOS Packages"

    NO_BEST=""
    if [ "${1}" == '"8"' ] ; then
        NO_BEST="--nobest"
    fi

    yum install -y yum-utils \
        device-mapper-persistent-data \
        lvm2 \
        lsof

    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo

    echo "Installing Docker-CE"
    yum install -y docker-ce $NO_BEST
    systemctl start docker

    if [ ! -f /usr/local/bin/docker-compose ]; then
        echo "Installing Docker Compose"
        curl -L https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m) -o /bin/docker-compose
        chmod +x /bin/docker-compose
    fi
}


function install_ubuntu (){
    echo "Ubuntu 16.04/18.04/20.04 Install"
    echo "Installing Base Ubuntu Packages"
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common

    if dpkg -s docker-ce | grep Status: | grep installed ; then
      echo "Docker Installed"
    else
      echo "Installing Docker-CE"

      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      apt-get update
      apt-get -y install docker-ce
    fi

    if [ ! -f /usr/local/bin/docker-compose ]; then
        echo "Installing Docker Compose"
        curl -L https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
}

function install_debian (){
    echo "Debian 9.x/10.x Install"
    echo "Installing Base Debian Packages"
    apt-get update
    sudo apt-get install -y \
         apt-transport-https \
         ca-certificates \
         curl \
         gnupg2 \
         software-properties-common

    if dpkg -s docker-ce | grep Status: | grep installed ; then
      echo "Docker Installed"
    else
      echo "Installing Docker-CE"

      curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
      add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
      apt-get update
      apt-get -y install docker-ce
    fi

    if [ ! -f /usr/local/bin/docker-compose ]; then
        echo "Installing Docker Compose"
        curl -L https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi

}

check_docker_dependencies

if [ -f /etc/os-release ] ; then
    OS_ID="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
    OS_VERSION_ID="$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release)"
fi

if [ "${OS_ID}" == "ubuntu" ] && ( [ "${OS_VERSION_ID}" == '"16.04"' ] || [ "${OS_VERSION_ID}" == '"18.04"' ] || [ "${OS_VERSION_ID}" == '"20.04"' ]) ; then
   SUPPORTED='true'
   install_ubuntu
fi

if [ "${OS_ID}" == "debian" ] && ( [ "${OS_VERSION_ID}" == '"9"' ] || [ "${OS_VERSION_ID}" == '"10"' ] ) ; then
   SUPPORTED='true'
   install_debian
fi

if [ "${OS_ID}" == '"centos"' ] && ( [ "${OS_VERSION_ID}" == '"7"' ] || [ "${OS_VERSION_ID}" == '"8"' ] ) ; then
   SUPPORTED='true'
   install_centos ${OS_VERSION_ID}
fi

if [ "${SUPPORTED}" == "false" ] ; then
   echo "Installation Not Supported for this Operating System. Exiting"
   exit -1
fi

echo "Dependency Installation Complete"
