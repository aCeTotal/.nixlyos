# GENERERT av scripts/detect-hw.sh — ikke rediger manuelt.
# Bus-IDer er DESIMAL (PCI:bus@domain:device:function), slik
# hardware.nvidia.prime.*BusId krever. Tom streng = ingen slik GPU.
{
  nvidia = "PCI:1@0:0:0";
  intel = "";
  amd = "";

  # NVIDIA-arkitektur fra PCI-device-ID, og driver-branchen den trenger.
  nvidiaArch = "turing_plus";
  nvidiaBranch = "latest";
}
