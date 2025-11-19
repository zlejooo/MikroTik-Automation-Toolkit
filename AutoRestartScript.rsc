# Script Version 1.0.0
# Auto Restart Script for MikroTik RouterOS
#*********************************************************************

# PING Configuration
:local hostToPing "8.8.8.8"     #Destination IP for ping test
:local maxFails 5               #Number of failed pings before reboot
:local failCount 0 

# Ping loop script
:for i from=1 to=$maxFails do={
    :if ([/ping $hostToPing count=1] = 0) do={
        :set failCount ($failCount + 1)
    } else={
        :set failCount 0
        :break
    }
    :delay 3s
}

# If all attempts failed, reboot
:if ($failCount = $maxFails) do={
    /system reboot
}
#*********************************************************************