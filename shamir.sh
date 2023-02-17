#!/bin/bash

CIPHER=aes-256-cbc

usage()
{
	echo ""
    echo "Usage: $(basename "$0") [ -e | -d ] [ -o filename ] [ -p ] -t number [ -s number ] [ -c cipher ] file1 [file2...]
              -e, --encrypt   Encrypt file, requires threshold and shares to be set, and a filename supplied.
              -d, --decrypt   Decrypt file, requires threshold to be set, and the same number of share files to be supplied.
              -o, --output    Output file, required when decrypting
              -p, --pack      Pack the encrypted data into the share files, otherwise keep it as a separate output file.
                              When decrypting, if this flag is missing, the first parameter needs to be only the encrypted
                              data, and the rest is the required number of shares.
              -t, --threshold Threshold, the number of shares required to decrypt
              -s, --shares    Shares, the number of shares to generate
              -c, --cipher    Openssl cipher to use, default is aes-256-cbc"

	exit 2
}


PARSED=$(getopt -n ss -o edo:pt:s:c: --long encrypt,decrypt,output:,pack,threshold:,shares:,cipher: -- "$@")
if [ $? != 0 ]; then
	usage
fi

eval set -- "$PARSED"
PACK=0

while :
do
	case "$1" in
		-e | --encrypt)
			ENCRYPT=1
			shift
			;;
		-d | --decrypt)
			DECRYPT=1
			shift
			;;
		-o | --output)
			DECRYPTED_FILE=$2
			shift 2
			;;
		-p | --pack)
			PACK=1
			shift
			;;
		-t | --threshold)
			THRESHOLD=$2
			shift 2
			;;
		-s | --shares)
			SHARES=$2
			shift 2
			;;
		-c | --cipher)
			CIPHER=$2
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "Unknown option: $1"
			usage
			;;
	esac
done

if [ $((ENCRYPT+DECRYPT)) = 0 ]; then
	echo "You must select either encryption or decryption"
	usage
fi

if [ $((ENCRYPT+DECRYPT)) != 1 ]; then
	echo "You can only select encryption or decryption"
	usage
fi

if [ -z ${THRESHOLD+x} ]; then
	echo "You must set threshold";
	usage
fi

if [[ $ENCRYPT = 1 ]]; then
	if [ -z ${SHARES+x} ]; then
		echo "You must set number of shares when encrypting";
		usage
	fi

	if [[ $# != 1 ]]; then
		echo "You must specify file to encrypt, and one file only"
		usage
	fi

	PASSWD=$(hexdump -v -n 64 -e'16/4 "%08x" 1 "\n"' /dev/urandom)
	INPUT_FILE=$1
	OUTPUT_FILE=${INPUT_FILE}.enc

	if [ ! -f "$INPUT_FILE" ]; then
		echo "File not found: ${INPUT_FILE}"
		usage
	fi

	openssl enc -${CIPHER} -pbkdf2 -pass pass:${PASSWD} < ${INPUT_FILE} > ${OUTPUT_FILE}

	SECRETS=$(ssss-split -t ${THRESHOLD} -n ${SHARES} -q <<< ${PASSWD})
	
	COUNTER=1
	while IFS= read -r secret; do
		if [ -f "${OUTPUT_FILE}.${COUNTER}" ]; then
			echo "Share output file '${OUTPUT_FILE}.${COUNTER}' already exists"
			exit 3
		fi
		
		echo ${secret} > ${OUTPUT_FILE}.${COUNTER}
		if [ $PACK = 1 ]; then
			cat ${OUTPUT_FILE} >> ${OUTPUT_FILE}.${COUNTER}
		fi
		
		echo "Share ${COUNTER}: ${OUTPUT_FILE}.${COUNTER}"
		COUNTER=$((COUNTER+1))
	done <<< "${SECRETS}"

	if [ ${PACK} = 1 ]; then
		shred -u ${OUTPUT_FILE}
		echo "Encrypted data is included in shares"
	else
		echo "Encrypted data is in ${OUTPUT_FILE}"
	fi
fi

if [[ $DECRYPT = 1 ]]; then
	INPUT_FILE=$1

	if [ -z ${DECRYPTED_FILE+x} ]; then
		echo "You need to specify output file when decrypting"
		usage
	fi

	if [ $PACK = 0 ]; then
		shift
	fi

	if [[ $# != ${THRESHOLD} ]]; then
		echo "You must specify a number of files equal to the threshold"
		usage
	fi

	while(($#)) ; do
		SECRETS+="$(head -n 1 $1)"$'\n'
		shift
	done

	PASSWD=$(ssss-combine -t ${THRESHOLD} -q <<< ${SECRETS} 2>&1)

	if [ $PACK = 1 ]; then
		openssl enc -${CIPHER} -d -pbkdf2 -pass pass:${PASSWD} < <(tail -n +2 ${INPUT_FILE}) > ${DECRYPTED_FILE}
	else
		openssl enc -${CIPHER} -d -pbkdf2 -pass pass:${PASSWD} < ${INPUT_FILE} > ${DECRYPTED_FILE}
	fi
fi
