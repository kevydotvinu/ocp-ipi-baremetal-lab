## OpenShift IPI Baremetal Lab (oibl)

### Architecture
![OpenShift IPI Baremetal Lab](https://raw.githubusercontent.com/kevydotvinu/ocp-ipi-baremetal-lab/main/.img/ocp-ipi-baremetal-lab.png)

### Prerequisites
* A virtual machine with the below resources:

| CPU | RAM | Storage |
|-----|-----|---------|
| 30 | 120 GB | 300 GB |

* Nested virtualization

![RHEV CPU Pass-through](https://raw.githubusercontent.com/kevydotvinu/disconnectedOCPonKVM/main/.img/passThroughHostCpu.png)

* Custom Fedora CoreOS
  - Either download an ISO image from [here]().
  - Or [build](#build-custom-fedora-coreos) one using the [CoreOs Assembler](https://github.com/coreos/coreos-assembler) with an [ignition](#generate-ignition) file and a [fedora-coreos-config](https://github.com/kevydotvinu/fedora-coreos-config).

### Preparation
```bash
$ coreos-installer install /dev/sda
$ sudo systemctl reboot
$ ssh kni@<IP> (Enter `Kni@123` as password)
$ sudo systemctl reboot
```

### Usage
```bash
oibl help
oibl ssh-pullsecret OCM_TOKEN=<OCM_TOKEN>
oibl install-config RELEASE=stable-4.10
oibl cluster LOGLEVEL=info
```
### Build custom Fedora CoreOS
##### Define a bash alias to run cosa
* See [this](https://github.com/coreos/coreos-assembler/blob/main/docs/building-fcos.md#define-a-bash-alias-to-run-cosa).
##### Initialize
```bash
$ mkdir oibl
$ cd oibl
$ cosa init https://github.com/kevydotvinu/fedora-coreos-config
```
##### Build
```bash
$ make -C src/config generate-iso
```
##### Check the ISO file
```bash
$ find -iname "*.iso" | tail -n 1
```
### Generate ignition
```bash
git clone https://gist.github.com/kevydotvinu/d8442779a1fd6de82fbc81c77047bd41
cd d8442779a1fd6de82fbc81c77047bd41
make
```
