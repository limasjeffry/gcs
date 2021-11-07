#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
stty erase ^H

#sh_ver='1.4.2'
#github='https://raw.githubusercontent.com/AmuyangA/public/master'
#new_ver=$(curl -s "${github}"/gcs/gcs.sh|grep 'sh_ver='|head -1|awk -F '=' '{print $2}'|sed $'s/\'//g')
#if [[ $sh_ver != "${new_ver}" ]]; then
#	wget -qO gcs.sh ${github}/gcs/gcs.sh
#	exec ./gcs.sh
#fi

green_font(){
	echo -e "\033[32m\033[01m$1\033[0m\033[37m\033[01m$2\033[0m"
}
red_font(){
	echo -e "\033[31m\033[01m$1\033[0m"
}
white_font(){
	echo -e "\033[37m\033[01m$1\033[0m"
}
yello_font(){
	echo -e "\033[33m\033[01m$1\033[0m"
}
Info=`green_font [信息]` && Error=`red_font [错误]` && Tip=`yello_font [注意]`
[ $(id -u) != '0' ] && { echo -e "${Error}您必须以root用户运行此脚本！\n${Info}使用$(red_font 'sudo su')命令切换到root用户！"; exit 1; }

sed -i "s#root:/root#root:$(pwd)#g" /etc/passwd

if [[ -f /etc/redhat-release ]]; then
	release="centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
	release="debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
	release="ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
	release="centos"
elif cat /proc/version | grep -q -E -i "debian"; then
	release="debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
	release="ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
	release="centos"
fi
if [[ ${release} == 'centos' ]]; then
	PM='yum'
else
	PM='apt'
fi

ssh_port=$(hostname -f|awk -F '-' '{print $2}')
HOSTNAME="$(hostname -f|awk -F "${ssh_port}-" '{print $2}').cloudshell.dev"
ip_path="$(pwd)/ipadd"
IP=$(curl -s ipinfo.io/ip)
[ -z ${IP} ] && IP=$(curl -s http://api.ipify.org)
[ -z ${IP} ] && IP=$(curl -s ipv4.icanhazip.com)
[ -z ${IP} ] && IP=$(curl -s ipv6.icanhazip.com)

num='y'
if [[ -e $ip_path ]]; then
	pw=$(cat ${ip_path}|sed -n '2p')
	clear
	echo -e "\n${Info}The original password is ：$(red_font ${pw})"
	read -p "Do you want to update the password? [y/n] (default: n) ：" num
	[ -z $num ] && num='n'
fi
echo $IP > $(pwd)/ipadd

if [[ $num == 'y' ]]; then
	pw=$(tr -dc 'A-Za-z0-9!@#$%^&*()[]{}+=_,' </dev/urandom |head -c 17)
fi
echo root:${pw} |chpasswd
sed -i '1,/PermitRootLogin/{s/.*PermitRootLogin.*/PermitRootLogin yes/}' /etc/ssh/sshd_config
sed -i '1,/PasswordAuthentication/{s/.*PasswordAuthentication.*/PasswordAuthentication yes/}' /etc/ssh/sshd_config
if [[ ${release} == 'centos' ]]; then
	service sshd restart
else
	service ssh restart
fi
echo $pw >> $(pwd)/ipadd

clear
green_font 'Free one-click script on Google Cloud ' " 版本号：${sh_ver}"
echo -e "            \033[37m\033[01m--胖波比--\033[0m\n"
echo -e "${Info}主机名1：  $(red_font $HOSTNAME)"
echo -e "${Info}主机名2：  $(red_font $IP)"
echo -e "${Info}SSH端口：  $(red_font $ssh_port)"
echo -e "${Info}username：   $(red_font root)"
echo -e "${Info}password：   $(red_font $pw)"
echo -e "${Tip}Be sure to record your login information！！\n"

app_name="$(pwd)/sshcopy"
if [ ! -e $app_name ]; then
	echo -e "${Info}正在下载免密登录程序..."
	wget -qO $app_name https://github.com/Jrohy/sshcopy/releases/download/v1.4/sshcopy_linux_386 && chmod +x $app_name
fi
$app_name -ip $IP -user root -port $ssh_port -pass $pw

if [ -e /var/spool/cron/root ]; then
	corn_path='/var/spool/cron/root'
elif [ -e /var/spool/cron/crontabs/root ]; then
	corn_path='/var/spool/cron/crontabs/root'
else
	corn_path="$(pwd)/temp"
	echo 'SHELL=/bin/bash' > $corn_path
fi

if [[ $corn_path != "$(pwd)/temp" ]]; then
	sed -i "/ssh -p ${ssh_port} root@${IP}/d" $corn_path
fi
read -p "请输入每 ? 分钟自动登录(默认:8)：" timer
[ -z $timer ] && timer=8
echo "*/${timer} * * * *  ssh -p ${ssh_port} root@${IP}" >> $corn_path
if [[ $corn_path == "$(pwd)/temp" ]]; then
	crontab -u root $corn_path
	rm -f $corn_path
fi
/etc/init.d/cron restart
echo -e "${Info}The self-awakening timed task is added successfully! ! "

echo -e "\n${Info}If you were $(green_font 'https://ssh.cloud.google.com') Executed this script "
echo -e "${Info}Then to execute this script later, just run $(red_font './gcs.sh') Yes, even if the machine is reset, it will not be affected "
echo -e "${Tip}Wake up this Shell regularly on other machines: $(green_font 'wget -O gcs_k.sh '${github}'/gcs/gcs_k.sh && chmod +x gcs_k.sh && ./gcs_k.sh')"

install_v2ray(){
	$PM -y install jq curl lsof
	clear && echo
	kernel_version=`uname -r|awk -F "-" '{print $1}'`
	if [[ `echo ${kernel_version}|awk -F '.' '{print $1}'` == '4' ]] && [[ `echo ${kernel_version}|awk -F '.' '{print $2}'` -ge 9 ]] || [[ `echo ${kernel_version}|awk -F '.' '{print $1}'` == '5' ]]; then
		sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
		sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
		echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
		echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
		sysctl -p
		clear && echo
		white_font '已安装\c' && green_font 'BBR\c' && white_font '内核！BBR启动\c'
		if [[ `lsmod|grep bbr|awk '{print $1}'` == 'tcp_bbr' ]]; then
			green_font '成功！\n'
		else
			red_font '失败！\n'
		fi
		sleep 1s
	fi

	clear
	v2ray_url='https://multi.netlify.com/v2ray.sh'
	bash <(curl -sL $v2ray_url) --remove
	check_pip(){
		if [[ ! `pip -V|awk -F '(' '{print $2}'` =~ 'python 3' ]]; then
			pip_array=($(whereis pip|awk -F 'pip: ' '{print $2}'))
			for node in ${pip_array[@]};
			do
				if [[ ! $node =~ [0-9] ]]; then
					rm -f $node
				fi
				if [[ $node =~ '3.' ]]; then
					pip_path=$node
				fi
			done
			if [[ -n $pip_path ]]; then
				ln -s $pip_path /usr/local/bin/pip
				ln -s $pip_path /usr/bin/pip
				pip install --upgrade pip
			else
				unset CMD
				py_array=(python3.1 python3.2 python3.3 python3.4 python3.5 python3.6 python3.7 python3.8 python3.9)
				for node in ${py_array[@]};
				do
					if type $node >/dev/null 2>&1; then
						CMD=$node
					fi
				done
				if [[ -n $CMD ]]; then
					wget -O get-pip.py https://bootstrap.pypa.io/get-pip.py
					$CMD get-pip.py
					rm -f get-pip.py
				else
					zlib_ver='1.2.11'
					wget "http://www.zlib.net/zlib-${zlib_ver}.tar.gz"
					tar -xvzf zlib-${zlib_ver}.tar.gz
					cd zlib-${zlib_ver}
					./configure
					make && make install && cd /root
					rm -rf zlib*
					py_ver='3.7.7'
					wget "https://www.python.org/ftp/python/${py_ver}/Python-${py_ver}.tgz"
					tar xvf Python-${py_ver}.tgz
					cd Python-${py_ver}
					./configure --prefix=/usr/local
					make && make install && cd /root
					rm -rf Python*
				fi
				check_pip
			fi
		fi
	}
	check_pip
	bash <(curl -sL $v2ray_url) --zh
	find /usr/local/lib/python*/*-packages/v2ray_util -name group.py > v2raypath
	sed -i 's#ps": ".*"#ps": "胖波比"#g' $(cat v2raypath)
	
	protocol=$(jq -r ".inbounds[0].streamSettings.network" /etc/v2ray/config.json)
	cat /etc/v2ray/config.json |jq "del(.inbounds[0].streamSettings.${protocol}Settings[])" |jq '.inbounds[0].streamSettings.network="ws"' > /root/temp.json
	temppath="/$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)/"
	cat /root/temp.json |jq '.inbounds[0].streamSettings.wsSettings.path="'${temppath}'"' |jq '.inbounds[0].streamSettings.wsSettings.headers.Host="www.bilibili.com"' > /etc/v2ray/config.json
	
	pid_array=($(lsof -i:22|grep LISTEN|awk '{print$2}'|uniq))
	for node in ${pid_array[@]};
	do
		kill $node
	done
	echo 22|v2ray port
	
	line=$(grep -n '__str__(self)' $(cat v2raypath)|tail -1|awk -F ':' '{print $1}')
	sed -i ''${line}'aself.port = "6000"' $(cat v2raypath)
	sed -i 's#self.port = "6000"#        self.port = "6000"#g' $(cat v2raypath)
	rm -f v2raypath
	clear && v2ray info
	echo -e "${Tip}Be sure to record the above information, because you will never see it again after turning off SSH! "
}
echo -e "\n${Tip}After installing Direct Connect V2Ray, GCS will no longer be able to connect via SSH! "
read -p "Do you want to start BBR and install 6000 port directly connected to V2Ray? [y: Yes n: Next] (default: y): " num
[ -z $num ] && num='y'
if [[ $num == 'y' ]]; then
	install_v2ray
fi

donation_developer(){
	yello_font 'Your support is the motivation for the author to update and improve the script! '
	yello_font 'Please visit the following website to scan the code to donate ：'
	green_font "[支付宝] \c" && white_font "${github}/donation/alipay.jpg"
	green_font "[微信]   \c" && white_font "${github}/donation/wechat.png"
	green_font "[银联]   \c" && white_font "${github}/donation/unionpay.png"
	green_font "[QQ]     \c" && white_font "${github}/donation/qq.png"
}
echo && read -p "Do you want to donate the author? [y: yes n: exit script] (default: y): " num
[ -z $num ] && num='y'
if [[ $num == 'y' ]]; then
	donation_developer
fi
