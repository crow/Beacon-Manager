#Beacon Manager ![alt text](https://github.com/crow/Beacon-Manager/blob/master/iBeacon_Manager/Icon-Spotlight-40.png "Beacon Manager")


Beacon Manager is a simple open-source iOS developer utility, available for [free on the App Store](https://itunes.apple.com/us/app/ibeacon-manager/id767148086?mt=8&ign-mpt=uo%3D4), that allows users to explore bluetooth low energy beacon functionality.  

Beacon Manager allows users to use their iOS device to broadcast as an beacon or monitor and interact with a list of beacon regions.  A beacon region list can be remotely hosted, or directly scanned in the application using a QR code.  

Beacon Manager Can:                                                                                       

* Broadcast using the Apple iBeacon standard
* Generate and read QR-encoded beacon lists
* Notify the user upon beacon region entry and exit
* Display proximity and RSSI for beacons in range
* Selectively monitor particular beacon regions
* Modify beacon notification properties
* Persistently store entry and exit statistics including dwell time

##Getting Started:##

Best way to get up and running with a custom beacon list is to generate a QR code using plain text. There are numerous free web applications to accomplish this task - one of which can be found [here](http://goqr.me/).

**Important:**

The plain text contents of the QR code must be properly formatted for the QR code to scan properly.

Each beacon signature component (UUID, Major, Minor, Identifier) must be separated by a comma.  
Each beacon signature must be separated by a period. 
Example:

```
<UUID1>,<major1>,<minor1>,<identifier1>.<UUID2>,<major2>,<minor2>,<identifier2>.<UUIDN>,<major>,<minorN>,<identifierN>.
```
