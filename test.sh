#!/bin/bash

cleanup()
{
	rm testfile*
}

dd if=/dev/urandom of=testfile bs=512 count=2048

./shamir.sh -e -t 3 -s 5 testfile

if [ $? != 0 ]; then
	echo "Error encrypting"
	cleanup
	exit 1
fi

./shamir.sh -d -t 3 -o testfile1 testfile.enc testfile.enc.1 testfile.enc.2 testfile.enc.3

if [ $? != 0 ]; then
	echo "Error decrypting 1"
	cleanup
	exit 1
fi

./shamir.sh -d -t 3 -o testfile2 testfile.enc testfile.enc.3 testfile.enc.4 testfile.enc.5

if [ $? != 0 ]; then
	echo "Error decrypting 2"
	cleanup
	exit 1
fi

cmp -s testfile testfile.enc

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile.enc.1 testfile.enc.2

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile.enc.2 testfile.enc.3

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile.enc.3 testfile.enc.4

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile.enc.4 testfile.enc.5

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile testfile1

if [ $? != 0 ]; then
	echo "Files are not the same"
	cleanup
	exit 1
fi

cmp -s testfile testfile2

if [ $? != 0 ]; then
	echo "Files are not the same"
	cleanup
	exit 1
fi

cleanup

dd if=/dev/urandom of=testfile bs=512 count=2048

./shamir.sh -e -t 3 -s 5 -p testfile

if [ $? != 0 ]; then
	echo "Error encrypting"
	cleanup
	exit 1
fi

./shamir.sh -d -t 3 -p -o testfile1 testfile.enc.1 testfile.enc.2 testfile.enc.3

if [ $? != 0 ]; then
	echo "Error decrypting 1"
	cleanup
	exit 1
fi

./shamir.sh -d -t 3 -p -o testfile2 testfile.enc.3 testfile.enc.4 testfile.enc.5

if [ $? != 0 ]; then
	echo "Error decrypting 2"
	cleanup
	exit 1
fi

cmp -s testfile.enc.1 testfile.enc.2

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile.enc.2 testfile.enc.3

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile.enc.3 testfile.enc.4

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile.enc.4 testfile.enc.5

if [ $? = 0 ]; then
	echo "File is the same"
	cleanup
	exit 1
fi

cmp -s testfile testfile1

if [ $? != 0 ]; then
	echo "Files are not the same"
	cleanup
	exit 1
fi

cmp -s testfile testfile2

if [ $? != 0 ]; then
	echo "Files are not the same"
	cleanup
	exit 1
fi

cleanup

echo ""
echo " *** SUCCESS *** "
echo ""
