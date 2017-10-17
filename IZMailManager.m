
#import "IZMailManager.h"

@interface IZMailManager () <MFMailComposeViewControllerDelegate>

@property (copy, nonatomic) void (^completionBlock)(MFMailComposeViewController *,MFMailComposeResult, NSError *);

@end

@implementation IZMailManager

- (void)dealloc {
    NSLog(@"Im free");
}

#pragma mark - Public -

-(void)sendEmailWithSubject:(NSString *)subject messageBody:(NSString *)body recipients:(NSArray<NSString *> *)recipients presenter:(UIViewController *)viewController completionBlock:(void(^)(MFMailComposeViewController *,MFMailComposeResult, NSError *))block {
    if (![MFMailComposeViewController canSendMail]) {
        NSLog(@"Mail services are not available.");
        return;
    }
    self.completionBlock = block;
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:subject];
    [mc setMessageBody:body isHTML:NO];
    [mc setToRecipients:recipients];
    
    // Present mail view controller on screen
    [viewController presentViewController:mc animated:YES completion:NULL];
}

#pragma mark - <MFMailComposeViewControllerDelegate> -

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error {
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    if (self.completionBlock) {
        self.completionBlock(controller, result, error);
    }
 }

@end
