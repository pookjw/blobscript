#!/bin/sh
# blobscript @pookjw
TOOL_VERSION=3

function defaultSettings(){
	PATH_IPSW=
	URL_TSSCHECKER="https://github.com/tihmstar/tsschecker/releases/download/v212/tsschecker_v212_mac_win_linux.zip"
	PATH_OUTPUT=
	DEVICE=
	ECID=
	OS_VERSION=auto
	OS_BUILD=auto
	BETA_FIRMWARE=NO
}

function showInterface(){
	while(true); do
		clear
		showLines "*"
		echo "blobscript.sh (Version: ${TOOL_VERSION})"
		showLines "-"
		if [[ -z "${PATH_IPSW}" ]]; then
			echo "(1) ipsw: (undefined)"
		else
			echo "(1) ipsw: ${PATH_IPSW}"
		fi
		if [[ -z "${URL_TSSCHECKER}" ]]; then
			echo "(2) tsschecker(release): (undefined)"
		else
			echo "(2) tsschecker(release): ${URL_TSSCHECKER}"
		fi
		if [[ -z "${PATH_OUTPUT}" ]]; then
			echo "(3) output: (undefined)"
		else
			echo "(3) output: ${PATH_OUTPUT}"
		fi
		if [[ -z "${DEVICE}" ]]; then
			echo "(4) device: (undefined)"
		else
			echo "(4) device: ${DEVICE}"
		fi
		if [[ -z "${ECID}" ]]; then
			echo "(5) ecid: (undefined)"
		else
			echo "(5) ecid: ${ECID}"
		fi
		if [[ -z "${OS_VERSION}" ]]; then
			echo "(6) version: (undefined)"
		elif [[ "${OS_VERSION}" == auto ]]; then
			echo "(6) version: (auto)"
		else
			echo "(6) version: ${OS_VERSION}"
		fi
		if [[ -z "${OS_BUILD}" ]]; then
			echo "(7) build: (undefined)"
		elif [[ "${OS_BUILD}" == auto ]]; then
			echo "(7) build: (auto)"
		else
			echo "(7) build: ${OS_BUILD}"
		fi
		echo "(8) beta: ${BETA_FIRMWARE}"
		showLines "-"
		echo "Available commands: 1~8, start, exit"
		showLines "*"
		read -p "- " ANSWER

		if [[ "${ANSWER}" == 1 ]]; then
			read -p "PATH_IPSW=" PATH_IPSW
			if [[ -z "${PATH_IPSW}" ]]; then
				:
			elif [[ ! -f "${PATH_IPSW}" ]]; then
				echo "No such file: ${PATH_IPSW}"
				PATH_IPSW=
				showPA2C
			fi
		elif [[ "${ANSWER}" == 2 ]]; then
			read -p "URL_TSSCHECKER=" URL_TSSCHECKER
		elif [[ "${ANSWER}" == 3 ]]; then
			read -p "PATH_OUTPUT=" PATH_OUTPUT
			if [[ -z "${PATH_OUTPUT}" ]]; then
				:
			elif [[ ! -d "${PATH_OUTPUT}" ]]; then
				echo "No such directory: ${PATH_OUTPUT}"
				PATH_OUTPUT=
				showPA2C
			fi
		elif [[ "${ANSWER}" == 4 ]]; then
			read -p "DEVICE=" DEVICE
		elif [[ "${ANSWER}" == 5 ]]; then
			read -p "ECID=" ECID
		elif [[ "${ANSWER}" == 6 ]]; then
			read -p "OS_VERSION=" OS_VERSION
		elif [[ "${ANSWER}" == 7 ]]; then
			read -p "OS_BUILD=" OS_BUILD
		elif [[ "${ANSWER}" == 8 ]]; then
			if [[ "${BETA_FIRMWARE}" == NO ]]; then
				BETA_FIRMWARE=YES
			else
				BETA_FIRMWARE=NO
			fi
		elif [[ "${ANSWER}" == start ]]; then
			if [[ -z "${PATH_IPSW}" || -z "${URL_TSSCHECKER}" || -z "${PATH_OUTPUT}" || -z "${DEVICE}" || -z "${ECID}" || -z "${OS_VERSION}" || -z "${OS_BUILD}" ]]; then
				echo "ERROR: Please fill all values."
				showPA2C
			else
				break
			fi
		elif [[ "${ANSWER}" == exit ]]; then
			exit 0
		elif [[ -z "${ANSWER}" ]]; then
			:
		else
			echo "${ANSWER}: Command not found."
			showPA2C
		fi
	done
}

function downloadBinary(){
	removeFile /tmp/tsschecker
	removeFile /tmp/tsschecker.zip
	wget --output-document=/tmp/tsschecker.zip "${URL_TSSCHECKER}"
	unzip -o -d /tmp/tsschecker /tmp/tsschecker.zip
	chmod +x /tmp/tsschecker/tsschecker_macos
}

function extractFirmware(){
	removeFile /tmp/BuildManifest.plist
	unzip -n -j "${PATH_IPSW}" BuildManifest.plist -d /tmp
	if [[ ! -f /tmp/BuildManifest.plist ]]; then
		echo "ERROR: corrupted IPSW"
		exit 1
	fi
}

function startProject(){
	if [[ "${OS_VERSION}" == auto ]]; then
		SKIP_ONCE=NO
		for VALUE in $(cat /tmp/BuildManifest.plist); do
			if [[ "${SKIP_ONCE}" == YES ]]; then
				OS_VERSION="$(echo "${VALUE}" | cut -d">" -f2 | cut -d"<" -f1)"
				break
			fi
			if [[ "${VALUE}" == "<key>ProductVersion</key>" ]]; then
				SKIP_ONCE=YES
			fi
		done
	fi
	if [[ "${OS_BUILD}" == auto ]]; then
		SKIP_ONCE=NO
		for VALUE in $(cat /tmp/BuildManifest.plist); do
			if [[ "${SKIP_ONCE}" == YES ]]; then
				OS_BUILD="$(echo "${VALUE}" | cut -d">" -f2 | cut -d"<" -f1)"
				break
			fi
			if [[ "${VALUE}" == "<key>ProductBuildVersion</key>" ]]; then
				SKIP_ONCE=YES
			fi
		done
	fi
	echo "${OS_VERSION} ${OS_BUILD}"
	cd /tmp
	if [[ "${BETA_FIRMWARE}" == YES ]]; then
		/tmp/tsschecker/tsschecker_macos -d "${DEVICE}" -e "${ECID}" -m /tmp/BuildManifest.plist -i --beta "${OS_VERSION}" --buildid "${OS_BUILD}" -s
	else
		/tmp/tsschecker/tsschecker_macos -d "${DEVICE}" -e "${ECID}" -m /tmp/BuildManifest.plist -i "${OS_VERSION}" --buildid "${OS_BUILD}" -s
	fi
	mv *.shsh2 "${PATH_OUTPUT}"
	echo "Done."
}

function removeFile(){
	if [[ ! -z "${1}" ]]; then
		if [[ -f "${1}" || -d "${1}" ]]; then
			rm -rf "${1}"
		fi
	fi
}

function showLines(){
	PRINTED_COUNTS=0
	COLS=`tput cols`
	if [[ "${COLS}" -ge 1 ]]; then
		while [[ ! $PRINTED_COUNTS == $COLS ]]; do
			printf "${1}"
			PRINTED_COUNTS=$(($PRINTED_COUNTS+1))
		done
		echo
	fi
}

function showPA2C(){
	read -s -n 1 -p "Press any key to continue..."
	echo
}

defaultSettings
showInterface
downloadBinary
extractFirmware
startProject
