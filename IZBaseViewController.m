//
//  IZBaseViewController.m
//  MediMee
//
//  Created by Vladislav Dudin on 11/21/16.
//  Copyright © 2016 Vladislav Dudin. All rights reserved.
//

#import "IZBaseViewController.h"

//#define IZLeftBarButtonFrame            CGRectMake(0, 0, 40, 35)
//#define IZLeftBarButtonArrowFrame       CGRectMake(0, 0, 20,30)

#define IZBackButtonImageNames              @[IZImageNameMenu, IZImageNameArrowBack]

static NSString *const IZImageNameArrowBack         = @"arrowBack";
static NSString *const IZImageNameMenu              = @"menuButton";
static CGFloat const IZAnimateDuration              = 0.3f;



//arrowBack"];
//button = [[UIButton alloc] initWithFrame: IZLeftBarButtonArrowFrame];
//} else {
//    image = [UIImage imageNamed:@"menuButton"];

@interface IZBaseViewController ()

@property (strong, nonatomic) IZRouter *router;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIGestureRecognizer *recognizer;

@end

@implementation IZBaseViewController

#pragma mark - LifeCycle -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Getters -
- (IZRouter *)router {
    if (!_router) {
        _router = [[IZRouter alloc] initWithNavigationController:self.navigationController];
    }
    return _router;
}

#pragma mark - Protected -

-(void)_addRecognizerForHideKeyboard {
    UITapGestureRecognizer *recoznizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_hideKeyboard)];
    recoznizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:recoznizer];
    self.recognizer = recoznizer;
}

- (void)_removeRecognizerForHideKeyboard {
    [self.view removeGestureRecognizer:self.recognizer ];
}

-(void)_hideKeyboard {
    [self.view endEditing:YES];
}

- (void)_setupObservation {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keayboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)_removeObservation {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    } @catch (NSException *exception) {
        //do nothing
    } @finally {
        //do nothing
    }
}

- (NSDate *)_dateFromString:(NSString *)string {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    NSDate *date = [dateFormatter dateFromString:string];
    return date;
}

- (NSString *)_stringFromDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy/MM/dd";
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

- (void)_setDefaultNavigationBar {
    self.navigationController.navigationBar.barTintColor = NAV_COLOR;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
}

#pragma mark - Should be overriden -

//- (CGSize)_scrollViewContentSize {
////    NSAssert(true, @"_scrollViewContentSize should be overriden in subclasses");
//    return self.scrollView.contentSize;
//}

#pragma mark - Keyboard Events -
//
- (void)keyboardWillBeShown:(NSNotification *)aNotification {
    NSDictionary *info = [aNotification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey]CGRectValue].size;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:IZAnimateDuration
                     animations:^{
                         CGRect viewFrame = weakSelf.view.frame;
                         viewFrame.origin.y = -keyboardSize.height;
                         weakSelf.view.frame = viewFrame;
                     }];
//    self.scrollView.contentSize = [self _scrollViewContentSize];
//    self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0);
}
//
- (void)keayboardWillBeHidden:(NSNotification *)aNotification {
//    self.scrollView.contentInset = UIEdgeInsetsZero;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:IZAnimateDuration
                     animations:^{
                         CGRect viewFrame = weakSelf.view.frame;
                         viewFrame.origin.y = 0.0f;
                         weakSelf.view.frame = viewFrame;
                     }];
    [self _removeObservation];
}

- (void)_setBarBackButton:(IZBackButton)type {
    NSParameterAssert(type < IZBackButtonImageNames.count);
    UIImage *image = [UIImage imageNamed:[IZBackButtonImageNames objectAtIndex:type]];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    self.navigationItem.leftBarButtonItem = nil;
    [button setBackgroundImage:image forState:UIControlStateNormal];
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc] initWithCustomView: button];
     [button addTarget:self action:@selector(backToMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationItem setLeftBarButtonItem:leftBarButton];
    self.navigationItem.hidesBackButton = YES;
    
}

- (void)backToMenu {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
