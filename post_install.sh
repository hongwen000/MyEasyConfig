#!/bin/bash
# Determine OS platform
APT="sudo apt"
NPM=npm
UNAME=""
Codename=""
Release=""
RemoteBase="https://lixinrui000.cn/MyEasyConfig"
ProxyUrl="$1"
GetOSRelase()
{
	UNAME=$(uname | tr "[:upper:]" "[:lower:]")
	# If Linux, try to determine specific distribution
	if [ "$UNAME" == "linux" ]; then
	    # If available, use LSB to identify distribution
	    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ] || [ -f /var/lib/dpkg/info/lsb-release.list ]; then
		export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
	    # Otherwise, use release info file
	    else
		export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
	    fi
	fi
	# For everything else (or if above failed), just use generic identifier
	[ "$DISTRO" == "" ] && export DISTRO=$UNAME
	unset UNAME
	if [ "$DISTRO" == "Ubuntu" ]
	then 
		Codename=`lsb_release -a | grep "Codename" | sed -rn "s|.*:\s*([a-z]*)|\1|p"`
		Release=`lsb_release -a | grep "Release" | sed -rn "s|.*:\s*([0-9]*).*|\1|p"`
		if [ "$Codename" == "" ]
		then
			echo "Can not determine ubuntu version"
			exit
		else
			echo "You are running ubuntu $Codename"
			if [ $Release -lt 16 ]
			then
				APT="sudo apt-get"
			fi
		fi
	elif [ "$DISTRO" == "Debian" ]
	then
		Codename=`lsb_release -a | grep "Codename" | sed -rn "s|.*:\s*([a-z]*)|\1|p"`
		Release=`lsb_release -a | grep "Release" | sed -rn "s|.*:\s*([0-9]*).*|\1|p"`
	else
		echo "Not supported OS ${DISTRO}"
		exit
	fi
}

_JoinBy() { local IFS="$1"; shift; echo "$*"; }

_ProxyEnv() 
{
    local ProxyCmd="export http_proxy='"${ProxyUrl}"';export https_proxy='"${ProxyUrl}"';"
    echo $*
    eval "$ProxyCmd $*"
    export http_proxy=""
    export https_proxy=""
}

_ProxyApt()
{
    eval "${APT} -o Acquire::http::proxy='"${ProxyUrl}"' -o Acquire::https::proxy='"${ProxyUrl}"' $*"
}


_AddPpaIfNotExist()
{
    local AptSourceDir="/etc/apt/sources.list.d"
    local PpaFileName1="$(echo $1 | cut -d'/' -f 1)"
    local PpaFileName2="$(echo $1 | cut -d'/' -f 2)"
    local PpaFileName=${PpaFileName1}"-"${DISTRO}"-"$PpaFileName2-"${Codename}"".list"
    echo $PpaFileName
    if [[ $(ls ${AptSourceDir} | grep -i ${PpaFileName}) == "" ]]; then 
		${APT}-add-repository --yes ppa:$1
    fi;
}

_GetFile()
{
	local DownloadFileName=$1
	local LocalFilePath=$2
	local UseSudo=$3
	local RemoteFilePath=${RemoteBase}/${DownloadFileName}
	if wget --spider ${RemoteFilePath} 2>/dev/null; then
		if [[ ${UseSudo} == "yes" ]]; then
			sudo mkdir -p $(dirname ${LocalFilePath})
			sudo wget -O ${LocalFilePath} ${RemoteFilePath}
		else
			mkdir -p $(dirname ${LocalFilePath})
			wget -O ${LocalFilePath} ${RemoteFilePath}
		fi

	else
		echo "Can not retrive remote source list file ${RemoteFilePath}"
		exit
	fi
}

ConfigCNSource()
{
	local LocalSourceList=/etc/apt/sources.list
	if [ "$(cat $LocalSourceList | grep 'tencentyun')" == "" ] ; then
		_GetFile ${DISTRO}_${Codename}_sources.list $LocalSourceList yes
	fi
}

ConfigPip()
{
    pip2 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip2 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
}

GetAptSoftware()
{
	local SoftwareList=(
		#Compilers
		"make"
		"gcc"
		"g++"
		"python"
		"python3"
		"python-pip"
		"python3-pip"
		"python-dev"
		"python3-dev"
		"openjdk-8-jdk"
		"npm"
		#utilities
		"git"
		"tmux"
		"silversearcher-ag"
	)
	name=$(_JoinBy " " "${SoftwareList[@]}")
	${APT} install ${name} -y
}

GetPPASoftware()
{
	${APT} install software-properties-common -y
	local PPAList=(
		"fish-shell/release-3"
		"aacebedo/fasd"
		"ansible/ansible"
		"neovim-ppa/stable"
	)
	for name in ${PPAList[@]}; do
        _AddPpaIfNotExist $name
	done
	local SoftwareList=(
		"fasd"
		"ansible"
		"fish"
		"neovim"
	)
	name=$(_JoinBy " " "${SoftwareList[@]}")
	echo $1
	_ProxyApt install ${name} -y
}

GetNPMSoftware()
{
	sudo ${NPM} install -g fd-find
}

GetGitSoftware()
{
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all
}


ConfigCNPM()
{
	ln -s /usr/bin/nodejs /usr/bin/node
	sudo npm install -g n --registry=https://registry.npm.taobao.org
	_ProxyEnv sudo n stable
	sudo npm install -g npm@latest --registry=https://registry.npm.taobao.org
	sudo npm install -g cnpm --registry=https://registry.npm.taobao.org
	NPM="cnpm"
}

ConfigFish()
{
	# install fisher
	curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish && fisher add znculee/fish-fasd
	_GetFile config.fish ~/.config/fish/config.fish 
	_GetFile .env.sh ~/.env.sh
}

ConfigNvim()
{
    local NvimDataDir=~/.local/share/nvim
    local NvimPython3="python3"
    local NvimPip3="pip3"
	_GetFile init.vim ~/.config/nvim/init.vim
    local NvimConfigFile=${LocalFilePath}
    if [ $DISTRO == "Ubuntu" ] && [ $Release -lt 18 ] ; then
        local MINICONDA_PYTHON_3_6_ADDRESS="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-4.5.4-Linux-x86_64.sh"
        local MINICONDA_INSTALL_FILE_LOCATION=/tmp/miniconda.sh 
        if [ ! -f ${MINICONDA_INSTALL_FILE_LOCATION} ] ; then
            wget -O ${MINICONDA_INSTALL_FILE_LOCATION} ${MINICONDA_PYTHON_3_6_ADDRESS} && chmod +x ${MINICONDA_INSTALL_FILE_LOCATION} && ${MINICONDA_INSTALL_FILE_LOCATION} -b -f -p ${NvimDataDir}/conda
        fi
        local NvimPython3="${NvimDataDir}/conda/bin/python3.6"
        local NvimPip3="${NvimDataDir}/conda/bin/pip"
        echo 'let g:python3_host_prog ="'${NvimPython3}'"' >> ${NvimConfigFile}
        ${NvimPip3} install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
        ${NvimPip3} config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
    fi
	sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
	sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
	sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
	# install vim-plug
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	# vim +PlugInstall
    pip2 install neovim
    ${NvimPip3} install neovim
}

ConfigTmux()
{
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	_GetFile .tmux.conf ~/.tmux.conf
	# Hit prefix + I to fetch the plugin and source it
}

function GetSoftware
{
	ConfigCNSource
	GetAptSoftware
	GetPPASoftware
	GetGitSoftware
	ConfigCNPM
	GetNPMSoftware
}

function ConfigUtilities
{
	ConfigNvim
	ConfigFish
	ConfigTmux
}

function main
{
	GetOSRelase
	${APT} install wget -y
	GetSoftware
	ConfigUtilities
}

main
