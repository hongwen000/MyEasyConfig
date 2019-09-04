#!/bin/bash
# Determine OS platform
APT=""
NPM=npm
UNAME=""
Codename=""
Release=""
RemoteBase="https://lixinrui000.cn/MyEasyConfig"
GetOSRelase()
{
	UNAME=$(uname | tr "[:upper:]" "[:lower:]")
	# If Linux, try to determine specific distribution
	if [ "$UNAME" == "linux" ]; then
	    # If available, use LSB to identify distribution
	    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
		export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
	    # Otherwise, use release info file
	    else
		export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
	    fi
	fi
	# For everything else (or if above failed), just use generic identifier
	[ "$DISTRO" == "" ] && export DISTRO=$UNAME
	unset UNAME
	if [ $DISTRO == "Ubuntu" ]
	then 
		Codename=`lsb_release -a | grep "Codename" | sed -rn "s|.*:\s*([a-z]*)|\1|p"`
		Release=`lsb_release -a | grep "Release" | sed -rn "s|.*:\s*([0-9]*).*|\1|p"`
		if [ $Codename == "" ]
		then
			echo "Can not determine ubuntu version"
			exit
		else
			echo "You are running ubuntu $Codename"
			if [ $Release -gt 14 ]
			then
				APT="apt"
			else
				APT="apt-get"
			fi
		fi
	fi
}

_JoinBy() { local IFS="$1"; shift; echo "$*"; }

_GetFile()
{
	local RemoteFilePath=${RemoteBase}/${DownloadFileName}
	if wget --spider ${RemoteFilePath} 2>/dev/null; then
		mkdir -p $(dirname ${LocalFilePath})
		wget -O ${LocalFilePath} ${RemoteFilePath}
	else
		echo "Can not retrive remote source list file ${RemoteFilePath}"
		exit
	fi
}

ConfigCNSource()
{
	local DownloadFileName=${DISTRO}_${Codename}_sources.list 
	local LocalFilePath=/etc/apt/sources.list
	_GetFile
}

ConfigPip()
{
    pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
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
		${APT}-add-repository --yes --update ppa:${name}
	done
	local SoftwareList=(
		"fasd"
		"ansible"
		"fish"
		"neovim"
	)
	name=$(_JoinBy " " "${SoftwareList[@]}")
	${APT} install ${name} -y $1
}

GetNPMSoftware()
{
	${NPM} install -g fd-find
}

GetGitSoftware()
{
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all
}


ConfigCNPM()
{
	ln -s /usr/bin/nodejs /usr/bin/node
	npm install -g n --registry=https://registry.npm.taobao.org
	n stable
	npm install -g npm@latest --registry=https://registry.npm.taobao.org
	npm install -g cnpm --registry=https://registry.npm.taobao.org
	NPM="cnpm"
}

ConfigFish()
{
	# install fisher
	curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish && fisher add znculee/fish-fasd
	local DownloadFileName=config.fish
	local LocalFilePath=~/.config/fish/config.fish
	_GetFile
	local DownloadFileName=.env.sh
	local LocalFilePath=~/.env.sh
	_GetFile
}

ConfigNvim()
{
    local NvimDataDir=~/.local/share/nvim
    local NvimPython3="python3"
    local NvimPip3="pip3"
	local DownloadFileName=init.vim
	local LocalFilePath=~/.config/nvim/init.vim
	_GetFile
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
	update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
	update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
	update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
	# install vim-plug
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	# vim +PlugInstall
    pip install neovim
    ${NvimPip3} install neovim
}

ConfigTmux()
{
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	local DownloadFileName=.tmux.conf
	local LocalFilePath=~/.tmux.conf
	_GetFile
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

GetOSRelase
ConfigNvim
