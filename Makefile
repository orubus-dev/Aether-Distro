CC ?= cc
CFLAGS ?= -D_GNU_SOURCE -std=c11 -Wall -Wextra -Wpedantic -O2
INCLUDES := -Icore/include -I03-init/include -I04-service-manager/include -I08-capabilities/include -I09-device/include -I10-cpu/include -I11-gpu/include -I12-display/include -I14-input/include -I13-audio/include -I15-camera/include -I16-storage/include -I17-network/include -I18-bluetooth/include -I20-thermal/include -I21-battery/include -I22-firmware/include -I23-aegis/include -I25-identity/include -I26-authentication/include -I27-accounts/include -I29-permissions/include -I30-sandbox/include -I31-crypto/include -I24-tpm/include -I23-biometric/include
CORE_SRC := core/src/power.c core/src/identity.c core/src/types.c core/src/ipc.c core/src/event_bus.c core/src/capability_registry.c core/src/session.c core/src/notification.c core/src/clipboard.c core/src/search.c 03-init/src/init.c 04-service-manager/src/service_manager.c 04-service-manager/src/system_services.c 08-capabilities/src/capability_service.c 09-device/src/device_manager.c 10-cpu/src/cpu_linux.c 11-gpu/src/gpu_linux.c 12-display/src/display_linux.c 14-input/src/input_linux.c 13-audio/src/audio_linux.c 13-audio/src/audio_service.c 15-camera/src/camera_linux.c 16-storage/src/storage_linux.c 16-storage/src/storage_service.c 17-network/src/network_linux.c 17-network/src/network_service.c 18-bluetooth/src/bluetooth_linux.c 20-thermal/src/thermal_linux.c 21-battery/src/battery_linux.c 22-firmware/src/firmware_linux.c 23-aegis/src/aegis.c 25-identity/src/identity_service.c 26-authentication/src/authentication_service.c 27-accounts/src/account_service.c 29-permissions/src/permission_broker.c 29-permissions/src/permission_subject.c 30-sandbox/src/sandbox_linux.c 31-crypto/src/crypto_linux.c 24-tpm/src/tpm_linux.c 23-biometric/src/biometric_service.c
CORE_OBJ := $(CORE_SRC:.c=.o)
.PHONY: all test foundation-test service-test system-service-test hardware-test capability-test aegis-test phase5-test sandbox-test crypto-tpm-test biometric-test pam-auth-test aether-init initramfs kernel iso boot boot-iso clean
all: test foundation-test service-test system-service-test aegis-test phase5-test sandbox-test crypto-tpm-test biometric-test capability-test pam-auth-test subject-test aegis-access-test hardware-test
test: build/test_power
        ./build/test_power
foundation-test: $(CORE_OBJ) tests/core/test_foundation.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) $(CORE_OBJ) tests/core/test_foundation.c -o build/test_foundation
        ./build/test_foundation
service-test: $(CORE_OBJ) tests/service/test_service_manager.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/service/test_service_manager.c $(CORE_OBJ) -o build/test_service_manager
        ./build/test_service_manager
system-service-test: $(CORE_OBJ) tests/service/test_system_services.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/service/test_system_services.c $(CORE_OBJ) -o build/test_system_services
        ./build/test_system_services
phase5-test: $(CORE_OBJ) tests/security/test_phase5.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/security/test_phase5.c $(CORE_OBJ) -o build/test_phase5
        ./build/test_phase5
biometric-test: $(CORE_OBJ) tests/security/test_biometric.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/security/test_biometric.c $(CORE_OBJ) -o build/test_biometric
        ./build/test_biometric
crypto-tpm-test: $(CORE_OBJ) tests/security/test_crypto_tpm.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/security/test_crypto_tpm.c $(CORE_OBJ) -o build/test_crypto_tpm
        ./build/test_crypto_tpm
sandbox-test: $(CORE_OBJ) tests/security/test_sandbox.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/security/test_sandbox.c $(CORE_OBJ) -o build/test_sandbox
        ./build/test_sandbox
aegis-test: $(CORE_OBJ) tests/aegis/test_aegis.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/aegis/test_aegis.c $(CORE_OBJ) -o build/test_aegis
        ./build/test_aegis
aegis-access-test: $(CORE_OBJ) tests/aegis/test_aegis_access.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/aegis/test_aegis_access.c $(CORE_OBJ) -o build/test_aegis_access
        ./build/test_aegis_access
subject-test: $(CORE_OBJ) tests/security/test_permission_subject.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/security/test_permission_subject.c $(CORE_OBJ) -o build/test_permission_subject
        ./build/test_permission_subject
pam-auth-test: $(CORE_OBJ) tests/security/test_pam_provider.c 26-authentication/src/pam_provider_linux.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/security/test_pam_provider.c 26-authentication/src/pam_provider_linux.c $(CORE_OBJ) -ldl -o build/test_pam_provider
        ./build/test_pam_provider
capability-test: $(CORE_OBJ) tests/hardware/test_capability_service.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/hardware/test_capability_service.c $(CORE_OBJ) -o build/test_capability_service
        ./build/test_capability_service
hardware-test: $(CORE_OBJ) tests/hardware/test_hardware.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) tests/hardware/test_hardware.c $(CORE_OBJ) -o build/test_hardware
        ./build/test_hardware
build/test_power: $(CORE_OBJ) tests/core/test_power.c
        @mkdir -p build
        $(CC) $(CFLAGS) $(INCLUDES) $(CORE_OBJ) tests/core/test_power.c -o $@
aether-init: $(CORE_OBJ)
        @mkdir -p build
        $(CC) $(CFLAGS) -static $(INCLUDES) 03-init/src/main.c $(CORE_OBJ) -o build/aether-init
initramfs: aether-init
        sh build/initramfs/build.sh
kernel:
        sh build/kernel/build.sh
iso: kernel initramfs
        sh build/iso/build.sh
boot: kernel initramfs
        sh build/qemu/run-initramfs.sh
boot-iso: iso
        sh build/qemu/run-iso.sh
core/src/%.o: core/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
03-init/src/%.o: 03-init/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
04-service-manager/src/%.o: 04-service-manager/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
08-capabilities/src/%.o: 08-capabilities/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
09-device/src/%.o: 09-device/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
10-cpu/src/%.o: 10-cpu/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
11-gpu/src/%.o: 11-gpu/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
12-display/src/%.o: 12-display/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
13-audio/src/%.o: 13-audio/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
14-input/src/%.o: 14-input/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
15-camera/src/%.o: 15-camera/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
16-storage/src/%.o: 16-storage/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
17-network/src/%.o: 17-network/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
18-bluetooth/src/%.o: 18-bluetooth/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
20-thermal/src/%.o: 20-thermal/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
21-battery/src/%.o: 21-battery/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
22-firmware/src/%.o: 22-firmware/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
26-authentication/src/%.o: 26-authentication/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
27-accounts/src/%.o: 27-accounts/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
25-identity/src/%.o: 25-identity/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
30-sandbox/src/%.o: 30-sandbox/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
31-crypto/src/%.o: 31-crypto/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
23-biometric/src/%.o: 23-biometric/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
24-tpm/src/%.o: 24-tpm/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
29-permissions/src/%.o: 29-permissions/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
23-aegis/src/%.o: 23-aegis/src/%.c
        $(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@
clean:
        rm -f build/test_* build/aether-init build/*.o build/initramfs/* build/iso/aether-*.iso build/kernel/linux-image-*.deb core/src/*.o 03-init/src/*.o 04-service-manager/src/*.o 09-device/src/*.o 10-cpu/src/*.o 11-gpu/src/*.o 12-display/src/*.o 14-input/src/*.o 13-audio/src/*.o 15-camera/src/*.o 16-storage/src/*.o 17-network/src/*.o 18-bluetooth/src/*.o 20-thermal/src/*.o 21-battery/src/*.o 22-firmware/src/*.o 23-aegis/src/*.o 25-identity/src/*.o 26-authentication/src/*.o 27-accounts/src/*.o 29-permissions/src/*.o 30-sandbox/src/*.o 29-permissions/src/*.o 31-crypto/src/*.o 24-tpm/src/*.o 23-biometric/src/*.o 16-storage/src/*.o 17-network/src/*.o 13-audio/src/*.o
