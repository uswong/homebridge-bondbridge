#!/bin/bash
#
# This script is to generate a complete configuration file needed for the bondbridge plugin
# This script can handle up to 3 independent BondBridge (BB) systems
#
# This script can be invoked in two ways:  
# 1. from homebridge customUI
#    a. click "SETTING" on bondbridge plugin and 
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
# Once the configuration file is generated and copied to Homebridge config.json and if you know
# what you are doing you can do some edits on the configuration file in MyPlace Config Editor
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

# define the possible names for MyPlace platform
myPlacePlatform=""
myPlacePlatform1="\"platform\": \"MyPlace\""
myPlacePlatform2="\"platform\": \"homebridge-myplace\""

# define some other variables
name=""

# define some file variables
homebridgeConfigJson=""           # homebridge config.json
configJson="config.json.copy"     # a working copy of homebridge config.json
myPlaceConfigJson="myPlaceConfig.json"  # homebridge-myplace config.json
myPlaceConfigJsonBB="myPlaceConfig_BB.json"
myPlaceConfigConstantsBB="myPlaceConfig.json.BBconstants"
myPlaceConfigQueueTypesBB="myPlaceConfig.json.BBqueueTypes"
myPlaceConfigAccessoriesBB="myPlaceConfig.json.BBaccessories"
myPlaceConfigJsonBBwithNonBB="${myPlaceConfigJsonBB}.withNonBB"
myPlaceConfigNonBB="myPlaceConfig.json.nonBB"
myPlaceConfigConstantsNonBB="myPlaceConfig.json.nonBBconstants"
myPlaceConfigQueueTypesNonBB="myPlaceConfig.json.nonBBqueueTypes"
myPlaceConfigAccessoriesNonBB="myPlaceConfig.json.nonBBaccessories"
myPlaceConfigMiscKeys="myPlaceConfig.json.miscKeys"
configJsonNew="${configJson}.new"     # new homebridge config.json

# fun color stuff
BOLD=$(tput bold)
TRED=$(tput setaf 1)
TGRN=$(tput setaf 2)
TYEL=$(tput setaf 3)
TPUR=$(tput setaf 5)
TLBL=$(tput setaf 6)
TNRM=$(tput sgr0)


function myPlaceHeader()
{
   local debugMyPlace="false"

   if [ "${debug}" = "true" ]; then
      debugMyPlace="true"
   fi

   { echo "{"
     echo "    \"platform\": \"MyPlace\","
     echo "    \"name\": \"MyPlace\","
     echo "    \"debug\": ${debugMyPlace},"
     echo "    \"outputConstants\": false,"
     echo "    \"statusMsg\": true,"
     echo "    \"timeout\": 60000,"
     echo "    \"stateChangeResponseTime\": 0,"
   } > "$1"
}

function myPlaceConstantsHeader()
{
   { echo "    \"constants\": ["
   } > "$1"
}

function myPlaceConstants()
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

function myPlaceQueueTypesHeader()
{
   { echo "    \"queueTypes\": ["
   } > "$1"
}

function myPlaceQueueTypes()
{
   { echo "        {"
     echo "            \"queue\": \"${queue}\","
     echo "            \"queueType\": \"WoRm2\""
     echo "        },"
   } >> "$1"
}

function myPlaceAccessoriesHeader()
{
   { echo "    \"accessories\": ["
   } > "$1"
}

function myPlaceConstantsQueueTypesAccessoriesMiscFooter()
{
   cp "$1" "$1.temp"
   sed '$ d' "$1.temp" > "$1" 
   rm "$1.temp"
   
   { echo "        }"
     echo "    ],"
   } >> "$1"
}

function myPlaceFan()
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

function myPlaceLightbulb()
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

function myPlaceTimerLightbulb()
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

function myPlaceFooter()
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
            checkForPlatformMyPlaceInHomebridgeConfigJson
            if [ -z "${validFile}" ]; then
               echo "ERROR: no MyPlace Config found in \"${homebridgeConfigJson}\"! Please ensure that homebridge-myplace plugin is installed"
               exit 1
            fi
         else
            echo "ERROR: no Homebridge config.json found in \"${DIR}\"! Please copy \"${myPlaceConfigJsonBB}\" to MyPlace JASON Config manually."
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
               echo "otherwise just hit enter to abort copying \"${myPlaceConfigJsonBB}\" to Homebridge config.json."
               echo "The config.json path should be in the form of /*/*/*/config.json ${TNRM}"
               read -r -p "${BOLD}> ${TNRM}" INPUT
               if [ -z "${INPUT}" ]; then
                  echo "${TPUR}WARNING: No Homebridge config.json file specified"
                  echo "         Copying of ${myPlaceConfigJsonBB} to Homebridge config.json was aborted"
                  echo ""
                  echo "${TLBL}${BOLD}INFO: Please copy/paste the ${myPlaceConfigJsonBB} into MyPlace JASON Config Editor manually${TNRM}"
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
            checkForPlatformMyPlaceInHomebridgeConfigJson
            if [ -z "${validFile}" ]; then
               echo ""
               echo "${TRED}ERROR: no MyPlace Config found in \"${homebridgeConfigJson}\"! Please ensure that homebridge-myplace plugin is installed${TNRM}"
               echo "${TLBL}INFO: ${myPlaceConfigJsonBB} was created but not copied to homebridge-myplace JASON Config Editor!"
               echo "      Please copy/paste the ${myPlaceConfigJsonBB} into MyPlace JASON Config Editor manually${TNRM}"
               cleanUp
               exit 1
            fi
         fi
      ;;
   esac
}

function extractMyPlaceConfigFromConfigJson()
{
   noOfPlatforms=$(( $( jq ".platforms|keys" "${configJson}" | wc -w) - 2 ))
   myPlacePlatformName=$(echo "${myPlacePlatform}"|cut -d'"' -f4)
   for ((i=0; i<noOfPlatforms; i++)); do
      plaftorm=$( jq ".platforms[${i}].platform" "${configJson}" )
      if [ "${plaftorm}" = "\"${myPlacePlatformName}\"" ]; then
         jq --indent 4 ".platforms[${i}]" "${configJson}" > "${myPlaceConfigJson}"
         jq --indent 4 "del(.platforms[${i}])" "${configJson}" > "${configJson}.MyPlaceless"
         break
      fi
   done
}

function extractMyPlaceConfigNonBBandAccessoriesNonBB()
{
   BBaccessories=""
   count=0
   presenceOfAccessories=$(jq ".accessories" "${myPlaceConfigJson}")
   if [ "${presenceOfAccessories}" != "null" ]; then
      noOfAccessories=$(( $( jq ".accessories|keys" "${myPlaceConfigJson}" | wc -w) - 2 ))
      for (( i=0; i<noOfAccessories; i++ )); do
         myPlaceStateCmd=$( jq ".accessories[${i}].state_cmd" "${myPlaceConfigJson}" | grep -n "homebridge-bondbridge" )

         # save the ${i} n a string for use to delete the BB accessories from ${myPlaceConfigJson}
         if [ "${myPlaceStateCmd}" != "" ]; then
            if [ "${BBaccessories}" = "" ]; then
               BBaccessories="${i}"
            else
               BBaccessories="${BBaccessories},${i}"
            fi
         else   # create the non-BB accessories
            count=$(( count + 1 ))
            if [ "${count}" -eq 1 ]; then
               jq --indent 4 ".accessories[${i}]" "${myPlaceConfigJson}" > "${myPlaceConfigAccessoriesNonBB}"
            else
               sed '$d' "${myPlaceConfigAccessoriesNonBB}" > "${myPlaceConfigAccessoriesNonBB}.tmp"
               mv "${myPlaceConfigAccessoriesNonBB}.tmp" "${myPlaceConfigAccessoriesNonBB}"
               echo "}," >> "${myPlaceConfigAccessoriesNonBB}"
               jq --indent 4 ".accessories[${i}]" "${myPlaceConfigJson}" >> "${myPlaceConfigAccessoriesNonBB}"
            fi
         fi
      done
   fi

   # delete the BB accessories to create ${myPlaceConfigNonBB} for use later 
   if [ "${BBaccessories}" = "" ]; then
      cp "${myPlaceConfigJson}" "${myPlaceConfigNonBB}"
   else
      jq --indent 4 "del(.accessories[${BBaccessories}])" "${myPlaceConfigJson}" > "${myPlaceConfigNonBB}"
   fi

   # check that there are non-BB accessories, if not, remove the file
   if [ -f "${myPlaceConfigAccessoriesNonBB}" ]; then
      validFile=$(head -n 1 "${myPlaceConfigAccessoriesNonBB}")
      if [ "${validFile}" = "" ]; then rm "${myPlaceConfigAccessoriesNonBB}"; fi
   fi 
}

function extractNonBBconstants()
{
   count=0
   noOfConstans=$(( $( jq ".constants|keys" "${myPlaceConfigNonBB}" | wc -w) - 2 ))
   for ((i=0; i<noOfConstans; i++)); do
      key=$( jq ".constants[${i}].key" "${myPlaceConfigNonBB}" )
      key=${key//\"/}
      keyUsed=$(grep -n "${key}" "${myPlaceConfigAccessoriesNonBB}"|grep -v 'key'|head -n 1|cut -d":" -f1)
      if [ -n "${keyUsed}" ]; then
         count=$(( count + 1 ))
         if [ "${count}" -eq 1 ]; then
            jq --indent 4 ".constants[${i}]" "${myPlaceConfigNonBB}" > "${myPlaceConfigConstantsNonBB}"
         else
            sed '$d' "${myPlaceConfigConstantsNonBB}" > "${myPlaceConfigConstantsNonBB}.tmp"
            mv "${myPlaceConfigConstantsNonBB}.tmp" "${myPlaceConfigConstantsNonBB}"
            echo "}," >> "${myPlaceConfigConstantsNonBB}"
            jq --indent 4 ".constants[${i}]" "${myPlaceConfigNonBB}" >> "${myPlaceConfigConstantsNonBB}"
         fi
      fi
   done
   if [ -f "${myPlaceConfigConstantsNonBB}" ]; then
      validFile=$(head -n 1 "${myPlaceConfigConstantsNonBB}")
      if [ "${validFile}" = "" ]; then rm "${myPlaceConfigConstantsNonBB}"; fi
   fi
}

function extractNonBBqueueTypes()
{
   count=0
   noOfQueues=$(( $( jq ".queueTypes|keys" "${myPlaceConfigNonBB}" | wc -w) - 2 ))
   for ((i=0; i<noOfQueues; i++)); do
      queue=$( jq ".queueTypes[${i}].queue" "${myPlaceConfigNonBB}" )
      queueUsed=$(grep -n "${queue}" "${myPlaceConfigAccessoriesNonBB}"|head -n 1)
      if [ -n "${queueUsed}" ]; then
         count=$(( count + 1 ))
         if [ "${count}" -eq 1 ]; then
            jq --indent 4 ".queueTypes[${i}]" "${myPlaceConfigNonBB}" > "${myPlaceConfigQueueTypesNonBB}"
         else
            sed '$d'  "${myPlaceConfigQueueTypesNonBB}" > "${myPlaceConfigQueueTypesNonBB}.tmp"
            mv "${myPlaceConfigQueueTypesNonBB}.tmp" "${myPlaceConfigQueueTypesNonBB}"
            echo "}," >> "${myPlaceConfigQueueTypesNonBB}"
            jq --indent 4 ".queueTypes[${i}]" "${myPlaceConfigNonBB}" >> "${myPlaceConfigQueueTypesNonBB}"
         fi
      fi
   done
   if [ -f "${myPlaceConfigQueueTypesNonBB}" ]; then
      validFile=$(head -n 1 "${myPlaceConfigQueueTypesNonBB}")
      if [ "${validFile}" = "" ]; then rm "${myPlaceConfigQueueTypesNonBB}"; fi
   fi
}

function extractMyPlaceMiscKeys()
{
   # Extract any misc Keys used for non-BB accessories 
   count=0
   keys=$( jq ".|keys" "${myPlaceConfigNonBB}" )
   noOfKeys=$(( $(echo "${keys}" | wc -w) - 2 ))
   for ((i=0; i<noOfKeys; i++)); do
      key=$( echo "${keys}" | jq ".[${i}]" )
      key=${key//\"/}
      if [[ "${key}" != "platform" && "${key}" != "name" && "${key}" != "debug" && "${key}" != "outputConstants" && "${key}" != "statusMsg" && "${key}" != "timeout" && "${key}" != "stateChangeResponseTime" && "${key}" != "constants" && "${key}" != "queueTypes" && "${key}" != "accessories" ]]; then
         count=$(( count + 1 ))
         miscKey=$( echo "${keys}" | jq ".[${i}]" )
         if [ "${count}" -eq 1 ]; then echo "{" >> "${myPlaceConfigMiscKeys}"; fi
         if [ "${count}" -gt 1 ]; then echo "," >> "${myPlaceConfigMiscKeys}"; fi
         echo "${miscKey}:" >> "${myPlaceConfigMiscKeys}"
         jq --indent 4 ".${miscKey}" "${myPlaceConfigNonBB}" >> "${myPlaceConfigMiscKeys}"
      fi
   done
   if [ -f "${myPlaceConfigMiscKeys}" ]; then
      validFile=$(head -n 1 "${myPlaceConfigMiscKeys}")
      if [ -z "${validFile}" ]; then
         rm -f "${myPlaceConfigMiscKeys}"
      else
         # reformat it to proper json and then remove the "{" and "}" at the begining and the end of the file
         echo "}" >> "${myPlaceConfigMiscKeys}"
         jq --indent 4 '.' "${myPlaceConfigMiscKeys}" | sed '1d;$d' > "${myPlaceConfigMiscKeys}".tmp
         mv "${myPlaceConfigMiscKeys}".tmp "${myPlaceConfigMiscKeys}"
      fi
   fi
}

function extractNonBBaccessoriesConstantsQueueTypesMisc()
{
   # extract non-BB myPlaceConfig and non-BB accessories ${myPlaceConfigJson}
   extractMyPlaceConfigNonBBandAccessoriesNonBB

   # extract non-BB constants and non-BB queueTypes                                          
   if [ -f "${myPlaceConfigAccessoriesNonBB}" ]; then
      extractNonBBconstants
      extractNonBBqueueTypes
   fi

   # extract some misc. keys existing in MyPlace config
   extractMyPlaceMiscKeys
}

function assembleMyPlaceConfigJson()
{
   myPlaceHeader "${myPlaceConfigJsonBB}"
   cat "${myPlaceConfigConstantsBB}" >> "${myPlaceConfigJsonBB}"
   myPlaceConstantsQueueTypesAccessoriesMiscFooter "${myPlaceConfigJsonBB}"
   cat "${myPlaceConfigQueueTypesBB}" >> "${myPlaceConfigJsonBB}"
   myPlaceConstantsQueueTypesAccessoriesMiscFooter "${myPlaceConfigJsonBB}"
   cat "${myPlaceConfigAccessoriesBB}" >> "${myPlaceConfigJsonBB}"
   myPlaceConstantsQueueTypesAccessoriesMiscFooter "${myPlaceConfigJsonBB}"
   myPlaceFooter "${myPlaceConfigJsonBB}"
}

function assembleMyPlaceConfigJsonBBwithNonBB()
{
   myPlaceHeader "${myPlaceConfigJsonBBwithNonBB}"
   cat "${myPlaceConfigConstantsBB}" >> "${myPlaceConfigJsonBBwithNonBB}"
   if [ -f "${myPlaceConfigConstantsNonBB}" ]; then cat "${myPlaceConfigConstantsNonBB}" >> "${myPlaceConfigJsonBBwithNonBB}"; fi
   myPlaceConstantsQueueTypesAccessoriesMiscFooter "${myPlaceConfigJsonBBwithNonBB}"
   cat "${myPlaceConfigQueueTypesBB}" >> "${myPlaceConfigJsonBBwithNonBB}"
   if [ -f "${myPlaceConfigQueueTypesNonBB}" ]; then cat "${myPlaceConfigQueueTypesNonBB}" >> "${myPlaceConfigJsonBBwithNonBB}"; fi
   myPlaceConstantsQueueTypesAccessoriesMiscFooter "${myPlaceConfigJsonBBwithNonBB}"
   cat "${myPlaceConfigAccessoriesBB}" >> "${myPlaceConfigJsonBBwithNonBB}"
   if [ -f "${myPlaceConfigAccessoriesNonBB}" ]; then cat "${myPlaceConfigAccessoriesNonBB}" >> "${myPlaceConfigJsonBBwithNonBB}"; fi
   myPlaceConstantsQueueTypesAccessoriesMiscFooter "${myPlaceConfigJsonBBwithNonBB}"
   if [ -f "${myPlaceConfigMiscKeys}" ]; then cat "${myPlaceConfigMiscKeys}" >> "${myPlaceConfigJsonBBwithNonBB}"; fi
   myPlaceFooter "${myPlaceConfigJsonBBwithNonBB}"
}

function writeToHomebridgeConfigJson()
{
   # Writing the created "${myPlaceConfigJsonBBwithNonBB}" to "${configJson}.MyPlaceless" to create "${configJsonNew}"
   # before copying to Homebridge config.json

   jq --argjson myPlaceConfig "$(<"${myPlaceConfigJsonBBwithNonBB}")" --indent 4 '.platforms += [$myPlaceConfig]' "${configJson}.MyPlaceless" > "${configJsonNew}"
   rc=$?
   if [ "${rc}" != "0" ]; then
      echo "${TRED}${BOLD}ERROR: Writing of created MyPlace config to config.json.new failed!${TNRM}"
      echo "${TLBL}${BOLD}INFO: Instead you can copy/paste the content of \"${myPlaceConfigJsonBB}\" into MyPlace JASON Config editor.${TNRM}"
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
}

function getGlobalNodeModulesPathForFile()
{
   file="$1"
   fullPath=""    

   for ((tryIndex = 1; tryIndex <= 8; tryIndex ++)); do
      case $tryIndex in  
         1)
            foundPath=$(find /var/lib/hoobs 2>&1|grep -v find|grep -v System|grep -v cache|grep node_modules|grep bondbridge|grep "/${file}$") 
            fullPath=$(echo "${foundPath}"|head -n 1)
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         2)
            foundPath=$(npm root -g)
            fullPath="${foundPath}/homebridge-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return    
            else
               fullPath=""
            fi
         ;;
         3)
            fullPath="/var/lib/homebridge/node_modules/homebridge-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return   
            else
               fullPath=""
            fi
         ;;
         4)
            fullPath="/var/lib/node_modules/homebridge-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return   
            else
               fullPath=""
            fi
         ;;
         5)
            fullPath="/usr/local/lib/node_modules/homebridge-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         6)
            fullPath="/usr/lib/node_modules/homebridge-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         7)
            fullPath="/opt/homebrew/lib/node_modules/homebridge-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         8)
            fullPath="/opt/homebridge/lib/node_modules/homebridge-bondbridge/${file}"
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
   # The typical full path to the "BondBridge.sh" script is .../hoobs/<bridge>/node_modules/homebridge-bondbridge/BondBridge.sh
   # First, determine whether this is a HOOBS installation
   Hoobs=$( echo "$BONDBRIDGE_SH_PATH" | grep "/hoobs/" )
   if [ -n "${Hoobs}" ]; then
      fullPath="${BONDBRIDGE_SH_PATH%/*/*/*}/config.json"
      if [ -f "${fullPath}" ]; then
         checkForMyPlacePlatformNameInFile
         if [ -z "${myPlacePlatformNameFound}" ]; then
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
               checkForMyPlacePlatformNameInFile   
               if [ -n "${myPlacePlatformNameFound}" ]; then 
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
               checkForMyPlacePlatformNameInFile   
               if [ -n "${myPlacePlatformNameFound}" ]; then 
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
                  checkForMyPlacePlatformNameInFile   
                  if [ -n "${myPlacePlatformNameFound}" ]; then 
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
                  checkForMyPlacePlatformNameInFile   
                  if [ -n "${myPlacePlatformNameFound}" ]; then 
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
                  checkForMyPlacePlatformNameInFile   
                  if [ -n "${myPlacePlatformNameFound}" ]; then 
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
                  checkForMyPlacePlatformNameInFile   
                  if [ -n "${myPlacePlatformNameFound}" ]; then 
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

function checkForPlatformMyPlaceInHomebridgeConfigJson()
{
   validFile=""
   for ((tryIndex = 1; tryIndex <= 2; tryIndex ++)); do
      case $tryIndex in
         1)
            validFile=$(grep -n "${myPlacePlatform1}" "${configJson}"|cut -d":" -f1)
            if [ -n "${validFile}" ]; then
               myPlacePlatform="${myPlacePlatform1}"
               return
            fi
         ;;
         2)
            validFile=$(grep -n "${myPlacePlatform2}" "${configJson}"|cut -d":" -f1)
            if [ -n "${validFile}" ]; then
               myPlacePlatform="${myPlacePlatform2}"
               return
            fi
         ;;
      esac
   done
}

function checkForMyPlacePlatformNameInFile()
{
   myPlacePlatformNameFound=""

   for ((Index = 1; Index <= 2; Index ++)); do
      case $Index in
         1)
            myPlacePlatformName=$(echo "${myPlacePlatform1}"|cut -d'"' -f4)
            myPlacePlatformNameFound=$(grep -n "\"${myPlacePlatformName}\"" "${fullPath}"|cut -d":" -f1)
            if [ -n "${myPlacePlatformNameFound}" ]; then
               return
            fi
         ;;
         2)
            myPlacePlatformName=$(echo "${myPlacePlatform2}"|cut -d'"' -f4)
            myPlacePlatformNameFound=$(grep -n "\"${myPlacePlatformName}\"" "${fullPath}"|cut -d":" -f1)
            if [ -n "${myPlacePlatformNameFound}" ]; then
               return
            fi
         ;;
      esac
   done
}

function cleanUp()
{
   rm -f "${configJson}"
   rm -f "${myPlaceConfigJson}"
   rm -f "${configJson}.MyPlaceless"
   rm -f "${myPlaceConfigConstantsBB}"
   rm -f "${myPlaceConfigQueueTypesBB}"
   rm -f "${myPlaceConfigAccessoriesBB}"
   rm -f "${myPlaceConfigNonBB}"
   rm -f "${myPlaceConfigConstantsNonBB}"
   rm -f "${myPlaceConfigQueueTypesNonBB}"
   rm -f "${myPlaceConfigAccessoriesNonBB}"
   rm -f "${myPlaceConfigMiscKeys}"
   rm -f "${myPlaceConfigJsonBBwithNonBB}"
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
            echo "The file path format should be : /*/*/*/node_modules/homebridge-bondbridge/BondBridge.sh${TNRM}"
            read -r -p "${BOLD}> ${TNRM}" INPUT
            if expr "${INPUT}" : '/[a-zA-Z0-9/_]*/node_modules/homebridge-bondbridge/BondBridge.sh$' >/dev/null; then
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

   # Create the ${myPlaceConfigConstantsBB}, ${myPlaceConfigQueueTypesBB} and ${myPlaceConfigAccessoriesBB}
   if [ "${n}" = "1" ]; then
      myPlaceConfigJsonBB="myPlaceConfig_BB_${bondToken}.json"
      myPlaceConfigJsonBBwithNonBB="${myPlaceConfigJsonBB}.withNonBB"
      myPlaceConstantsHeader "${myPlaceConfigConstantsBB}"
      myPlaceQueueTypesHeader "${myPlaceConfigQueueTypesBB}"
      myPlaceAccessoriesHeader "${myPlaceConfigAccessoriesBB}"
   fi
   
   # Append the body of BB constants and queueTypes
   myPlaceConstants "${myPlaceConfigConstantsBB}"
   myPlaceQueueTypes "${myPlaceConfigQueueTypesBB}"

   # Create the $myPlaceConfigAccessories
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
               myPlaceFan "${myPlaceConfigAccessoriesBB}" "${name}"
            fi
            if [ "${timerSetup}" = "includeTimers" ]; then
               myPlaceTimerLightbulb "${myPlaceConfigAccessoriesBB}" "${name} Timer" "fanTimer" "fanDevice"
            fi
         fi
         #
         if expr "${name}" : '[a-zA-Z0-9 ]*Light$' >/dev/null; then
            if [ "${fullSetup}" = "fullSetup" ]; then
               myPlaceLightbulb "${myPlaceConfigAccessoriesBB}" "${name}" "light"
            else
               myPlaceLightbulb "${myPlaceConfigAccessoriesBB}" "${name} Dimmer" "dimmer"
            fi
            if [ "${timerSetup}" = "includeTimers" ]; then
               myPlaceTimerLightbulb "${myPlaceConfigAccessoriesBB}" "${name} Timer" "lightTimer" "lightDevice"
            fi
         fi
      fi
   done      
done

# Now write the created ${myPlaceConfigJsonBB} to ${HomebridgeConfigJson} replacing all 
# existing BB-related configuration 

# Assemble a complete MyPlace configuration file for the specified BB device(s)
assembleMyPlaceConfigJson

# Read the existing Homebridge config.json file
readHomebridgeConfigJson

# Extract all non-BB related devices
extractMyPlaceConfigFromConfigJson
extractNonBBaccessoriesConstantsQueueTypesMisc

# Assemble a complete MyPlace configuration file for the specified BB devices(s) with the extracted 
# non-BB related devices
assembleMyPlaceConfigJsonBBwithNonBB

# Write the assembled BB + non-BB configuration into the Homebridge config.json
writeToHomebridgeConfigJson

if [ "${rc}" = "0" ]; then
   echo "${TGRN}${BOLD}DONE! Run CheckConfig then restart Homebridge or HOOBS.${TNRM}" 
   rm -f "${myPlaceConfigJsonBB}"
   if [ "${UIversion}" = "nonUI" ]; then
      check1="${BONDBRIDGE_SH_PATH%/*}/CheckConfig.sh"
      echo ""
      echo "${TYEL}To run CheckConfig, please copy/paste and run the following command to check whether the configuration meets all the requirements${TNRM}"
      echo "${check1}"
   fi
else
   # Copying of the new config.json to homebridge config.json failes so restore the homebridge config.json from backup
   if [ "${UIversion}" = "nonUI" ]; then
     sudo cp "${configJson}" "${homebridgeConfigJson}"
   else
     cp "${configJson}" "${homebridgeConfigJson}"
   fi
   echo "${TRED}${BOLD}ERROR: Copying of \"${myPlaceConfigJsonBB}\" to Homebridge config.json failed! Original config.json restored.${TNRM}"
   echo "${TLBL}${BOLD}INFO: Instead you can copy/paste the content of \"${myPlaceConfigJsonBB}\" into MyPlace JASON Config editor.${TNRM}"
fi

cleanUp
exit 0
