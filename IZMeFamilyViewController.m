//
//  IZMeFamilyViewController.m
//  MediMee
//
//  Created by Vladislav Dudin on 12/6/16.
//  Copyright © 2016 Vladislav Dudin. All rights reserved.
//

#import "IZMeFamilyViewController.h"
#import "IZBaseViewController+Protected.h"
#import "IZFamilyAndWorkTableViewCell.h"
#import "IZAddPersonViewController.h"
#import "UIViewController+UIAlertControllerStyleAlert.h"
#import <MessageUI/MessageUI.h>
#import "NSString+Validation.h"
#import <CoreLocation/CoreLocation.h>
#import "UIViewController+MFMailCompose.h"
#import "IZLocationManager.h"
#import "NSString+Validation.h"
@import NSString_RemoveEmoji;

static NSString* const IZTitleNavBar                    = @"Me Family";
static NSString* const IZTitleSwipeDeleteButton         = @" DELETE";
static NSString *const IZUnssuccesfulGetLocationTitle   = @"Failed to get your location";
static NSString *const IZReadOnlyButtonTitle            = @"CONTACT ALL";
static NSString *const IZLocationManagerMessage         = @"You have to allow application use your location";

@interface IZMeFamilyViewController ()<UITableViewDelegate, UITableViewDataSource, IZAddPersonDelegate, IZTableViewCellDelegate,MFMessageComposeViewControllerDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataSource;
@property (strong, nonatomic) IZContactService *contactService;
@property (weak, nonatomic) IBOutlet UIButton *addPersonButton;
@property (strong, nonatomic) IZLocationManager *locationManager;
@property (assign, nonatomic) CGFloat currentLatitude;
@property (assign, nonatomic) CGFloat currentLongitude;

@end

@implementation IZMeFamilyViewController

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray arrayWithCapacity:0];
    }
    return _dataSource;
}

#pragma mark - LifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _setNavigationBar];
    [self _setBarBackButton:IZBackButtonDefault];
    [self _setDelegate];
    [self _updateData];
    [self _readOnlyMode];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

#pragma mark - Getters -

- (IZLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [IZLocationManager new];
    }
    return _locationManager;
}

#pragma mark - Private -

- (void)_setDelegate {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)_setNavigationBar {
    self.navigationController.navigationBarHidden = NO;
    [self _setDefaultNavigationBar];
    self.title = IZTitleNavBar ;
}

- (void)_updateData {
    [self showLoading];
    IZUser *currentUser = [IZDataManager sharedManager].currentUser;
    __weak typeof(self) weakSelf = self;
    [self.contactService getFamilyContactsByMedimeeID:currentUser.medimeeID complition:^(NSArray *result, NSError *error) {
        [weakSelf hideLoading];
        if (error) {
            [weakSelf showAlertWithError:error];
            return;
        }
        [weakSelf.dataSource removeAllObjects];
        [weakSelf.dataSource addObjectsFromArray:result];
        [weakSelf.tableView reloadData];
    }];
}

- (void)_getCurrentLocationAndSendSMS {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [self showAlertWithString:IZLocationManagerMessage title:@"" OKButtonHandler:nil];
    } else {
        [self showLoading];
        __weak typeof(self) weakSelf = self;
        [self.locationManager updateLocationAtOnceWithCompletionBlock:^(CLLocationManager *manager, CLLocation *currentLocation, NSError *error) {
            [weakSelf hideLoading];
            weakSelf.currentLatitude = currentLocation.coordinate.latitude;
            weakSelf.currentLongitude = currentLocation.coordinate.longitude;
            [self sendMessageWithBody:[NSString stringWithFormat:sos_message, [IZDataManager sharedManager].currentUser.firstName, [IZDataManager sharedManager].currentUser.surname, self.currentLatitude, self.currentLongitude] recipients:[self _getFamilyPhones] delegate:self];
        }];
    }
}

- (void)_readOnlyMode {
    if ([[IZDataManager sharedManager].currentUser isReadOnly]) {
        [self _setReadOnlyButton];
        [self _tableViewSelection];
    }
}

- (void)_setReadOnlyButton {
    [self.addPersonButton setTitle:IZReadOnlyButtonTitle forState:UIControlStateNormal];
    [self.addPersonButton setImage:nil forState:UIControlStateNormal];
    [self.addPersonButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    if (!self.dataSource.count) {
        self.addPersonButton.enabled = NO;
    }
}

- (void)_tableViewSelection {
    self.tableView.allowsSelection = NO;
}

- (NSArray *)_getFamilyPhones {
    NSArray *phones = [self.dataSource valueForKey:NSStringFromSelector(@selector(phoneNumber))];
    return phones;
}

- (void)_deleteContactWithIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView{
    IZContact *contact = [self.dataSource objectAtIndex:indexPath.row];
    [self showLoading];
    __weak typeof(self) weakSelf = self;
    [self.contactService deleteContactWithID:contact.modelID completion:^(BOOL success, NSError *error) {
        [weakSelf hideLoading];
        if (error) {
            [weakSelf showAlertWithError:error];
            return ;
        }
        if (!success) {
            return;
        }
        [weakSelf.dataSource removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [weakSelf.tableView reloadData];
    }];
}

#pragma mark - Getter - 

- (IZContactService *)contactService {
    if (!_contactService) {
        IZUser *currentUser = [IZDataManager sharedManager].currentUser;
        _contactService = [[IZContactService alloc] initWithToken:currentUser.token];
    }
    return _contactService;
}

#pragma mark - Actions -

- (IBAction)addPersonAction:(id)sender {
    if ([[IZDataManager sharedManager].currentUser.token isEmpty]) {
        [self _getCurrentLocationAndSendSMS];
    } else {
      [self.router showAddPersonScreenWithContact:nil delegate:self family:YES];
    }
}

#pragma mark - UITableViewDataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IZFamilyAndWorkTableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([IZFamilyAndWorkTableViewCell class])];
    cell.myDelegate = self;
    if (self.dataSource.count > 0) {
        IZContact *contact = [self.dataSource objectAtIndex:indexPath.row];
        [cell loadWithContactItem:contact];
    }
    if (![[IZDataManager sharedManager].currentUser.token isEmpty]) {
    cell.rightButtons = @[[MGSwipeButton buttonWithTitle:IZTitleSwipeDeleteButton icon:[UIImage imageNamed:@"deleteIMG"] backgroundColor:GREEN_COLOR callback:^BOOL(MGSwipeTableCell * _Nonnull cell) {
        [self _deleteContactWithIndexPath:indexPath tableView:tableView];
        return YES;
    }]];
    }
    return cell;
}

#pragma mark - IZAddPersonDelegate -

- (void)addPersonViewControllerDidUpdateContact:(IZAddPersonViewController *)addPersonViewController {
    [self _updateData];
}

#pragma mark - IZTableViewCellDelegate -

- (void)callMember:(IZFamilyAndWorkTableViewCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    IZContact *contact = [self.dataSource objectAtIndex:indexPath.row ];
    
    NSString *memberPhone = [contact.phoneNumber stringByRemovingEmoji];
    NSString *newString = [[memberPhone componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"() ,"]] componentsJoinedByString:@""];
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt://%@",newString]];
    if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl options:@{} completionHandler:nil];
    } else{
        [self showAlertWithString:@"Call facility is not available!" title:@"" OKButtonHandler:nil];
    }
 }

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        IZContact *contact = [self.dataSource objectAtIndex:indexPath.row];
        [self.router showAddPersonScreenWithContact:contact delegate:self family:contact.type];
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[IZDataManager sharedManager].currentUser isReadOnly]) {
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - MFMessageComposeViewControllerDelegate -

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    switch (result) {
            case MessageComposeResultCancelled:
            NSLog(@"Cancelled");
            break;
            
            case MessageComposeResultFailed:
            [self showAlertWithString:@"Failed to send SMS!" title:@"" OKButtonHandler:nil];
            
            break;
            case MessageComposeResultSent:
            
            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
