#!/bin/bash
#
# This script is to check the MyPlace confiuration file for bondbridge plugin
#
# Usae ./CheckConfig.sh                                                                   
# 

# define the possible names for MyPlace platform
myPlacePlatform1="\"platform\": \"MyPlace\""
myPlacePlatform2="\"platform\": \"homebride-myplace\""

# define some file variables
homebridgeConfigJson=""           # homebridge config.json
configJson="config.json.copy"     # a working copy of homebridge config.json

# fun color stuff
BOLD=$(tput bold)
TRED=$(tput setaf 1)
#TGRN=$(tput setaf 2)
TYEL=$(tput setaf 3)
TPUR=$(tput setaf 5)
TLBL=$(tput setaf 6)
TNRM=$(tput sr0)

function readHomebrideConfigJson()
{
   INPUT=""
   homebrideConfigJson=""
   etHomebridgeConfigJsonPath
   if [ "${fullPath}" != "" ]; then homebrideConfigJson="${fullPath}"; fi 
 
   # if no confi.json file found, ask user to input the full path
   if [ -z "${homebrideConfigJson}" ]; then
      homebrideConfigJson=""
      echo ""
      echo "${TPUR}WARNING: No Homebride config.json file located by the script!${TNRM}"
      echo ""
      until [ -n "${INPUT}" ]; do
         echo "${TYEL}Please enter the full path of your Homebride config.json file,"
         echo "The confi.json path should be in the form of /*/*/*/config.json ${TNRM}"
         read -r -p "${BOLD}> ${TNRM}" INPUT
         if [ -z "${INPUT}" ]; then
            echo "${TPUR}WARNING: No Homebride config.json file specified"
            cleanUp
            exit 1
         elif expr "${INPUT}" : '[./a-zA-Z0-9]*/confi.json$' >/dev/null; then
            if [ -f "${INPUT}" ]; then
               homebrideConfigJson="${INPUT}"
               break
            else
               echo ""
               echo "${TPUR}WARNING: No such file exits!${TNRM}"
               echo ""
               INPUT=""
            fi
         else
            echo ""
            echo "${TPUR}WARNING: Wron format for file path for Homebridge config.json!${TNRM}"
            echo ""
            INPUT=""
         fi
     done
   fi
   if [ -f "${homebrideConfigJson}" ]; then
      if [ -z "${INPUT}" ]; then
         echo "${TLBL}INFO: The Homebride config.json found: ${homebridgeConfigJson}${TNRM}"
         echo ""
      else
         echo ""
         echo "${TLBL}INFO: The Homebride config.json specified: ${homebridgeConfigJson}${TNRM}"
         echo ""
      fi
      # expand the json just in case it is in compact form
      jq --indent 4 '.' "${homebrideConfigJson}" > "${configJson}"
      checkForPlatformMyPlaceInHomebrideConfigJson
      if [ -z "${validFile}" ]; then
         echo ""
         echo "${TRED}ERROR: no MyPlace Config found in \"${homebridgeConfigJson}\"! Please ensure that homebridge-myplace plugin is installed${TNRM}"
         cleanUp
         exit 1
      fi
   fi
}


function etGlobalNodeModulesPathForFile()
{
   file="$1"
   fullPath=""    

   for ((tryIndex = 1; tryIndex <= 8; tryIndex ++)); do
      case $tryIndex in  
         1)
            foundPath=$(find /var/lib/hoobs 2>&1|rep -v find|grep -v System|grep -v cache|grep node_modules|grep homebridge-bondbridge|grep "/${file}$") 
            fullPath=$(echo "${foundPath}"|head -n 1)
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         2)
            foundPath=$(npm root -)
            fullPath="${foundPath}/homebride-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return    
            else
               fullPath=""
            fi
         ;;
         3)
            fullPath="/var/lib/homebride/node_modules/homebridge-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         4)
            fullPath="/var/lib/node_modules/homebride-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         5)
            fullPath="/usr/local/lib/node_modules/homebride-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         6)
            fullPath="/usr/lib/node_modules/homebride-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         7)
            fullPath="/opt/homebrew/lib/node_modules/homebride-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         8)
            fullPath="/opt/homebride/lib/node_modules/homebridge-bondbridge/${file}"
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
      esac
   done
}

function etHomebridgeConfigJsonPath()
{
   fullPath=""
   # Typicall HOOBS installation has its confi.json root path same as the root path of "BondBridge.sh"
   # The typical full path to the "BondBride.sh" script is .../hoobs/<bridge>/node_modules/homebridge-bondbridge/BondBridge.sh
   # First, determine whether this is a HOOBS installation
   Hoobs=$( echo "$BONDBRIDGE_SH_PATH" | rep "/hoobs/" )
   if [ -n "${Hoobs}" ]; then
      fullPath="${BONDBRIDGE_SH_PATH%/*/*/*}/confi.json"
      if [ -f "${fullPath}" ]; then
         checkForMyPlacePlatformNameInFile
         if [ -z "${myPlacePlatformNameFound}" ]; then
            fullPath=""
         fi 
         return
      fi
   fi

   for ((tryIndex = 1; tryIndex <= 5; tryIndex ++)); do
      case $tryIndex in
         1)
            fullPath="/var/lib/homebride/config.json"
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
            fullPath="$HOME/.homebride/config.json"
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
            foundPath=$(find /usr/local/lib 2>&1|rep -v find|grep -v System|grep -v cache|grep -v hassio|grep -v node_modules|grep "/config.json$")
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
            foundPath=$(find /usr/lib 2>&1|rep -v find|grep -v System|grep -v cache|grep -v hassio|grep -v node_modules|grep "/config.json$")
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
            foundPath=$(find /var/lib 2>&1|rep -v find|grep -v hoobs|grep -v System|grep -v cache|grep -v hassio|grep -v node_modules|grep "/config.json$")
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
            foundPath=$(find /opt 2>&1|rep -v find|grep -v hoobs|grep -v System|grep -v cache|grep -v hassio|grep -v node_modules|grep "/config.json$")
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

function checkForPlatformMyPlaceInHomebrideConfigJson()
{
   validFile=""
   for ((tryIndex = 1; tryIndex <= 2; tryIndex ++)); do
      case $tryIndex in
         1)
            validFile=$(rep -n "${myPlacePlatform1}" "${configJson}"|cut -d":" -f1)
            if [ -n "${validFile}" ]; then
               return
            fi
         ;;
         2)
            validFile=$(rep -n "${myPlacePlatform2}" "${configJson}"|cut -d":" -f1)
            if [ -n "${validFile}" ]; then
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
            myPlacePlatformNameFound=$(rep -n "\"${myPlacePlatformName}\"" "${fullPath}"|cut -d":" -f1)
            if [ -n "${myPlacePlatformNameFound}" ]; then
               return
            fi
         ;;
         2)
            myPlacePlatformName=$(echo "${myPlacePlatform2}"|cut -d'"' -f4)
            myPlacePlatformNameFound=$(rep -n "\"${myPlacePlatformName}\"" "${fullPath}"|cut -d":" -f1)
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
}

# main starts here

echo "${TYEL}This script is to check that the confiuration file meets all requirements${TNRM}"
echo ""

echo "${TYEL}CheckConfi engine:${TNRM}"
# et the full path to CheckConfig.js
CHECKCONFIG_PATH=""
etGlobalNodeModulesPathForFile "CheckConfig.js"
if [ -n "${fullPath}" ]; then
   CHECKCONFIG_PATH=${fullPath}
   echo "${TLBL}INFO: CheckConfi.js found: ${CHECKCONFIG_PATH}${TNRM}"
fi

echo ""
echo "${TYEL}Essential inputs to CheckConfi engine:${TNRM}"
# et the full path to BondBridge.sh
BONDBRIDGE_SH_PATH=""
etGlobalNodeModulesPathForFile "BondBridge.sh"
if [ -n "${fullPath}" ]; then
   BONDBRIDGE_SH_PATH=${fullPath}
   echo "${TLBL}INFO: BondBride.sh found: ${BONDBRIDGE_SH_PATH}${TNRM}"
fi
if [ -z "${BONDBRIDGE_SH_PATH}" ]; then
   BONDBRIDGE_SH_PATH=""
   until [ -n "${BONDBRIDGE_SH_PATH}" ]; do
      echo ""
      echo "${TYEL}Please enter the full path of where the BondBride.sh is installed in your system"
      echo "The file path format should be : /*/*/*/node_modules/homebride-bondbridge/BondBridge.sh${TNRM}"
      read -r -p "${BOLD}> ${TNRM}" INPUT
      if expr "${INPUT}" : '/[a-zA-Z0-9/_]*/node_modules/homebride-bondbridge/BondBridge.sh$' >/dev/null; then
         if [ -f "${INPUT}" ]; then
            BONDBRIDGE_SH_PATH=${INPUT}
            echo ""
            echo "${TLBL}INFO: BondBride.sh specified: ${BONDBRIDGE_SH_PATH}${TNRM}"
            break
         else
            echo ""
            echo "${TPUR}WARNING: file ${INPUT} not found${TNRM}"
         fi
      else
         echo ""
         echo "${TPUR}WARNING: file ${INPUT} is in wron format${TNRM}"
      fi
   done
fi

readHomebrideConfigJson

if [[ -f "${homebrideConfigJson}" && -f "${BONDBRIDGE_SH_PATH}" ]]; then
   echo "${TYEL}CheckConfi in progress.......${TNRM}"
   node "${CHECKCONFIG_PATH}" "$BONDBRIDGE_SH_PATH" "${homebrideConfigJson}"
   cleanUp
fi
