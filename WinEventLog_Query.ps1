$startscript = get-date
$shortdate = get-date -format MM-dd-yy
$systemrunning = hostname
$runpath = get-location
$logfile = $runpath.path+"\runlog_"+$shortdate+".txt"

Write-output "Starting script at $startscript" | Tee-object -filepath $logfile
Write-output "log file location: $logfile" | Tee-Object -filepath $logfile -append
Write-output "This script is executing on $systemrunning" | Tee-Object -filepath $logfile -append
Write-output "in directory $runpath"
add-content $logfile "`r"

$targetsystem = read-host -prompt "ENTER target computername as FQDN"
$scope = read-host -prompt "(Time) based results or (Latest) entries"
$verbose = read-host -prompt "Enter verbose mode (True) or (False)"
$numberofevents = read-host -prompt "Enter maximum events per log to return"

$eventarray = @()
$logswithentries = get-winevent -computername $targetsystem -listlog * | where-object { $_.recordcount -gt 0 }

Function Add-EventDetails {
    $eventconvert = [xml]$event.toxml()
    $timecreated = get-date -date $eventconvert.event.system.timecreated.systemtime
    $provider = $eventconvert.event.system.provider.Name
    $Level = $event.LevelDisplayName
    $EID = $event.Id
    $msg = $event.message
    $newobj = [PSCustomObject]@{ 'Timestamp' = $timecreated; 'Log' = $provider; 'Level' = $level; 'EventID' = $EID; 'Message' = $msg }
    $global:eventarray+=$newobj
    }

Switch ( $scope )
    {
        Time
            {
                $beginrange = read-host -prompt "Enter initial date/time in format '11/2/2018 10:32am'"
                $endrange = read-host -prompt "Enter end date/time"
                $starttime = get-date $beginrange
                $endtime = get-date $endrange 
                foreach ( $log in $logswithentries ) {
                    $events = get-winevent $log.logname -maxevents $numberofevents | where-object {($_.TimeCreated -ge $starttime -and $_.timecreated -le $endtime)}
                        foreach ( $event in $events ) {
                            Add-EventDetails
                        }
                }
            }
        Latest
            {
                foreach ( $log in $logswithentries ) {
                    $events = get-winevent $log.logname -maxevents $numberofevents
                        foreach ( $event in $events ) {
                            Add-EventDetails
                        }
                }
            }
    }                           

Switch ( $verbose )
    {
        True
            {
                $eventarray = $eventarray | sort-object -property "Timestamp" -Descending | format-table -AutoSize -wrap 
            }
        False
            {
                $eventarray = $eventarray | sort-object -property "Timestamp" -Descending | format-table 
            }
    }
    
$eventarray | tee-object $runlog -append
