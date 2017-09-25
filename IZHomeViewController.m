

#import "IZHomeViewController.h"
#import "IZBaseViewController+Protected.h"
#import "IZMenuCollectionViewCell.h"
#import "IZMenuFactory.h"
#import "NSString+Validation.h"
#import "IZUserService.h"

static NSString *const IZItemTitle          = @"Me profile";

@interface IZHomeViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *CollectionView;
@property (strong, nonatomic) NSArray *dataSource;
@property (weak, nonatomic) IBOutlet UILabel *idLabel;
@property (strong, nonatomic) IZUserService *userService;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@end

@implementation IZHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.idLabel.hidden = YES;
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self _setupForReadOnly];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

#pragma mark - Getter -

- (NSArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [IZMenuFactory menuItems:self.router];
    }
    return _dataSource;
}

- (IZUserService *)userService {
    if (!_userService) {
        IZUser *user = [IZDataManager sharedManager].currentUser;
        _userService = [[IZUserService alloc] initWithToken:user.token];
    }
    return _userService;
}

#pragma mark - Actions -

- (IBAction)editAction:(UIButton *)sender {
    [self.router showEnterPinOrWearableIDScreenAsRoot:YES];
}


#pragma mark - Private -

- (void)_setIdLabelWithUser:(IZUser *)user{
    self.idLabel.hidden = NO;
    self.idLabel.text = user.medimeeID;
    self.idLabel.textColor = [UIColor redColor];
}

- (void)_setEditButton {
    self.editButton.hidden = NO;
}

- (void)_setupForReadOnly {
    IZUser *user = [IZDataManager sharedManager].currentUser;
    if ([user isReadOnly]) {
        [self _setIdLabelWithUser:user];
        [self _setEditButton];
    }
}

#pragma mark - UICollectionViewDataSource - 

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IZMenuCollectionViewCell *cell = nil;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([IZMenuCollectionViewCell class]) forIndexPath:indexPath];
    [cell loadWithMenuItem:[self.dataSource objectAtIndex:indexPath.row]];
    cell.leftAlignment = indexPath.row % 2;
    return cell;
}

#pragma mark - UICollectionViewDelegate -

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    IZMenuItem *item = [self.dataSource objectAtIndex:indexPath.row];
    item.callback();
    IZMenuCollectionViewCell *cell = (IZMenuCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.imageView.highlightedImage = [UIImage imageNamed:item.highlightedImage];
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    IZMenuCollectionViewCell *cell = nil;
    cell = (IZMenuCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    IZMenuItem *item = [self.dataSource objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:item.imageName];
}

#pragma mark - UICollectionViewDelegateFlowLayout -

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float height = [UIScreen mainScreen].bounds.size.height;
    height -= [self collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:indexPath.section].top + [self collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:indexPath.section].bottom;
    height -= [self collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:indexPath.section] * (self.dataSource.count / 2 - 1);
    height /= self.dataSource.count / 2.0;
    return CGSizeMake(collectionView.frame.size.width / 2.0, height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(110, 0, 20, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 15;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

@end
