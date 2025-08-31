.PHONY: mac linux wsl windows

    mac:
	bash provision/macos.sh

    linux:
	bash provision/ubuntu_wsl.sh

    wsl:
	bash provision/ubuntu_wsl.sh

    windows:
	powershell -ExecutionPolicy Bypass -File provision/windows.ps1
