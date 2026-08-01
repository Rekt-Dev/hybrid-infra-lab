# Gracefully powers off the lab (ACPI): the 3-node Ubuntu fleet, then the DC last.
# No pauses, no interaction.
$vbox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

$fleet = @(
    "Ubuntu  Linux Server",
    "Ubuntu  Linux Server Clone1",
    "Ubuntu  Linux Server Clone2"
)
foreach ($vm in $fleet) {
    & $vbox controlvm $vm acpipowerbutton
}

# DC last so it serves the fleet until they're down
& $vbox controlvm "Svr_22_Eval" acpipowerbutton
