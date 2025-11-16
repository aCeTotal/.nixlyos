{ lib, pkgs, ... }:

let
  domainName = "win11-rdp";
  diskPath = "/var/lib/libvirt/images/${domainName}.qcow2";
  nvramPath = "/var/lib/libvirt/qemu/nvram/${domainName}_VARS.fd";
  # Default disk size
  diskSize = "200G";

  domainXML = ''
    <domain type='kvm'>
      <name>${domainName}</name>
      <memory unit='MiB'>6000</memory>
      <currentMemory unit='MiB'>600</currentMemory>
      <vcpu placement='static'>3</vcpu>
      <cpu mode='host-passthrough' check='none'>
        <topology sockets='1' dies='1' cores='3' threads='1'/>
      </cpu>
      <os>
        <type arch='x86_64' machine='q35'>hvm</type>
        <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
        <nvram>${nvramPath}</nvram>
      </os>
      <features>
        <acpi/>
        <apic/>
        <hyperv>
          <relaxed state='on'/>
          <vapic state='on'/>
          <spinlocks state='on' retries='8191'/>
        </hyperv>
      </features>
      <clock offset='localtime'/>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <devices>
        <!-- System disk -->
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2' cache='none'/>
          <source file='${diskPath}'/>
          <target dev='vda' bus='virtio'/>
        </disk>
        <!-- Ensure SATA bus exists for attaching CD/DVD drives in virt-manager -->
        <controller type='sata' index='0'/>
        <!-- Attach Windows ISO in virt-manager (CDROM) before install -->
        <controller type='usb' model='qemu-xhci'/>
        <input type='tablet' bus='usb'/>
        <interface type='network'>
          <source network='default'/>
          <model type='virtio'/>
        </interface>
        <graphics type='spice' autoport='yes' listen='127.0.0.1'>
          <listen type='address' address='127.0.0.1'/>
        </graphics>
        <video>
          <model type='virtio' heads='1'/>
        </video>
        <rng model='virtio'>
          <backend model='random'>/dev/urandom</backend>
        </rng>
        <tpm model='tpm-tis'>
          <backend type='emulator' version='2.0'/>
        </tpm>
        <memballoon model='virtio'/>
        <channel type='spicevmc'>
          <target type='virtio' name='com.redhat.spice.0'/>
        </channel>
      </devices>
      <memtune>
        <min_guarantee unit='MiB'>600</min_guarantee>
      </memtune>
    </domain>
  '';

  netDefaultXML = ''
    <network>
      <name>default</name>
      <forward mode='nat'/>
      <bridge name='virbr0' stp='on' delay='0'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.122.2' end='192.168.122.254'/>
        </dhcp>
      </ip>
    </network>
  '';
in
{
  # Provide XMLs under /etc for virsh define
  environment.etc = {
    "libvirt/${domainName}.xml".text = domainXML;
    "libvirt/net-default.xml".text = netDefaultXML;
  };

  # Ensure default NAT network exists and is started (qemu:///system)
  systemd.services.libvirt-ensure-default-net = {
    description = "Ensure libvirt default NAT network defined and started";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''
        ${pkgs.bash}/bin/bash -euo pipefail -c '
          if ! ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-info default >/dev/null 2>&1; then
            ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-define /etc/libvirt/net-default.xml
            ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-autostart default
          fi
          ${pkgs.libvirt}/bin/virsh --connect qemu:///system net-start default >/dev/null 2>&1 || true
        '
      '';
    };
  };

  # Create disk/NVRAM and define the VM in qemu:///system so it shows in virt-manager
  systemd.services."define-${domainName}" = {
    description = "Define libvirt domain ${domainName} (qemu:///system)";
    after = [ "libvirtd.service" "libvirt-ensure-default-net.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p /var/lib/libvirt/images /var/lib/libvirt/qemu/nvram"
        "${pkgs.bash}/bin/bash -euo pipefail -c 'if [ ! -f ${diskPath} ]; then ${pkgs.qemu}/bin/qemu-img create -f qcow2 ${diskPath} ${diskSize}; else ${pkgs.qemu}/bin/qemu-img resize -f qcow2 ${diskPath} ${diskSize}; fi'"
        "${pkgs.bash}/bin/bash -euo pipefail -c 'test -f ${nvramPath} || ${pkgs.coreutils}/bin/cp /run/libvirt/nix-ovmf/OVMF_VARS.fd ${nvramPath}'"
      ];
      ExecStart = ''
        ${pkgs.bash}/bin/bash -euo pipefail -c '
          if ! ${pkgs.libvirt}/bin/virsh --connect qemu:///system dominfo ${domainName} >/dev/null 2>&1; then
            ${pkgs.libvirt}/bin/virsh --connect qemu:///system define /etc/libvirt/${domainName}.xml
          fi
        '
      '';
    };
  };
}
