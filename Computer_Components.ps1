# Subject              : System information with PowerShell 
# Created By           : Selcuk KILINC
# PSVersion            : 7.4.5


# Get CPU Name
try{
 $cpuname = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name
}
catch{
 $cpuname = "N/A"	
}

#Retrieve CPU Architecture. Include information on whether the CPU is 32-bit or 64-bit
$cpuArchitecture=(Get-WmiObject Win32_Processor).Architecture

$cpuArchitecture=switch($cpuArchitecture)
					{
						0 {"x86"}
						1 {"MIPS"}
						2 {"Alpha"}
						3 {"PowerPC"}
						5 {"ARM"}
						6 {"ia64"}
						9 {"x64"}
						default {"Unknown"}
						
					}

# Get CPU Clock Speed in GHz
try{ 
 $cpuClockSpeedGHz = [math]::Round((Get-WmiObject Win32_Processor | Select-Object -ExpandProperty MaxClockSpeed) / 1000, 2)
}
catch{
 $cpuClockSpeedGHz = "N/A"	
}

# Get Number of Cores
$numberOfCores = (Get-WmiObject Win32_Processor).NumberOfCores

# If Number of Logical Processors > Number of Cores, SMT or HT is enabled
$mtEnabled = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors -gt (Get-WmiObject Win32_Processor).NumberOfCores

# Define multi Threading technology
if($mtEnabled)
{
   if($cpuname -like "*AMD*")
   {
   	$mulThreadingTech="SMT"
   }
   elseif($cpuname -like "*Intel*")
   {
   	$mulThreadingTech="Hyper-Threading"
   }
   else{
   	$mulThreadingTech="N/A"
   }
}
else{
	$mulThreadingTech="N/A"
}

# Get Number of Logical Processors
$numberOfLogicalProcessors = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors

$L1CacheSize=(Get-WmiObject Win32_CacheMemory | where-object{$_.Purpose -like 'L1*'}).MaxCacheSize
$L2CacheSize=(Get-WmiObject Win32_CacheMemory | where-object{$_.Purpose -like 'L2*'}).MaxCacheSize
$L3CacheSize=(Get-WmiObject Win32_CacheMemory | where-object{$_.Purpose -like 'L3*'}).MaxCacheSize

#Get Integrated graphics name which embedded within the CPU
try{
    $integratedGraphics=(Get-WmiObject Win32_VideoController | Where-Object {$_.Description -like "*AMD*" -or $_.Description -like "*Intel*"} | Select-Object Name).Name
}
catch{
	$integratedGraphics="N/A"
}

#Retrieve the socket type of the CPU 
try {
    $socket = (Get-WmiObject Win32_Processor | Select-Object -ExpandProperty SocketDesignation)
} catch {
    $socket = "N/A"
}

#Retrieve CPU voltage
try {
    $voltage = (Get-WmiObject Win32_Processor).CurrentVoltage
} catch {
    $voltage = "N/A"
}

# Get CPU Virtualization Firmware Enabled
$virtualizationFirmwareEnabled = (Get-WmiObject Win32_Processor).VirtualizationFirmwareEnabled

# Create a custom object to hold the CPU results
$cpuInfo = [psCustomObject]@{
	"CPU_Name" = $cpuname
	"CPU_Architecture" = $cpuArchitecture
	"Clock_Speed_GHz" = $cpuClockSpeedGHz
	"Number_Of_Cores" = $numberOfCores 
	"Multithreading" = $mtEnabled
	"Multithreading_Tech" = $mulThreadingTech 
	"Number_Of_LogicalProcessors" = $numberOfLogicalProcessors
	"L1_Cache_Size_KB" = $L1CacheSize
	"L2_Cache_Size_KB" = $L2CacheSize
	"L3_Cache_Size_KB" = $L3CacheSize
	"Integrated_Graphics" = $integratedGraphics
	"Scoket_Type_of_CPU" = $socket
	"CPU_Voltage" = $voltage
	"CPU_VirtualizationFirmwareEnabled" = $virtualizationFirmwareEnabled
}

#Get Motherboard Information

$MBManufacturer = (Get-WmiObject Win32_BaseBoard | Select-Object Manufacturer).Manufacturer
$MBProduct = (Get-WmiObject Win32_BaseBoard | Select-Object Product).Product


$MotherboardInfo =[psCustomObject]@{
     "MotherboardManufacturer" = $MBManufacturer
     "MotherboardProduct" = $MBProduct 	 
}

# Get RAM Information

$RAMInfo=(Get-WmiObject Win32_PhysicalMemory | select-object BankLabel, Manufacturer,@{Name = "Capacity_GB"; Expression = {$_.Capacity / 1GB}},SMBIOSMemoryType,Speed,ConfiguredVoltage)


# Create a root object for logical separation
$rootObject = [psCustomObject]@{
    "CPU" = $cpuInfo
    "Motherboard" = $MotherboardInfo
	"RAM" = $RAMInfo
}

# Output as JSON
$rootObject | ConvertTo-Json | Out-File Server_Components.json

# Output as JSON
# $cpuInfo | ConvertTo-Json | Out-File Server_Components.json

# (Optional) Display the results in a table format
write-host "------------------------------------------ CPU ------------------------------------------"
$cpuInfo | Format-List

write-host "-------------------------------------- Motherboard --------------------------------------"
$MotherboardInfo | Format-List

write-host "------------------------------------------ RAM ------------------------------------------"
$RAMInfo | Format-List