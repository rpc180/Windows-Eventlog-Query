$startscript = get-date
$shortdate = get-date -format MM-dd-yy
$systemrunning = hostname
$runpath = get-location
$logfile = $runpath.path+"\runlog_"+$shortdate+".txt"

Write-output "Starting script at $startscript" | Tee-object -filepath $logfile
Write-output "log file location: $logfile" | Tee-Object -filepath $logfile -append
Write-output "This script is executing on $systemrunning" | Tee-Object -filepath $logfile -append
Write-output "in directory $runpath"

$targetsystem = read-host -prompt "ENTER target computername as FQDN"
$scope = read-host -prompt "(Time) based results or (Last) entries"
$verbose = read-host -prompt "Enter verbose mode (True) or (False)"
$numberofevents = read-host -prompt "Enter maximum events to return"

Switch ( $scope )
    {
        Time
            {
                $beginrange = read-host -prompt "Enter initial date/time in format '11/2/2018 10:32am'"
                $endrange = read-host -prompt "Enter end date/time"
                $starttime = get-date $beginrange
                $endtime = get-date $endrange
                $logswithentries = get-winevent -computername $targetsystem -listlog * | where-object { $_.recordcount -gt 0 }
                foreach ( $log in $logswithentries ) {
                    if ( $verbose -eq 'True' ) 
                        {
                        get-winevent -computername $targetsystem -logname $log.logname -maxevents $numberofevents | where-object {($_.TimeCreated -ge $starttime -and $_.timecreated -le $endtime)} | ft -auto -wrap | write-output | tee-object $logfile -append                      
                        }
                    elseif ( $verbose -eq 'False' ) 
                        {            
                        get-winevent -computername $targetsystem -logname $log.logname -maxevents $numberofevents | where-object {($_.TimeCreated -ge $starttime -and $_.timecreated -le $endtime)} | write-output | tee-object $logfile -append
                        }
                    }
             }
        Last
            {
                $logswithentries = get-winevent -computername $targetsystem -listlog * | where-object { $_.recordcount -gt 0 }
                foreach ( $log in $logswithentries ) {
                    if ( $verbose -eq 'True' )
                        {
                        get-winevent -computername $targetsystem -logname $log.logname -maxevents $numberofevents | ft -auto -wrap | write-output | tee-object $logfile -append
                        }
                    elseif ( $verbose -eq 'False' )
                        {
                        get-winevent -computername $targetsystem -logname $log.logname -maxevents $numberofevents | write-output | tee-object $logfile -append
                        }
                    }
            }
    }