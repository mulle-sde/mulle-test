#!/usr/bin/env bash
#
# freebsd-vm.sh - create and manage a FreeBSD test VM under libvirt/KVM.
#
# Uses the official FreeBSD BASIC-CLOUDINIT qcow2 image, so provisioning
# (user, ssh key, hostname) is fully unattended through a NoCloud seed ISO.
# A stable DHCP address is reserved in the libvirt network by MAC.
#
# Typical use:
#   freebsd-vm.sh keygen
#   freebsd-vm.sh create          # fetch + seed + reserve + define + start
#   freebsd-vm.sh wait
#   freebsd-vm.sh ssh
#
# Environment:
#   FREEBSD_VM_NAME        domain name                 (default: freebsd)
#   FREEBSD_VERSION        release, default latest
#   FREEBSD_VM_IP          reserved address            (default: 192.168.122.20)
#   FREEBSD_VM_MAC         MAC address                 (default: 52:54:00:fb:5d:20)
#   FREEBSD_VM_SSH_KEY     private key                 (default: ~/.ssh/id_rsa_vm)
#   FREEBSD_VM_USER        guest user                  (default: vm)
#   FREEBSD_VM_MEMORY      MiB                         (default: 2048)
#   FREEBSD_VM_VCPUS       vcpus                       (default: 2)
#   FREEBSD_VM_DISK_SIZE   disk size                   (default: 20G)
#   FREEBSD_VM_IMAGE_DIR   qcow2 directory             (default: /home/vm/images)
#   FREEBSD_VM_ISO_DIR     seed directory              (default: /home/vm/isos)
#   FREEBSD_VM_NETWORK     libvirt network             (default: default)
#   FREEBSD_VM_WAIT        ssh wait seconds            (default: 300)
#
set -euo pipefail

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${here}/freebsd-common.sh"

usage()
{
   cat <<EOF
Usage: $(basename "$0") [options] <command> [version]

Commands:
   keygen            generate FREEBSD_VM_SSH_KEY if missing
   fetch [version]   download/verify/resize the cloud-init qcow2
   seed              generate the NoCloud seed ISO
   reserve           reserve the MAC->IP mapping in the libvirt network
   hosts             add the /etc/hosts entry (needs sudo)
   create [version]  fetch + seed + reserve + hosts + define + start
   start             start the domain
   stop              gracefully shut down the domain
   destroy           power off the domain
   console           attach to the serial console
   ip                print the guest IP
   wait              wait until ssh answers
   ssh [command...]  run a command over ssh (default: interactive shell)
   status            show domain and disk state
   rm                destroy and undefine (keeps disk + seed)
   purge             like rm but also deletes disk + seed

Options:
   --name <name>     domain name (default: \${FREEBSD_VM_NAME:-freebsd})
   --version <ver>   FreeBSD release (default: latest)
   -h, --help        this help
EOF
}

cfg_name()       { printf '%s\n' "${FREEBSD_VM_NAME:-freebsd}"; }
cfg_user()       { printf '%s\n' "${FREEBSD_VM_USER:-vm}"; }
cfg_ip()         { printf '%s\n' "${FREEBSD_VM_IP:-192.168.122.20}"; }
cfg_mac()        { printf '%s\n' "${FREEBSD_VM_MAC:-52:54:00:fb:5d:20}"; }
cfg_key()        { printf '%s\n' "${FREEBSD_VM_SSH_KEY:-${HOME}/.ssh/id_rsa_vm}"; }
cfg_memory()     { printf '%s\n' "${FREEBSD_VM_MEMORY:-2048}"; }
cfg_vcpus()      { printf '%s\n' "${FREEBSD_VM_VCPUS:-2}"; }
cfg_disk_size()  { printf '%s\n' "${FREEBSD_VM_DISK_SIZE:-20G}"; }
cfg_image_dir()  { printf '%s\n' "${FREEBSD_VM_IMAGE_DIR:-/home/vm/images}"; }
cfg_iso_dir()    { printf '%s\n' "${FREEBSD_VM_ISO_DIR:-/home/vm/isos}"; }
cfg_network()    { printf '%s\n' "${FREEBSD_VM_NETWORK:-default}"; }
cfg_wait()       { printf '%s\n' "${FREEBSD_VM_WAIT:-300}"; }

cfg_disk()       { printf '%s/%s.qcow2\n' "$(cfg_image_dir)" "$(cfg_name)"; }
cfg_seed()       { printf '%s/%s-seed.iso\n' "$(cfg_iso_dir)" "$(cfg_name)"; }

ssh_opts()
{
   printf -- '-i %s -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5' "$(cfg_key)"
}

main()
{
   local name=""
   local version_arg=""
   local command=""

   while [ $# -gt 0 ]
   do
      case "$1" in
         --name)
            [ $# -ge 2 ] || freebsd_fail "--name requires an argument"
            export FREEBSD_VM_NAME="$2"
            shift 2
            ;;
         --version)
            [ $# -ge 2 ] || freebsd_fail "--version requires an argument"
            version_arg="$2"
            shift 2
            ;;
         -h|--help)
            usage
            exit 0
            ;;
         -*)
            freebsd_fail "unknown option \"$1\" (try --help)"
            ;;
         *)
            command="$1"
            shift
            break
            ;;
      esac
   done

   [ -n "${command}" ] || { usage; exit 1; }

   local version
   version="$(freebsd_resolve_version "${version_arg}")"

   case "${command}" in
      keygen)   vm_keygen ;;
      fetch)    vm_fetch "${version}" ;;
      seed)     vm_seed "${version}" ;;
      reserve)  vm_reserve ;;
      hosts)    vm_hosts ;;
      create)   vm_keygen; vm_fetch "${version}"; vm_seed "${version}"; vm_reserve; vm_hosts; vm_define "${version}"; vm_start ;;
      start)    vm_start ;;
      stop)     vm_stop ;;
      destroy)  virsh destroy "$(cfg_name)" ;;
      console)  virsh console "$(cfg_name)" ;;
      ip)       vm_ip ;;
      wait)     vm_wait ;;
      ssh)      shift_args_ssh "$@" ;;
      status)   vm_status ;;
      rm)       vm_rm ;;
      purge)    vm_rm; vm_purge ;;
      *)
         freebsd_fail "unknown command \"${command}\" (try --help)"
         ;;
   esac
}

shift_args_ssh()
{
   local opts
   opts="$(ssh_opts)"
   # shellcheck disable=SC2086
   exec ssh ${opts} "$(cfg_user)@$(cfg_ip)" "$@"
}

vm_keygen()
{
   local key
   key="$(cfg_key)"

   if [ -f "${key}" ] && [ -f "${key}.pub" ]
   then
      return 0
   fi

   freebsd_require ssh-keygen
   freebsd_info "generating ssh key ${key}"
   ssh-keygen -t rsa -b 4096 -N '' -f "${key}"
}

vm_fetch()
{
   local version="$1"
   local url="${FREEBSD_VMIMAGE_INDEX}/${version}/amd64/Latest"
   local image="FreeBSD-${version}-amd64-BASIC-CLOUDINIT-ufs.qcow2"
   local disk
   disk="$(cfg_disk)"

   freebsd_require curl xz sha256sum qemu-img

   mkdir -p "$(cfg_image_dir)"

   if [ -f "${disk}" ]
   then
      freebsd_info "reusing ${disk}"
      return 0
   fi

   freebsd_info "fetching ${image}.xz"
   curl -fL --progress-bar -o "${disk}.xz.part" "${url}/${image}.xz"
   mv "${disk}.xz.part" "${disk}.xz"

   curl -fsSL -o "${disk}.CHECKSUM.part" "${url}/CHECKSUM.SHA256"
   mv "${disk}.CHECKSUM.part" "${disk}.CHECKSUM"
   freebsd_verify_sha256 "${disk}.xz" "${disk}.CHECKSUM" "${image}.xz"

   freebsd_info "decompressing"
   xz -d "${disk}.xz"

   freebsd_info "resizing to $(cfg_disk_size)"
   qemu-img resize "${disk}" "$(cfg_disk_size)"
}

vm_seed()
{
   local version="$1"
   local seed
   local key
   local pubkey
   local tmp

   seed="$(cfg_seed)"
   key="$(cfg_key)"
   pubkey="${key}.pub"

   [ -f "${pubkey}" ] || freebsd_fail "public key ${pubkey} not found (run: keygen)"

   freebsd_require genisoimage

   tmp="$(mktemp -d)"
   trap 'rm -rf "${tmp:-}"' EXIT

   cat > "${tmp}/meta-data" <<EOF
instance-id: $(cfg_name)-${version}
local-hostname: $(cfg_name)
EOF

   cat > "${tmp}/user-data" <<EOF
#cloud-config
hostname: $(cfg_name)
manage_etc_hosts: true
ssh_pwauth: false
disable_root: true
users:
  - name: $(cfg_user)
    gecos: FreeBSD test user
    groups: wheel
    shell: /bin/sh
    lock_passwd: true
    ssh_authorized_keys:
      - $(cat "${pubkey}")
runcmd:
  - [ pkg, install, -y, rsync ]
EOF

   mkdir -p "$(cfg_iso_dir)"
   rm -f "${seed}"
   genisoimage -quiet -output "${seed}" -volid cidata -joliet -rock \
      "${tmp}/meta-data" "${tmp}/user-data"

   freebsd_info "seed written to ${seed}"
}

vm_reserve()
{
   local network
   local desired
   local mac
   local name
   local existing
   local existing_ip

   network="$(cfg_network)"
   desired="$(cfg_ip)"
   mac="$(cfg_mac)"
   name="$(cfg_name)"

   existing="$(virsh net-dumpxml "${network}" 2>/dev/null \
      | grep -oE "host mac='[^']*' name='[^']*' ip='[^']*'" \
      | grep -E "name='${name}'|mac='${mac}'" | head -1 || true)"

   if [ -n "${existing}" ]
   then
      existing_ip="$(printf '%s\n' "${existing}" | sed -n "s/.*ip='\([^']*\)'.*/\1/p")"
      if [ "${existing_ip}" = "${desired}" ]
      then
         freebsd_info "address ${desired} already reserved"
         return 0
      fi
      freebsd_fail "${name}/${mac} is already reserved to ${existing_ip}, not ${desired}"
   fi

   if virsh net-dumpxml "${network}" 2>/dev/null | grep -q "ip='${desired}'"
   then
      freebsd_fail "address ${desired} is already reserved for another host; set FREEBSD_VM_IP"
   fi

   freebsd_info "reserving ${mac} -> ${desired} in network ${network}"
   virsh net-update "${network}" add ip-dhcp-host \
      "<host mac='${mac}' name='${name}' ip='${desired}'/>" --live --config
}

vm_hosts()
{
   local ip
   local name

   ip="$(cfg_ip)"
   name="$(cfg_name)"

   # always remove stale entries for this name, then add the correct one
   if grep -qE "[[:space:]]${name}([[:space:]]|$)" /etc/hosts 2>/dev/null
   then
      freebsd_info "updating ${name} in /etc/hosts"
      sudo sed -i -E "/[[:space:]]${name}([[:space:]]|$)/d" /etc/hosts
   else
      freebsd_info "adding ${name} to /etc/hosts"
   fi

   printf '%s\t%s\n' "${ip}" "${name}" | sudo tee -a /etc/hosts > /dev/null
}

vm_define()
{
   local version="$1"
   local disk
   local seed
   local xml

   disk="$(cfg_disk)"
   seed="$(cfg_seed)"

   [ -f "${disk}" ] || freebsd_fail "no disk ${disk} (run: fetch)"
   [ -f "${seed}" ] || freebsd_fail "no seed ${seed} (run: seed)"

   if virsh dominfo "$(cfg_name)" > /dev/null 2>&1
   then
      freebsd_info "domain $(cfg_name) already defined"
      return 0
   fi

   xml="$(mktemp)"
   trap 'rm -f "${xml:-}"' EXIT

   cat > "${xml}" <<EOF
<domain type='kvm'>
  <name>$(cfg_name)</name>
  <memory unit='MiB'>$(cfg_memory)</memory>
  <currentMemory unit='MiB'>$(cfg_memory)</currentMemory>
  <vcpu placement='static'>$(cfg_vcpus)</vcpu>
  <os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'/>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='${disk}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${seed}'/>
      <target dev='sda' bus='sata'/>
      <readonly/>
    </disk>
    <controller type='sata' index='0'/>
    <interface type='network'>
      <source network='$(cfg_network)'/>
      <mac address='$(cfg_mac)'/>
      <model type='virtio'/>
    </interface>
    <serial type='pty'>
      <target type='isa-serial' port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
  </devices>
</domain>
EOF

   freebsd_info "defining domain $(cfg_name)"
   virsh define "${xml}"
}

vm_start()
{
   if virsh domstate "$(cfg_name)" 2>/dev/null | grep -q "running"
   then
      freebsd_info "$(cfg_name) already running"
      return 0
   fi

   virsh start "$(cfg_name)"
}

vm_stop()
{
   virsh shutdown "$(cfg_name)"
}

vm_ip()
{
   local ip

   ip="$(virsh domifaddr "$(cfg_name)" --source lease 2>/dev/null \
      | awk '/ipv4/ { print $4 }' | cut -d/ -f1 | head -1 || true)"

   [ -n "${ip}" ] || ip="$(cfg_ip)"
   printf '%s\n' "${ip}"
}

vm_wait()
{
   local waited=0
   local limit
   local opts
   local target

   limit="$(cfg_wait)"
   opts="$(ssh_opts)"
   target="$(cfg_user)@$(cfg_ip)"

   freebsd_info "waiting for ${target} (up to ${limit}s)"
   while [ "${waited}" -lt "${limit}" ]
   do
      # shellcheck disable=SC2086
      if ssh ${opts} "${target}" true 2>/dev/null
      then
         freebsd_info "${target} is up after ${waited}s"
         return 0
      fi
      sleep 5
      waited=$(( waited + 5 ))
   done

   freebsd_fail "timed out waiting for ${target}"
}

vm_status()
{
   virsh dominfo "$(cfg_name)" 2>/dev/null || freebsd_info "domain $(cfg_name) is not defined"
   if [ -f "$(cfg_disk)" ]
   then
      qemu-img info "$(cfg_disk)"
   fi
}

vm_rm()
{
   if virsh dominfo "$(cfg_name)" > /dev/null 2>&1
   then
      virsh destroy "$(cfg_name)" 2>/dev/null || true
      virsh undefine "$(cfg_name)" --nvram 2>/dev/null || virsh undefine "$(cfg_name)" || true
      freebsd_info "domain $(cfg_name) removed"
   fi
}

vm_purge()
{
   rm -f "$(cfg_disk)" "$(cfg_seed)"
   freebsd_info "disk and seed removed"
}

main "$@"
