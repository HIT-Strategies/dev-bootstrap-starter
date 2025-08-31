.PHONY: mac linux wsl

    mac:
	bash provision/macos.sh

    linux:
	bash provision/ubuntu_wsl.sh

    wsl:
	bash provision/ubuntu_wsl.sh
