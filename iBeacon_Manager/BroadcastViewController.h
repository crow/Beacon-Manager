

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BroadcastViewController : UITableViewController <CBPeripheralManagerDelegate, UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@end
