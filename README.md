# shamir

This script uses ssss and openssl to encrypt a file with a random key, and split the key into shares with Shamir's secret sharing scheme. This script leaks the keys left and right and should probably be ran on a temporary system (e.g. live USB) to retain secrecy.

I give no guarantees as to how safe this protocol implementation is :)
