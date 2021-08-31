#######################################################################################
### 2021년 계산노드 기본 설정 #########################################################
#######################################################################################

00# BIOS 기본 설정 (HP)
	Workload Profiles: HPCProfile
	Hyper-threading  : Disabled
	NUMA             : Enabled

00# RHEL8.3 설치옵션
	RHEL8.3 Install Option : Server with GUI
	
01# Host Name 설정
	hostnamectl set-hostname bm1251
	hostnamectl set-hostname bm1252

	
02# 방화벽 끄기
	systemctl stop firewalld.service
	systemctl disable firewalld.service

	
03# SELinux(Security-Enhanced Linux) 끄기
	[root@bm1252 ~]# cat /etc/selinux/config

	# This file controls the state of SELinux on the system.
	# SELINUX= can take one of these three values:
	#     enforcing - SELinux security policy is enforced.
	#     permissive - SELinux prints warnings instead of enforcing.
	#     disabled - No SELinux policy is loaded.
	SELINUX=disabled
	# SELINUXTYPE= can take one of these three values:
	#     targeted - Targeted processes are protected,
	#     minimum - Modification of targeted policy. Only selected processes are protected.
	#     mls - Multi Level Security protection.
	SELINUXTYPE=targeted

	
04# Node 재시작
	reboot

	SELinux 설정 확인
	[root@bm1251 ~]# sestatus
	SELinux status:                 disabled

	
05# 슈퍼컴 localrepo 설정
	wget -P /etc/yum.repos.d http://202.20.187.241/rhel8.3_iso/rhel8.3_iso.repo
	wget -P /etc/yum.repos.d http://202.20.187.241/epelrepo_rhel8/epel/epel-rhel8.repo
	wget -P /etc/yum.repos.d http://202.20.187.241/MLNX_OFED/5.2-1.0.4.0-rhel8.3.repo
	wget -P /etc/yum.repos.d http://202.20.187.241/linux/centos/docker-ce.repo
	wget -P /etc/yum.repos.d http://202.20.187.241/cudarepo_rhel8/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
	dnf clean all
	dnf repolist

	
06# 초기 Package 설치
	dnf -y group install "Development Tools"
	dnf -y install numactl
	dnf -y install numactl-devel
	dnf -y install python36
	dnf -y install htop
	dnf -y install yum-utils
	dnf -y install dstat
	dnf -y install iftop
	dnf -y install ksh
	dnf -y install lapack
	dnf -y install hwloc
	dnf -y install ipmitool
	dnf -y install sysstat
	systemctl enable sysstat



07# MLNX OFED 기본 버전 설치 -> !!!! IP 재설정 필요
	dnf install mlnx-ofed-hpc
	Node 재시작
	reboot

	- IP 설정 example ......
		nmcli connection delete Wired\ connection\ 1
		nmcli connection delete Wired\ connection\ 2
		nmcli dev status
		nmcli dev show enp99s0f0
		nmcli connection add con-name "eno3" ifname enp99s0f0 type ethernet ipv4.addresses 202.20.187.251/24 ipv4.gateway 202.20.187.254

	- Dell HCA Card Firmware 확이 후 필요시
		mlxfwmanager -u -i ./fw-ConnectX6-rel-20_28_4512-0CY7GD_01GK7G_Ax-UEFI-14.22.15-FlexBoot-3.6.203.signed.bin


08# GPU 기본 버전 설치(cuda-11.2.2 + 460.32.03) 
        # V100 기본 Display 출력 이슈로 변경됨(465.19.01 -> 460.32.03)
	# A100 Fabric Manager 설치 이슈로 변경됨(460.32.03 -> 460.73.01)
	# CUDA 설치 순서 하위 버전부터

	dnf -y module install nvidia-driver:460-dkms/fm
	dnf -y install cuda-10.2.89
	dnf -y install cuda-11.2.2
	systemctl start nvidia-fabricmanager.service
	systemctl enable nvidia-fabricmanager.service
	systemctl status nvidia-fabricmanager.service

	wget -P ./ http://202.20.187.241/cudarepo_rhel8/nvidia_peer_memory-1.1-0.x86_64.rpm
	dnf -y install ./nvidia_peer_memory-1.1-0.x86_64.rpm
	systemctl start nv_peer_mem.service
	systemctl enable nv_peer_mem.service
	systemctl status nv_peer_mem.service



### SSSD 설정

	- Edit config file
		/etc/openldap/ldap.conf
		/etc/sssd/sssd.conf
		/etc/nsswitch.conf
		
	[root@bm1251 ~]# egrep -v '^#|^$' /etc/openldap/ldap.conf
	SASL_NOCANON    on
	URI ldap://202.20.185.110/ ldap://202.20.183.110/ ldap://202.20.185.11/
	BASE dc=supercom,dc=samsung

	[root@bm1251 ~]# grep -v ^# /etc/sssd/sssd.conf
	[sssd]
	config_file_version = 2
	services = nss,pam
	domains = supercom.samsung

	[nss]
	filter_users = root,ldap,named,avahi,haldaemon,dbus,radiusd,news,nscd

	[pam]

	[domain/supercom.samsung]
	auth_provider = ldap
	id_provider = ldap
	ldap_schema = rfc2307bis
	ldap_search_base = dc=supercom,dc=samsung
	ldap_group_member = uniqueMember
	ldap_tls_reqcert = never
	ldap_id_use_start_tls = False
	chpass_provider = ldap
	ldap_uri = ldap://202.20.185.110/, ldap://202.20.183.110/, ldap://202.20.185.11/
	ldap_tls_cacertdir = /etc/openldap/cacerts
	entry_cache_timeout = 60
	ldap_network_timeout = 3
	cache_credentials = True
	enumerate = True

	chmod 600 /etc/sssd/sssd.conf
	chown root:root /etc/sssd/sssd.conf
	openssl rehash /etc/openldap/certs
	authselect select sssd with-mkhomedir --force
	systemctl enable --now oddjobd.service



	[root@bm1251 ~]# egrep -v '^#|^$' /etc/nsswitch.conf
	passwd:     sss files systemd
	group:      sss files systemd
	netgroup:   sss files
	automount:  sss files
	services:   sss files
	shadow:     files sss
	hosts:      files dns myhostname
	aliases:    files
	ethers:     files
	gshadow:    files sss   (sss 부문 추가 (허수영대리))
	networks:   files dns
	protocols:  files
	publickey:  files
	rpc:        files

	
	systemctl start sssd.service
	systemctl enable sssd.service
	systemctl start oddjobd.service
	systemctl enable oddjobd.service
	

### limit 설정 - for mpi job (허수영 대리)
	[root@bm1251 ~]# grep -v ^# /etc/security/limits.conf

	
	* soft memlock unlimited
	* hard memlock unlimited
	
	* soft stack   unlimited
	* hard nofile  10240
	* soft nofile  10240

### docker 기본버전(19.03.15) 설치
	dnf -y erase runc
	dnf -y install docker-ce-19.03.15 docker-ce-cli-19.03.15

	rpm 설치 후 local docker group 을 삭제 해야 ldap그룹 권한으로 동작합니다.
	[root@bm1252 openldap]# grep docker /etc/group
	docker:x:971:

	systemctl --now enable docker



### Time 설정 (허수영 대리 수정)
	systemctl enable chronyd	
	vim /etc/chrony.conf	
		#pool 2.rhel.pool.ntp.org iburst
		  server 202.20.185.8 iburst		
	systemctl restart chronyd.service
            timedatectl  - > System clock synchronized : yes / NTP service: active : yes Check

### ssh_config 변경

### root sshkey 설정

### Storage Mount


#######################################################################################
#### 수정 및 추가작업이 필요한 내용은 해당 라인 아래에 추가 부탁 드립니다. ############
#######################################################################################

### Ansys FDTD (허수영 대리)
	dnf -y install xterm.x86_64 

### runlevel 설정(graphical.target -> multi-user.target) (김태수)
	systemctl set-default multi-user.target

	
### Nvidia Persistence Mode 설정(김태수) - 사용
	systemctl start nvidia-persistenced.service
	systemctl enable nvidia-persistenced.service
	systemctl status nvidia-persistenced.service

### LSF Env (이원기)
	dnf -y install libnsl
	scp secm:/etc/profile.d/lsf.sh /etc/profile.d/
	scp secm:/etc/profile.d/lsf.csh /etc/profile.d/

### HPE 8GPU 장비 nvidia driver 설치를 repo로 하고자 할때(김태수)
	dnf -y erase nvidia-fabricmanager-460
	/usr/bin/nvidia-uninstall -s

	dnf -y install nvidia-driver-460.73.01-1.el8
	dnf -y install nvidia-fabricmanager-460

	dnf -y install cuda-10.2.89
	dnf -y install cuda-11.2.2

	systemctl start nvidia-fabricmanager.service
	systemctl enable nvidia-fabricmanager.service
	systemctl status nvidia-fabricmanager.service

	systemctl start nvidia-persistenced.service
	systemctl enable nvidia-persistenced.service
	systemctl status nvidia-persistenced.service

### cmake os 기본 버전 설치 (김태수)
	dnf -y install cmake
