SHELL=/bin/bash
DIR=$(shell pwd)
ORANGE=\e[0;33m
NOCOLOR=\e[0m
IGNITION_DIR=${DIR}/ignition
OSTREE_IMAGE?=quay.io/oibl/oibl:develop
REGISTRY=$(shell echo ${OSTREE_IMAGE} | cut -d/ -f1)
RELEASEVER=$(shell curl -s https://raw.githubusercontent.com/coreos/fedora-coreos-config/testing-devel/manifest.yaml | grep releasever:)

check-regcred:
ifndef REGUSER
	$(error REGUSER is undefined)
endif
ifndef REGPASS
	$(error REGPASS is undefined)
endif

.PHONY: generate-ignition

generate-ignition:
	@echo -e "${ORANGE}Generating 00-core.ign file ...${NOCOLOR}"
	podman run --interactive --rm quay.io/coreos/butane:release --pretty --strict < ${IGNITION_DIR}/00-core.bu > ${IGNITION_DIR}/00-core.ign

.PHONY: update-repo

update-repo:
	@echo -e "${ORANGE}Updating submodule ...${NOCOLOR}"
	git submodule update --remote
	@echo -e "${ORANGE}Removing linked & copied files ...${NOCOLOR}"
	rm -rvf manifest-lock* \
		fedora.repo \
		fedora-coreos-pool.repo \
		image.yaml \
		image-base.yaml \
		manifests \
		overlay.d \
		live \
		platforms.yaml
	@echo -e "${ORANGE}Linking manifest-lock*,image.yaml,image-base.yaml & live ...${NOCOLOR}"
	ln -svf fedora-coreos-config/manifest-lock* \
		fedora-coreos-config/image.yaml \
		fedora-coreos-config/image-base.yaml \
		fedora-coreos-config/live \
		fedora-coreos-config/platforms.yaml \
		.
	@echo -e "${ORANGE}Copying fedora.repo & fedora-coreos-pool.repo ...${NOCOLOR}"
	cp -rvf fedora-coreos-config/fedora.repo \
		fedora-coreos-config/fedora-coreos-pool.repo \
		.
	@echo -e "${ORANGE}Linking and copying files from manifests ...${NOCOLOR}"
	mkdir manifests && \
		pushd manifests && \
		ln -svf ../fedora-coreos-config/manifests/* . && \
		rm -rvf fedora-coreos.yaml && \
		cp -rvf ../fedora-coreos-config/manifests/fedora-coreos.yaml \
		fedora-coreos.yaml && \
		popd
	@echo -e "${ORANGE}Linking files from overlay.d ...${NOCOLOR}"
	mkdir overlay.d && \
		pushd overlay.d && \
		ln -svf ../fedora-coreos-config/overlay.d/* . && \
		popd
	@echo -e "${ORANGE}Patching manifest.yaml with releasever ...${NOCOLOR}"
	sed -i "s/releasever.*/${RELEASEVER}/" manifest.yaml
	@echo -e "${ORANGE}Including python3 and python3-libs in manifests/fedora-coreos.yaml ...${NOCOLOR}"
	sed -i 's/^  - python3/#&/' manifests/fedora-coreos.yaml

.PHONY: cosa-init

cosa-init:
	@echo -e "${ORANGE}Initializing CoreOS assembler ...${NOCOLOR}"
	-rm -rf ../cosa
	mkdir ../cosa
	source ${DIR}/env && \
		pushd ../cosa && \
		unset COREOS_ASSEMBLER_CONFIG_GIT && \
		cosa init https://github.com/kevydotvinu/ocp-ipi-baremetal-lab && \
		popd

.PHONY: cosa-run

cosa-run:
	@echo -e "${ORANGE}Building and running FCOS image ...${NOCOLOR}"
	source ${DIR}/env && \
		pushd ../cosa && \
		COREOS_ASSEMBLER_CONFIG_GIT=${DIR} && \
		cosa fetch && \
		cosa build && \
		cosa run && \
		popd

.PHONY: build-ostree

build-ostree:
	@echo -e "${ORANGE}Building ostree container image ...${NOCOLOR}"
	source ${DIR}/env && \
		pushd ../cosa && \
		COREOS_ASSEMBLER_CONFIG_GIT=${DIR} && \
		cosa fetch && \
		cosa build ostree && \
		popd

.PHONY: push-ostree

push-ostree: check-regcred
	@echo -e "${ORANGE}Pushing ostree container image ...${NOCOLOR}"
	source ${DIR}/env && \
		pushd ../cosa && \
		COREOS_ASSEMBLER_CONFIG_GIT=${DIR} && \
		echo "Logging in ${REGISTRY} ..." && \
		podman login --authfile auth.json --username=${REGUSER} --password=${REGPASS} ${REGISTRY} && \
		cosa push-container --authfile auth.json --format oci ${OSTREE_IMAGE} && \
		popd

.PHONY: build-push-ostree

build-push-ostree: check-regcred update-repo cosa-init build-ostree push-ostree
