#!/bin/sh

# /*
# Copyright (C) HWPORT.COM
# All rights reserved.
# Author: JAEHYUK CHO <mailto:minzkn@minzkn.com>
# */

# *.key : 개인키 파일 (유출 주의)
# *.enc.key : 개인키 암호화된 파일 (유출 주의)
# *.csr : 인증서 요청 파일
# *.der : DER형식의 인증서 파일
# *.pem : PEM형식의 인증서 파일
# *.srl : Serial 파일

# OpenSSL 명령어
DEF_openssl_command=openssl

DEF_rootca_config_pathname=rootca.conf
DEF_host_config_pathname=host.conf

DEF_rootca_pathname=rootca
DEF_rootca_expire_days=36500

DEF_host_expire_days=1825

generate_key_file()
{
	local s_pathname=${1}
	
	[ -z "${s_pathname}" ] && return 1

	# 2048bit 개인키 생성하여 개인키 분실에 대비해 AES 256bit 로 암호화 합니다.
	# AES 이므로 암호(pass phrase)를 분실하면 개인키를 얻을수 없으니 꼭 기억해야 합니다.
	echo "Generating KEY(Encrypt) file : ${s_pathname}.enc.key"
	${DEF_openssl_command} genrsa -aes256 -out "${s_pathname}.enc.key" 2048
	[ "${?}" -eq 0 -a -f "${s_pathname}.enc.key" ] || return 1

	#개인키의 유출 방지를 위해 group 과 other의 permission 을 모두 제거합니다.
	chmod 600 "${s_pathname}.enc.key"

	# 개인키 암호 해제 (이 파일은 최대한 보안 유지 필요, 이 파일은 암호를 매번 물어보지 않게 되지만 보안상 유출되지 않도록 특별히 관리 필요)
	echo "Removing pass phrase KEY file : ${s_pathname}.key from ${s_pathname}.enc.key"
	${DEF_openssl_command} \
		rsa \
		-in "${s_pathname}.enc.key" \
		-out "${s_pathname}.key"
	[ "${?}" -eq 0 -a -f "${s_pathname}.key" ] || return 1

	#개인키의 유출 방지를 위해 group 과 other의 permission 을 모두 제거합니다.
	chmod 600 "${s_pathname}.key"

	echo "Generated KEY file."

	return 0
}

generate_csr_file()
{
	local s_pathname=${1}
	local s_config_pathname=${2}

	[ -z "${s_pathname}" ] && return 1
	[ -z "${s_config_pathname}" ] && s_config_pathname="${s_pathname}.conf"

	# 인증서 요청 생성
	echo "Generating CSR file : ${s_pathname}.csr"
	if [ -f "${s_config_pathname}" ]
	then
		${DEF_openssl_command} req -new -key "${s_pathname}.enc.key" -out "${s_pathname}.csr" -config "${s_config_pathname}"
	else
		${DEF_openssl_command} req -new -key "${s_pathname}.enc.key" -out "${s_pathname}.csr"
	fi
	[ "${?}" -eq 0 -a -f "${s_pathname}.csr" ] || return 1

	echo "Generated CSR file."

	return 0
}

generate_root_crt_file()
{
	local s_pathname=${1}
	local s_expire_days=${2}
	local s_config_pathname=${3}

	[ -z "${s_pathname}" ] && return 1
	[ -z "${s_expire_days}" ] && return 1
	[ -z "${s_config_pathname}" ] && s_config_pathname="${s_pathname}.conf"

	echo "Generating CRT file : ${s_pathname}.crt"
	# self-signed 인증서 생성
	if [ -f "${s_config_pathname}" ]
	then
		${DEF_openssl_command} \
			x509 \
			-req \
			-days "${s_expire_days}" \
			-extensions v3_ca \
			-set_serial 1 \
			-in "${s_pathname}.csr" \
			-signkey "${s_pathname}.enc.key" \
			-outform PEM \
			-out "${s_pathname}.crt" \
			-extfile "${s_config_pathname}"
	else
		${DEF_openssl_command} \
			x509 \
			-req \
			-days "${s_expire_days}" \
			-extensions v3_ca \
			-set_serial 1 \
			-in "${s_pathname}.csr" \
			-signkey "${s_pathname}.enc.key" \
			-outform PEM \
			-out "${s_pathname}.crt"
	fi
	[ "${?}" -eq 0 -a -f "${s_pathname}.crt" ] || return 1

	echo "Generated CRT file."

	echo "Copying CRT to PEM file : ${s_pathname}.pem"
	cp -f "${s_pathname}.crt" "${s_pathname}.pem"
	[ "${?}" -eq 0 -a -f "${s_pathname}.pem" ] || return 1

	echo "Copyed PEM file."

	echo "Converting PEM to DER file : ${s_pathname}.der"
	${DEF_openssl_command} \
		x509 \
		-inform PEM \
		-in "${s_pathname}.pem" \
		-outform DER \
		-out "${s_pathname}.der"
	[ "${?}" -eq 0 -a -f "${s_pathname}.der" ] || return 1

	echo "Converted DER file."

	return 0
}

generate_crt_file()
{
	local s_pathname=${1}
	local s_expire_days=${2}
	local s_config_pathname=${3}
	local s_rootca_pathname=${4}

	[ -z "${s_pathname}" ] && return 1
	[ -z "${s_expire_days}" ] && return 1
	[ -z "${s_config_pathname}" ] && s_config_pathname="${s_pathname}.conf"
	[ -z "${s_rootca_pathname}" ] && return 1

	echo "Generating CRT file : ${s_pathname}.crt"
	if [ -f "${s_config_pathname}" ]
	then
		${DEF_openssl_command} \
			x509 \
			-req \
			-days "${s_expire_days}" \
			-extensions v3_user \
			-in "${s_pathname}.csr" \
			-CA "${s_rootca_pathname}.crt" \
			-CAcreateserial \
			-CAkey "${s_rootca_pathname}.enc.key" \
			-outform PEM \
			-out "${s_pathname}.crt" \
			-extfile "${s_config_pathname}"
	else
		${DEF_openssl_command} \
			x509 \
			-req \
			-days "${s_expire_days}" \
			-extensions v3_user \
			-in "${s_pathname}.csr" \
			-CA "${s_rootca_pathname}.crt" \
			-CAcreateserial \
			-CAkey "${s_rootca_pathname}.enc.key" \
			-outform PEM \
			-out "${s_pathname}.crt"
	fi
	[ "${?}" -eq 0 -a -f "${s_pathname}.crt" ] || return 1

	echo "Generated CRT file."

	echo "Copying CRT to PEM file : ${s_pathname}.pem"
	cp -f "${s_pathname}.crt" "${s_pathname}.pem"
	[ "${?}" -eq 0 -a -f "${s_pathname}.pem" ] || return 1

	echo "Copyed PEM file."

	echo "Converting PEM to DER file : ${s_pathname}.der"
	${DEF_openssl_command} \
		x509 \
		-inform PEM \
		-in "${s_pathname}.pem" \
		-outform DER \
		-out "${s_pathname}.der"
	[ "${?}" -eq 0 -a -f "${s_pathname}.der" ] || return 1
	
	echo "Converted DER file."

	return 0
}

# 제대로 생성되었는지 확인을 위해 인증서의 정보를 출력
dump_info()
{
	local s_pathname=${1}

	[ -z "${s_pathname}" ] && return 1

	echo "Dumping CRT file."
	${DEF_openssl_command} \
		x509 \
		-inform PEM \
		-in "${s_pathname}.crt" \
		-text
	if [ "${?}" -ne 0 ]
	then
		echo "dump info failed !"
		return 1
	fi

	return 0
}

generate_rootca()
{
	local s_pathname=${1}
	local s_expire_days=${2}

	[ -z "${s_pathname}" ] && return 1
	[ -z "${s_expire_days}" ] && return 1

	# CA 가 사용할 RSA  key pair(public, private key) 생성
	generate_key_file \
		"${s_pathname}"
	if [ "${?}" -ne 0 ]
	then
		echo "key generate failed !"
		return 1
	fi

	generate_csr_file \
		"${s_pathname}" \
		"${DEF_rootca_config_pathname}"
	if [ "${?}" -ne 0 ]
	then
		echo "csr generate failed !"
		return 1
	fi

	generate_root_crt_file \
		"${s_pathname}" \
		"${s_expire_days}" \
		"${DEF_rootca_config_pathname}"
	if [ "${?}" -ne 0 ]
	then
		echo "crt generate failed !"
		return 1
	fi

	dump_info \
		"${s_pathname}"

	return 0
}

generate_cert()
{
	local s_pathname=${1}
	local s_expire_days=${2}

	[ -z "${s_pathname}" ] && s_pathname="host0"
	[ -z "${s_expire_days}" ] && return 1

	generate_key_file \
		"${s_pathname}"
	if [ "${?}" -ne 0 ]
	then
		echo "key generate failed !"
		return 1
	fi

	generate_csr_file \
		"${s_pathname}" \
		"${DEF_host_config_pathname}"
	if [ "${?}" -ne 0 ]
	then
		echo "csr generate failed !"
		return 1
	fi

	generate_crt_file \
		"${s_pathname}" \
		"${s_expire_days}" \
		"${DEF_host_config_pathname}" \
		"${DEF_rootca_pathname}"
	if [ "${?}" -ne 0 ]
	then
		echo "crt generate failed !"
		return 1
	fi

	dump_info \
		"${s_pathname}"

	return 0
}

case "${1}" in
	ca|rootca)
		generate_rootca \
			"${DEF_rootca_pathname}" \
			"${DEF_rootca_expire_days}"
		if [ "${?}" -eq 0 ]
		then
			echo "generated root CA."
		else
			echo "root CA generate failed !"
			return 1
		fi
	;;
	gen|generate|cert|sign)
		if [ ! -f "${DEF_rootca_pathname}.crt" ]
		then
			echo "${DEF_rootca_pathname}.crt not found !"
			return 1
		fi
		generate_cert \
			"${2}" \
			"${DEF_host_expire_days}"
		if [ "${?}" -eq 0 ]
		then
			echo "generated cert."
		else
			echo "cert generate failed !"
			return 1
		fi
	;;
	clean)
		echo "cleaning..."
		rm -f *.key *.csr *.crt *.der *.pem *.srl
	;;
	*)
		echo "$(basename ${0}) v1.0 Copyrights (C) HWPORT.COM - All rights reserved."
		echo ""
		echo "usage: ${0} <rootca | gen [<name>] | clean>"
		echo ""
	;;
esac

exit 0

# End of cert.sh
