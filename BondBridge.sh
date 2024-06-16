#!/bin/bash

# Lets be explicit
typeset -i a argSTART argEND

#
# Passed in required Args
#
argEND=$#
IP=""
device=""
io=""
characteristic=""
bondDevice=""
bondToken=""
fanDevice=""
lightDevice=""
value="1"
speed=""
action="state"
queryType="copy2"
ioType=""

#
# Global returned data
#
rc=1
state="{}"
#
# For optional args and arg parsing
#

# Default values
argSTART=4
logErrors=true
debugSpecified=false 
lightSpecified=false
dimmerSpecified=false
fanSpecified=false
fanTimerSpecified=false

#Temporary files - the subdirectory full path will be defined later
if [ -z "${TMPDIR}" ]; then TMPDIR="/tmp"; fi
tmpSubDir="${TMPDIR}"
BONDBRIDGE_STATE_FILE="BondBridgeState.txt"
BONDBRIDGE_LOG_FILE="BondBridge.log"

function showHelp()
{
   local rc="$1"
   cat <<'   HELP_EOF'
   Usage:
     BondBridge.sh Get < AccessoryName > < characteristic > [ Options ]
   or
     BondBridge.sh Set < AccessoryName > < characteristic > < value > [ Options ]
   Where Options maybe any of the following in any order:
     XXX.XXX.XXX.XXX    The IP address of the AirCon to talk to
     Token              The unique token of this Bond Bridge
   HELP_EOF
   exit "$rc"
}

function logError()
{
   if [ "$logErrors" != true ]; then
      return
   fi

   local comment="$1"
   local result="$2"
   local data1="$3"
   local data2="$4"
   local count=1
   local sfx
   local file
   local fileName

   sfx="$rc-$io-$device-$characteristic"
   sfx=${sfx// /_}
   fileName="${tmpSubDir}/AAerror-${sfx}.txt"
   file=$(find "${fileName}"* 2>&1|grep -v find)
   #
   # append a counter to the file so that the number of same error is logged
   if [ -f "${file}" ]; then
      getFileStaeStatDt "${file}"
      if [ "${dt}" -lt 600 ]; then
         count=$(echo "${file}" | cut -d'#' -f2)
         count=$((count + 1))
      fi
      rm -f "${file}"
   fi
   #
   fileName="${fileName}#${count}"
   { echo "$io $device $characteristic"
     echo "${comment}"
     echo "return code: $rc"
     echo "result: $result"
     echo "data1: $data1"
     echo "data2: $data2"
   } > "$fileName"
   #
   if [ "${io}" = "Set" ]; then
      logBondBridgeDiagnostic "Unhandled $io $device $characteristic $value rc=$rc, accessory is most likely inaccessible"
   else
      logBondBridgeDiagnostic "Unhandled $io $device $characteristic rc=$rc, accessory is most likely inaccessible"
   fi
}

function logBondBridgeDiagnostic()
{
   if [ "$debugSpecified" != true ]; then
      return
   fi
   local str="$1"
   echo "$str" >> "$BONDBRIDGE_LOG_FILE"

   # Delete the log if it is > 15 MB
   fSize=$(find "$BONDBRIDGE_LOG_FILE" -ls | awk '{print $7}')
   if [ "$fSize" -gt 15728640 ];then
      rm "$BONDBRIDGE_LOG_FILE"
   fi
}

function getFileStatDt()
{
   local fileName="$1"
   # This script is to determine the time of a file using 'stat'
   # command and calculate the age of the file in seconds
   # The return variables of this script:
   #    tf = last changed time of the file since Epoch
   #    t0 = current time since Epoch
   #    dt = the age of the file in seconds since last changed
   case "$OSTYPE" in
      darwin*)
         tf=$( stat -r "$fileName" | awk '{print $11}' )  # for Mac users
      ;;
      *)
         tf=$( stat -c %Z "$fileName" )
      ;;
   esac
   t0=$(date '+%s')
   dt=$((t0 - tf))
}

function queryBondBridge()
{
   local Device="$1"
   if [ -n "$2" ];then queryType="$2"; fi 

   local stateFile=""
   local stateDateFile=""

   if [ -n "$Device" ]; then 
      stateFile="$(echo "${BONDBRIDGE_STATE_FILE}"|cut -d '.' -f-2).${Device}"
   else
      Device="${bondDevice}"
      stateFile="${BONDBRIDGE_STATE_FILE}"
   fi

   stateDateFile="${stateFile}.date"

   if [[ -f "${stateDateFile}" && "${queryType}" != "fetch" ]]; then
      getFileStatDt "${stateDateFile}"
      if [ "$dt" -le 120 ]; then queryType="copy1"; fi
   fi  

   if [ "$queryType" = "copy1" ]; then
      state=$(jq -ec '.' "${stateFile}")
      rc=$?
   else
      state=$(curl -s -g -H "BOND-Token: ${bondToken}" http://"${IP}"/v2/devices/"${Device}"/state)
      properties=$(curl -s -g -H "BOND-Token: ${bondToken}" http://"${IP}"/v2/devices/"${Device}"/properties)
      rc=$?
      state=$(jq -ec --slurp 'add' <(echo "$state") <(echo "$properties"))
      state=$(echo "$state"|jq -c '{power, speed, max_speed, light}')
      if [ "$rc" != "0" ]; then
         logError "curl failed" "${state}" "${Device}/state" ""
         exit "${rc}"
      fi
      if [ -f "$stateFile" ]; then cachedState=$(cat "${stateFile}"); fi
      if [ "${state}" != "${cachedState}" ]; then
         echo "${state}" > "${stateFile}" 
         queryType="fetch"
      fi
      touch "${stateDateFile}"
   fi

   power=$(echo "$state" | jq -e ".power")
   speed=$(echo "$state" | jq -e ".speed")
   max_speed=$(echo "$state" | jq -e ".max_speed")
   light=$(echo "$state" | jq -e ".light")

   # Diagnostic logging
   log=$(printf "BondBridge_${Device}_${ioType} %10s $t0 %3s $queryType $rc $io $device $characteristic" "$tf" "$dt")
   logBondBridgeDiagnostic "$log"
}

function setBondBridge()
{
   local Device="$1"
   local action="$2"
   local argument="$3"

   if [ -z "${Device}" ]; then Device="${bondDevice}"; fi

   curl -s -g -H "BOND-Token: ${bondToken}" http://"${IP}"/v2/devices/"${Device}"/actions/"${action}" -X PUT -d "{${argument}}"
   rc=$?

   # Diagnostic logging
   log=$(printf "BondBridge_${Device}_${ioType} ++++++++++ $t0 %3s +++++ $rc $io $device $characteristic $value ${action}: $speed" "0")
   logBondBridgeDiagnostic "$log"

   if [ "$rc" != "0" ]; then
      logError "curl failed" "${state}" "${Device}/actions" "${action} -X PUT -d \"{${argument}}\""
      exit "${rc}"
   fi
}

function updateBondBridgeStateFile()
{
   local Device="$1"
   local stateFile=""

   if [ -n "${Device}" ]; then
      stateFile="$(echo "${BONDBRIDGE_STATE_FILE}"|cut -d '.' -f-2).${Device}"
   else
      Device="${bondDevice}"
      stateFile="${BONDBRIDGE_STATE_FILE}"
   fi

   updatedState=$(jq -ec ".power=$power" "${stateFile}" | jq -ec ".speed=$speed" | jq -ec ".light=$light")
   echo "$updatedState" > "${stateFile}"
}

function queryTimerStateFile()
{
   local Device="$1"
   local rc=0

   if [ -n "$2" ]; then
      queryType="$2"
   fi

   if [ -f "$BONDBRIDGE_STATE_FILE" ]; then
      state=$(jq -ec '.' "${BONDBRIDGE_STATE_FILE}")
      rc=$?
   fi
   if [[ "${rc}" != "0" || -z "$state" ]]; then
      state="{\"timeToOn\":0,\"timeToOff\":0,\"setTime\":0}"
      echo "$state" > "$BONDBRIDGE_STATE_FILE"
   fi 

   timeToOn=$(echo "$state" | jq -e ".timeToOn")
   timeToOff=$(echo "$state" | jq -e ".timeToOff")
   setTime=$(echo "$state" | jq -e ".setTime")

   log=$(printf "BondBridge_${bondDevice}_${ioType} %10s $t0 %03s timer $rc $io $device $characteristic" "$tf" "$dt") 
   logBondBridgeDiagnostic "$log" 

   # Get the state of the associated fan or light device
   queryBondBridge "${Device}" "${queryType}"
}

function updateTimers()
{
   # Update fan timer
   if [ $fanTimerSpecified = true ]; then
      if [[ "$timeToOn" = "0" && "$timeToOff" = "0" ]]; then # no update required 
         echo ""
      elif [[ "$power" = "1" && "$timeToOn" != "0" ]]; then # reset timer
         timeToOn=0
         setTime=${t0}
         updateTimerStateFile
      elif [[ "$power" = "1" && "$timeToOff" != "0" ]]; then # update timer
         timeToOff=$((timeToOff - t0 + setTime))
         timeToOff=$((timeToOff > 30? timeToOff : 0))
         setTime=${t0}
         updateTimerStateFile
         if [ "$timeToOff" = "0" ]; then # turn off the fan
            power=0
            setBondBridge "${fanDevice}" "TurnOff"
            updateBondBridgeStateFile "${fanDevice}"
         fi
      elif [[ "$power" = "0" && "$timeToOff" != "0" ]]; then # reset timer 
         timeToOff=0
         setTime=${t0}
         updateTimerStateFile
      elif [[ "$power" = "0" && "$timeToOn" != "0" ]]; then # update timer
         timeToOn=$((timeToOn - t0 + setTime))
         timeToOn=$((timeToOn > 30? timeToOn : 0))
         setTime=${t0}
         updateTimerStateFile
         if [ "$timeToOn" = "0" ]; then # turn on the fan
            power=1
            setBondBridge "${fanDevice}" "TurnOn"
            updateBondBridgeStateFile "${fanDevice}"
         fi
      fi
   fi

   # Update light timer
   if [ "${lightTimerSpecified}" = true ]; then
      if [[ "$timeToOn" = "0" && "$timeToOff" = "0" ]]; then # no update required 
         echo ""
      elif [[ "$light" = "1" && "$timeToOn" != "0" ]]; then # reset timer        
         timeToOn=0
         setTime=${t0}
         updateTimerStateFile
      elif [[ "$light" = "1" && "$timeToOff" != "0" ]]; then # update timer
         timeToOff=$((timeToOff - t0 + setTime))
         timeToOff=$((timeToOff > 30? timeToOff : 0))
         setTime=${t0}
         updateTimerStateFile
         if [ "$timeToOff" = "0" ]; then # turn off the light
            light=0
            setBondBridge "${lightDevice}" "TurnLightOff"
            updateBondBridgeStateFile "${lightDevice}"
         fi
      elif [[ "$light" = "0" && "$timeToOff" != "0" ]]; then # reset timer        
         timeToOff=0
         setTime=${t0}
         updateTimerStateFile
      elif [[ "$light" = "0" && "$timeToOn" != "0" ]]; then # update timer
         timeToOn=$((timeToOn - t0 + setTime))
         timeToOn=$((timeToOn > 30? timeToOn : 0))
         setTime=${t0}
         updateTimerStateFile
         if [ "$timeToOn" = "0" ]; then # turn on the light
            light=1
            setBondBridge "${lightDevice}" "TurnLightOn"
            updateBondBridgeStateFile "${lightDevice}"
         fi
      fi
   fi
}

function updateTimerStateFile()
{
   updatedState=$(jq -ec ".timeToOn=$timeToOn" "$BONDBRIDGE_STATE_FILE" | jq -ec ".timeToOff=$timeToOff" | jq -ec ".setTime=$setTime")
   rc=$?
   echo "$updatedState" > "$BONDBRIDGE_STATE_FILE"
   # Diagnostic logging
   log=$(printf "BondBridge_${bondDevice}_${ioType} %5s%5s $t0 %3s timer $rc $io $device $characteristic" "$timeToOn" "$timeToOff" "0") 
   logBondBridgeDiagnostic "$log" 
}

# main starts here
if [ $argEND -le 1 ]; then
   showHelp 199
fi
if [ $argEND -ge 1 ]; then
   io=$1
   if [ $argEND -ge 2 ]; then
      device=$2
   else
      echo "Error - No device given for io: ${io}"
      exit 1
   fi
   if [ $argEND -ge 3 ]; then
      characteristic=$3
   else
      echo "Error - No Characteristic given for io: ${io} ${device}"
      exit 1
   fi
   if [ "$io" = "Get" ]; then
      argSTART=4
   elif [[ "$io" == "Set" ]]; then
      argSTART=5
      if [ $argEND -ge 4 ]; then
         value=$4
      else
         echo "Error - No value given to Set: ${io}"
         exit 1
      fi
   else
      echo "Error - Invalid io: ${io}"
      exit 1
   fi
fi
# For any unprocessed arguments
if [ $argEND -ge $argSTART ]; then
   # Scan the remaining options
   for (( a=argSTART;a<=argEND;a++ ))
   do
      # convert argument number to its value
      v=${!a}
      optionUnderstood=false
      # Check the actual option against patterns
      case ${v} in
         dimmer )
           dimmerSpecified=true
         ;;
         light )
           lightSpecified=true
         ;;
         fan )
           fanSpecified=true
         ;;
         fanTimer )
           fanTimerSpecified=true
         ;;
         lightTimer )
           lightTimerSpecified=true
         ;;
         token* )
            #
            # See if the option starts with a "token"
            #
            bondToken="${v:6}"
         ;;
         device* )
            #
            # See if the option starts with a "device" for bond device         
            #
            bondDevice="${v:7}"
         ;;
         fanDevice* )
            #
            # See if the option starts with a "fanDevice": associated device        
            #
            fanDevice="${v:10}"
         ;;
         lightDevice* )
            #
            # See if the option starts with a "lightDevice": associated device        
            #
            lightDevice="${v:12}"
         ;;
         * )
            #
            # See if the option is in the format of an IP
            #
            if expr "$v" : '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*[-a-z]*$' >/dev/null; then
               IP=$(echo "$v"|cut -d"-" -f1)
               debug=$(echo "$v"|cut -d"-" -f2)
               if [ "$debug" = "debug" ]; then debugSpecified=true; fi
               optionUnderstood=true
            fi
            if [ "$optionUnderstood" = false ]; then
               echo "Unknown Option: ${v}"
               showHelp 1
            fi
         ;;
      esac
   done
fi

# Create a temporary sub-directory "${tmpSubDir}" to store the temporary files
subDir=$( echo "${IP}"|cut -d"." -f4 )
tmpSubDir=$( printf "${TMPDIR}/BB-%03d" "$subDir" )
if [ ! -d "${tmpSubDir}/" ]; then mkdir "${tmpSubDir}/"; fi

# Redefine temporary files with full path
BONDBRIDGE_STATE_FILE="${tmpSubDir}/${BONDBRIDGE_STATE_FILE}.${bondDevice}"
BONDBRIDGE_LOG_FILE="${tmpSubDir}/${BONDBRIDGE_LOG_FILE}"
#

t0=$(date '+%s')

# For "Get" Directives
if [ "$io" = "Get" ]; then

ioType="GET"

# Get the ${BONDBRIDGE_STATE_FILE}
if [[ $lightTimerSpecified = true ]]; then
   queryTimerStateFile "${lightDevice}"
elif [[ $fanTimerSpecified = true ]]; then
   queryTimerStateFile "${fanDevice}"
else
   queryBondBridge
   speed_interval=$((100 / max_speed))
fi

   case "$characteristic" in
      On )
         if [[ $lightSpecified = true || $dimmerSpecified = true ]]; then # it should be On only when the light is on       
            if [ "${light}" = "1" ]; then
               echo 1
               exit 0
            else
               echo 0
               exit 0
            fi
         elif [ $fanSpecified = true ]; then # it should be On only when the fan is On
            if [ "${power}" = "1" ]; then
               echo 1
               exit 0
            else
               echo 0
               exit 0
            fi
         elif [ $fanTimerSpecified = true ]; then 
            if [[ "$timeToOn" = "0" && "$timeToOff" = "0" ]]; then 
               echo 0
               exit 0
            elif [[ "$power" = "1" && "$timeToOff" != "0" ]]; then 
               echo 1
               exit 0
            elif [[ "$power" = "0" && "$timeToOn" != "0" ]]; then 
               echo 1
               exit 0
            fi
         elif [ $lightTimerSpecified = true ]; then 
            if [[ "$timeToOn" = "0" && "$timeToOff" = "0" ]]; then 
               echo 0
               exit 0
            elif [[ "$light" = "1" && "$timeToOff" != "0" ]]; then 
               echo 1
               exit 0
            elif [[ "$light" = "0" && "$timeToOn" != "0" ]]; then 
               echo 1
               exit 0
            fi
         fi
      ;;
      Brightness )
         if [[ $lightSpecified = true || $dimmerSpecified = true ]]; then
            echo $((speed * 14))
            exit 0
         elif [[ $fanTimerSpecified = true || $lightTimerSpecified = true ]]; then
            updateTimers
            value=$((timeToOn > timeToOff? timeToOn : timeToOff))
            value=$(((value / 360) + (value % 360 > 0)))
            echo $((value > 1? value : 1)) 
            exit 0
         fi
      ;;
      RotationSpeed )
         echo $((speed * 25))
         exit 0
      ;;
   esac
fi

# For "Set" Directives
if [ "$io" = "Set" ]; then

   ioType="PUT"


   case "$characteristic" in
      On )
         # Dimmer is only used in conjuction with Home Assistant light switch.
         # require Homekit automation to turn on/off the Dimmer when the HA light switch is turned on/off
         if [ $dimmerSpecified = true ]; then # update the $state of the device from Bond Bridge 
            ioType="UPD"
            queryBondBridge "${bondDevice}" "fetch"
            exit 0 
         fi 
         # for a full setup of fan and light, the followings are used
         # setting the state of the fan   
          if [ "$fanSpecified" = true ]; then
            queryBondBridge
            if [ "$value" = "1" ]; then
               if [ "${power}" = "0" ]; then
                  setBondBridge "" "TurnOn"
                  power=1
               fi
            else
               setBondBridge "" "TurnOff"
               power=0
            fi
            updateBondBridgeStateFile
            exit 0
         # setting the state of the light 
         elif [ $lightSpecified = true ]; then
            queryBondBridge
            if [ "$value" = "1" ]; then
               if [ "${light}" = "0" ]; then
                  setBondBridge "" "TurnLightOn"
                  light=1
               fi
            else
               setBondBridge "" "TurnLightOff"
               light=0
            fi
            updateBondBridgeStateFile
            exit 0
         # setting the state of the fan timer   
         elif [[ $fanTimerSpecified = true || $lightTimerSpecified ]]; then
            ioType="UPD"
            if [ "$value" = "1" ]; then # do nothing
               exit 0
            else
               timeToOn=0
               timeToOff=0
               setTime=${t0}
               updateTimerStateFile
               exit 0
            fi
         fi
      ;;
      #Light Bulb service for used controlling brightness of light     
      Brightness )
         if [[ $lightSpecified = true || $dimmerSpecified = true ]]; then
            queryBondBridge
            speed_interval=$((100 / max_speed))
            # calculate speed or brightness (1, 2, 3, 4, etc) based on $value & speed_interval
            speed=$(((value - 1) / speed_interval + 1))
            setBondBridge "" "SetSpeed" "\"argument\": ${speed}"
            updateBondBridgeStateFile
            exit 0
         elif [ $fanTimerSpecified = true ]; then
            ioType="UPD"
            queryTimerStateFile "${fanDevice}" "fetch"
            if [ "$power" = "1" ]; then
               timeToOff=$((value * 360))
               timeToOn=0
               setTime=${t0}
               updateTimerStateFile
               setBondBridge "${fanDevice}" "TurnOn"
            else
               timeToOn=$((value * 360))
               timeToOff=0
               setTime=${t0}
               updateTimerStateFile
               setBondBridge "${fanDevice}" "TurnOff"
            fi
            exit 0
         elif [ $lightTimerSpecified = true ]; then
            ioType="UPD"
            queryTimerStateFile "${lightDevice}" "fetch"
            if [ "$light" = "1" ]; then
               timeToOff=$((value * 360))
               timeToOn=0
               setTime=${t0}
               updateTimerStateFile
               setBondBridge "${lightDevice}" "TurnLightOn"
            else
               timeToOn=$((value * 360))
               timeToOff=0
               setTime=${t0}
               updateTimerStateFile
               setBondBridge "${lightDevice}" "TurnLightOff"
            fi
            exit 0
         fi
      ;;
      # fan speed 
      RotationSpeed )
         if [ $fanSpecified = true ]; then
            queryBondBridge "${bondDevice}" "fetch"
            speed_interval=$((100 / max_speed))
            # calculate speed (1, 2, 3, 4, etc...) based on $value & $speed_interval
            speed=$(((value - 1) / speed_interval + 1))
            power=1  # It was built-in in BondBridge that if the speed is set, the fan will turn on anyway!
            setBondBridge "" "SetSpeed" "\"argument\": ${speed}"
            updateBondBridgeStateFile
            exit 0
         fi
      ;;
   esac
fi
echo "Unhandled $io $device $characteristic" >&2
exit 150
