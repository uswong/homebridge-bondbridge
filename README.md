# homebridge-cmd4-bondbridge
For ceiling fans fitted with **Hunter Pacific LOGIC remote control** or **equivalent** via **Bond Bridge RF Controller**

## Introduction

This `homebridge-cmd4-bondbridge` plugin is specially designed to control ceiling fans fitted with **[Hunter Pacific LOGIC remote control A2003](https://www.hunterpacificinternational.com/remotes)** (left image below) or **equivalent** via **[Bond Bridge RF Controller](https://bondhome.io/product/bond-bridge/)** (right image below).

![image](https://user-images.githubusercontent.com/96530237/224465046-3ee8211e-c92c-4c8f-9119-77256fd9e0e9.png)![image](https://user-images.githubusercontent.com/96530237/226806633-a846876d-af1b-4b49-8417-a9cc919da790.png)




You can make use of this plugin only if your ceiling fan remote is not in the Bond Bridge database and it has a Light with Dimmer, otherwise you should use the **[homebridge-bond](https://github.com/aarons22/homebridge-bond)** plugin instead.

## How to programme my RF remote control functions onto Bond Bridge RF Controller
To work as intended, the remote functions need to be programmed onto the Bond Bridge RF Controller as two separate "Celing Fan" devices, one for the Fan and one for the Light:
1. Add a "Ceiling Fan" device onto **Bond Bridge RF Controller** and programme the `Fan Off` function and the `Fan Speed` functions under "Fan". Name the device ending with " Fan" (e.g. Bed 4 Fan). Do not programme the `Light On/Off` functions here.  

     Note that the Fan Speed has intrinsic On function, as such the "Fan On" function is not required, only the "Fan Off" function need to be programmed.  No harm done also if you do programme both On/Off functions.

2. Add another "Ceiling Fan" device onto **Bond Bridge RF Controller** and programme the `Light On/Off` functions under "Light" and programme the `Light Dimmer` functions under "Fan" as "Fan Speed". This LOGIC remote has 7-levels dimmer, so programme them as "Speed 1", "Speed 2", etc.  Name this device ending with " Light" (e.g. Bed 4 Light).


     ![image](https://user-images.githubusercontent.com/96530237/226813380-1a867f56-61a5-42b8-ad10-5deeb7ac44f5.png)


This plugin does not use the built-in timers but use customer-built timers within a bash script. These timers have greater flexibility and capability to turn on or off the fan and the light. 

These timers used 'Lightbulb' accessory as proxy and `time-to-on` and `time-to-off` is set in % in a scale of 6 minutes per 1%, or 10% = 1.0 hour. Setting the Fan Timer when the Fan is in Off state will be a `time-to-on` timer and vice versa.

## Installation
### Raspbian/HOOBS/macOS/NAS:
1. If you have not already, install Homebridge via these instructions for [Raspbian](https://github.com/homebridge/homebridge/wiki/Install-Homebridge-on-Raspbian), [HOOBS](https://support.hoobs.org/docs) or [macOS](https://github.com/homebridge/homebridge/wiki/Install-Homebridge-on-macOS).
2. Install the `homebridge-cmd4` plug-in via the Homebridge UI `Plugins` tab search function. Once installed, a pop-up box with a small config in it will appear. Do not edit anything and make sure you click `SAVE`.
3. Install `homebridge-cmd4-bondbridge` plug-in via the Homebridge UI `Plugins` tab search function.
4. If you have not already, install  <B>jq</B> and <B>curl</B> via your terminal or Homebridge UI terminal or through ssh: 


     #### Raspbian/Hoobs:
     ```shell
     sudo apt-get install jq
     sudo apt-get install curl
     ```
     #### macOS:
     ```shell
     brew install jq
     brew install curl
     ```
     #### Synology NAS:

     ```shell
     apt-get install jq
     apt-get install curl
     ```
     #### QNAP NAS:

     ```shell
     apk add jq
     apk add curl
     ```

## Configuring the plugin
A configuration file is required to run this plugin and it can be generated automatically by running the script **ConfigCreator.sh**.

(A) Homebridge users with access to the Homebridge web UI can follow the steps below to run the script:

1. Go to the 'Plugins' tab in Homebridge UI and locate your newly installed `homebridge-cmd4-bondbridge`. Click `SETTINGS` and it should launch the **Homebridge Cmd4 BondBridge** setting dialogue page.
2. Scroll down to the 'Bond Bridge Device Settings' area and fill out the `IP Address` and `Token` of your Bond Bridge device (if you have more than one Bond Bridge devices, you can click `Add new device` to setup the others), and then click `SAVE`. It will close the UI and you will need to open it once more as per Step 1.
3. Tick/untick the `"Setup"` and `"Timer"`checkboxes depending what you would like to have in Homekit, then press the `CONFIG CREATOR` button to create your Bond Bridge configuration file. This Bond Bridge configuration file created is stored under `homebridge-cmd4` plugin.  You can have a look at this config by clicking `SETTING` of `homebridge-cmd4` plugin.
4. You may click `CHECK CONFIGURATION`to check the config created satisfies all requirements. On a success it will say `Passed`; if something is incorrect, an error message will pop up telling you what it is that you have missed and need to fix.

     ![image](https://user-images.githubusercontent.com/96530237/226834701-308a4d2c-3cfb-47c6-9675-4d4976c7a6fc.png)


(B) for users (e.g. HOOBS users) who do not have access to Homebridge UI will have to run the **ConfigCreator.sh** from your terminal.  Use the following terminal commands to locate and run the **ConfigCreator.sh** and follow the prompts: 

     cd
     config=$(find /usr 2>&1 | grep -v find | grep "homebridge-cmd4-bondbridge/ConfigCreator.sh$")
     echo "${config}"

  if `echo "${config}"` returns nothing, try the following:

     config=$(find /var/lib 2>&1 | grep -v find | grep "homebridge-cmd4-bondbridge/ConfigCreator.sh$")

  if `echo "${config}"` returns something then use the following command to run **ConfigCreator.sh**

     ${config}
     
  ![image](https://user-images.githubusercontent.com/96530237/226835385-dff9d40b-3ad7-43a1-95db-cafddfbf7668.png)
 

## How You Can Help:
* Report Bugs/Errors by opening Issues/Tickets.
* Suggest Improvements and Features you would like to see!

## Special Thanks:
1. Many thanks to [Mitch Williams](https://github.com/mitch7391) who has created the wonderful [Homebridge-cmd4-AdvantageAir](https://github.com/mitch7391/homebridge-cmd4-AdvantageAir) plugin and has allowed me to participate in its development and in the process I have leant a lot on **bash** and **javascript** coding in homebridge environment.
2. And never forget to thank my beautiful wife who has put up with my obsession on this.....
