# homebridge-bondbridge

## Introduction
This `homebridge-bondbridge` plugin is specifically designed for ceiling fan with `Hunter Pacific LOGIC remote control` based on Bond V2 OpenAPI.

There is already a very advanced `homebridge-bond` plugin (https://github.com/aarons22/homebridge-bond), also based on Bond V2 OpenAPI, to control all devices mapped onto `Bond Bridge`. It is also very easy to set up! 

However, if your remote control (like my `LOGIC` remote control) is not in the `Bond Bridge` database, you need to map each button of your remote into `Bond Bridge` manually. The device created manually this way is referred to as `Raw Recorded Device`. The potential issue with `Raw Recorded Device` is that the accessories created on Homekit using `homebridge-bond` plugin may not be as intuitive as you want it to be and also may not be as functional as the remote itself.  This is the case for me, as such, I have decided to code this alternative plugin.

This plugin is not a standalone plugin but one which piggy-back on existing `homebridge-myplace` plugin which takes care of the creation of accessories in HomeKit and all the communications with HomeKit.  All I need to do is to code a `BondBridge.sh` bash script to take care of the interations between `homebridge-myplace` and `Bond Bridge`.

## Hunter Pacific LOGIC remote control
My `Hunter Pacific` `LOGIC` remote control is a very comprehensice Ceiling Fan remote control. It provides 4 speeds Fan with 4 levels Timer (1, 2, 3 and 6 hours) and 7 levels Light dimmer which also comes with 4 levels Timer.  This remote control allows the Fan Speed and the Light dimmer to be set even when the Fan or Light is in Off state.  The setting of the Fan speed when the Fan is Off will turn On the Fan.  The setting of the dimmer when the Light is Off will not turn On the Light.

![image](https://user-images.githubusercontent.com/96530237/175461637-2f1d0cd2-8ed2-497d-af99-7656fcd89824.png)

## My motivation
While I could manually map the 4 speeds Fan onto `Bond Bridge` as Ceiling Fan (`CF`) device, I was unable to map my 7 levels light dimmer as a Light (`LT`) device.  I ended up have to create a separate `CF` device as a proxy to map my 7 levels dimmer as 7 different speeds.  It works fine but the accessory created in Homekit using `homebridge-bond` plugin is a Fan rather a Lightbulb, hence it is a bit unintuitive. Moreover, the switch for the Light On/Off switch is displayed on the right side, the state of which is not the state shown on the HomeKit tile.  Only the state of the accessory displayed on the left side is displayed on the HomeKit tile.

I have contacted the Bond support requesting them to either include `LOGIC` remote control in their database or update the `Bond Bridge` firmware of the `LT` device to include dimmer buttons like the speed buttons in `CF` device. I have a couple of interactions with them on this issue and currently still awaiting for their solid actions on this.

For the Timer, I can map the Fan Timer into `Bond Bridge` `CF` device but timer option is not available for the `LT` device. With the current V2 OpenAPI, there is also no command available to retrieve the status of the Timer. This makes it not very useful! I ended up using `CF` device again as a proxy to map my Fan/Light Timer as `speed`. 

So, aftering mapping all my remote control buttons onto `Bond Bridge`, I have the following 4 separate independent `Raw Recorded Devices`:
1. A `CF` device with a Off button and 4 Speed buttons for my Ceiling Fan

![bond00](https://user-images.githubusercontent.com/96530237/175754554-d9d1b686-49f5-4131-87a3-23fbbc3ca819.jpg)

2. A `CF` device with 4 Speed buttons (Speed 1, Speed 2, Speed 3 and Speed 6) as a proxy for the Ceiling Fan for 1hr, 2hr, 3hr and 6 hr Timer

![bond11](https://user-images.githubusercontent.com/96530237/175754622-b054e8bd-dcc7-4e9a-9854-c63c04b680fd.jpg)

3. A combo `CF/LT` device for one On and one Off button in `LT` device and 7 Speed buttons in `CF` device as a proxy for the 7 levels of dimmer for the Light

![bond33](https://user-images.githubusercontent.com/96530237/175754878-128a4796-8dfe-485c-9101-d950dff3720f.jpg)

4. Another `CF` device with 4 Speed buttons (Speed 1, Speed 2, Speed 3 and Speed 6) as a proxy for the Ceiling Fan for 1hr, 2hr, 3hr and 6 hr Timer

![bond33](https://user-images.githubusercontent.com/96530237/175754630-a551aafd-0db7-45d8-ba92-d5fd84abbd43.jpg)

 
If I use `homebridge-bond` plugin, the above 4 respectively independent devices will be represented in HomeKit by 4 separate tiles/accessories:
1. An adjustable (0% - 100%) `Fan` accessory for the **Fan**
2. An adjsutable (0% - 100%) `Fan` accessory for **Fan Timer**
3. A combo accessory consisting of an adjustable (0% - 100%) `Fan` accessory on the left and a `Switch` accessory for the **Light** on the right
4. An adjsutable (0% - 100%) `Fan` accessory for **Light Timer**

These 4 accessories are independent of each other.  It is ok for the **Fan** & **Light** (accessories 1 & 3 above) to be independent but the **Timers** need to interact with their associated accessories and are not doing so with `homebridge-bond` plugin.

## My vision of the LOGIC remote accessories on HomeKit
1. I would like to have an addition `Switch` accessory on top of the adjustable `Fan` accessory for the **Fan** with the `Switch` accessory displayed on the left so that the state of the Homekit tile will be represented by whether the **Fan** is **On** or **Off**. The adjustable `Fan` accessory for Fan speed setting should be left **On** at all time as the Fan speed can be adjusted even when the **Fan** is on **Off** state.
2. Using `homebridge-bond` plugin, the combo accessory for the **Light** is not very intuitive with the adjustable `Fan` accessory on the left as light dimmer and a On/Off `Switch` accessory on the right. I would like the On/Off `Switch` accessory to be on the left so that the state of the HomeKit tile will be representative of whether the **Light** is **On** or **Off**. Instead of an adjustable `Fan` accessory as a proxy for light dimmer, I would like to have a adjustable `Lightbulb` accessory for **Light** dimmer and it should be left **On** at all time because it is adjustable even when the **Light** is in **Off** state.
3. Moreover, the **Timer** needs to interact with its associated device (**Fan** or **Light**).  The interactions is to ensure the followings:

    a. The **Timer** can only be set only if the associated device (**Fan** or **Light**) is **On**. It is a `count down to Off` timer.

    b. The **Timer**, once set, can only be cancelled by turning off the associated device. So if you just want to cancel the Timer, the associated device (**Fan** or **Light**) has to be turned **Off** and turn back **On** again. 

With the Bond V2 local OpenAPI and with my very recent experiences in bash script coding, I managed to code this `BondBridge.sh` bash script to have my remote control represented more intuitively on HomeKit and fully functional, perhaps even more functional, as the remote itself. The additional big advantage of this representation on Homekit is to be able to take advantage of the convenience of `Siri`.  I can ask `Siri` to turn **On/Off** the **Fan/Light** and set/cancel **Timers** without reaching out for the remote or the smart phone. If you are very tired and in bed already, getting up to get the remote or the smart phone is an undesirable chore! 

### Version 2
I don't exactly like the remote timer very much! I decided to have a timer independent of the remote but done locally within my homebridge script.  This version 2 homebridge script (`BaondBridge_v2.sh`) has the same Fan and Light functions as before but with `countDownToOn` and `countDownToOff` timer. If the Fan or Light is in Off state, the timer set will be a `countDownToOn` timer.  If the Fan or Light is in On state, the timer set will be a `countDownToOff` timer. The remaining time on the timer is also displayed on the Homekit timer accessory as well. You can cancel or reset the timer anytime you wish without needing to turn off the Fan/Light. 

I found this timer a lot more intuitive and useful.

### Version 3
I would like to be able to use a single wireless switch to toggle on/off the `Fan` or `Light`.  The Homekit automation is very limited and it does not support toggling of the state of a accessory. However, Home Assistant has a very advanced automation capability and allow the togging of a state of a device.  As such, I used Home Assistant Bond integration and used HASS Bridge to bring the `Fan` and `Light Switch` accessories to Homekit while still using my own homebridge script (BondBridge_v3.sh) to bring the adjustable `Lightbulb` accessory (not `Fan` accessory) as light dimmer and the timer accessories as described above to Homekit. For the accessories to work together, a simple automation within HomeKit is required to ensure the state of the `Light Dimmer` (from Homebridge) is always the same as the state of the `Light Switch` (from HASS Bridge).

This arrangement works better than version 2. It allows me to do the automation within Home Assistant to toggle the `Fan` or `Light` using a Xiaomi/Aqara wireless switch which was not possible with version 2.  Note that the Xiaomi/Aqara wireless switch needs to be integrated into Home Assistant for this to work. 

Below is a sketch of the above described interactions between the smart devices with HomeKit via Homebridge or Home Assistant/HASS bridge.

![image](https://user-images.githubusercontent.com/96530237/178499445-f52432fc-6015-46d5-bd20-8bb590533484.png)

