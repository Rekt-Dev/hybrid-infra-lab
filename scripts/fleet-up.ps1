# Powers up the lab headless: DC first (DNS/AD/DHCP), then the 3-node Ubuntu fleet.
# No pauses, no interaction.
$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# DC first so DNS/AD is serving before the fleet comes up
$dc = "Svr_22_Eval"
& $vbox startvm $dc --type headless

$fleet = @(
    "Ubuntu  Linux Server",
    "Ubuntu  Linux Server Clone1",
    "Ubuntu  Linux Server Clone2"
)
foreach ($vm in $fleet) {
    & $vbox startvm $vm --type headless
}
