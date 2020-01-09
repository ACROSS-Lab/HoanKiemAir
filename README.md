# HoanKiemAir
Repository for the HoanKiemAir

![screenshots](https://i.imgur.com/8mhaV0i.png)

# Which project ?

* ~./HoanKiemAir/GAMA/GAMA_1.8RC2/HoanKiemAir/~
* ~./HoanKiemAir/GAMA/GAMA_1.8RC2/HoanKiemAir - 2018 Journees Innovation HCMC/~
* ./HoanKiemAir/GAMA/GAMA_1.8RC2/HoanKiemAir - 2019 Journees Environnement Ambassade HN/

# What GAMA ?

* ~GAMA 1.8 RC2~
* [GAMA 1.8.0](https://github.com/gama-platform/gama/releases/tag/v1.8.0)

# Setup

## GAMA

### Plugins

From that URL : http://updates.gama-platform.org/experimental

Install the whole package _Paticipative simulations_ <!--yes there's really that mistake in the name--> including :

* Gaming
* Remote.Gui

### Keystone

* Press the `K` key
* Move your angles
* Values are automatically copied in your press-paper
* Paste it in your model's experiment (line 343)

## Remote controler

> ⚠️ Works only on android OS

* Use [_Android Studio_](https://developer.android.com/studio) to install the app on your phone/tablet
* Launch [`activemq`](https://activemq.apache.org/) on your computer running GAMA
* Set the `mqtt_connect` boolean (line 16) on `true`
* Enter the IP address of the computer in the app

> Mind that the computer and the remote should both be on the same network
