

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BeaconBroadcastViewController : UITableViewController <CBPeripheralManagerDelegate, UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@end
