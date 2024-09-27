#!/bin/bash
#
# This script is to check the MyPlace configuration file for bondbridge plugin
#
# Usae ./CheckConfig.sh                                                                   
# 

# fun color stuff
BOLD=$(tput bold)
TRED=$(tput setaf 1)
TYEL=$(tput setaf 3)
TPUR=$(tput setaf 5)
TLBL=$(tput setaf 6)
TNRM=$(tput setaf 0)

function readHomebridgeConfigJson()
{
   INPUT=""
   homebridgeConfigJson=""
   getHomebridgeConfigJsonPath
   if [ "${fullPath}" != "" ]; then
      homebridgeConfigJson="${fullPath}"
      echo "${TLBL}INFO: The Homebridge config.json found: ${homebridgeConfigJson}${TNRM}"
      echo ""
   else 
      # if no valid config.json file, ask user to specify the full path
      echo ""
      echo "${TPUR}WARNING: No Homebridge config.json file located by the script!${TNRM}"
      echo ""
      until [ -n "${INPUT}" ]; do
         echo "${TYEL}Please enter the full path of your Homebridge config.json file,"
         echo "The config.json path should be in the form of /*/*/*/config.json ${TNRM}"
         read -r -p "${BOLD}> ${TNRM}" INPUT
         if [ -z "${INPUT}" ]; then
            echo "${TPUR}WARNING: No Homebridge config.json file specified"
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
      # check that this config.json file is valid - has "MyPlace" platform in it.
      fullPath="${homebridgeConfigJson}"
      checkForMyPlacePlatformInFile
      if [ -z "${myPlacePlatformFound}" ]; then
         echo ""
         echo "${TRED}ERROR: Homebridge Config.json specified in \"${homebridgeConfigJson}\" is invalid! Please ensure that homebridge-myplace plugin is installed and configured${TNRM}"
         exit 1
      else
         echo ""
         echo "${TLBL}INFO: Valid Homebridge config.json specified: ${homebridgeConfigJson}${TNRM}"
         echo ""
      fi
   fi
}


function getGlobalNodeModulesPathForFile()
{
   file="$1"
   fullPath=""    

   for ((tryIndex = 1; tryIndex <= 8; tryIndex ++)); do
      case $tryIndex in  
         1)
            foundPath=$(find /var/lib/hoobs 2>&1|grep -v find|grep -v System|grep -v cache|grep node_modules|grep homebridge-bondbridge|grep "/${file}$") 
            fullPath=$(echo "${foundPath}"|head -n 1)
            if [ -f "${fullPath}" ]; then
               return
            else
               fullPath=""
            fi
         ;;
         2)
            foundPath=$(npm root -)
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
   # The typical full path to the "BondBride.sh" script is .../hoobs/<bridge>/node_modules/homebridge-bondbridge/BondBridge.sh
   # First, determine whether this is a HOOBS installation
   Hoobs=$( echo "$BONDBRIDGE_SH_PATH" | grep "/hoobs/" )
   if [ -n "${Hoobs}" ]; then
      fullPath="${BONDBRIDGE_SH_PATH%/*/*/*}/config.json"
      if [ -f "${fullPath}" ]; then
         checkForMyPlacePlatformInFile
         if [ -z "${myPlacePlatformFound}" ]; then
            fullPath=""
         fi 
         return
      fi
   fi

   for ((tryIndex = 1; tryIndex <= 5; tryIndex ++)); do
      case $tryIndex in
         1)
            fullPath="/var/lib/homebridge/config.json"
            if [ -f "${fullPath}" ]; then
               checkForMyPlacePlatformInFile   
               if [ -n "${myPlacePlatformFound}" ]; then 
                  return
               else
                  fullPath=""
               fi
            fi
         ;;
         2)
            fullPath="$HOME/.homebridge/config.json"
            if [ -f "${fullPath}" ]; then
               checkForMyPlacePlatformInFile   
               if [ -n "${myPlacePlatformFound}" ]; then 
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
                  checkForMyPlacePlatformInFile   
                  if [ -n "${myPlacePlatformFound}" ]; then 
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
                  checkForMyPlacePlatformInFile   
                  if [ -n "${myPlacePlatformFound}" ]; then 
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
                  checkForMyPlacePlatformInFile   
                  if [ -n "${myPlacePlatformFound}" ]; then 
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
                  checkForMyPlacePlatformInFile   
                  if [ -n "${myPlacePlatformFound}" ]; then 
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

function checkForMyPlacePlatformInFile()
{
   myPlacePlatformFound=""
   myPlacePlatformFound=$( grep -n "\"MyPlace\"" "${fullPath}" )
}

# main starts here

echo "${TYEL}This script is to check that the configuration file meets all requirements${TNRM}"
echo ""

echo "${TYEL}CheckConfig engine:${TNRM}"
# get the full path to CheckConfig.js
CHECKCONFIG_PATH=""
getGlobalNodeModulesPathForFile "CheckConfig.js"
if [ -n "${fullPath}" ]; then
   CHECKCONFIG_PATH=${fullPath}
   echo "${TLBL}INFO: CheckConfig.js found: ${CHECKCONFIG_PATH}${TNRM}"
fi

echo ""
echo "${TYEL}Essential inputs to CheckConfig engine:${TNRM}"
# get the full path to BondBridge.sh
BONDBRIDGE_SH_PATH=""
getGlobalNodeModulesPathForFile "BondBridge.sh"
if [ -n "${fullPath}" ]; then
   BONDBRIDGE_SH_PATH=${fullPath}
   echo "${TLBL}INFO: BondBride.sh found: ${BONDBRIDGE_SH_PATH}${TNRM}"
fi
if [ -z "${BONDBRIDGE_SH_PATH}" ]; then
   BONDBRIDGE_SH_PATH=""
   until [ -n "${BONDBRIDGE_SH_PATH}" ]; do
      echo ""
      echo "${TYEL}Please enter the full path of where the BondBride.sh is installed in your system"
      echo "The file path format should be : /*/*/*/node_modules/homebridge-bondbridge/BondBridge.sh${TNRM}"
      read -r -p "${BOLD}> ${TNRM}" INPUT
      if expr "${INPUT}" : '/[a-zA-Z0-9/_]*/node_modules/homebridge-bondbridge/BondBridge.sh$' >/dev/null; then
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
         echo "${TPUR}WARNING: file ${INPUT} is in wrongformat${TNRM}"
      fi
   done
fi

readHomebridgeConfigJson

if [[ -f "${homebridgeConfigJson}" && -f "${BONDBRIDGE_SH_PATH}" ]]; then
   echo "${TYEL}CheckConfig in progress.......${TNRM}"
   node "${CHECKCONFIG_PATH}" "$BONDBRIDGE_SH_PATH" "${homebridgeConfigJson}"
fi
