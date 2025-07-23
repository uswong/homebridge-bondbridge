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
value=""
speed=""
action="state"
ioType=""

#
# Global returned data
#
rc=0
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
lightTimerSpecified=false

#Temporary files - the subdirectory full path will be defined later
if [ -z "${TMPDIR}" ]; then TMPDIR="/tmp"; fi
tmpSubDir="${TMPDIR}"
BONDBRIDGE_STATE_FILE="BBstate.txt"
BONDBRIDGE_TIMER_STATE_FILE="BBtimerState.txt"
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
   local sfx
   sfx="$rc-$io-$device-$characteristic"
   sfx=${sfx// /_}
   local fileName="${tmpSubDir}/BBerror-${sfx}.txt"
   file=$(find "${fileName}"* 2>&1|grep -v find)
   #
   # append a counter to the file so that the number of same error is logged
   if [ -f "${file}" ]; then
      count=$(echo "${file}" | cut -d'#' -f2)
      count=$((count + 1))
   else
      count=1
   fi
   rm -f "${file}"
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
      logBBdiagnostic "Unhandled $io $device $characteristic $value rc=$rc, accessory is most likely inaccessible"
   else
      logBBdiagnostic "Unhandled $io $device $characteristic rc=$rc, accessory is most likely inaccessible"
   fi
}

function logBBdiagnostic()
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

function queryBondBridge()
{
   local Device="$1"
   local queryType="$2" 
   local ioType="GET"
   local name

   if [ -z "$Device" ]; then 
      Device="${bondDevice}"
   fi

   name=$( echo "${device}" | sed -E 's/ (Timer|Dimmer)$//' )

   if [ -f "${BONDBRIDGE_STATE_FILE}" ]; then
      state=$( jq -c "." "${BONDBRIDGE_STATE_FILE}")
      cachedDeviceState=$( echo "${state}" | jq -c ".B${Device}" )
   else
      state="{}"
   fi

   if [[ "${cachedDeviceState}" != "null" && "${state}" != "{}" && "${queryType}" != "fetch" ]]; then
      queryType="copy "
   else
      queryType="fetch"
   fi  

   #Calculate some basic info for the diagnostic
   tf=$( echo "$state" | jq ".B${Device}.lastFetched" )
   dt=$(( t0 - tf ))
   
   if [ "$queryType" = "fetch" ]; then

      # log the fetch instances
      # debugSpecified=true

      deviceState=$(curl -s -g -H "BOND-Token: ${bondToken}" http://"${IP}"/v2/devices/"${Device}"/state)
      rc=$?
      if [ "$rc" != "0" ]; then
         logError "curl failed" "${state}" "${Device}/state" ""
         exit "${rc}"
      fi
      deviceProperties=$(curl -s -g -H "BOND-Token: ${bondToken}" http://"${IP}"/v2/devices/"${Device}"/properties)
      deviceState=$( jq -c --slurp 'add' <(echo "{\"name\":\"${name}\"}") <(echo "$deviceState") <(echo "$deviceProperties") <(echo "{\"lastFetched\":$t0}") )
      deviceState=$( echo "${deviceState}"  |jq -c '{name, power, speed, max_speed, light, lastFetched}' )
      state=$( echo "${state}" | jq -c ".B${Device} |= ${deviceState}" )
      echo "${state}" > "${BONDBRIDGE_STATE_FILE}" 
   fi

   power=$( echo "$state"     | jq ".B${Device}.power" )
   speed=$( echo "$state"     | jq ".B${Device}.speed" )
   max_speed=$( echo "$state" | jq ".B${Device}.max_speed" )
   light=$( echo "$state"     | jq ".B${Device}.light" )

   # Diagnostic logging
   tm0=$( date -d @"$t0" | cut -d" " -f4 )
   tmf="+++ $( date -d @"$tf" | cut -d" " -f4 )"
   log=$(printf "BondBridge_${Device}_${ioType} %12s %8s %5s $queryType $rc $io $device $characteristic" "$tmf" "$tm0" "$dt")
   logBBdiagnostic "$log"
}

function setBondBridge()
{
   local Device="$1"
   local action="$2"
   local argument="$3"
   local ioType="PUT"

   if [ -z "${Device}" ]; then Device="${bondDevice}"; fi

   curl -s -g -H "BOND-Token: ${bondToken}" http://"${IP}"/v2/devices/"${Device}"/actions/"${action}" -X PUT -d "{${argument}}"
   rc=$?

   # Diagnostic logging
   tm0=$( date -d @"$t0" | cut -d" " -f4 )
   log=$(printf "BondBridge_${Device}_${ioType} ++++++++++++ %8s %5s +++++ $rc $io $device $characteristic $value ${action}: $speed" "$tm0" "0")
   logBBdiagnostic "$log"

   if [ "$rc" != "0" ]; then
      logError "curl failed" "${state}" "${Device}/actions" "${action} -X PUT -d \"{${argument}}\""
      exit "${rc}"
   fi
}

function updateBondBridgeStateFile()
{
   local Device="$1"
   local action="$2"
   local value="$3"
   local ioType="UPD"         


   if [ -z "${Device}" ]; then Device="${bondDevice}"; fi

   updatedState=$( jq -c ".B${Device}.power       |= $power" "${BONDBRIDGE_STATE_FILE}" \
                 | jq -c ".B${Device}.speed       |= $speed" \
                 | jq -c ".B${Device}.light       |= $light" \
                 | jq -c ".B${Device}.lastFetched |= $t0" )
   echo "$updatedState" > "${BONDBRIDGE_STATE_FILE}"

   tm0=$( date -d @"$t0" | cut -d" " -f4 )
   log=$(printf "BondBridge_${Device}_${ioType} ++++++++++++ %8s %5s +++++ $rc $io $device $characteristic ${action}: ${value}" "$tm0" "0")
   logBBdiagnostic "$log" 
}

function queryTimerStateFile()
{
   local ioType="GET"

   if [ -f "$BONDBRIDGE_TIMER_STATE_FILE" ]; then
      state=$( jq -c "." "${BONDBRIDGE_TIMER_STATE_FILE}" )
      deviceState=$( echo "${state}" | jq -c ".T${bondDevice}" )
   else
      state="{}"
   fi
   if [[ "${deviceState}" = "null" || "${state}" = "{}" ]]; then
      deviceState="{\"name\":\"${device}\",\"timeToOn\":0,\"timeToOff\":0,\"setTime\":0}"
      state=$( echo "${state}" | jq -c ".T${bondDevice} |= ${deviceState}" )
      echo "${state}" > "$BONDBRIDGE_TIMER_STATE_FILE"
   fi 

   timeToOn=$(echo "$state"  | jq ".T${bondDevice}.timeToOn")
   timeToOff=$(echo "$state" | jq ".T${bondDevice}.timeToOff")
   setTime=$(echo "$state"   | jq ".T${bondDevice}.setTime")

   tm0=$( date -d @"$t0" | cut -d" " -f4 )
   tmf="+++ $( date -d @"$tf" | cut -d" " -f4 )"
   log=$(printf "BondBridge_${bondDevice}_${ioType} %12s %8s %5s timer $rc $io $device $characteristic" "$tmf" "$tm0" "$dt") 
   logBBdiagnostic "$log" 
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
            updateBondBridgeStateFile "${fanDevice}" "TurnOff" ""
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
            updateBondBridgeStateFile "${fanDevice}" "TurnOn" ""
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
            updateBondBridgeStateFile "${lightDevice}" "TurnLightOff" ""
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
            updateBondBridgeStateFile "${lightDevice}" "TurnLightOn" ""
         fi
      fi
   fi
}

function updateTimerStateFile()
{
   local ioType="UPD"

   updatedState=$( jq -c ".T${bondDevice}.timeToOn  |= $timeToOn" "$BONDBRIDGE_TIMER_STATE_FILE" \
                 | jq -c ".T${bondDevice}.timeToOff |= $timeToOff" \
                 | jq -c ".T${bondDevice}.setTime   |= $setTime" )
   echo "${updatedState}" > "$BONDBRIDGE_TIMER_STATE_FILE"
   # Diagnostic logging
   tm0=$( date -d @"$t0" | cut -d" " -f4 )
   log=$(printf "BondBridge_${bondDevice}_${ioType} %-6s%6s %8s %5s timer $rc $io $device $characteristic" "$timeToOn" "$timeToOff" "$tm0" "0") 
   logBBdiagnostic "$log" 
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
BONDBRIDGE_STATE_FILE="${tmpSubDir}/${BONDBRIDGE_STATE_FILE}"
BONDBRIDGE_TIMER_STATE_FILE="${tmpSubDir}/${BONDBRIDGE_TIMER_STATE_FILE}"
BONDBRIDGE_LOG_FILE="${tmpSubDir}/${BONDBRIDGE_LOG_FILE}"
#

t0=$(date '+%s')

# For "Get" Directives
if [ "$io" = "Get" ]; then

ioType="GET"

# Get the ${BONDBRIDGE_STATE_FILE}
if [[ $lightTimerSpecified = true ]]; then
   queryBondBridge "${lightDevice}"
   queryTimerStateFile
elif [[ $fanTimerSpecified = true ]]; then
   queryBondBridge "${fanDevice}"
   queryTimerStateFile
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
            echo $((speed * speed_interval))
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
         echo $((speed * speed_interval))
         exit 0
      ;;
   esac
fi

# For "Set" Directives
if [ "$io" = "Set" ]; then

   case "$characteristic" in
      On )
         # Dimmer is only used in conjuction with Home Assistant light switch.
         # require Homekit automation to turn on/off the Dimmer when the HA light switch is turned on/off
         if [ $dimmerSpecified = true ]; then # update the $state of the device from Bond Bridge
            queryBondBridge "${bondDevice}" "fetch"
            exit 0
         fi
         # for a full setup of fan and light, the followings are used
         # setting the state of the fan
          if [ "$fanSpecified" = true ]; then
            queryBondBridge
            if [ "$value" = "1" ]; then
               if [ "${power}" = "0" ]; then
                  action="TurnOn"
                  power=1
               fi
            else
               action="TurnOff"
               power=0
            fi
            setBondBridge "" "${action}"
            updateBondBridgeStateFile "" "${action}"
            exit 0
         # setting the state of the light
         elif [ $lightSpecified = true ]; then
            queryBondBridge
            if [ "$value" = "1" ]; then
               if [ "${light}" = "0" ]; then
                  action="TurnLightOn"
                  light=1
               fi
            else
               action="TurnLightOff"
               light=0
            fi
            setBondBridge "" "${action}"
            updateBondBridgeStateFile "" "${action}"
            exit 0
         # setting the state of the fan timer
         elif [[ $fanTimerSpecified = true || $lightTimerSpecified ]]; then
            if [ "$value" = "1" ]; then # do nothing
               exit 0
            else
               timeToOn=0
               timeToOff=0
               setTime=${t0}
               updateTimerStateFile
               if [ $fanTimerSpecified = true ]; then
                  # query the state of the fan as the fan was turned on or off
                  # by Home Assistant
                  queryBondBridge "${fanDevice}" "fetch"
               fi
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
            updateBondBridgeStateFile "" "SetSpeed" "S{speed}"
            exit 0
         elif [ $fanTimerSpecified = true ]; then
            queryBondBridge "${fanDevice}" "fetch"
            queryTimerStateFile
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
            queryBondBridge "${lightDevice}" "fetch"
            queryTimerStateFile
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
            updateBondBridgeStateFile "" "SetSpeed" "${speed}"
            exit 0
         fi
      ;;
   esac
fi
echo "Unhandled $io $device $characteristic" >&2
exit 150
