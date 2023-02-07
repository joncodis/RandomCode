######################
#   App Functions
######################
function ConnectVIServer() {
    $choice = $dropDownVCList.SelectedItem.ToString()
    $Cred = Get-Credential -Message "Login $env:UserName..." -User "administrator@homenet.local"
    try {
            $viServer = Connect-VIServer $choice -User $Cred.UserName -Password $Cred.GetNetworkCredential().Password            
            if ($viServer -eq $null) { return }
                $button1.Enabled = $false
                ShowCloningOpts
        }
    catch
        {
            Write-Host -ForegroundColor Red "Exception: $_"
        }
}
function PickVcenter() {
    # Text label for vCenter selection
    $dropDownLabel = New-Object System.Windows.Forms.Label
    $dropDownLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
    $dropDownLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    $dropDownLabel.Location = New-Object System.Drawing.Size(8,32)
    $dropDownLabel.Size = New-Object System.Drawing.Size(115, 16)
    $dropDownLabel.Text = "vCenter Server :"
    $form.Controls.Add($dropDownLabel)
    # Dropdown list for vCenter names
    $dropDownVCList = New-Object System.Windows.Forms.ComboBox
    $dropDownVCList.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $dropDownVCList.Location = New-Object System.Drawing.Size(124,30)
    $dropDownVCList.Size = New-Object System.Drawing.Size(300,20)
    $dropDownVCList.Items.Add("vcenter.home.net")
    $dropDownVCList.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropDownList
    $dropDownVCList.SelectedItem = $dropDownVCList.Items[0]
    $form.Controls.Add($dropDownVCList)
    # Connect button
    $button1 = New-Object System.Windows.Forms.Button
    $button1.Location = New-Object System.Drawing.Size(430, 30)
    $button1.Size = New-Object System.Drawing.Size(80, 20)
    $button1.Text = "Connect"
    $button1.Add_Click({ConnectVIServer})
    $form.Controls.Add($button1)
    $form.AcceptButton = $button1
    # Close button
    $button2 = new-object windows.forms.button
    $button2.Location = New-Object System.Drawing.Size(515, 30)
    $button2.Size = New-Object System.Drawing.Size(80, 20)
    $button2.text = "Close"
    $button2.add_click({$form.close()})
    $form.Controls.Add($button2)
    $form.CancelButton = $button2
    # Dialog title name of GUI Form, and size of form
    $form.Text = "VM Cloner"
    $form.minimumSize = $mainFormSize
    $form.maximumSize = $mainFormSize
    $form.Size = $mainFormSize
    $form.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
    $form.ShowDialog()
}
function ShowCloningOpts() {
    # Listbox of VMs returned
    $listBoxTmplsLabel = New-Object System.Windows.Forms.Label
    $listBoxTmplsLabel.Size = New-Object System.Drawing.Size(200, 16)
    $listBoxTmplsLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $listBoxTmplsLabel.ForeColor = [System.Drawing.Color]::DarkRed
    $listBoxTmplsLabel.Location = New-Object System.Drawing.Size(10,85)
    $listBoxTmplsLabel.Text = "Select VM Template"
    $form.Controls.Add($listBoxTmplsLabel)
    $listBoxTmpls.Location = New-Object System.Drawing.Size(10,105)
    $listBoxTmpls.Size = New-Object System.Drawing.Size(250,20)    
    $listBoxTmpls.Height = $global:mainFormHeight - 145
    Get-Template | % {
        $listBoxTmpls.Items.Add($_.Name)
    }
    $listBoxTmpls.Sorted = $true
    $listBoxTmpls.add_SelectedIndexChanged({TemplSelected})
    $form.Controls.Add($listBoxTmpls)
    # Datastore list box
    $listBoxDSLabel = New-Object System.Windows.Forms.Label
    $listBoxDSLabel.Size = New-Object System.Drawing.Size(200, 16)
    $listBoxDSLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $listBoxDSLabel.ForeColor = [System.Drawing.Color]::DarkRed
    $listBoxDSLabel.Location = New-Object System.Drawing.Size(266,85)
    $listBoxDSLabel.Text = "Select Datastore"
    $form.Controls.Add($listBoxDSLabel)
    $listBoxDS.Location = New-Object System.Drawing.Size(268,105)
    $listBoxDS.Size = New-Object System.Drawing.Size(250,20)
    $listBoxDS.Height = $global:mainFormHeight - 145
    Get-DataStore | % {
        $freeGB = [string]::Format("{0:#,##0}", $_.FreeSpaceGB)
        $listBoxDS.Items.Add("$($_.Name) | $freeGB GB Free")
    }
    $form.Controls.Add($listBoxDS)
    $listBoxDS.Sorted = $true
    # Host list box
    $listBoxHostLabel = New-Object System.Windows.Forms.Label
    $listBoxHostLabel.Size = New-Object System.Drawing.Size(200, 16)
    $listBoxHostLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $listBoxHostLabel.ForeColor = [System.Drawing.Color]::DarkRed
    $listBoxHostLabel.Location = New-Object System.Drawing.Size(526,85)
    $listBoxHostLabel.Text = "Select Target Host"
    $form.Controls.Add($listBoxHostLabel)
    $listBoxHost.Location = New-Object System.Drawing.Size(528,105)
    $listBoxHost.Size = New-Object System.Drawing.Size(250,20)
    $listBoxHost.Height = $global:mainFormHeight - 145
    Get-VMHost | % {
        $memoryTotalMB = $_.MemoryTotalMB
        $memoryUsageMB = $_.MemoryUsageMB
        $memoryFreeMB = $_.MemoryTotalMB - $_.MemoryUsageMB
        $memoryFreePerc = 0.0
        try { $memoryFreePerc = $memoryFreeMB / $memoryTotalMB}
        catch { }
        $freeMB = [string]::Format("{0:#,##0.0%}", $memoryFreePerc)
        $listBoxHost.Items.Add("$($_.Name) | $freeMB Free")
    }
    $form.Controls.Add($listBoxHost)
    $listBoxHost.Sorted = $true
    # Output message area
    $OutputLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 9, [System.Drawing.FontStyle]::Regular)
    $OutputLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    $OutputLabel.BorderStyle = 2
    $OutputLabel.Padding = 5
    $OutputLabel.Location = New-Object System.Drawing.Size(670, 5)
    $OutputLabel.Size = New-Object System.Drawing.Size(400, 70)
    $OutputLabel.Visible = $false
    $form.Controls.Add($OutputLabel)
    # New Virtual Machine name
    $newNameLabel = New-Object System.Windows.Forms.Label
    $newNameLabel.Size = New-Object System.Drawing.Size(200, 16)
    $newNameLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $newNameLabel.ForeColor = [System.Drawing.Color]::DarkRed
    $newNameLabel.Location = New-Object System.Drawing.Size(784, 104)
    $newNameLabel.Text = "New VM Name"
    $form.Controls.Add($newNameLabel)
    $txtBoxNewName.Location = New-Object System.Drawing.Size(786, 122)
    $txtBoxNewName.Size = New-Object System.Drawing.Size(275, 25)
    $form.Controls.Add($txtBoxNewName)
    # Num CPUs
    $numCPULabel = New-Object System.Windows.Forms.Label
    $numCPULabel.Size = New-Object System.Drawing.Size(200, 16)
    $numCPULabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $numCPULabel.ForeColor = [System.Drawing.Color]::DarkRed
    $numCPULabel.Location = New-Object System.Drawing.Size(784, 145)
    $numCPULabel.Text = "Number of CPUs"
    $form.Controls.Add($numCPULabel)
    $dropDownNumCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $dropDownNumCPU.Location = New-Object System.Drawing.Size(786, 163)
    $dropDownNumCPU.Size = New-Object System.Drawing.Size(65, 15)
    $dropDownNumCPU.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropDownList
    $dropDownNumCPU.Items.Add("      2")
    $dropDownNumCPU.Items.Add("      4")
    $dropDownNumCPU.Items.Add("      6")
    $dropDownNumCPU.Items.Add("      8")
    $dropDownNumCPU.Items.Add("     10")
    $dropDownNumCPU.Items.Add("     12")
    $dropDownNumCPU.Items.Add("     14")
    $dropDownNumCPU.Items.Add("     16")
    $dropDownNumCPU.SelectedItem = $dropDownNumCPU.Items[0]
    $form.Controls.Add($dropDownNumCPU)
    # Memory Size
    $memSizeLabel = New-Object System.Windows.Forms.Label
    $memSizeLabel.Size = New-Object System.Drawing.Size(200, 16)
    $memSizeLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $memSizeLabel.ForeColor = [System.Drawing.Color]::DarkRed
    $memSizeLabel.Location = New-Object System.Drawing.Size(784, 188)
    $memSizeLabel.Text = "Memory Size (GB)"
    $form.Controls.Add($memSizeLabel)
    $dropDownMemSz.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $dropDownMemSz.Location = New-Object System.Drawing.Size(786, 206)
    $dropDownMemSz.Size = New-Object System.Drawing.Size(65, 15)
    $dropDownMemSz.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropDownList
    $dropDownMemSz.Items.Add("      1")
    $dropDownMemSz.Items.Add("      2")
    $dropDownMemSz.Items.Add("      4")
    $dropDownMemSz.Items.Add("      6")
    $dropDownMemSz.Items.Add("      8")
    $dropDownMemSz.Items.Add("     10")
    $dropDownMemSz.Items.Add("     12")
    $dropDownMemSz.Items.Add("     14")
    $dropDownMemSz.Items.Add("     16")
    $dropDownMemSz.Items.Add("     18")
    $dropDownMemSz.Items.Add("     20")
    $dropDownMemSz.Items.Add("     22")
    $dropDownMemSz.Items.Add("     24")
    $dropDownMemSz.Items.Add("     26")
    $dropDownMemSz.Items.Add("     28")
    $dropDownMemSz.Items.Add("     30")
    $dropDownMemSz.SelectedItem = $dropDownMemSz.Items[1]
    $form.Controls.Add($dropDownMemSz)
    # HDD Size
    $hddSizeLabel = New-Object System.Windows.Forms.Label
    $hddSizeLabel.Size = New-Object System.Drawing.Size(200, 16)
    $hddSizeLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $hddSizeLabel.ForeColor = [System.Drawing.Color]::DarkRed
    $hddSizeLabel.Location = New-Object System.Drawing.Size(784, 231)
    $hddSizeLabel.Text = "Disk 1 Size (GB)"
    $form.Controls.Add($hddSizeLabel)
    $dropDownHddSz.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $dropDownHddSz.Location = New-Object System.Drawing.Size(786, 249)
    $dropDownHddSz.Size = New-Object System.Drawing.Size(65, 15)
    $dropDownHddSz.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropDownList
    $dropDownHddSz.Items.Add("     40")
    $dropDownHddSz.Items.Add("     60")
    $dropDownHddSz.Items.Add("     80")
    $dropDownHddSz.Items.Add("    100")
    $dropDownHddSz.Items.Add("    150")
    $dropDownHddSz.Items.Add("    200")
    $dropDownHddSz.Items.Add("    250")
    $dropDownHddSz.Items.Add("    300")
    $dropDownHddSz.Items.Add("    350")
    $dropDownHddSz.Items.Add("    400")
    $dropDownHddSz.Items.Add("    450")
    $dropDownHddSz.Items.Add("    500")
    $dropDownHddSz.Items.Add("    550")
    $dropDownHddSz.Items.Add("    600")
    $dropDownHddSz.Items.Add("    650")
    $dropDownHddSz.Items.Add("    700")
    $dropDownHddSz.Items.Add("    750")
    $dropDownHddSz.Items.Add("    800")
    $dropDownHddSz.Items.Add("    850")
    $dropDownHddSz.Items.Add("    900")
    $dropDownHddSz.Items.Add("    950")
    $dropDownHddSz.Items.Add("   1000")
    $dropDownHddSz.Items.Add("   1500")
    $dropDownHddSz.Items.Add("   2000")
    $dropDownHddSz.Items.Add("   2500")
    $dropDownHddSz.Items.Add("   3000")
    $dropDownHddSz.Items.Add("   3500")
    $dropDownHddSz.SelectedItem = $dropDownHddSz.Items[0]
    $form.Controls.Add($dropDownHddSz)
    # Hostname
    $staticHostNmLabel.Size = New-Object System.Drawing.Size(120, 16)
    $staticHostNmLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $staticHostNmLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
    $staticHostNmLabel.Location = New-Object System.Drawing.Size(784, 275)
    $staticHostNmLabel.Text = "Custom Hostname"
    $form.Controls.Add($staticHostNmLabel)
    $chkBoxStaticHostNm.Location = New-Object System.Drawing.Size(906, 273)
    $chkBoxStaticHostNm.Size = New-Object System.Drawing.Size(15, 20)
    $chkBoxStaticHostNm.Add_Click({ToggleStaticHN})
    $form.Controls.Add($chkBoxStaticHostNm)
    $txtBoxStaticHN.Location = New-Object System.Drawing.Size(786, 292)
    $txtBoxStaticHN.Size = New-Object System.Drawing.Size(135, 25)    
    $txtBoxStaticHN.Text = "Based on VM Name"
    $txtBoxStaticHN.Enabled = $false
    $txtBoxStaticHN.ForeColor = [System.Drawing.Color]::DarkBlue
    $form.Controls.Add($txtBoxStaticHN)
    # VDPortGroup
    $vdPortGrpLabel = New-Object System.Windows.Forms.Label
    $vdPortGrpLabel.Size = New-Object System.Drawing.Size(200, 16)
    $vdPortGrpLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $vdPortGrpLabel.ForeColor = [System.Drawing.Color]::DarkRed
    $vdPortGrpLabel.Location = New-Object System.Drawing.Size(784, 316)
    $vdPortGrpLabel.Text = "Network Adapter 1 - Network"
    $form.Controls.Add($vdPortGrpLabel)
    $dropDownvdPortGrp.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $dropDownvdPortGrp.Location = New-Object System.Drawing.Size(786, 333)
    $dropDownvdPortGrp.Size = New-Object System.Drawing.Size(275, 15)
    $dropDownvdPortGrp.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropDownList
    $dropDownvdPortGrp.Items.Add("      --  No Changes from Template  --")
    Get-VirtualPortGroup | Sort-Object | Get-Unique | %  {
        $dropDownvdPortGrp.Items.Add($_.Name)
    }
    $dropDownvdPortGrp.SelectedItem = $dropDownvdPortGrp.Items[0]
    $dropDownvdPortGrp.Add_SelectedIndexChanged({VPG_Changed})
    $dropDownvdPortGrp.Enabled = $false;
    $form.Controls.Add($dropDownvdPortGrp)
    # Static IP - IP Addr
    $staticIpLabel.Size = New-Object System.Drawing.Size(115, 16)
    $staticIpLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $staticIpLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
    $staticIpLabel.Location = New-Object System.Drawing.Size(784, 360)
    $staticIpLabel.Text = "Static IP Address"
    $form.Controls.Add($staticIpLabel)
    $chkBoxStaticIp.Location = New-Object System.Drawing.Size(906,357)
    $chkBoxStaticIp.Size = New-Object System.Drawing.Size(15, 20)
    $chkBoxStaticIp.Add_Click({ToggleStaticIP})
    $chkBoxStaticIp.Enabled = $false
    $form.Controls.Add($chkBoxStaticIp)
    $txtBoxStaticIp.Location = New-Object System.Drawing.Size(786, 376)
    $txtBoxStaticIp.Size = New-Object System.Drawing.Size(135, 25)
    $txtBoxStaticIp.Enabled = $false
    $form.Controls.Add($txtBoxStaticIp)
    # Static IP - Mask
    $staticMaskLabel.Size = New-Object System.Drawing.Size(115, 16)
    $staticMaskLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $staticMaskLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
    $staticMaskLabel.Location = New-Object System.Drawing.Size(784, 400)
    $staticMaskLabel.Text = "Subnet Mask"
    $form.Controls.Add($staticMaskLabel)
    $txtBoxStaticMask.Location = New-Object System.Drawing.Size(786, 416)
    $txtBoxStaticMask.Size = New-Object System.Drawing.Size(135, 25)
    $txtBoxStaticMask.Enabled = $false
    $form.Controls.Add($txtBoxStaticMask)
    #Static IP - Gateway
    $staticGWLabel.Size = New-Object System.Drawing.Size(115, 16)
    $staticGWLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $staticGWLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
    $staticGWLabel.Location = New-Object System.Drawing.Size(784, 440)
    $staticGWLabel.Text = "Default Gateway"
    $form.Controls.Add($staticGWLabel)
    $txtBoxStaticGW.Location = New-Object System.Drawing.Size(786, 456)
    $txtBoxStaticGW.Size = New-Object System.Drawing.Size(135, 25)
    $txtBoxStaticGW.Enabled = $false
    $form.Controls.Add($txtBoxStaticGW)
    # Static IP - DNS
    $staticDNSLabel.Size = New-Object System.Drawing.Size(115, 16)
    $staticDNSLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $staticDNSLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
    $staticDNSLabel.Location = New-Object System.Drawing.Size(784, 480)
    $staticDNSLabel.Text = "DNS Server(s)"
    $form.Controls.Add($staticDNSLabel)
    $txtBoxStaticDNS.Location = New-Object System.Drawing.Size(786, 496)
    $txtBoxStaticDNS.Size = New-Object System.Drawing.Size(275, 25)
    $txtBoxStaticDNS.Enabled = $false
    $form.Controls.Add($txtBoxStaticDNS)
    # Additional Disk(s)
    $hdd2SizeLabel.Size = New-Object System.Drawing.Size(95, 16)
    $hdd2SizeLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $hdd2SizeLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
    $hdd2SizeLabel.Location = New-Object System.Drawing.Size(784, 520)
    $hdd2SizeLabel.Text = "Add Disk (GB)"
    $form.Controls.Add($hdd2SizeLabel)
    $hdd2NumLabel.Size = New-Object System.Drawing.Size(60, 16)
    $hdd2NumLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $hdd2NumLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
    $hdd2NumLabel.Location = New-Object System.Drawing.Size(880, 520)
    $hdd2NumLabel.Text = "Quantity"
    $form.Controls.Add($hdd2NumLabel)
    $chkBoxAddHDD.Location = New-Object System.Drawing.Size(946, 518)
    $chkBoxAddHDD.Size = New-Object System.Drawing.Size(15, 20)
    $chkBoxAddHDD.Add_Click({ToggleAddDisk})
    $form.Controls.Add($chkBoxAddHDD)
    $dropDownHdd2Sz.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $dropDownHdd2Sz.Location = New-Object System.Drawing.Size(784, 538)
    $dropDownHdd2Sz.Size = New-Object System.Drawing.Size(80, 15)
    $dropDownHdd2Sz.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropDownList
    $dropDownHdd2Sz.Items.Add("        40")
    $dropDownHdd2Sz.Items.Add("        60")
    $dropDownHdd2Sz.Items.Add("        80")
    $dropDownHdd2Sz.Items.Add("       100")
    $dropDownHdd2Sz.Items.Add("       150")
    $dropDownHdd2Sz.Items.Add("       200")
    $dropDownHdd2Sz.Items.Add("       250")
    $dropDownHdd2Sz.Items.Add("       300")
    $dropDownHdd2Sz.Items.Add("       350")
    $dropDownHdd2Sz.Items.Add("       400")
    $dropDownHdd2Sz.Items.Add("       450")
    $dropDownHdd2Sz.Items.Add("       500")
    $dropDownHdd2Sz.Items.Add("       550")
    $dropDownHdd2Sz.Items.Add("       600")
    $dropDownHdd2Sz.Items.Add("       650")
    $dropDownHdd2Sz.Items.Add("       700")
    $dropDownHdd2Sz.Items.Add("       750")
    $dropDownHdd2Sz.Items.Add("       800")
    $dropDownHdd2Sz.Items.Add("       850")
    $dropDownHdd2Sz.Items.Add("       900")
    $dropDownHdd2Sz.Items.Add("       950")
    $dropDownHdd2Sz.Items.Add("      1000")
    $dropDownHdd2Sz.Items.Add("      1500")
    $dropDownHdd2Sz.Items.Add("      2000")
    $dropDownHdd2Sz.Items.Add("      2500")
    $dropDownHdd2Sz.Items.Add("      3000")
    $dropDownHdd2Sz.Items.Add("      3500")
    $dropDownHdd2Sz.SelectedItem = $dropDownHdd2Sz.Items[3]
    $dropDownHdd2Sz.Enabled = $false
    $form.Controls.Add($dropDownHdd2Sz)
    $dropDownHdd2Cnt.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10, [System.Drawing.FontStyle]::Regular)
    $dropDownHdd2Cnt.Location = New-Object System.Drawing.Size(880, 538)
    $dropDownHdd2Cnt.Size = New-Object System.Drawing.Size(80, 15)
    $dropDownHdd2Cnt.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::dropDownList
    $dropDownHdd2Cnt.Items.Add("         1")
    $dropDownHdd2Cnt.Items.Add("         2")
    $dropDownHdd2Cnt.Items.Add("         3")
    $dropDownHdd2Cnt.Items.Add("         4")
    $dropDownHdd2Cnt.Items.Add("         5")
    $dropDownHdd2Cnt.SelectedItem = $dropDownHdd2Cnt.Items[0]
    $dropDownHdd2Cnt.Enabled = $false
    $form.Controls.Add($dropDownHdd2Cnt)
    #Clone button
    $cloneButton = New-Object System.Windows.Forms.Button
    $cloneButton.Location = New-Object System.Drawing.Size(984, 582)
    $cloneButton.Size = New-Object System.Drawing.Size(90, 25)
    $cloneButton.Text = "Start Cloning"
    $cloneButton.Add_Click({ CloneVM })
    $form.Controls.Add($cloneButton)
}
function ToggleStaticIP() {
    if ($chkBoxStaticIp.Checked) {
        $staticIpLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $staticMaskLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $staticGWLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $staticDNSLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $txtBoxStaticIp.Enabled = $true
        $txtBoxStaticMask.Enabled = $true
        $txtBoxStaticGW.Enabled = $true
        $txtBoxStaticDNS.Enabled = $true
        if ($dropDownvdPortGrp.SelectedIndex -eq 0) {
            if ( $global:NetworkParams.$global:templateNetNm[0] -eq $null) {
                FillStaticEntries($null)
            } else {
                FillStaticEntries($global:templateNetNm)
            }
        } else {
            $myitem = $dropDownvdPortGrp.SelectedItem.ToString()
            if ( $global:NetworkParams."$myitem"[0] -eq $null) {
                FillStaticEntries($null)
            } else {
                FillStaticEntries($myitem)
            }
        }
    } else {
        $staticIpLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
        $staticMaskLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
        $staticGWLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
        $staticDNSLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
        $txtBoxStaticIp.Text = ""
        $txtBoxStaticIp.Enabled = $false
        $txtBoxStaticMask.Text = ""
        $txtBoxStaticMask.Enabled = $false
        $txtBoxStaticGW.Text = ""
        $txtBoxStaticGW.Enabled = $false
        $txtBoxStaticDNS.Text = ""
        $txtBoxStaticDNS.Enabled = $false
    }
}
function FillStaticEntries($LookupVal) {
    if ($LookupVal -eq $null) {
        $txtBoxStaticIp.Text = ""
        $txtBoxStaticMask.Text = ""
        $txtBoxStaticGW.Text = ""
        $txtBoxStaticDNS.Text = ""
    } else {
        $txtBoxStaticIp.Text = $global:NetworkParams.$LookupVal[0]
        $txtBoxStaticMask.Text = $global:NetworkParams.$LookupVal[1]
        $txtBoxStaticGW.Text = $global:NetworkParams.$LookupVal[2]
        $txtBoxStaticDNS.Text = $global:NetworkParams.$LookupVal[3]
    }
}
function ToggleStaticHN() {
    if ($chkBoxStaticHostNm.Checked) {
        $staticHostNmLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $txtBoxStaticHN.Text = ""
        $txtBoxStaticHN.Enabled = $true
    } else {
        $staticHostNmLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
        $txtBoxStaticHN.Text = "Based on VM Name"
        $txtBoxStaticHN.Enabled = $false
        $txtBoxStaticHN.ForeColor = [System.Drawing.Color]::DarkBlue
    }
}
function ToggleAddDisk() {
    if ($chkBoxAddHDD.Checked) {
        $hdd2SizeLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $hdd2NumLabel.ForeColor = [System.Drawing.Color]::DarkRed
        $dropDownHdd2Sz.Enabled = $true
        $dropDownHdd2Cnt.Enabled = $true
    } else {
        $hdd2SizeLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
        $hdd2NumLabel.ForeColor = [System.Drawing.Color]::DarkSlateGray
        $dropDownHdd2Sz.Enabled = $false
        $dropDownHdd2Cnt.Enabled = $false
    }
}
function VPG_Changed() {
    if ($chkBoxStaticIp.Checked) {
        if ($dropDownvdPortGrp.SelectedIndex -eq 0) {
            #$txtBoxStaticIp.Text = $global:NetworkParams.$global:templateNetNm[0]
            FillStaticEntries($global:templateNetNm)
        } else {
            $myitem = $dropDownvdPortGrp.SelectedItem.ToString()
            if ( $global:NetworkParams.$myitem -eq $null) {
                FillStaticEntries($null)
            } else {
                FillStaticEntries($myitem)
            }
        }
    }
}
function TemplSelected() {
    if ($listBoxTmpls.SelectedIndex -eq -1) {
        $dropDownvdPortGrp.Enabled = $false;
        $chkBoxStaticIp.Enabled = $false
        return
    } else {
        # Capture some selected Template data
        $global:templateNm = $listBoxTmpls.Items[$listBoxTmpls.SelectedIndex].ToString()
        $template = Get-Template -Name $global:templateNm
        $global:templateNetNm = $template | Select-Object @{N = "VPG"; E = { (Get-View -Id $_.ExtensionData.Network -Property Name).Name } } | Select -ExpandProperty "VPG"
        $dropDownvdPortGrp.Items[0] = "From Template -> $global:templateNetNm"
        $dropDownvdPortGrp.Enabled = $true;
        $chkBoxStaticIp.Enabled = $true
    }
    if ($chkBoxStaticIp.Checked) {
        if ($dropDownvdPortGrp.SelectedIndex -eq 0) {
            FillStaticEntries($global:templateNetNm)
        }
    }
}
function CloneVM() {
    # Check for listbox selections
    if ($listBoxTmpls.SelectedIndex -eq -1) { [System.Windows.MessageBox]::Show("No Template Selected!"); return }
    if ($listBoxDS.SelectedIndex -eq -1) { [System.Windows.MessageBox]::Show("No Datastore Selected!"); return }
    if ($listBoxHost.SelectedIndex -eq -1) { [System.Windows.MessageBox]::Show("No ESX Hostname Selected!"); return }
    # Grab user settings strings
    $global:templateNm = $listBoxTmpls.Items[$listBoxTmpls.SelectedIndex].ToString()
    $dsName = $listBoxDS.Items[$listBoxDS.SelectedIndex].ToString().Split("|")[0].ToString().Trim()
    $hostName = $listBoxHost.Items[$listBoxHost.SelectedIndex].ToString().Split("|")[0].ToString().Trim()
    $newName = $txtBoxNewName.Text.ToString().Trim()
    $newStaticHN = $txtBoxStaticHN.Text.ToString().Trim()
    $newIpAddr =  $txtBoxStaticIp.Text.ToString().Trim()
    $newSubnetMask =  $txtBoxStaticMask.Text.ToString().Trim()
    $newGWAddr =  $txtBoxStaticGW.Text.ToString().Trim()
    $newDNSAddr =  $txtBoxStaticDNS.Text.ToString().Trim()
    $newDNSAddr = $newDNSAddr -replace '\s',''
    $newHddCnt = 0
    # Basic error checking of user settings strings
    if ($global:templateNm.Length -eq 0) { [System.Windows.MessageBox]::Show("Bad Template Selected!"); return }
    if ($dsName.Length -eq 0) { [System.Windows.MessageBox]::Show("Bad Datastore Selected!"); return }
    if ($hostName.Length -eq 0) { [System.Windows.MessageBox]::Show("Bad HostName Selected!"); return }
    if ($newName.Length -eq 0) { [System.Windows.MessageBox]::Show("Bad VM Name Entered!"); return }
    if ($chkBoxStaticHostNm.Checked) {
        if ($newStaticHN.Length -eq 0) { [System.Windows.MessageBox]::Show("Bad Hostname Entered!"); return }
    }
    # Basic IP address format checking
    if ($chkBoxStaticIp.Checked) {
        $regip=[regex]"^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        if (($newIpAddr.Length -eq 0) -or (-not ($regip.IsMatch($newIpAddr)))) { [System.Windows.MessageBox]::Show("Bad IP Address Entered : $newIpAddr"); return }
        if  (($newSubnetMask.Length -eq 0) -or (-not ($regip.IsMatch($newSubnetMask)))) { [System.Windows.MessageBox]::Show("Bad Subnet Mask Entered : $newSubnetMask"); return }
        if (($newGWAddr.Length -eq 0) -or (-not ($regip.IsMatch($newGWAddr)))) { [System.Windows.MessageBox]::Show("Bad Gateway Address Entered : $newGWAddr"); return }
        $newDNSAddr.Split(',') | ForEach {
            if (($_.Length -eq 0) -or (-not ($regip.IsMatch($_)))) { [System.Windows.MessageBox]::Show("Bad DNS Address Entered : $_"); $boolDnsAddrsValid = $false; return }
        }
    }
    # Capture current date for logging purposes
    $Date = get-date
    # Update output message showing selected variables for confirmation
    $message = [string]::Format('Template : {0}{1}Datastore : {2}{3}ESX Host : {4}{5}VM Name : {6}', $global:templateNm, "`r`n", $dsName, "`r`n", $hostName, "`r`n", $newName)
    $OutputLabel.Text = $message
    $OutputLabel.Visible = $true
    $msgButton = 'YesNoCancel'
    $msgImage = 'Question'
    $Result = [System.Windows.MessageBox]::Show("Please review the selected cloning options. Ready to proceed?","Ready to Clone",$msgButton,$msgImage)
    # Start cloning
    if ($result -eq "Yes") {
        # Setup and validate parameters for command to folow
        $ds = Get-Datastore -Name $dsName
        $esx = Get-VMHost -Name $hostName
        $numCpu = $dropDownNumCPU.Text.ToString().Trim()
        $memSize = $dropDownMemSz.Text.ToString().Trim()
        $hddSize = $dropDownHddSz.Text.ToString().Trim()
        if ($dropDownvdPortGrp.SelectedIndex -eq 0) {
            $vdPortGrp = $global:templateNetNm.ToString().Trim()
        } else {
            $vdPortGrp = $dropDownvdPortGrp.Text.ToString().Trim()
        }
        $newHddSize = $dropDownHdd2Sz
        $newHddCnt = $dropDownHdd2Sz
        # Setup Customization Spec based on static or dynamic net config
        if ($chkBoxStaticIp.Checked) {
            # Setup Customization to inject static IP
            $subnet = $txtBoxStaticMask
            if ($chkBoxStaticHostNm.Checked) {
                $SrcCustSpecNm = "Ubuntu Spec - Specify Hostname"
                $OSCusSpec = Get-OSCustomizationSpec -Name $SrcCustSpecNm | Set-OSCustomizationSpec -NamingPrefix "$newStaticHN" -NamingScheme fixed -DnsServer $newDNSAddr.Split(',') -DnsSuffix "home.net" -Domain "home.net" | New-OSCustomizationSpec -Type NonPersistent -Name 'NewTempSpec'
            } else {
                $SrcCustSpecNm = "Ubuntu Spec - VM As Hostname"
                $OSCusSpec = Get-OSCustomizationSpec -Name $SrcCustSpecNm | Set-OSCustomizationSpec -DnsServer $newDNSAddr.Split(',') -DnsSuffix "home.net" -Domain "home.net" | New-OSCustomizationSpec -Type NonPersistent -Name 'NewTempSpec'
            }
            Get-OSCustomizationNicMapping -OSCustomizationSpec $OSCusSpec | Set-OSCustomizationNicMapping -IPMode UseStaticIP -IPAddress $newIpAddr -SubnetMask $newSubnetMask -DefaultGateway $newGWAddr
            $vm = New-VM -Template $global:templateNm -Name $newName -VMHost $esx -OSCustomizationSpec $OSCusSpec -DiskStorageFormat Thin -Datastore $ds -Notes "Clone created $(whoami) $Date"  | Set-VM -NumCpu $numCpu -MemoryGB $memSize -Confirm:$false
            Get-OSCustomizationSpec -Name $OSCusSpec | Remove-OSCustomizationSpec -Confirm:$false
        } else {
            # Setup Customization for standard DHCP
            if ($chkBoxStaticHostNm.Checked) {
                $SrcCustSpecNm = "Ubuntu Spec - Specify Hostname"
                $OSCusSpec = Get-OSCustomizationSpec -Name $SrcCustSpecNm | Set-OSCustomizationSpec -NamingPrefix "$newStaticHN" -NamingScheme fixed | New-OSCustomizationSpec -Type NonPersistent -Name "NewTempSpec"
            } else {
                $SrcCustSpecNm = "Ubuntu Spec - VM As Hostname"
                $OSCusSpec = Get-OSCustomizationSpec -Name $SrcCustSpecNm | New-OSCustomizationSpec -Type NonPersistent -Name 'NewTempSpec'
            }
            $vm = New-VM -Template $global:templateNm -Name $newName -VMHost $esx -OSCustomizationSpec $OSCusSpec -DiskStorageFormat Thin -Datastore $ds -Notes "Clone created $(whoami) $Date"  | Set-VM -NumCpu $numCpu -MemoryGB $memSize -Confirm:$false
            Get-OSCustomizationSpec -Name $OSCusSpec | Remove-OSCustomizationSpec -Confirm:$false
        }
        Get-VM $vm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $vdPortGrp -Confirm:$false
        Get-HardDisk -VM $vm  | Set-HardDisk -CapacityGB $hddSize -Confirm:$false
        if ($chkBoxAddHDD.Checked) {
            $newHddCnt = [int] $dropDownHdd2Cnt.Text.ToString().Trim()
            if ( $newHddCnt -gt 1) {
                for($i=1; $i -le $newHddCnt; $i++){
                    New-HardDisk -vm $vm -CapacityGB $dropDownHdd2Sz.Text.ToString().Trim() -Datastore $ds -StorageFormat Thin
                }
            } else {
                New-HardDisk -vm $vm -CapacityGB $dropDownHdd2Sz.Text.ToString().Trim() -Datastore $ds -StorageFormat Thin
            }
        }
        Start-VM -VM $vm -Confirm:$false        
        $message = [string]::Format('Cloning process completed:')
        $OutputLabel.Text = $message
    } else {
        $OutputLabel.Text = ""
        $OutputLabel.Visible = $false
    }
}
###########
#   Main
###########
# Init PowerShell environment
Add-Type -AssemblyName PresentationCore,PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$monitor = [System.Windows.Forms.Screen]::PrimaryScreen
[void]::$monitor.WorkingArea.Width
# Init Windows Forms
$form = New-Object System.Windows.Forms.Form
# Listboxes
$listBoxTmpls = New-Object System.Windows.Forms.ListBox
$listBoxDS = New-Object System.Windows.Forms.ListBox
$listBoxHost = New-Object System.Windows.Forms.ListBox
$txtBoxNewName = New-Object System.Windows.Forms.TextBox
# Comboboxes
$dropDownNumCPU = New-Object System.Windows.Forms.ComboBox
$dropDownMemSz = New-Object System.Windows.Forms.ComboBox
$dropDownHddSz = New-Object System.Windows.Forms.ComboBox
$dropDownvdPortGrp = New-Object System.Windows.Forms.ComboBox
$dropDownHdd2Sz = New-Object System.Windows.Forms.ComboBox
$dropDownHdd2Cnt = New-Object System.Windows.Forms.ComboBox
# Checkboxes
$chkBoxStaticIp = New-Object System.Windows.Forms.CheckBox
$chkBoxStaticHostNm = New-Object System.Windows.Forms.CheckBox
$chkBoxAddHDD = New-Object System.Windows.Forms.CheckBox
# Textboxes
$txtBoxStaticIp = New-Object System.Windows.Forms.TextBox
$txtBoxStaticHN = New-Object System.Windows.Forms.TextBox
$txtBoxStaticMask = New-Object System.Windows.Forms.TextBox
$txtBoxStaticGW = New-Object System.Windows.Forms.TextBox
$txtBoxStaticDNS = New-Object System.Windows.Forms.TextBox
# Labels
$OutputLabel = New-Object System.Windows.Forms.Label
$staticIpLabel = New-Object System.Windows.Forms.Label
$staticMaskLabel = New-Object System.Windows.Forms.Label
$staticGWLabel = New-Object System.Windows.Forms.Label
$staticDNSLabel = New-Object System.Windows.Forms.Label
$staticHostNmLabel = New-Object System.Windows.Forms.Label
$hdd2SizeLabel = New-Object System.Windows.Forms.Label
$hdd2NumLabel = New-Object System.Windows.Forms.Label
# Init some globals
$global:mainFormWidth = 1100
$global:mainFormHeight = 655
$global:mainFormSize = New-Object System.Drawing.Size($global:mainFormWidth,$global:mainFormHeight)
$global:templateNetNm = "NA"
$global:templateNm = "NA"
[hashtable]$global:NetworkParams = @{
    "DSwitch-VM Network"           = @("192.168.1." ,"255.255.255.0","192.168.1.1" ,"192.168.1.250, 192.168.1.1");
    "DSwitch-VM Network-ephemeral" = @("192.168.3." ,"255.255.255.0","192.168.3.1" ,"192.168.1.250, 192.168.1.1");
    "DSwitch-Management Network"   = @("192.168.10.","255.255.255.0","192.168.10.1","192.168.1.250, 192.168.1.1");
    "VM Network"                   = @("192.168.1." ,"255.255.255.0","192.168.1.1" ,"192.168.1.250, 192.168.1.1")
}
# Get the party started!
PickVcenter
