function installPrinter ($IPAddress,$ComputerName,$PrinterName,$ButtonName, $DriverType) {
    
    #===================================================================================================
    #==========================     КОНФИГ     =========================================================
    #===================================================================================================

    $PrinterConfig = switch ($ButtonName) { 
        "HP PCL5" {@{
            IP=$IPAddress
            ComputerName=$ComputerName
            PrinterName=$PrinterName
            NameDriver="HP Universal Printing PCL 5"
            NameFolder="HPPCL5"
            Path="C:\Temp\Helper_Printer\Drivers\Printers\HP\HPPCL5\"
            Dest="C:\Temp\"
            ExePath="C:\Temp\HPPCL5\*.inf"
        }}
        "HP PCL6" {@{
            IP=$IPAddress
            ComputerName=$ComputerName
            PrinterName=$PrinterName
            NameDriver="HP Universal Printing PCL 6"
            NameFolder="HPPCL6"
            Path="C:\Temp\Helper_Printer\Drivers\Printers\HP\HPPCL6\"
            Dest="C:\Temp\"
            ExePath="C:\Temp\HPPCL6\*.inf"
        }}
        "Ricoh 2000" {@{
            IP=$IPAddress
            ComputerName=$ComputerName
            PrinterName=$PrinterName
            NameDriver="PCL6 Driver for Universal Print"
            NameFolder="RICOH2000"
            Path="C:\Temp\Helper_Printer\Drivers\Printers\RICOH\RICOH2000" 
            Dest="C:\Temp\"
            ExePath="C:\Temp\RICOH2000\disk1\oemsetup.inf"
        }}
        "VersaLink C7000 7020 7025 7030" {@{
            IP=$IPAddress
            ComputerName=$ComputerName
            PrinterName=$PrinterName
            NameDriver=$DriverType
            NameFolder="VersaLink_C7000_C7020_C7025_C7030_7.175.0.0_PCL6_x64"
            Path="C:\Temp\Helper_Printer\Drivers\Printers\Xerox\VersaLink_C7000_C7020_C7025_C7030_7.175.0.0_PCL6_x64"
            Dest="c:\temp\"
            ExePath="C:\Temp\VersaLink_C7000_C7020_C7025_C7030_7.175.0.0_PCL6_x64\Xerox_VersaLink_C7000_C7020_C7025_C7030_PCL6.inf"
        }}
        "WorkCenter 7830 7835 7845 7855" {@{
            IP=$IPAddress
            ComputerName=$ComputerName
            PrinterName=$PrinterName
            NameDriver=$DriverType
            NameFolder="xerox_workcenter_pcl6"
            Path="C:\Temp\Helper_Printer\Drivers\Printers\Xerox\xerox_workcenter_pcl6"
            Dest="c:\temp\"
            ExePath="C:\Temp\xerox_workcenter_pcl6\WC78XX_5.433.16.0_PCL6_x64_Driver.inf\x2DSPYX.inf"
        }}
        "Xerox B1025 1022" {@{
            IP=$IPAddress
            ComputerName=$ComputerName
            PrinterName=$PrinterName
            NameDriver=$DriverType
            NameFolder="xerox_B1025"
            Path="C:\Temp\Helper_Printer\Drivers\Printers\Xerox\xerox_B1025"
            Dest="c:\temp\"
            ExePath="C:\Temp\xerox_B1025\Windows PCL6\64-bit_x64\x3SRAMX.inf"
        }}
        "Xerox 5022 5024" {@{
            IP=$IPAddress
            ComputerName=$ComputerName
            PrinterName=$PrinterName
            NameDriver=$DriverType
            NameFolder="Xerox5024"
            Path="C:\Temp\Helper_Printer\Drivers\Printers\Xerox\Xerox5024"
            Dest="c:\temp\"
            ExePath="C:\Temp\Xerox5024\Drivers\HB\Win\x64\Russian\XRHMLML.inf"
        }}
        "VersaLink C400 405" {@{
            IP=$IPAddress
            ComputerName=$ComputerName
            PrinterName=$PrinterName
            NameDriver=$DriverType
            NameFolder="VersaLink_C400_C405_7.95.0.0_PCL6_x64"
            Path="C:\Temp\Helper_Printer\Drivers\Printers\Xerox\VersaLink_C400_C405_7.95.0.0_PCL6_x64"
            Dest="c:\temp\"
            ExePath="C:\Temp\VersaLink_C400_C405_7.95.0.0_PCL6_x64\Xerox_VersaLink_C400_C405_PCL6.inf"
        }}

    }

    #=======================     Конец КОНФИГА     =====================================================

    try {
        $Session = New-PSSession -ComputerName $ComputerName
    }
    catch {
        return @{Error=@{Err=$true; ErrorMessage="Ошибка. Не удалось установить соеденение с компьютером"}; Succesed=$false}
    }
    Start-Sleep -Seconds 1

    $IsHasDriverFolder = Invoke-Command -Session $Session -ScriptBlock {
        param($Conf)
        $nameFolder = $Conf.NameFolder
        Test-Path "C:\Temp\$nameFolder"
    } -ArgumentList $PrinterConfig

    if ($IsHasDriverFolder -eq $False) {
        Copy-Item -Path $PrinterConfig.Path -Destination $PrinterConfig.Dest -ToSession $Session -Recurse
    }

    Invoke-Command -Session $Session -ScriptBlock {
        param($Conf, $PrinterName, $IPAddress)
        $isHasDriver = Get-PrinterDriver | where {$_.name -Like $Conf.NameDriver}
        $isHasPort = Get-PrinterPort | where {$_.name -Like $Conf.IP}
        $Printer = Get-Printer | where {$_.name -Like $Conf.PrinterName}

        if ($isHasDriver -eq $NULL) {
            pnputil.exe -i -a $Conf.ExePath
            Add-PrinterDriver -Name $Conf.NameDriver
        }

        if ($isHasPort -eq $NULL) {
            Add-PrinterPort -Name $Conf.IP -PrinterHostAddress $Conf.IP
        }

        if ($IsHasDriver -and $isHasPort -and $Printer) {
            return @{Error={Err=$true; ErrorMessage="Такой принтер уже существует"}}
        }

        if ($isHasDriver -and $Printer) {
            Set-Printer -Name $Printer.name -PortName $Conf.IP
            "Ку-ку, это проверка вашего принтера" | Out-Printer $Conf.PrinterName
            return @{Error=$false; Succesed=@{Err4=$false; SuccesedMessage="Такой принтер уже существует, был добавлен указанный ip в порт настроек принтера"}}
        }

        if ($Printer -eq $NULL) {
            Add-Printer -Name $Conf.PrinterName -DriverName $Conf.NameDriver -PortName $Conf.IP
            "Ку-ку, это проверка вашего принтера" | Out-Printer $Conf.PrinterName
            return @{Error=$false; $Succesed=@{Err=$false; SuccesedMessage="Принтер успешно подключен"}} 
        } else {
            return @{Error=@{Err=$true; ErrorMessage="Не удалось проверить выполнить подключения принтера, пожалуста, проверьте правильность вводимых данных"}; Succesed=$false}
        }
             
    } -ArgumentList $PrinterConfig
    
}

function Remove-CurrentPrinter ($ComputerName, $Printer) {
    $Printers = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Remove-Printer -Name $Printer.Name
    }
}

function Get-CurrentPrinter ($ComputerName) {
    return Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-Printer | select Name, DriverName, PortName
    }
}

$buttonName = ''

Add-Type -assembly System.Windows.Forms
$img = [System.Drawing.Image]::FromFile('C:\Users\GaliullinAZR\Desktop\Scripts\Helper_Printer\img\item11.jpg')


$CenterScreen = [System.Windows.Forms.FormStartPosition]::CenterScreen;
$window_form = New-Object System.Windows.Forms.Form
$window_form.StartPosition = $CenterScreen
$window_form.Text ='Helper Printer'
$window_form.Width = 570
$window_form.Height = 650
$window_form.minimumSize = New-Object System.Drawing.Size(570,650) 
$window_form.maximumSize = New-Object System.Drawing.Size(570,650) 
$window_form.BackColor = '#f5f5f5'
$window_form.BackgroundImage = $img
$window_form.AutoSize = $true

$form_status_label1 = New-Object System.Windows.Forms.Label
$form_status_label1 = New-Object System.Windows.Forms.Label
$form_status_label1.Text = "cтатус:"
$form_status_label1.Location = New-Object System.Drawing.Point(8,586)
$form_status_label1.AutoSize = $true
$form_status_label1.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
$window_form.Controls.Add($form_status_label1)

$form_status_label2 = New-Object System.Windows.Forms.Label
$form_status_label2 = New-Object System.Windows.Forms.Label
$form_status_label2.Text = ""
$form_status_label2.Location = New-Object System.Drawing.Point(100,586)
$form_status_label2.AutoSize = $true
$form_status_label2.Font = New-Object System.Drawing.Font("Arial",14,[System.Drawing.FontStyle]::Regular)
$window_form.Controls.Add($form_status_label2)

$FormLabel1 = New-Object System.Windows.Forms.Label
$FormLabel1.Text = "Введите имя компьютера"
$FormLabel1.Location = New-Object System.Drawing.Point(10,10)
$FormLabel1.AutoSize = $true
$FormLabel1.BackColor = '#c4c4c4'
$window_form.Controls.Add($FormLabel1)

$FormLabel2 = New-Object System.Windows.Forms.Label
$FormLabel2.Text = "Введите ip принтера"
$FormLabel2.Location = New-Object System.Drawing.Point(280,10)
$FormLabel2.AutoSize = $true
$FormLabel2.BackColor = '#c4c4c4'
$window_form.Controls.Add($FormLabel2)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,30)
$textBox.Size = New-Object System.Drawing.Size(260,30)
$textBox.Height = 40
$window_form.Controls.Add($textBox)

$textBox1 = New-Object System.Windows.Forms.TextBox
$textBox1.Location = New-Object System.Drawing.Point(280,30)
$textBox1.Size = New-Object System.Drawing.Size(260,30)
$window_form.Controls.Add($textBox1)

$Pcl5Button = New-Object System.Windows.Forms.Button
$Pcl5Button.BackColor = '#90e1a7'
$Pcl5Button.text = "HP PCL5"
$Pcl5Button.Location = New-Object System.Drawing.Point(10,60)
$Pcl5Button.Size = New-Object System.Drawing.Size(260,40)
$Pcl5Button.AutoSize = $True
$Pcl5Button.Add_Click({
    if ($textBox.text.Length -eq 15 -and $textBox1.text.Length -ge 10 -and $textBox1.text.Length -le 14) {

        $buttonName = $this.text
    
        $window_form1 = New-Object System.Windows.Forms.Form
        $window_form1.BackColor = '#f5f5f5'
        $window_form1.StartPosition = $CenterScreen
        $window_form1.Text ='Helper Printer'
        $window_form1.Width = 300
        $window_form1.Height = 160
        $window_form1.AutoSize = $false
    
        $FormLabel3 = New-Object System.Windows.Forms.Label
        $FormLabel3.Text = "Введите имя принтера"
        $FormLabel3.Location = New-Object System.Drawing.Point(10,10)
        $FormLabel3.AutoSize = $true
        $window_form1.Controls.Add($FormLabel3)
    
        $InputPrinterName = New-Object System.Windows.Forms.TextBox
        $InputPrinterName.Location = New-Object System.Drawing.Point(10,30)
        $InputPrinterName.Size = New-Object System.Drawing.Size(260,30)
        $InputPrinterName.Add_KeyUp({
            if ($this.text.Length -gt 4) {
                $PrinterNameBtn.Enabled = $True
            } else {
                $PrinterNameBtn.Enabled = $False
            }
        })
        $window_form1.Controls.Add($InputPrinterName)
    
        $PrinterNameBtn = New-Object System.Windows.Forms.Button
        $PrinterNameBtn.text = "OK"
        $PrinterNameBtn.Location = New-Object System.Drawing.Point(10,60)
        $PrinterNameBtn.Size = New-Object System.Drawing.Size(260,40)
        $PrinterNameBtn.Enabled = $False
        $PrinterNameBtn.AutoSize = $True
        $PrinterNameBtn.BackColor = '#90e1a7'
        $PrinterNameBtn.Add_Click({
            $form_status_label2.Text = "Подключение..."
            try {
                installPrinter -IPAddress $textBox1.text -ComputerName $textBox.text -PrinterName $InputPrinterName.text -ButtonName $buttonName
                $form_status_label2.Text = "Готово"
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            catch {
                $form_status_label2.Text = "Ошибка подключения"
                msg * $_
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            $window_form1.Close()
        })
        $window_form1.Controls.Add($PrinterNameBtn)
        $window_form1.ShowDialog()
    } else {
        msg * "Не верное имя компьютера или ip принтера"
    }
})
$window_form.Controls.Add($Pcl5Button)

$Pcl6Button = New-Object System.Windows.Forms.Button
$Pcl6Button.BackColor = '#90e1a7'
$Pcl6Button.text = "HP PCL6"
$Pcl6Button.Location = New-Object System.Drawing.Point(280,60)
$Pcl6Button.Size = New-Object System.Drawing.Size(260,40)
$Pcl6Button.Enabled = $True
$Pcl6Button.AutoSize = $True
$Pcl6Button.Add_Click({
    if ($textBox.text.Length -eq 15 -and $textBox1.text.Length -ge 10 -and $textBox1.text.Length -le 14) {

        $buttonName = $this.text
    
        $window_form1 = New-Object System.Windows.Forms.Form
        $window_form1.BackColor = '#f5f5f5'
        $window_form1.StartPosition = $CenterScreen
        $window_form1.Text ='Helper Printer'
        $window_form1.Width = 300
        $window_form1.Height = 160
        $window_form1.AutoSize = $false
    
        $FormLabel3 = New-Object System.Windows.Forms.Label
        $FormLabel3.Text = "Введите имя принтера"
        $FormLabel3.Location = New-Object System.Drawing.Point(10,10)
        $FormLabel3.AutoSize = $true
        $window_form1.Controls.Add($FormLabel3)
    
        $InputPrinterName = New-Object System.Windows.Forms.TextBox
        $InputPrinterName.Location = New-Object System.Drawing.Point(10,30)
        $InputPrinterName.Size = New-Object System.Drawing.Size(260,30)
        $InputPrinterName.Add_KeyUp({
            if ($this.text.Length -gt 4) {
                $PrinterNameBtn.Enabled = $True
            } else {
                $PrinterNameBtn.Enabled = $False
            }
        })
        $window_form1.Controls.Add($InputPrinterName)
    
        $PrinterNameBtn = New-Object System.Windows.Forms.Button
        $PrinterNameBtn.text = "OK"
        $PrinterNameBtn.Location = New-Object System.Drawing.Point(10,60)
        $PrinterNameBtn.Size = New-Object System.Drawing.Size(260,40)
        $PrinterNameBtn.Enabled = $False
        $PrinterNameBtn.AutoSize = $True
        $PrinterNameBtn.BackColor = '#90e1a7'
        $PrinterNameBtn.Add_Click({
            $form_status_label2.Text = "Подключение..."
            try {
                installPrinter -IPAddress $textBox1.text -ComputerName $textBox.text -PrinterName $InputPrinterName.text -ButtonName $buttonName
                $form_status_label2.Text = "Готово"
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            catch {
                $form_status_label2.Text = "Ошибка подключения."
                msg * $_
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            $window_form1.Close()
        })
        $window_form1.Controls.Add($PrinterNameBtn)
        $window_form1.ShowDialog()
    } else {
        msg * "Не верное имя компьютера или ip принтера"
    }
})
$window_form.Controls.Add($Pcl6Button)

$Ric2Button = New-Object System.Windows.Forms.Button
$Ric2Button.BackColor = '#90e1a7'
$Ric2Button.text = "Ricoh 2000"
$Ric2Button.Location = New-Object System.Drawing.Point(10,110)
$Ric2Button.Size = New-Object System.Drawing.Size(260,40)
$Ric2Button.Enabled = $true
$Ric2Button.AutoSize = $True
$Ric2Button.Add_Click({
    if ($textBox.text.Length -eq 15 -and $textBox1.text.Length -ge 10 -and $textBox1.text.Length -le 14) {

        $buttonName = $this.text
    
        $window_form1 = New-Object System.Windows.Forms.Form
        $window_form1.BackColor = '#f5f5f5'
        $window_form1.StartPosition = $CenterScreen
        $window_form1.Text ='Helper Printer'
        $window_form1.Width = 300
        $window_form1.Height = 160
        $window_form1.AutoSize = $false
    
        $FormLabel3 = New-Object System.Windows.Forms.Label
        $FormLabel3.Text = "Введите имя принтера"
        $FormLabel3.Location = New-Object System.Drawing.Point(10,10)
        $FormLabel3.AutoSize = $true
        $window_form1.Controls.Add($FormLabel3)
    
        $InputPrinterName = New-Object System.Windows.Forms.TextBox
        $InputPrinterName.Location = New-Object System.Drawing.Point(10,30)
        $InputPrinterName.Size = New-Object System.Drawing.Size(260,30)
        $InputPrinterName.Add_KeyUp({
            if ($this.text.Length -gt 4) {
                $PrinterNameBtn.Enabled = $True
            } else {
                $PrinterNameBtn.Enabled = $False
            }
        })
        $window_form1.Controls.Add($InputPrinterName)
    
        $PrinterNameBtn = New-Object System.Windows.Forms.Button
        $PrinterNameBtn.text = "OK"
        $PrinterNameBtn.Location = New-Object System.Drawing.Point(10,60)
        $PrinterNameBtn.Size = New-Object System.Drawing.Size(260,40)
        $PrinterNameBtn.Enabled = $False
        $PrinterNameBtn.AutoSize = $True
        $PrinterNameBtn.BackColor = '#90e1a7'
        $PrinterNameBtn.Add_Click({
            $form_status_label2.Text = "Подключение..."
            try {
                installPrinter -IPAddress $textBox1.text -ComputerName $textBox.text -PrinterName $InputPrinterName.text -ButtonName $buttonName
                $form_status_label2.Text = "Готово"
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            catch {
                $form_status_label2.Text = "Ошибка подключения"
                msg * $_
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            $window_form1.Close()
        })
        $window_form1.Controls.Add($PrinterNameBtn)
        $window_form1.ShowDialog()
    } else {
        msg * "Не верное имя компьютера или ip принтера"
    }
})
$window_form.Controls.Add($Ric2Button)

$VerLink7Button = New-Object System.Windows.Forms.Button
$VerLink7Button.BackColor = '#90e1a7'
$VerLink7Button.text = "VersaLink C7000 7020 7025 7030"
$VerLink7Button.Location = New-Object System.Drawing.Point(280,110)
$VerLink7Button.Size = New-Object System.Drawing.Size(260,40)
$VerLink7Button.Enabled = $True
$VerLink7Button.AutoSize = $True
$VerLink7Button.Add_Click({
    if ($textBox.text.Length -eq 15 -and $textBox1.text.Length -ge 10 -and $textBox1.text.Length -le 14) {

        $XeroxPrinterVersionDriver = @("Xerox VersaLink C7000 V4 PCL6", "Xerox VersaLink C7020 V4 PCL6", "Xerox VersaLink C7025 V4 PCL6", "Xerox VersaLink C7030 V4 PCL6")
        $buttonName = $this.text
        $window_form1 = New-Object System.Windows.Forms.Form
        $window_form1.BackColor = '#f5f5f5'
        $window_form1.StartPosition = $CenterScreen
        $window_form1.Text ='Helper Printer'
        $window_form1.Width = 300
        $window_form1.Height = 285
        $window_form1.AutoSize = $false
    
        $FormLabel3 = New-Object System.Windows.Forms.Label
        $FormLabel3.Text = "Введите имя принтера"
        $FormLabel3.Location = New-Object System.Drawing.Point(10,10)
        $FormLabel3.AutoSize = $true
        $window_form1.Controls.Add($FormLabel3)
    
        $InputPrinterName = New-Object System.Windows.Forms.TextBox
        $InputPrinterName.Location = New-Object System.Drawing.Point(10,30)
        $InputPrinterName.Size = New-Object System.Drawing.Size(260,30)
        $InputPrinterName.Add_KeyUp({
            if ($InputPrinterName.text.Length -gt 4 -and $SelectNameDriver.SelectedItem) {
                $PrinterNameBtn.Enabled = $true
            } else {
                $PrinterNameBtn.Enabled = $False
            }
        })
        $window_form1.Controls.Add($InputPrinterName)
    
        $SelectFormLabel = New-Object System.Windows.Forms.Label
        $SelectFormLabel.Text = "Выберите версию драйвера"
        $SelectFormLabel.Location = New-Object System.Drawing.Point(10,70)
        $SelectFormLabel.Width = 260
        $window_form1.Controls.Add($SelectFormLabel)
    
        $SelectNameDriver = New-Object System.Windows.Forms.ListBox
        $SelectNameDriver.Location = New-Object System.Drawing.Point(10,100)
        $SelectNameDriver.Size = New-Object System.Drawing.Size(260,10)
        foreach ($XeroxDriver in $XeroxPrinterVersionDriver) {
            $SelectNameDriver.Items.Add($XeroxDriver)
        }
        $SelectNameDriver.Height = 60
        $SelectNameDriver.Add_Click({
            if ($this.SelectedItem -and $InputPrinterName.text.Length -gt 4) {
                $PrinterNameBtn.Enabled = $True
            } else {
                $PrinterNameBtn = $False
            }
        })
        $window_form1.Controls.Add($SelectNameDriver)
    
        $PrinterNameBtn = New-Object System.Windows.Forms.Button
        $PrinterNameBtn.text = "OK"
        $PrinterNameBtn.Location = New-Object System.Drawing.Point(10,170)
        $PrinterNameBtn.Size = New-Object System.Drawing.Size(260,40)
        $PrinterNameBtn.Enabled = $False
        $PrinterNameBtn.AutoSize = $True
        $PrinterNameBtn.BackColor = '#90e1a7'
        $PrinterNameBtn.Add_Click({
            $form_status_label2.Text = "Подключение..."
            try {
                installPrinter -IPAddress $textBox1.text -ComputerName $textBox.text -PrinterName $InputPrinterName.text -ButtonName $buttonName -DriverType $SelectNameDriver.SelectedItem
                $form_status_label2.Text = "Готово"
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            catch {
                $form_status_label2.Text = "Ошибка подключения"
                msg * $_
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            $window_form1.Close()
        })
        $window_form1.Controls.Add($PrinterNameBtn)
        $window_form1.ShowDialog()
    } else {
        msg * "Не верное имя компьютера или ip принтера"
    }
})
$window_form.Controls.Add($VerLink7Button)

$WrkCen7830Button = New-Object System.Windows.Forms.Button
$WrkCen7830Button.BackColor = '#90e1a7'
$WrkCen7830Button.text = "WorkCenter 7830 7835 7845 7855"
$WrkCen7830Button.Location = New-Object System.Drawing.Point(10,160)
$WrkCen7830Button.Size = New-Object System.Drawing.Size(260,40)
$WrkCen7830Button.Enabled = $true
$WrkCen7830Button.AutoSize = $True
$WrkCen7830Button.Add_Click({
    if ($textBox.text.Length -eq 15 -and $textBox1.text.Length -ge 10 -and $textBox1.text.Length -le 14) {

        $XeroxPrinterVersionDriver = @("Xerox WorkCentre 7855 PCL6", "Xerox WorkCentre 7845 PCL6", "Xerox WorkCentre 7835 PCL6", "Xerox WorkCentre 7830 PCL6")
        $buttonName = $this.text
        $window_form1 = New-Object System.Windows.Forms.Form
        $window_form1.BackColor = '#f5f5f5'
        $window_form1.StartPosition = $CenterScreen
        $window_form1.Text ='Helper Printer'
        $window_form1.Width = 300
        $window_form1.Height = 285
        $window_form1.AutoSize = $false
    
        $FormLabel3 = New-Object System.Windows.Forms.Label
        $FormLabel3.Text = "Введите имя принтера"
        $FormLabel3.Location = New-Object System.Drawing.Point(10,10)
        $FormLabel3.AutoSize = $true
        $window_form1.Controls.Add($FormLabel3)
    
        $InputPrinterName = New-Object System.Windows.Forms.TextBox
        $InputPrinterName.Location = New-Object System.Drawing.Point(10,30)
        $InputPrinterName.Size = New-Object System.Drawing.Size(260,30)
        $InputPrinterName.Add_KeyUp({
            if ($InputPrinterName.text.Length -gt 4 -and $SelectNameDriver.SelectedItem) {
                $PrinterNameBtn.Enabled = $true
            } else {
                $PrinterNameBtn.Enabled = $False
            }
        })
        $window_form1.Controls.Add($InputPrinterName)
    
        $SelectFormLabel = New-Object System.Windows.Forms.Label
        $SelectFormLabel.Text = "Выберите версию драйвера"
        $SelectFormLabel.Location = New-Object System.Drawing.Point(10,70)
        $SelectFormLabel.Width = 260
        $window_form1.Controls.Add($SelectFormLabel)
    
        $SelectNameDriver = New-Object System.Windows.Forms.ListBox
        $SelectNameDriver.Location = New-Object System.Drawing.Point(10,100)
        $SelectNameDriver.Size = New-Object System.Drawing.Size(260,10)
        foreach ($XeroxDriver in $XeroxPrinterVersionDriver) {
            $SelectNameDriver.Items.Add($XeroxDriver)
        }
        $SelectNameDriver.Height = 60
        $SelectNameDriver.Add_Click({
            if ($this.SelectedItem -and $InputPrinterName.text.Length -gt 4) {
                $PrinterNameBtn.Enabled = $True
            } else {
                $PrinterNameBtn = $False
            }
        })
        $window_form1.Controls.Add($SelectNameDriver)
    
        $PrinterNameBtn = New-Object System.Windows.Forms.Button
        $PrinterNameBtn.text = "OK"
        $PrinterNameBtn.Location = New-Object System.Drawing.Point(10,170)
        $PrinterNameBtn.Size = New-Object System.Drawing.Size(260,40)
        $PrinterNameBtn.Enabled = $False
        $PrinterNameBtn.AutoSize = $True
        $PrinterNameBtn.BackColor = '#90e1a7'
        $PrinterNameBtn.Add_Click({
            $form_status_label2.Text = "Подключение..."
            try {
                installPrinter -IPAddress $textBox1.text -ComputerName $textBox.text -PrinterName $InputPrinterName.text -ButtonName $buttonName -DriverType $SelectNameDriver.SelectedItem
                $form_status_label2.Text = "Готово"
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            catch {
                $form_status_label2.Text = "Ошибка подключения"
                msg * $_
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            $window_form1.Close()
        })
        $window_form1.Controls.Add($PrinterNameBtn)
        $window_form1.ShowDialog()
    } else {
        msg * "Не верное имя компьютера или ip принтера"
    }
})


$window_form.Controls.Add($WrkCen7830Button)

$XeroxB1025Button = New-Object System.Windows.Forms.Button
$XeroxB1025Button.BackColor = '#90e1a7'
$XeroxB1025Button.text = "Xerox B1025 1022"
$XeroxB1025Button.Location = New-Object System.Drawing.Point(280,160)
$XeroxB1025Button.Size = New-Object System.Drawing.Size(260,40)
$XeroxB1025Button.Enabled = $True
$XeroxB1025Button.AutoSize = $True
$XeroxB1025Button.Add_Click({
    if ($textBox.text.Length -eq 15 -and $textBox1.text.Length -ge 10 -and $textBox1.text.Length -le 14) {

        $XeroxPrinterVersionDriver = @("Xerox B1022 Multifunction Printer PCL6","Xerox B1025 Multifunction Printer PCL6")
        $buttonName = $this.text
        $window_form1 = New-Object System.Windows.Forms.Form
        $window_form1.BackColor = '#f5f5f5'
        $window_form1.StartPosition = $CenterScreen
        $window_form1.Text ='Helper Printer'
        $window_form1.Width = 300
        $window_form1.Height = 285
        $window_form1.AutoSize = $false
    
        $FormLabel3 = New-Object System.Windows.Forms.Label
        $FormLabel3.Text = "Введите имя принтера"
        $FormLabel3.Location = New-Object System.Drawing.Point(10,10)
        $FormLabel3.AutoSize = $true
        $window_form1.Controls.Add($FormLabel3)
    
        $InputPrinterName = New-Object System.Windows.Forms.TextBox
        $InputPrinterName.Location = New-Object System.Drawing.Point(10,30)
        $InputPrinterName.Size = New-Object System.Drawing.Size(260,30)
        $InputPrinterName.Add_KeyUp({
            if ($InputPrinterName.text.Length -gt 4 -and $SelectNameDriver.SelectedItem) {
                $PrinterNameBtn.Enabled = $true
            } else {
                $PrinterNameBtn.Enabled = $False
            }
        })
        $window_form1.Controls.Add($InputPrinterName)
    
        $SelectFormLabel = New-Object System.Windows.Forms.Label
        $SelectFormLabel.Text = "Выберите версию драйвера"
        $SelectFormLabel.Location = New-Object System.Drawing.Point(10,70)
        $SelectFormLabel.Width = 260
        $window_form1.Controls.Add($SelectFormLabel)
    
        $SelectNameDriver = New-Object System.Windows.Forms.ListBox
        $SelectNameDriver.Location = New-Object System.Drawing.Point(10,100)
        $SelectNameDriver.Size = New-Object System.Drawing.Size(260,10)
        foreach ($XeroxDriver in $XeroxPrinterVersionDriver) {
            $SelectNameDriver.Items.Add($XeroxDriver)
        }
        $SelectNameDriver.Height = 60
        $SelectNameDriver.Add_Click({
            if ($this.SelectedItem -and $InputPrinterName.text.Length -gt 4) {
                $PrinterNameBtn.Enabled = $True
            } else {
                $PrinterNameBtn = $False
            }
        })
        $window_form1.Controls.Add($SelectNameDriver)
    
        $PrinterNameBtn = New-Object System.Windows.Forms.Button
        $PrinterNameBtn.text = "OK"
        $PrinterNameBtn.Location = New-Object System.Drawing.Point(10,170)
        $PrinterNameBtn.Size = New-Object System.Drawing.Size(260,40)
        $PrinterNameBtn.Enabled = $False
        $PrinterNameBtn.AutoSize = $True
        $PrinterNameBtn.BackColor = '#90e1a7'
        $PrinterNameBtn.Add_Click({
            $form_status_label2.Text = "Подключение..."
            try {
                installPrinter -IPAddress $textBox1.text -ComputerName $textBox.text -PrinterName $InputPrinterName.text -ButtonName $buttonName -DriverType $SelectNameDriver.SelectedItem
                $form_status_label2.Text = "Ошибка подключения"
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            catch {
                $form_status_label2.Text = "Готово"
                msg * $_
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            $window_form1.Close()
        })
        $window_form1.Controls.Add($PrinterNameBtn)
        $window_form1.ShowDialog()
    } else {
        msg * "Не верное имя компьютера или ip принтера"
    }
})
$window_form.Controls.Add($XeroxB1025Button)

$VersaLinkC400_405 = New-Object System.Windows.Forms.Button
$VersaLinkC400_405.BackColor = '#90e1a7'
$VersaLinkC400_405.text = "VersaLink C400 405"
$VersaLinkC400_405.Location = New-Object System.Drawing.Point(10,210)
$VersaLinkC400_405.Size = New-Object System.Drawing.Size(260,40)
$VersaLinkC400_405.Enabled = $True
$VersaLinkC400_405.AutoSize = $True
$VersaLinkC400_405.Add_Click({
    if ($textBox.text.Length -eq 15 -and $textBox1.text.Length -ge 10 -and $textBox1.text.Length -le 14) {

        $XeroxPrinterVersionDriver = @("Xerox VersaLink C400 V4 PCL6","Xerox VersaLink C405 V4 PCL6")
        $buttonName = $this.text
        $window_form1 = New-Object System.Windows.Forms.Form
        $window_form1.BackColor = '#f5f5f5'
        $window_form1.StartPosition = $CenterScreen
        $window_form1.Text ='Helper Printer'
        $window_form1.Width = 300
        $window_form1.Height = 285
        $window_form1.AutoSize = $false
    
        $FormLabel3 = New-Object System.Windows.Forms.Label
        $FormLabel3.Text = "Введите имя принтера"
        $FormLabel3.Location = New-Object System.Drawing.Point(10,10)
        $FormLabel3.AutoSize = $true
        $window_form1.Controls.Add($FormLabel3)
    
        $InputPrinterName = New-Object System.Windows.Forms.TextBox
        $InputPrinterName.Location = New-Object System.Drawing.Point(10,30)
        $InputPrinterName.Size = New-Object System.Drawing.Size(260,30)
        $InputPrinterName.Add_KeyUp({
            if ($InputPrinterName.text.Length -gt 4 -and $SelectNameDriver.SelectedItem) {
                $PrinterNameBtn.Enabled = $true
            } else {
                $PrinterNameBtn.Enabled = $False
            }
        })
        $window_form1.Controls.Add($InputPrinterName)
    
        $SelectFormLabel = New-Object System.Windows.Forms.Label
        $SelectFormLabel.Text = "Выберите версию драйвера"
        $SelectFormLabel.Location = New-Object System.Drawing.Point(10,70)
        $SelectFormLabel.Width = 260
        $window_form1.Controls.Add($SelectFormLabel)
    
        $SelectNameDriver = New-Object System.Windows.Forms.ListBox
        $SelectNameDriver.Location = New-Object System.Drawing.Point(10,100)
        $SelectNameDriver.Size = New-Object System.Drawing.Size(260,10)
        foreach ($XeroxDriver in $XeroxPrinterVersionDriver) {
            $SelectNameDriver.Items.Add($XeroxDriver)
        }
        $SelectNameDriver.Height = 60
        $SelectNameDriver.Add_Click({
            if ($this.SelectedItem -and $InputPrinterName.text.Length -gt 4) {
                $PrinterNameBtn.Enabled = $True
            } else {
                $PrinterNameBtn = $False
            }
        })
        $window_form1.Controls.Add($SelectNameDriver)
    
        $PrinterNameBtn = New-Object System.Windows.Forms.Button
        $PrinterNameBtn.text = "OK"
        $PrinterNameBtn.Location = New-Object System.Drawing.Point(10,170)
        $PrinterNameBtn.Size = New-Object System.Drawing.Size(260,40)
        $PrinterNameBtn.Enabled = $False
        $PrinterNameBtn.AutoSize = $True
        $PrinterNameBtn.BackColor = '#90e1a7'
        $PrinterNameBtn.Add_Click({
            $form_status_label2.Text = "Подключение..."
            try {
                installPrinter -IPAddress $textBox1.text -ComputerName $textBox.text -PrinterName $InputPrinterName.text -ButtonName $buttonName -DriverType $SelectNameDriver.SelectedItem
                $form_status_label2.Text = "Готово"
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            catch {
                $form_status_label2.Text = "Ошибка подключения"
                msg * $_
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            $window_form1.Close()
        })
        $window_form1.Controls.Add($PrinterNameBtn)
        $window_form1.ShowDialog()
    } else {
        msg * "Не верное имя компьютера или ip принтера"
    }
})
$window_form.Controls.Add($VersaLinkC400_405)

$Xerox5024_5022 = New-Object System.Windows.Forms.Button
$Xerox5024_5022.BackColor = '#90e1a7'
$Xerox5024_5022.text = "Xerox 5022 5024"
$Xerox5024_5022.Location = New-Object System.Drawing.Point(280,210)
$Xerox5024_5022.Size = New-Object System.Drawing.Size(260,40)
$Xerox5024_5022.Enabled = $True
$Xerox5024_5022.AutoSize = $True
$Xerox5024_5022.Add_Click({
    if ($textBox.text.Length -eq 15 -and $textBox1.text.Length -ge 10 -and $textBox1.text.Length -le 14) {

        $XeroxPrinterVersionDriver = @("Xerox WorkCentre 5022","Xerox WorkCentre 5024")
        $buttonName = $this.text
        $window_form1 = New-Object System.Windows.Forms.Form
        $window_form1.BackColor = '#f5f5f5'
        $window_form1.StartPosition = $CenterScreen
        $window_form1.Text ='Helper Printer'
        $window_form1.Width = 300
        $window_form1.Height = 285
        $window_form1.AutoSize = $false
    
        $FormLabel3 = New-Object System.Windows.Forms.Label
        $FormLabel3.Text = "Введите имя принтера"
        $FormLabel3.Location = New-Object System.Drawing.Point(10,10)
        $FormLabel3.AutoSize = $true
        $window_form1.Controls.Add($FormLabel3)
    
        $InputPrinterName = New-Object System.Windows.Forms.TextBox
        $InputPrinterName.Location = New-Object System.Drawing.Point(10,30)
        $InputPrinterName.Size = New-Object System.Drawing.Size(260,30)
        $InputPrinterName.Add_KeyUp({
            if ($InputPrinterName.text.Length -gt 4 -and $SelectNameDriver.SelectedItem) {
                $PrinterNameBtn.Enabled = $true
            } else {
                $PrinterNameBtn.Enabled = $False
            }
        })
        $window_form1.Controls.Add($InputPrinterName)
    
        $SelectFormLabel = New-Object System.Windows.Forms.Label
        $SelectFormLabel.Text = "Выберите версию драйвера"
        $SelectFormLabel.Location = New-Object System.Drawing.Point(10,70)
        $SelectFormLabel.Width = 260
        $window_form1.Controls.Add($SelectFormLabel)
    
        $SelectNameDriver = New-Object System.Windows.Forms.ListBox
        $SelectNameDriver.Location = New-Object System.Drawing.Point(10,100)
        $SelectNameDriver.Size = New-Object System.Drawing.Size(260,10)
        foreach ($XeroxDriver in $XeroxPrinterVersionDriver) {
            $SelectNameDriver.Items.Add($XeroxDriver)
        }
        $SelectNameDriver.Height = 60
        $SelectNameDriver.Add_Click({
            if ($this.SelectedItem -and $InputPrinterName.text.Length -gt 4) {
                $PrinterNameBtn.Enabled = $True
            } else {
                $PrinterNameBtn = $False
            }
        })
        $window_form1.Controls.Add($SelectNameDriver)
    
        $PrinterNameBtn = New-Object System.Windows.Forms.Button
        $PrinterNameBtn.text = "OK"
        $PrinterNameBtn.Location = New-Object System.Drawing.Point(10,170)
        $PrinterNameBtn.Size = New-Object System.Drawing.Size(260,40)
        $PrinterNameBtn.Enabled = $False
        $PrinterNameBtn.AutoSize = $True
        $PrinterNameBtn.BackColor = '#90e1a7'
        $PrinterNameBtn.Add_Click({
            $form_status_label2.Text = "Подключение..."
            try {
                installPrinter -IPAddress $textBox1.text -ComputerName $textBox.text -PrinterName $InputPrinterName.text -ButtonName $buttonName -DriverType $SelectNameDriver.SelectedItem
                $form_status_label2.Text = "Готово"
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            catch {
                $form_status_label2.Text = "Ошибка подключения"
                msg * $_
                Start-Sleep -Seconds 5
                $form_status_label2.Text = ""
            }
            $window_form1.Close()
        })
        $window_form1.Controls.Add($PrinterNameBtn)
        $window_form1.ShowDialog()
    } else {
        msg * "Не верное имя компьютера или ip принтера"
    }
})
$window_form.Controls.Add($Xerox5024_5022)



$Remove_Printer_Box = New-Object System.Windows.Forms.ListBox
$Remove_Printer_Box.Location = New-Object System.Drawing.Point(10,260)
$Remove_Printer_Box.Size = New-Object System.Drawing.Size(530,120)
$Remove_Printer_Box.Add_Click({
    if ($Remove_Printer_Box.SelectedItem) {
        $Remove_Printer_Button_Remove.Enabled = $True
    } else {
        $Remove_Printer_Button_Remove.Enabled = $False
    }
})
$window_form.Controls.Add($Remove_Printer_Box)

$Remove_Printer_Button_Remove = New-Object System.Windows.Forms.Button
$Remove_Printer_Button_Remove.text = "Удалить принтер"
$Remove_Printer_Button_Remove.Location = New-Object System.Drawing.Point(10,380)
$Remove_Printer_Button_Remove.Size = New-Object System.Drawing.Size(260,40)
$Remove_Printer_Button_Remove.Enabled = $False
$Remove_Printer_Button_Remove.AutoSize = $True
$Remove_Printer_Button_Remove.BackColor = '#90e1a7'
$Remove_Printer_Button_Remove.Add_Click({
    $form_status_label2.text = 'Удаление...'
    $result = $Remove_Printer_Box.SelectedItem.Split(' | ')[0]
    Invoke-Command -ComputerName $textBox.text -ScriptBlock {
        param($PrinterName)
        Remove-Printer -Name $PrinterName
    } -ArgumentList $result

    $Remove_Printer_Box.Items.Clear()
    $Printers = Get-CurrentPrinter -ComputerName $textBox.text
    foreach ($item in $Printers) {
        $Remove_Printer_Box.Items.Add($item.Name + ' | ' + $item.DriverName + ' | ' + $item.PortName);
    }

    $form_status_label2.text = "Готово"
    Start-Sleep -Seconds 3
    $form_status_label2.text = ''
})
$window_form.Controls.Add($Remove_Printer_Button_Remove)

$Remove_Printer_Button_Checked = New-Object System.Windows.Forms.Button
$Remove_Printer_Button_Checked.text = "Проверить подключенные принтеры"
$Remove_Printer_Button_Checked.Location = New-Object System.Drawing.Point(280,380)
$Remove_Printer_Button_Checked.Size = New-Object System.Drawing.Size(260,40)
$Remove_Printer_Button_Checked.Enabled = $True
$Remove_Printer_Button_Checked.AutoSize = $True
$Remove_Printer_Button_Checked.BackColor = '#90e1a7'
$Remove_Printer_Button_Checked.Add_Click({
    $form_status_label2.text = "Проверка наличия подключенных принтеров..."
    $Result = Get-CurrentPrinter -ComputerName $textBox.text
    if ($Remove_Printer_Box.Items.Count -gt 0) {
        $Remove_Printer_Box.Items.Clear()
    }
    if ($Result) {
        foreach ($item in $Result) {
            $Remove_Printer_Box.Items.Add($item.Name + ' | ' + $item.DriverName + ' | ' + $item.PortName);
        }
    }

    $form_status_label2.text = "Готово"
    Start-Sleep -Seconds 3
    $form_status_label2.text = ''
})
$window_form.Controls.Add($Remove_Printer_Button_Checked)


$FormLabel5 = New-Object System.Windows.Forms.Label
$FormLabel5.Text = "Подключение через принт сервер"
$FormLabel5.Location = New-Object System.Drawing.Point(140,430)
$FormLabel5.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Regular)
$FormLabel5.AutoSize = $true
$FormLabel5.BackColor = '#c4c4c4'
$window_form.Controls.Add($FormLabel5)

$PrintServerInput = New-Object System.Windows.Forms.TextBox
$PrintServerInput.Location = New-Object System.Drawing.Point(10,460)
$PrintServerInput.Size = New-Object System.Drawing.Size(530,60)
$PrintServerInput.Add_KeyUp({
    if ($PrintServerInput.text.Length -gt 10) {
        $PrintServerButton.Enabled = $true
    } else {
        $PrintServerButton.Enabled = $False
    }
})

$window_form.Controls.Add($PrintServerInput)

$PrintServerButton = New-Object System.Windows.Forms.Button
$PrintServerButton.text = "Подключить"
$PrintServerButton.Location = New-Object System.Drawing.Point(140,490)
$PrintServerButton.Size = New-Object System.Drawing.Size(260,40)
$PrintServerButton.Enabled = $False
$PrintServerButton.AutoSize = $True
$PrintServerButton.BackColor = '#90e1a7'
$PrintServerButton.Add_Click({
    $form_status_label2.text = 'Подключение...'
    try {
        Invoke-Command -ComputerName $textBox.text -ScriptBlock {
            param($PrinterLink)
            iex "RUNDLL32 PRINTUI.DLL,PrintUIEntry /ga /n""$PrinterLink"""
            Stop-Service -Name spooler -Force
            Start-Service -Name spooler
        } -ArgumentList $PrintServerInput.text
        $form_status_label2.text = 'Подключено'
        $PrintServerInput.text = ''
        Start-Sleep -Seconds 1
        $form_status_label2.text = ''
    }
    catch {
        $form_status_label2.text = 'Ошибка подключения'
        msg * "Ошибка подключения принтера. Пожалуйста, проверьте корректность адреса принтера на принт сервере"
    }
})

$window_form.Controls.Add($PrintServerButton)


$window_form.ShowDialog()