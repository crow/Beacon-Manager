

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ALConfigurationViewController : UITableViewController <CBPeripheralManagerDelegate, UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@end
