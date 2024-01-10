#!/bin/bash
#
# This script is to generate a complete Cmd4 configuration file needed for the cmd4-bondbridge plugin
# This script can handle up to 3 independent BondBridge (BB) systems
#
# This script can be invoked in two ways:  
# 1. from homebridge customUI
#    a. click "SETTING" on cmd4-bondbridge plugin and 
#    b. at the bottom of the SETTING page, define your BondBridge Device(s), then clikc SAVE
#    c. click "SETTING" again and 
#    d. check the checkbox if you want a full setup with a Fan and a Light, otherwise a light dimmer only
#    e. click "CONFIG CREATOR" button 
#
# 2. from a terminal
#    a. find out where the bash script "ConfigCreator.sh" is installed (please see plugin wiki for details)  
#    b. run the bash script ConfigCreator.sh 
#    c. Enter the name and IP address of your BondBridge device(s) - up to 3 systems can be processed
#    d. you can choose whether you want the fan to be setup as fanSwitch or not
#    e. you might need to enter the path to BondBridge.sh if it is not found by the script. 
#    f. you might also need to enter the path to the Homebridge config.json file if it is not found by the script.
#      
# Once the Cmd4 configuration file is generated and copied to Homebridge config.json and if you know
# what you are doing you can do some edits on the Cmd4 configuration file in Cmd4 Config Editor
# Click SAVE when you are done.
#
UIversion="customUI"

BBIP="$1"
BBtoken="$2"
BBdebug="$3"
BBIP2="$4"
BBtoken2="$5"
BBdebug2="$6"
BBIP3="$7"
BBtoken3="$8"
BBdebug3="$9"
fullSetup="${10}"
timerSetup="${11}"
BONDBRIDGE_SH_PATH="${12}"

# define the possible names for cmd4 platform
cmd4Platform=""
cmd4Platform1="\"platform\": \"Cmd4\""
cmd4Platform2="\"platform\": \"homebridge-cmd4\""

# define some other variables
name=""

# define some file variables
homebridgeConfigJson=""           # homebridge config.json
configJson="config.json.copy"     # a working copy of homebridge config.json
cmd4ConfigJson="cmd4Config.json"  # Homebridge-Cmd4 config.json
cmd4ConfigJsonBB="cmd4Config_BB.json"
cmd4ConfigConstantsBB="cmd4Config.json.BBconstants"
cmd4ConfigQueueTypesBB="cmd4Config.json.BBqueueTypes"
cmd4ConfigAccessoriesBB="cmd4Config.json.BBaccessories"
cmd4ConfigJsonBBwithNonBB="${cmd4ConfigJsonBB}.withNonBB"
cmd4ConfigNonBB="cmd4Config.json.nonBB"
cmd4ConfigConstantsNonBB="cmd4Config.json.nonBBconstants"
cmd4ConfigQueueTypesNonBB="cmd4Config.json.nonBBqueueTypes"
cmd4ConfigAccessoriesNonBB="cmd4Config.json.nonBBaccessories"
cmd4ConfigMiscKeys="cmd4Config.json.miscKeys"
configJsonNew="${configJson}.new"     # new homebridge config.json

# fun color stuff
BOLD=$(tput bold)
TRED=$(tput setaf 1)
TGRN=$(tput setaf 2)
TYEL=$(tput setaf 3)
TPUR=$(tput setaf 5)
TLBL=$(tput setaf 6)
TNRM=$(tput sgr0)


function cmd4Header()
{
   local debugCmd4="false"

   if [ "${debug}" = "true" ]; then
      debugCmd4="true"
   fi

   { echo "{"
     echo "    \"platform\": \"Cmd4\","
     echo "    \"name\": \"Cmd4\","
     echo "    \"debug\": ${debugCmd4},"
     echo "    \"outputConstants\": false,"
     echo "    \"statusMsg\": true,"
     echo "    \"timeout\": 60000,"
     echo "    \"stateChangeResponseTime\": 0,"
   } > "$1"
}

function cmd4ConstantsHeader()
{
   { echo "    \"constants\": ["
   } > "$1"
}

function cmd4Constants()
{
   local debugA=""

   if [ "${debug}" = "true" ]; then
      debugA="-debug"
   fi

   { echo "        {"
     echo "            \"key\": \"${ip}\","
     echo "            \"value\": \"${IPA}${debugA}\""
     echo "        },"
   } >> "$1"
}

function cmd4QueueTypesHeader()
{
   { echo "    \"queueTypes\": ["
   } > "$1"
}

function cmd4QueueTypes()
{
   { echo "        {"
     echo "            \"queue\": \"${queue}\","
     echo "            \"queueType\": \"WoRm2\""
     echo "        },"
   } >> "$1"
}

function cmd4AccessoriesHeader()
{
   { echo "    \"accessories\": ["
   } > "$1"
}

function cmd4ConstantsQueueTypesAccessoriesMiscFooter()
{
   cp "$1" "$1.temp"
   sed '$ d' "$1.temp" > "$1" 
   rm "$1.temp"
   
   { echo "        }"
     echo "    ],"
   } >> "$1"
}

function cmd4Fan()
{
   local name="$2"

   { echo "        {"
     echo "            \"type\": \"Fan\","
     echo "            \"displayName\": \"${name}\","
     echo "            \"on\": \"FALSE\","
     echo "            \"rotationSpeed\": 25,"
     echo "            \"name\": \"${name}\","
     echo "            \"manufacturer\": \"OLIBRA\","
     echo "            \"model\": \"${model}\","
     echo "            \"serialNumber\": \"${bondid}\","
     echo "            \"queue\": \"$queue\","
     echo "            \"polling\": ["
     echo "                {"
     echo "                    \"characteristic\": \"on\""
     echo "                },"
     echo "                {"
     echo "                    \"characteristic\": \"rotationSpeed\""
     echo "                }"
     echo "            ],"
     echo "            \"state_cmd\": \"'${BONDBRIDGE_SH_PATH}'\","
     echo "            \"state_cmd_suffix\": \"fan 'token:${bondToken}' 'device:${device}' ${ip}\""
     echo "        },"
   } >> "$1"
}

function cmd4Lightbulb()
{
   local name="$2"
   local accType="$3"
   { echo "        {"
     echo "            \"type\": \"Lightbulb\","
     echo "            \"displayName\": \"${name}\","
     echo "            \"on\": \"FALSE\","
     echo "            \"brightness\": 25,"
     echo "            \"name\": \"${name}\","
     echo "            \"manufacturer\": \"OLIBRA\","
     echo "            \"model\": \"${model}\","
     echo "            \"serialNumber\": \"${bondid}\","
     echo "            \"queue\": \"$queue\","
     echo "            \"polling\": ["
     echo "                {"
     echo "                    \"characteristic\": \"on\""
     echo "                },"
     echo "                {"
     echo "                    \"characteristic\": \"brightness\""
     echo "                }"
     echo "            ],"
     echo "            \"state_cmd\": \"'${BONDBRIDGE_SH_PATH}'\","
     echo "            \"state_cmd_suffix\": \"${accType} 'token:${bondToken}' 'device:${device}' ${ip}\""
     echo "        },"
   } >> "$1"
}

function cmd4TimerLightbulb()
{
   local name="$2"
   local accType="$3"
   local deviceType="$4"

   { echo "        {"
     echo "            \"type\": \"Lightbulb\","
     echo "            \"displayName\": \"${name}\","
     echo "            \"on\": \"FALSE\","
     echo "            \"brightness\": 0,"
     echo "            \"name\": \"${name}\","
     echo "            \"manufacturer\": \"OLIBRA\","
     echo "            \"model\": \"${model}\","
     echo "            \"serialNumber\": \"${bondid}\","
     echo "            \"queue\": \"$queue\","
     echo "            \"polling\": ["
     echo "                {"
     echo "                    \"characteristic\": \"on\""
     echo "                },"
     echo "                {"
     echo "                    \"characteristic\": \"brightness\""
     echo "                }"
     echo "            ],"
     echo "            \"state_cmd\": \"'${BONDBRIDGE_SH_PATH}'\","
     echo "            \"state_cmd_suffix\": \"${accType} 'token:${bondToken}' 'device:${timerDevice}' '${deviceType}:${device}' ${ip}\""
     echo "        },"
   } >> "$1"
}

function cmd4Footer()
{
   lastLine=$(tail -n 1 "$1")
   squareBracket=$(echo "${lastLine}"|grep "]") 

   cp "$1" "$1.temp"
   sed '$ d' "$1.temp" > "$1" 
   rm "$1.temp"
   #                               
   if [ -n "${squareBracket}" ]; then
      { echo "    ]"                      
        echo "}"
      } >> "$1"
   else
      { echo "    }"                      
        echo "}"
      } >> "$1"
   fi
}

function readHomebridgeConfigJson()
{
   case  $UIversion in
      customUI )
         DIR=$(pwd) 
         homebridgeConfigJson="${DIR}/config.json"
         if [ -f "${homebridgeConfigJson}" ]; then
            # expand the json just in case it is in compact form
            jq --indent 4 '.' "${homebridgeConfigJson}" > "${configJson}"
            checkForPlatformCmd4InHomebridgeConfigJson
            if [ -z "${validFile}" ]; then
               echo "ERROR: no Cmd4 Config found in \"${homebridgeConfigJson}\"! Please ensure that Homebridge-Cmd4 plugin is installed"
               exit 1
            fi
         else
            echo "ERROR: no Homebridge config.json found in \"${DIR}\"! Please copy \"${cmd4ConfigJsonBB}\" to cmd4 JASON Config manually."
            cleanUp
            exit 1
         fi
      ;;
      nonUI )
         INPUT=""
         homebridgeConfigJson=""
         getHomebridgeConfigJsonPath
         if [ "${fullPath}" != "" ]; then homebridgeConfigJson="${fullPath}"; fi 
 
         # if no config.json file found, ask user to input the full path
         if [ -z "${homebridgeConfigJson}" ]; then
            homebridgeConfigJson=""
            echo ""
            echo "${TPUR}WARNING: No Homebridge config.json file located by the script!${TNRM}"
            echo ""
            until [ -n "${INPUT}" ]; do
               echo "${TYEL}Please enter the full path of your Homebridge config.json file,"
               echo "otherwise just hit enter to abort copying \"${cmd4ConfigJsonBB}\" to Homebridge config.json."
               echo "The config.json path should be in the form of /*/*/*/config.json ${TNRM}"
               read -r -p "${BOLD}> ${TNRM}" INPUT
               if [ -z "${INPUT}" ]; then
                  echo "${TPUR}WARNING: No Homebridge config.json file specified"
                  echo "         Copying of ${cmd4ConfigJsonBB} to Homebridge config.json was aborted"
                  echo ""
                  echo "${TLBL}${BOLD}INFO: Please copy/paste the ${cmd4ConfigJsonBB} into Cmd4 JASON Config Editor manually${TNRM}"
                  cleanUp
                  exit 1
               elif expr "${INPUT}" : '[./a-zA-Z0-9]*/config.json$' >/dev/null; then
                  if [ -f "${INPUT}" ]; then
                     homebridgeConfigJson="${INPUT}"
                     break
                  else
                     echo ""
                     echo "${TPUR}WARNING: No such file exits!${TNRM}"
                     echo ""
                     INPUT=""
                  fi
               else
                  echo ""
                  echo "${TPUR}WARNING: Wrong format for file path for Homebridge config.json!${TNRM}"
                  echo ""
                  INPUT=""
               fi
           done
         fi
         if [ -f "${homebridgeConfigJson}" ]; then
            if [ -z "${INPUT}" ]; then
               echo ""
               echo "${TLBL}INFO: The Homebridge config.json found: ${homebridgeConfigJson}${TNRM}"
               echo ""
            else
               echo ""
               echo "${TLBL}INFO: The Homebridge config.json specified: ${homebridgeConfigJson}${TNRM}"
               echo ""
            fi
            # expand the json just in case it is in compact form
            jq --indent 4 '.' "${homebridgeConfigJson}" > "${configJson}"
            checkForPlatformCmd4InHomebridgeConfigJson
            if [ -z "${validFile}" ]; then
               echo ""
               echo "${TRED}ERROR: no Cmd4 Config found in \"${homebridgeConfigJson}\"! Please ensure that Homebridge-Cmd4 plugin is installed${TNRM}"
               echo "${TLBL}INFO: ${cmd4ConfigJsonBB} was created but not copied to Homebridge-Cmd4 JASON Config Editor!"
               echo "      Please copy/paste the ${cmd4ConfigJsonBB} into Cmd4 JASON Config Editor manually${TNRM}"
               cleanUp
               exit 1
            fi
         fi
      ;;
   esac
}

function extractCmd4ConfigFromConfigJson()
{
   noOfPlatforms=$(( $( jq ".platforms|keys" "${configJson}" | wc -w) - 2 ))
   cmd4PlatformName=$(echo "${cmd4Platform}"|cut -d'"' -f4)
   for ((i=0; i<noOfPlatforms; i++)); do
      plaftorm=$( jq ".platforms[${i}].platform" "${configJson}" )
      if [ "${plaftorm}" = "\"${cmd4PlatformName}\"" ]; then
         jq --indent 4 ".platforms[${i}]" "${configJson}" > "${cmd4ConfigJson}"
         jq --indent 4 "del(.platforms[${i}])" "${configJson}" > "${configJson}.Cmd4less"
         break
      fi
   done
}

function extractCmd4ConfigNonBBandAccessoriesNonBB()
{
   BBaccessories=""
   count=0
   presenceOfAccessories=$(jq ".accessories" "${cmd4ConfigJson}")
   if [ "${presenceOfAccessories}" != "null" ]; then
      noOfAccessories=$(( $( jq ".accessories|keys" "${cmd4ConfigJson}" | wc -w) - 2 ))
      for (( i=0; i<noOfAccessories; i++ )); do
         cmd4StateCmd=$( jq ".accessories[${i}].state_cmd" "${cmd4ConfigJson}" | grep -n "homebridge-cmd4-bondbridge" )

         # save the ${i} n a string for use to delete the BB accessories from ${cmd4ConfigJson}
         if [ "${cmd4StateCmd}" != "" ]; then
            if [ "${BBaccessories}" = "" ]; then
               BBaccessories="${i}"
            else
               BBaccessories="${BBaccessories},${i}"
            fi
         else   # create the non-BB accessories
            count=$(( count + 1 ))
            if [ "${count}" -eq 1 ]; then
               jq --indent 4 ".accessories[${i}]" "${cmd4ConfigJson}" > "${cmd4ConfigAccessoriesNonBB}"
            else
               sed '$d' "${cmd4ConfigAccessoriesNonBB}" > "${cmd4ConfigAccessoriesNonBB}.tmp"
               mv "${cmd4ConfigAccessoriesNonBB}.tmp" "${cmd4ConfigAccessoriesNonBB}"
               echo "}," >> "${cmd4ConfigAccessoriesNonBB}"
               jq --indent 4 ".accessories[${i}]" "${cmd4ConfigJson}" >> "${cmd4ConfigAccessoriesNonBB}"
            fi
         fi
      done
   fi

   # delete the BB accessories to create ${cmd4ConfigNonBB} for use later 
   if [ "${BBaccessories}" = "" ]; then
      cp "${cmd4ConfigJson}" "${cmd4ConfigNonBB}"
   else
      jq --indent 4 "del(.accessories[${BBaccessories}])" "${cmd4ConfigJson}" > "${cmd4ConfigNonBB}"
   fi

   # check that there are non-BB accessories, if not, remove the file
   if [ -f "${cmd4ConfigAccessoriesNonBB}" ]; then
      validFile=$(head -n 1 "${cmd4ConfigAccessoriesNonBB}")
      if [ "${validFile}" = "" ]; then rm "${cmd4ConfigAccessoriesNonBB}"; fi
   fi 
}

function extractNonBBconstants()
{
   count=0
   noOfConstans=$(( $( jq ".constants|keys" "${cmd4ConfigNonBB}" | wc -w) - 2 ))
   for ((i=0; i<noOfConstans; i++)); do
      key=$( jq ".constants[${i}].key" "${cmd4ConfigNonBB}" )
      key=${key//\"/}
      keyUsed=$(grep -n "${key}" "${cmd4ConfigAccessoriesNonBB}"|grep -v 'key'|head -n 1|cut -d":" -f1)
      if [ -n "${keyUsed}" ]; then
         count=$(( count + 1 ))
         if [ "${count}" -eq 1 ]; then
            jq --indent 4 ".constants[${i}]" "${cmd4ConfigNonBB}" > "${cmd4ConfigConstantsNonBB}"
         else
            sed '$d' "${cmd4ConfigConstantsNonBB}" > "${cmd4ConfigConstantsNonBB}.tmp"
            mv "${cmd4ConfigConstantsNonBB}.tmp" "${cmd4ConfigConstantsNonBB}"
            echo "}," >> "${cmd4ConfigConstantsNonBB}"
            jq --indent 4 ".constants[${i}]" "${cmd4ConfigNonBB}" >> "${cmd4ConfigConstantsNonBB}"
         fi
      fi
   done
   if [ -f "${cmd4ConfigConstantsNonBB}" ]; then
      validFile=$(head -n 1 "${cmd4ConfigConstantsNonBB}")
      if [ "${validFile}" = "" ]; then rm "${cmd4ConfigConstantsNonBB}"; fi
   fi
}

function extractNonBBqueueTypes()
{
   count=0
   noOfQueues=$(( $( jq ".queueTypes|keys" "${cmd4ConfigNonBB}" | wc -w) - 2 ))
   for ((i=0; i<noOfQueues; i++)); do
      queue=$( jq ".queueTypes[${i}].queue" "${cmd4ConfigNonBB}" )
      queueUsed=$(grep -n "${queue}" "${cmd4ConfigAccessoriesNonBB}"|head -n 1)
      if [ -n "${queueUsed}" ]; then
         count=$(( count + 1 ))
         if [ "${count}" -eq 1 ]; then
            jq --indent 4 ".queueTypes[${i}]" "${cmd4ConfigNonBB}" > "${cmd4ConfigQueueTypesNonBB}"
         else
            sed '$d'  "${cmd4ConfigQueueTypesNonBB}" > "${cmd4ConfigQueueTypesNonBB}.tmp"
            mv "${cmd4ConfigQueueTypesNonBB}.tmp" "${cmd4ConfigQueueTypesNonBB}"
            echo "}," >> "${cmd4ConfigQueueTypesNonBB}"
            jq --indent 4 ".queueTypes[${i}]" "${cmd4ConfigNonBB}" >> "${cmd4ConfigQueueTypesNonBB}"
         fi
      fi
   done
   if [ -f "${cmd4ConfigQueueTypesNonBB}" ]; then
      validFile=$(head -n 1 "${cmd4ConfigQueueTypesNonBB}")
      if [ "${validFile}" = "" ]; then rm "${cmd4ConfigQueueTypesNonBB}"; fi
   fi
}

function extractCmd4MiscKeys()
{
   # Extract any misc Cmd4 Keys used for non-BB accessories 
   count=0
   keys=$( jq ".|keys" "${cmd4ConfigNonBB}" )
   noOfKeys=$(( $(echo "${keys}" | wc -w) - 2 ))
   for ((i=0; i<noOfKeys; i++)); do
      key=$( echo "${keys}" | jq ".[${i}]" )
      key=${key//\"/}
      if [[ "${key}" != "platform" && "${key}" != "name" && "${key}" != "debug" && "${key}" != "outputConstants" && "${key}" != "statusMsg" && "${key}" != "timeout" && "${key}" != "stateChangeResponseTime" && "${key}" != "constants" && "${key}" != "queueTypes" && "${key}" != "accessories" ]]; then
         count=$(( count + 1 ))
         miscKey=$( echo "${keys}" | jq ".[${i}]" )
         if [ "${count}" -eq 1 ]; then echo "{" >> "${cmd4ConfigMiscKeys}"; fi
         if [ "${count}" -gt 1 ]; then echo "," >> "${cmd4ConfigMiscKeys}"; fi
         echo "${miscKey}:" >> "${cmd4ConfigMiscKeys}"
         jq --indent 4 ".${miscKey}" "${cmd4ConfigNonBB}" >> "${cmd4ConfigMiscKeys}"
      fi
   done
   if [ -f "${cmd4ConfigMiscKeys}" ]; then
      validFile=$(head -n 1 "${cmd4ConfigMiscKeys}")
      if [ -z "${validFile}" ]; then
         rm -f "${cmd4ConfigMiscKeys}"
      else
         # reformat it to proper json and then remove the "{" and "}" at the begining and the end of the file
         echo "}" >> "${cmd4ConfigMiscKeys}"
         jq --indent 4 '.' "${cmd4ConfigMiscKeys}" | sed '1d;$d' > "${cmd4ConfigMiscKeys}".tmp
         mv "${cmd4ConfigMiscKeys}".tmp "${cmd4ConfigMiscKeys}"
      fi
   fi
}

function extractNonBBaccessoriesConstantsQueueTypesMisc()
{
   # extract non-BB cmd4Config and non-BB accessories ${cmd4ConfigJson}
   extractCmd4ConfigNonBBandAccessoriesNonBB

   # extract non-BB constants and non-BB queueTypes                                          
   if [ -f "${cmd4ConfigAccessoriesNonBB}" ]; then
      extractNonBBconstants
      extractNonBBqueueTypes
   fi

   # extract some misc. keys existing in Cmd4
   extractCmd4MiscKeys
}

function assembleCmd4ConfigJson()
{
   cmd4Header "${cmd4ConfigJsonBB}"
   cat "${cmd4ConfigConstantsBB}" >> "${cmd4ConfigJsonBB}"
   cmd4ConstantsQueueTypesAccessoriesMiscFooter "${cmd4ConfigJsonBB}"
   cat "${cmd4ConfigQueueTypesBB}" >> "${cmd4ConfigJsonBB}"
   cmd4ConstantsQueueTypesAccessoriesMiscFooter "${cmd4ConfigJsonBB}"
   cat "${cmd4ConfigAccessoriesBB}" >> "${cmd4ConfigJsonBB}"
   cmd4ConstantsQueueTypesAccessoriesMiscFooter "${cmd4ConfigJsonBB}"
   cmd4Footer "${cmd4ConfigJsonBB}"
}

function assembleCmd4ConfigJsonBBwithNonBB()
{
   cmd4Header "${cmd4ConfigJsonBBwithNonBB}"
   cat "${cmd4ConfigConstantsBB}" >> "${cmd4ConfigJsonBBwithNonBB}"
   if [ -f "${cmd4ConfigConstantsNonBB}" ]; then cat "${cmd4ConfigConstantsNonBB}" >> "${cmd4ConfigJsonBBwithNonBB}"; fi
   cmd4ConstantsQueueTypesAccessoriesMiscFooter "${cmd4ConfigJsonBBwithNonBB}"
   cat "${cmd4ConfigQueueTypesBB}" >> "${cmd4ConfigJsonBBwithNonBB}"
   if [ -f "${cmd4ConfigQueueTypesNonBB}" ]; then cat "${cmd4ConfigQueueTypesNonBB}" >> "${cmd4ConfigJsonBBwithNonBB}"; fi
   cmd4ConstantsQueueTypesAccessoriesMiscFooter "${cmd4ConfigJsonBBwithNonBB}"
   cat "${cmd4ConfigAccessoriesBB}" >> "${cmd4ConfigJsonBBwithNonBB}"
   if [ -f "${cmd4ConfigAccessoriesNonBB}" ]; then cat "${cmd4ConfigAccessoriesNonBB}" >> "${cmd4ConfigJsonBBwithNonBB}"; fi
   cmd4ConstantsQueueTypesAccessoriesMiscFooter "${cmd4ConfigJsonBBwithNonBB}"
   if [ -f "${cmd4ConfigMiscKeys}" ]; then cat "${cmd4ConfigMiscKeys}" >> "${cmd4ConfigJsonBBwithNonBB}"; fi
   cmd4Footer "${cmd4ConfigJsonBBwithNonBB}"
}

function writeToHomebridgeConfigJson()
{
   # Writing the created "${cmd4ConfigJsonBBwithNonBB}" to "${configJson}.Cmd4less" to create "${configJsonNew}"
   # before copying to Homebridge config.json

   jq --argjson cmd4Config "$(<"${cmd4ConfigJsonBBwithNonBB}")" --indent 4 '.platforms += [$cmd4Config]' "${configJson}.Cmd4less" > "${configJsonNew}"
   rc=$?
   if [ "${rc}" != "0" ]; then
      echo "${TRED}${BOLD}ERROR: Writing of created Cmd4 config to config.json.new failed!${TNRM}"
      echo "${TLBL}${BOLD}INFO: Instead you can copy/paste the content of \"${cmd4ConfigJsonBB}\" into Cmd4 JASON Config editor.${TNRM}"
      cleanUp
      exit 1
   fi

   # Copy the "${configJsonNew}" to Homebridge config.json
   case $UIversion in
      customUI )
         cp "${configJsonNew}" "${homebridgeConfigJson}"
         rc=$?
      ;;
      nonUI )
         sudo cp "${configJsonNew}" "${homebridgeConfigJson}"
         rc=$?
      ;;
   esac

   # copy and use the enhanced version of Cmd4PriorityPollingQueue.js if the Cmd4 version is v7.0.0 or v7.0.1 or v7.0.2
   copyEnhancedCmd4PriorityPollingQueueJs
}

function getGlobalNodeModulesPathForFile()
{
   file="$1"
   fullPath=""    

   for ((tryIndex = 1; tryIndex <= 8; tryIndex ++)); do
      case $tryIndex in  
         1)
            foundPath=$(find /var/lib/hoobs 2>&1|grep -v find|grep -v System|grep -v cache|grep node_modules|grep cmd4-bondbridge|grep "/${file}$") 
            fullPath=$(echo "${foundPath}"|head -n 1)
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         2)
            foundPath=$(npm root -g)
            fullPath="${foundPath}/homebridge-cmd4-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return    
            else
               fullPath=""
            fi
         ;;
         3)
            fullPath="/var/lib/homebridge/node_modules/homebridge-cmd4-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return   
            else
               fullPath=""
            fi
         ;;
         4)
            fullPath="/var/lib/node_modules/homebridge-cmd4-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return   
            else
               fullPath=""
            fi
         ;;
         5)
            fullPath="/usr/local/lib/node_modules/homebridge-cmd4-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         6)
            fullPath="/usr/lib/node_modules/homebridge-cmd4-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         7)
            fullPath="/opt/homebrew/lib/node_modules/homebridge-cmd4-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         8)
            fullPath="/opt/homebridge/lib/node_modules/homebridge-cmd4-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
      esac
   done
}

function getHomebridgeConfigJsonPath()
{
   fullPath=""
   # Typicall HOOBS installation has its config.json root path same as the root path of "BondBridge.sh"
   # The typical full path to the "BondBridge.sh" script is .../hoobs/<bridge>/node_modules/homebridge-cmd4-bondbridge/BondBridge.sh
   # First, determine whether this is a HOOBS installation
   Hoobs=$( echo "$BONDBRIDGE_SH_PATH" | grep "/hoobs/" )
   if [ -n "${Hoobs}" ]; then
      fullPath="${BONDBRIDGE_SH_PATH%/*/*/*}/config.json"
      if [ -f "${fullPath}" ]; then
         checkForCmd4PlatformNameInFile
         if [ -z "${cmd4PlatformNameFound}" ]; then
            fullPath=""
         fi
         return
      fi
   fi

   for ((tryIndex = 1; tryIndex <= 6; tryIndex ++)); do
      case $tryIndex in
         1)
            # Typical RPi, Synology NAS installations have this path to config.json
            fullPath="/var/lib/homebridge/config.json"
            if [ -f "${fullPath}" ]; then
               checkForCmd4PlatformNameInFile   
               if [ -n "${cmd4PlatformNameFound}" ]; then 
                  return
               else
                  fullPath=""
               fi
            fi
         ;;
         2)
            # Typical Mac installation has this path to config.json
            fullPath="$HOME/.homebridge/config.json"
            if [ -f "${fullPath}" ]; then
               checkForCmd4PlatformNameInFile   
               if [ -n "${cmd4PlatformNameFound}" ]; then 
                  return
               else
                  fullPath=""
               fi
            fi
         ;;
         3)
            foundPath=$(find /usr/local/lib 2>&1|grep -v find|grep -v System|grep -v cache|grep -v hassio|grep -v node_modules|grep "/config.json$")
            noOfInstances=$(echo "${foundPath}"|wc -l)
            for ((i = 1; i <= noOfInstances; i ++)); do
               fullPath=$(echo "${foundPath}"|sed -n "${i}"p)
               if [ -f "${fullPath}" ]; then
                  checkForCmd4PlatformNameInFile   
                  if [ -n "${cmd4PlatformNameFound}" ]; then 
                     return
                  else
                     fullPath=""
                  fi
               fi
            done
         ;;
         4)
            foundPath=$(find /usr/lib 2>&1|grep -v find|grep -v System|grep -v cache|grep -v hassio|grep -v node_modules|grep "/config.json$")
            noOfInstances=$(echo "${foundPath}"|wc -l)
            for ((i = 1; i <= noOfInstances; i ++)); do
               fullPath=$(echo "${foundPath}"|sed -n "${i}"p)
               if [ -f "${fullPath}" ]; then
                  checkForCmd4PlatformNameInFile   
                  if [ -n "${cmd4PlatformNameFound}" ]; then 
                     return
                  else
                     fullPath=""
                  fi
               fi
            done
         ;;
         5)
            foundPath=$(find /var/lib 2>&1|grep -v find|grep -v hoobs|grep -v System|grep -v cache|grep -v hassio|grep -v node_modules|grep "/config.json$")
            noOfInstances=$(echo "${foundPath}"|wc -l)
            for ((i = 1; i <= noOfInstances; i ++)); do
               fullPath=$(echo "${foundPath}"|sed -n "${i}"p)
               if [ -f "${fullPath}" ]; then
                  checkForCmd4PlatformNameInFile   
                  if [ -n "${cmd4PlatformNameFound}" ]; then 
                     return
                  else
                     fullPath=""
                  fi
               fi
            done
         ;;
         6)
            foundPath=$(find /opt 2>&1|grep -v find|grep -v hoobs|grep -v System|grep -v cache|grep -v hassio|grep -v node_modules|grep "/config.json$")
            noOfInstances=$(echo "${foundPath}"|wc -l)
            for ((i = 1; i <= noOfInstances; i ++)); do
               fullPath=$(echo "${foundPath}"|sed -n "${i}"p)
               if [ -f "${fullPath}" ]; then
                  checkForCmd4PlatformNameInFile   
                  if [ -n "${cmd4PlatformNameFound}" ]; then 
                     return
                  else
                     fullPath=""
                  fi
               fi
            done
         ;;
      esac
   done
}

function checkForPlatformCmd4InHomebridgeConfigJson()
{
   validFile=""
   for ((tryIndex = 1; tryIndex <= 2; tryIndex ++)); do
      case $tryIndex in
         1)
            validFile=$(grep -n "${cmd4Platform1}" "${configJson}"|cut -d":" -f1)
            if [ -n "${validFile}" ]; then
               cmd4Platform="${cmd4Platform1}"
               return
            fi
         ;;
         2)
            validFile=$(grep -n "${cmd4Platform2}" "${configJson}"|cut -d":" -f1)
            if [ -n "${validFile}" ]; then
               cmd4Platform="${cmd4Platform2}"
               return
            fi
         ;;
      esac
   done
}

function checkForCmd4PlatformNameInFile()
{
   cmd4PlatformNameFound=""

   for ((Index = 1; Index <= 2; Index ++)); do
      case $Index in
         1)
            cmd4PlatformName=$(echo "${cmd4Platform1}"|cut -d'"' -f4)
            cmd4PlatformNameFound=$(grep -n "\"${cmd4PlatformName}\"" "${fullPath}"|cut -d":" -f1)
            if [ -n "${cmd4PlatformNameFound}" ]; then
               return
            fi
         ;;
         2)
            cmd4PlatformName=$(echo "${cmd4Platform2}"|cut -d'"' -f4)
            cmd4PlatformNameFound=$(grep -n "\"${cmd4PlatformName}\"" "${fullPath}"|cut -d":" -f1)
            if [ -n "${cmd4PlatformNameFound}" ]; then
               return
            fi
         ;;
      esac
   done
}

function copyEnhancedCmd4PriorityPollingQueueJs()
{
   # if the enhanced version of "Cmd4PriorityPollingQueue.txt" is present and Cmd4 version is 7.0.0 or 7.0.1 or 7.0.2, then use this enhanced verison.
   getGlobalNodeModulesPathForFile "Cmd4PriorityPollingQueue.txt"
   if [ -n "${fullPath}" ]; then
      fullPath_txt="${fullPath}"
      fullPath_package="${fullPath%/*/*}/homebridge-cmd4/package.json"
      # check the Cmd4 version
      Cmd4_version="$(jq '.version' "${fullPath_package}")"
      if expr "${Cmd4_version}" : '"7.0.[0-2]"' >/dev/null; then
         fullPath_js="${fullPath%/*/*}/homebridge-cmd4/Cmd4PriorityPollingQueue.js"
         case $UIversion in
            customUI )
               if cp "${fullPath_txt}" "${fullPath_js}"; then
                  echo "COPIED and "
               else
                  echo "NOT COPIED but "
               fi
            ;;
            nonUI )
               if sudo cp "${fullPath_txt}" "${fullPath_js}"; then
                  echo "${TLBL}INFO: An enhanced version of ${BOLD}\"Cmd4PriorityPollingQueue.js\"${TNRM}${TLBL} was located and copied to Cmd4 plugin.${TNRM}"
                  echo ""
               else
                  echo "${TYEL}WARNING: An enhanced version of ${BOLD}\"Cmd4PriorityPollingQueue.js\"${TNRM}${TYEL} was NOT copied to Cmd4 plugin."
                  echo "         Please copy it manually.${TNRM}"
                  echo ""

               fi
            ;;
         esac
      fi 
  fi
}
   
function cleanUp()
{
   rm -f "${configJson}"
   rm -f "${cmd4ConfigJson}"
   rm -f "${configJson}.Cmd4less"
   rm -f "${cmd4ConfigConstantsBB}"
   rm -f "${cmd4ConfigQueueTypesBB}"
   rm -f "${cmd4ConfigAccessoriesBB}"
   rm -f "${cmd4ConfigNonBB}"
   rm -f "${cmd4ConfigConstantsNonBB}"
   rm -f "${cmd4ConfigQueueTypesNonBB}"
   rm -f "${cmd4ConfigAccessoriesNonBB}"
   rm -f "${cmd4ConfigMiscKeys}"
   rm -f "${cmd4ConfigJsonBBwithNonBB}"
   rm -f "${configJsonNew}"
}

# main starts here

if [ -z "${BONDBRIDGE_SH_PATH}" ]; then UIversion="nonUI"; fi

case $UIversion in
   customUI )
      if expr "${BBIP}" : '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$' >/dev/null; then
         echo ""
      else
         echo "WARNING: the specified IP address ${BBIP} is in wrong format"
         exit 1
      fi

      if [[ -n "${BBIP2}" && "${BBIP2}" != "undefined" ]]; then 
         if expr "${BBIP2}" : '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$' >/dev/null; then
           echo "" 
         else
            echo "WARNING: the specified IP address ${BBIP2} is in wrong format"
            exit 1
         fi
      else
         BBIP2=""
         BBtoken2=""
      fi

      if [[ -n "${BBIP3}" && "${BBIP3}" != "undefined" ]]; then 
         if expr "$5" : '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$' >/dev/null; then
            echo ""
         else
            echo "WARNING: the specified IP address ${BBIP3} is in wrong format"
            exit 1
         fi
      else
         BBIP3=""
         BBtoken3=""
      fi
   ;;
   nonUI )
      BBIP=""
      BBIP2=""
      BBIP3=""

      until [ -n "${BBIP}" ]; do
         echo "${TYEL}Please enter the IP address and the token of your BondBridge device:"
         read -r -p "${TYEL}IP address (xxx.xxx.xxx.xxx): ${TNRM}" INPUT
         if expr "${INPUT}" : '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$' >/dev/null; then
            BBIP="${INPUT}"
            read -r -p "${TYEL}Token of this device (this can be found in Bond Settings of Bond app): ${TNRM}" INPUT
            BBtoken="${INPUT}"
            BBdebug="false"
            read -r -p "${TYEL}Enable debug? (y/n, default=n): ${TNRM}" INPUT
            if [[ "${INPUT}" = "y" || "${INPUT}" = "Y" || "${INPUT}" = "true" ]]; then BBdebug="true"; fi
         else
            echo ""
            echo "${TPUR}WARNING: Wrong format for an IP address! Please enter again!${TNRM}"
            echo ""
         fi
      done
      until [ -n "${BBIP2}" ]; do
         echo ""
         echo "${TYEL}Please enter the IP address and the token of your 2nd BondBridge device if any. Just hit 'enter' if none:"
         read -r -p "${TYEL}IP address (xxx.xxx.xxx.xxx): ${TNRM}" INPUT
         if [ -z "${INPUT}" ]; then
            break
         fi
         if expr "${INPUT}" : '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$' >/dev/null; then
            BBIP2="${INPUT}"
            read -r -p "${TYEL}Token of this device (this can be found in Bond Settings of Bond app): ${TNRM}" INPUT
            BBtoken2="${INPUT}"
            BBdebug2="false"
            read -r -p "${TYEL}Enable debug? (y/n, default=n): ${TNRM}" INPUT
            if [[ "${INPUT}" = "y" || "${INPUT}" = "Y" || "${INPUT}" = "true" ]]; then BBdebug2="true"; fi
         else
            echo ""
            echo "${TPUR}WARNING: Wrong format for an IP address! Please enter again!${TNRM}"
            echo ""
         fi
      done
      if [ -n "${BBIP2}" ]; then
         until [ -n "${BBIP3}" ]; do
            echo ""
            echo "${TYEL}Please enter the IP address and the token of your 2nd BondBridge device if any. Just hit 'enter' if none:"
            read -r -p "${TYEL}IP address (xxx.xxx.xxx.xxx): ${TNRM}" INPUT
            if [ -z "${INPUT}" ]; then
               break
            fi
            if expr "${INPUT}" : '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$' >/dev/null; then
               BBIP3="${INPUT}"
               read -r -p "${TYEL}Token of this device (this can be found in Bond Settings of Bond app): ${TNRM}" INPUT
               BBtoken3="${INPUT}"
               BBdebug3="false"
               read -r -p "${TYEL}Enable debug? (y/n, default=n): ${TNRM}" INPUT
               if [[ "${INPUT}" = "y" || "${INPUT}" = "Y" || "${INPUT}" = "true" ]]; then BBdebug3="true"; fi
            else
               echo ""
               echo "${TNRM}${TPUR}WARNING: Wrong format for an IP address! Please enter again!${TNRM}"
               echo ""
            fi
         done
      fi

      echo ""
      read -r -p "${TYEL}Include a Fan and a Light? n=a Light Dimmer only (y/n, default=n):${TNRM} " INPUT
      if [[ "${INPUT}" = "y" || "${INPUT}" = "Y" ]]; then
         fullSetup="fullSetup"
      else
         fullSetup="lightDimmer only"
      fi

      read -r -p "${TYEL}Include timers to turn-on/off the fan and light? (y/n, default=y):${TNRM} " INPUT
      if [[ "${INPUT}" = "n" || "${INPUT}" = "N" ]]; then
         timerSetup="noTimers"
      else
         timerSetup="includeTimers"
      fi
      echo ""
      echo "${TLBL}INFO: fullSetup=${fullSetup}${TNRM}"
      echo "${TLBL}INFO: timerSetup=${timerSetup}${TNRM}"
      echo ""

      # get the full path to BondBridge.sh
      BONDBRIDGE_SH_PATH=""
      getGlobalNodeModulesPathForFile "BondBridge.sh"
      if [ -n "${fullPath}" ]; then
         BONDBRIDGE_SH_PATH=${fullPath}
         echo "${TLBL}INFO: BondBridge.sh found: ${BONDBRIDGE_SH_PATH}${TNRM}"
      fi

      if [ -z "${BONDBRIDGE_SH_PATH}" ]; then
         BONDBRIDGE_SH_PATH=""
         until [ -n "${BONDBRIDGE_SH_PATH}" ]; do
            echo ""
            echo "${TYEL}Please enter the full path of where the BondBridge.sh is installed in your system"
            echo "The file path format should be : /*/*/*/node_modules/homebridge-cmd4-bondbridge/BondBridge.sh${TNRM}"
            read -r -p "${BOLD}> ${TNRM}" INPUT
            if expr "${INPUT}" : '/[a-zA-Z0-9/_]*/node_modules/homebridge-cmd4-bondbridge/BondBridge.sh$' >/dev/null; then
               if [ -f "${INPUT}" ]; then
                  BONDBRIDGE_SH_PATH=${INPUT}
                  echo ""
                  echo "${TLBL}INFO: BondBridge.sh specified: ${BONDBRIDGE_SH_PATH}${TNRM}"
                  break
               else
                  echo ""
                  echo "${TPUR}WARNING: file ${INPUT} not found${TNRM}"
               fi
            else
               echo ""
               echo "${TPUR}WARNING: file ${INPUT} is in wrong format${TNRM}"
            fi
         done
      fi
   ;;
esac

if [ -n "${BBIP}" ]; then noOfBondBridges=1; fi
if [ -n "${BBIP2}" ]; then noOfBondBridges=2; fi
if [ -n "${BBIP3}" ]; then noOfBondBridges=3; fi

for ((n=1; n<=noOfBondBridges; n++)); do

   if [ "${n}" = "1" ]; then 
      ip="\${BBIP}"
      IPA="${BBIP}"
      bondToken="${BBtoken}"
      debug="${BBdebug}"
      queue="BBA"
   fi
   if [ "${n}" = "2" ]; then 
      ip="\${BBIP2}"
      IPA="${BBIP2}"
      bondToken="${BBtoken2}"
      debug="${BBdebug2}"
      queue="BBB"
   fi
   if [ "${n}" = "3" ]; then 
      ip="\${BBIP3}"
      IPA="${BBIP3}"
      bondToken="${BBtoken3}"
      debug="${BBdebug3}"
      queue="BBC"
   fi
  
   if [[ "${n}" = "1" && "${UIversion}" = "nonUI" ]]; then
      echo ""
      if [ "${noOfBondBridges}" = "1" ]; then echo "${TLBL}${BOLD}INFO: This will take up to 1 minute to process!${TNRM}"; fi
      if [ "${noOfBondBridges}" = "2" ]; then echo "${TLBL}${BOLD}INFO: This will take up to 2 minutes to process!${TNRM}"; fi
      if [ "${noOfBondBridges}" = "3" ]; then echo "${TLBL}${BOLD}INFO: This will take up to 3 minutes to process!${TNRM}"; fi
   fi

   if [ "${UIversion}" = "nonUI" ]; then
      echo "${TLBL}INFO: Fetching and processing data from your BondBridge device (${bondToken} ${IPA}).... ${TNRM}"
   fi

   # retrieve the Bond Bridge system info and get the bondid
   version=$(curl -s -g -H -i http://"${IPA}"/v2/sys/version)
   if [ -z "${version}" ]; then
      echo "${TRED}ERROR: BondBridge device is inaccessible or your IP address ${IPA} is invalid!${TNRM}"
      exit 1
   fi

   bondid=$(echo "${version}" | jq ".bondid")
   bondid=${bondid//\"/}
   if [ -z "${bondid}" ]; then
      echo "${TRED}ERROR: jq failed! Please make sure that jq is installed!${TNRM}"
      exit 1
   fi

   model=$(echo "${version}" | jq ".model")
   model=${model//\"/}

   # Create the ${cmd4ConfigConstantsBB}, ${cmd4ConfigQueueTypesBB} and ${cmd4ConfigAccessoriesBB}
   if [ "${n}" = "1" ]; then
      cmd4ConfigJsonBB="cmd4Config_BB_${bondToken}.json"
      cmd4ConfigJsonBBwithNonBB="${cmd4ConfigJsonBB}.withNonBB"
      cmd4ConstantsHeader "${cmd4ConfigConstantsBB}"
      cmd4QueueTypesHeader "${cmd4ConfigQueueTypesBB}"
      cmd4AccessoriesHeader "${cmd4ConfigAccessoriesBB}"
   fi
   
   # Append the body of BB constants and queueTypes
   cmd4Constants "${cmd4ConfigConstantsBB}"
   cmd4QueueTypes "${cmd4ConfigQueueTypesBB}"

   # Create the $cmd4ConfigAccessories
   # first retireve the info of all the defined devices 
   Devices=$(curl -s -g -H "BOND-Token: ${bondToken}" http://"${IPA}"/v2/devices)
   devices=$(echo "$Devices" | jq '. | keys')
   noOfDevices=$(($(echo "${devices}" | wc -w) - 2))

   # Now create the config for the devices
   for (( i=0;i<noOfDevices;i++ )); do
      device=$(echo "${devices}"|jq ".[$i]")
      if expr "${device}" : '^\"[a-f0-9]*\"$' >/dev/null; then
         device=${device//\"/}
         timerDevice=$(echo "${device}" | rev)
         name=$(curl -s -g -H "BOND-Token: ${bondToken}" http://"${IPA}"/v2/devices/"${device}" |  jq ".name")
         name=${name//\"/}
         if expr "${name}" : '[a-zA-Z0-9 ]*Fan$' >/dev/null; then
            if [ "${fullSetup}" = "fullSetup" ]; then
               cmd4Fan "${cmd4ConfigAccessoriesBB}" "${name}"
            fi
            if [ "${timerSetup}" = "includeTimers" ]; then
               cmd4TimerLightbulb "${cmd4ConfigAccessoriesBB}" "${name} Timer" "fanTimer" "fanDevice"
            fi
         fi
         #
         if expr "${name}" : '[a-zA-Z0-9 ]*Light$' >/dev/null; then
            if [ "${fullSetup}" = "fullSetup" ]; then
               cmd4Lightbulb "${cmd4ConfigAccessoriesBB}" "${name}" "light"
            else
               cmd4Lightbulb "${cmd4ConfigAccessoriesBB}" "${name} Dimmer" "dimmer"
            fi
            if [ "${timerSetup}" = "includeTimers" ]; then
               cmd4TimerLightbulb "${cmd4ConfigAccessoriesBB}" "${name} Timer" "lightTimer" "lightDevice"
            fi
         fi
      fi
   done      
done

# Now write the created ${cmd4ConfigJsonBB} to ${HomebridgeConfigJson} replacing all 
# existing BB-related configuration 

# Assemble a complete Cmd4 configuration file for the specified BB device(s)
assembleCmd4ConfigJson

# Read the existing Homebridge config.json file
readHomebridgeConfigJson

# Extract all non-BB related Cmd4 devices
extractCmd4ConfigFromConfigJson
extractNonBBaccessoriesConstantsQueueTypesMisc

# Assemble a complete Cmd4 configuration file for the specified BB devices(s) with the extracted 
# non-BB related Cmd4 devices
assembleCmd4ConfigJsonBBwithNonBB

# Write the assembled BB + non-BB Cmd4 configuration into the Homebridge config.json
writeToHomebridgeConfigJson

if [ "${rc}" = "0" ]; then
   echo "${TGRN}${BOLD}DONE! Run CheckConfig then restart Homebridge or HOOBS.${TNRM}" 
   rm -f "${cmd4ConfigJsonBB}"
   if [ "${UIversion}" = "nonUI" ]; then
      check1="${BONDBRIDGE_SH_PATH%/*}/CheckConfig.sh"
      echo ""
      echo "${TYEL}To run CheckConfig, please copy/paste and run the following command to check whether the Cmd4 configuration meets all the requirements${TNRM}"
      echo "${check1}"
   fi
else
   # Copying of the new config.json to homebridge config.json failes so restore the homebridge config.json from backup
   if [ "${UIversion}" = "nonUI" ]; then
     sudo cp "${configJson}" "${homebridgeConfigJson}"
   else
     cp "${configJson}" "${homebridgeConfigJson}"
   fi
   echo "${TRED}${BOLD}ERROR: Copying of \"${cmd4ConfigJsonBB}\" to Homebridge config.json failed! Original config.json restored.${TNRM}"
   echo "${TLBL}${BOLD}INFO: Instead you can copy/paste the content of \"${cmd4ConfigJsonBB}\" into Cmd4 JASON Config editor.${TNRM}"
fi

cleanUp
exit 0
