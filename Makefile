SHELL=/bin/bash
DIR=$(shell pwd)
IGNITION_DIR=${DIR}/ignition
OSTREE_IMAGE?=docker.io/kevydotvinu/oibl-ostree

.PHONY: generate-ignition

generate-ignition:
	@echo -e "\e[0;33m" >&2
	@echo "Generating 00-core.ign file ..."
	@echo -e "\e[0m" >&2
	podman run --interactive --rm quay.io/coreos/butane:release --pretty --strict < ${IGNITION_DIR}/00-core.bu > ${IGNITION_DIR}/00-core.ign

.PHONY: cosa-init

cosa-init:
	@echo -e "\e[0;33m" >&2
	@echo "Initializing CoreOS assembler ..."
	@echo -e "\e[0m" >&2
	-rm -rf ../cosa
	mkdir ../cosa
	source ${DIR}/env && pushd ../cosa && unset COREOS_ASSEMBLER_CONFIG_GIT && cosa init https://github.com/kevydotvinu/ocp-ipi-baremetal-lab && popd

.PHONY: build-ostree

build-ostree:
	@echo -e "\e[0;33m" >&2
	@echo "Building ostree container image ..."
	@echo -e "\e[0m" >&2
	source ${DIR}/env && pushd ../cosa && COREOS_ASSEMBLER_CONFIG_GIT=${DIR} && cosa fetch && cosa build ostree && popd

.PHONY: push-ostree

push-ostree:
	@echo -e "\e[0;33m" >&2
	@echo "Pushing ostree container image ..."
	@echo -e "\e[0m" >&2
	source ${DIR}/env && pushd ../cosa && COREOS_ASSEMBLER_CONFIG_GIT=${DIR} && cosa push-container --authfile /srv/src/config/auth.json --format oci --base-image-name docker.io/kevydotvinu/oibl-ostree && popd

.PHONY: build-push-ostree

build-push-ostree: cosa-init build-ostree push-ostree
