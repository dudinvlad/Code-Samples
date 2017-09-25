

#import "IZRegistrationViewController.h"
#import "IZBaseViewController+Protected.h"
#import "NSString+Validation.h"
#import "IZCountryFactory.h"
#import "IZMailManager.h"
#import "NSError+ErrorMessage.h"
#import "IZKeychain.h"
#import <CoreLocation/CoreLocation.h>
#import "IZLocationManager.h"


static CGFloat const IZLoginScreenBottomOffset     = 20.f;
static CGFloat const IZAnimationDuration           = 0.5f;
static CGFloat const IZPickerViewHeight            = 155.f;

static NSString* const IZMailSubject                            = @"We've problems";
static NSString* const IZMailMessageBody                        = @"Type your problem here";

@interface IZRegistrationViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) NSMutableArray *dataSource;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pickerViewHeight;
@property (weak, nonatomic) IBOutlet UILabel *countryLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *totalHeight;
@property (weak, nonatomic) IBOutlet UILabel *contactUsLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *activateButton;
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) NSString *countryCode;
@property (strong, nonatomic) IZUserService *userService;
@property (strong, nonatomic) IZMailManager *mailManager;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userEmailLabel;
@property (weak, nonatomic) IBOutlet UITextField *enterpriseIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *employeeTextField;
@property (weak, nonatomic) IBOutlet UILabel *emlpoyeeErrorLabel;
@property (weak, nonatomic) IBOutlet UILabel *enterpriseErrorLabel;
@property (strong, nonatomic) IZLocationManager *locationManager;
@property (strong, nonatomic) CLGeocoder *geocoder;

@end

@implementation IZRegistrationViewController

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (CLGeocoder *)geocoder {
    if (!_geocoder) {
        _geocoder = [CLGeocoder new];
    }
    return _geocoder;
}

- (IZLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [IZLocationManager new];
    }
    return _locationManager;
}

#pragma mark - Lifecycle -
- (void)viewDidLoad {
    [super viewDidLoad];
    [self _initialSetup];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.scrollView.contentSize = [self _scrollViewContentSize];
}

#pragma mark - Private -

- (void)_initialSetup {
    [self _getCurrentPosition];
    [self _setDelegates];
    [self _fillUserRow];
    self.pickerViewHeight.constant = 0;
    [self.dataSource addObjectsFromArray:[IZCountryFactory countries]];
    [self _hideValidationLabel];
}

- (void)_getCurrentPosition {
    [self showLoading];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [self hideLoading];
        [self showAlertWithString:@"You have to allow application use your location" title:@"" OKButtonHandler:nil];
    }
    __weak typeof(self) weakSelf = self;
    [self.locationManager updateLocationAtOnceWithCompletionBlock:^(CLLocationManager *manager, CLLocation *currentLocation, NSError *error) {
        [weakSelf _getAddressFromCoordinates:currentLocation];
    }];
}

- (void)_getAddressFromCoordinates:(CLLocation *)location {
    __weak typeof(self) weakSelf = self;
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        [weakSelf hideLoading];
        if ([placemarks count] > 0) {
            CLPlacemark *placemark = [placemarks lastObject];
            [weakSelf _getCurrentCountryCode:placemark.ISOcountryCode];
        }
    }];
}

- (void)_getCurrentCountryCode:(NSString *)code {
    self.countryCode = code;
    self.countryLabel.text = [IZCountryFactory countryNameForCode:code];
}

- (void)_hideValidationLabel {
    self.emlpoyeeErrorLabel.hidden = YES;
    self.enterpriseErrorLabel.hidden = YES;
}

- (void)_fillUserRow {
    IZUser *user = [IZUser new];
    user = [IZDataManager sharedManager].currentUser;
    NSString *firstPlusSurname = [user.firstName stringByAppendingString:[NSString stringWithFormat:@" %@", user.surname]];
    self.userEmailLabel.text = user.email;
    self.userNameLabel.text = firstPlusSurname;
}

- (void)callPrivacy {
    [self.router showPrivacyPolicyScreenWithTerms:NO];
}

- (void)_setCountryLabelByDefault {
    self.countryLabel.text = @"United Kingdom";
    self.countryCode = @"GB";
}

- (void) _setDelegates {
    self.pickerView.delegate =self;
}

- (void)_hideCountryPicker {
    self.totalHeight.constant = self.totalHeight.constant - self.pickerViewHeight.constant;
    self.pickerViewHeight.constant = 0;
    self.pickerView.hidden = YES;
}

- (void)_showCountryPicker {
    self.pickerViewHeight.constant = IZPickerViewHeight;
    self.totalHeight.constant = self.totalHeight.constant + self.pickerViewHeight.constant;
    self.pickerView.hidden = NO;
}

- (CGSize)_scrollViewContentSize {
    return CGSizeMake([UIScreen mainScreen].bounds.size.width, self.contactUsLabel.bottom + IZLoginScreenBottomOffset);
}

#pragma mark - Getter - 

- (IZUserService *)userService {
    if (!_userService) {
        _userService = [[IZUserService alloc] initWithToken:[IZDataManager sharedManager].currentUser.token];
    }
    return _userService;
}

- (IZMailManager *)mailManager {
    if (!_mailManager) {
        _mailManager = [IZMailManager new];
    }
    return _mailManager;
}

#pragma mark - Action -

- (IBAction)backToLoginAction:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)activateButtonAction:(UIButton *)sender {
    [self _hideValidationLabel];
    [self showLoading];
    __weak typeof(self) weakSelf = self;
    [self.userService activateIDWithEnterpriseID:self.enterpriseIDTextField.text employeeID:self.employeeTextField.text countryCode:self.countryCode compilation:^(id result, NSError *error) {
        [weakSelf hideLoading];
        if (!error) {
            [IZDataManager sharedManager].currentUser = result;
            [IZKeychain setOwner:result];
            [weakSelf.router showSuccessRegistrationScreen];
        } else if ([error errorMessageByType:IZErrorTypeEmployerId]) {
                            NSString *text = [error errorMessageByType:IZErrorTypeEmployerId];
                            weakSelf.emlpoyeeErrorLabel.hidden = NO;
                            weakSelf.emlpoyeeErrorLabel.text = [NSString stringWithFormat:@"%@", text];
        } else if ([error errorMessageByType:IZErrorTypeEnterpriseId]) {
                            NSString *text = [error errorMessageByType:IZErrorTypeEnterpriseId];
                            weakSelf.enterpriseErrorLabel.hidden = NO;
                            weakSelf.enterpriseErrorLabel.text = [NSString stringWithFormat:@"%@", text];
                        }
    }];
}

- (IBAction)tapCountryLabel:(UITapGestureRecognizer *)sender {
    [UIView animateWithDuration:IZAnimationDuration animations:^{
        if (self.pickerViewHeight.constant == 0) {
            [self _showCountryPicker];
            [self.view setNeedsLayout];
        } else {
            [self _hideCountryPicker];
        }
        [self.view layoutIfNeeded];
    }];
}


- (IBAction)showCountryPickerAction:(UIButton *)sender {
    [UIView animateWithDuration:IZAnimationDuration animations:^{
        if (self.pickerViewHeight.constant == 0) {
            [self _showCountryPicker];
            [self.view setNeedsLayout];
        } else {
            [self _hideCountryPicker];
        }
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)bottomLabelTap:(UITapGestureRecognizer *)sender {
    [self.mailManager sendEmailWithSubject:IZMailSubject messageBody:IZMailMessageBody recipients:Mail_Recipients presenter:self completionBlock:^(MFMailComposeViewController *controller, MFMailComposeResult result, NSError *error) {
        [controller dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)enterpriseEditingChanged:(UITextField *)sender {
    [self _enableActivateButton];
}


#pragma mark - UITextFieldDelegate -

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isFirstResponder]) {
        [textField resignFirstResponder];
    }
    return YES;
}

#pragma mark - UIPickerViewDataSource -
// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.dataSource.count;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    IZCountry *country = [self.dataSource objectAtIndex:row];
    return country.name;
//    return [self.sortArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    IZCountry *country = [self.dataSource objectAtIndex:row];
    self.countryCode = country.code;
    self.countryLabel.text = country.name;
}

#pragma mark - Validation - 

- (void)_enableActivateButton {
    self.activateButton.enabled = (![self.enterpriseIDTextField.text isEmpty]);
}

@end
