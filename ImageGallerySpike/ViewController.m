
#import "ViewController.h"

@interface ViewController ()

@property (nonatomic) ImageGalleryNode *imageGallery;
@property (nonatomic) RainbowNode *rainbow;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    ImageGalleryNode *imageGallery = [[ImageGalleryNode alloc] init];
    imageGallery.frame = CGRectMake(0, self.view.frame.size.height - 250, self.view.frame.size.width, 250);
    imageGallery.cornerRadius = 4;
    imageGallery.dataSource = self;
    imageGallery.delegate = self;
    imageGallery.backgroundColor = [UIColor clearColor];

    [self.view addSubview:imageGallery.view];
}

- (BOOL)shouldAutorotate;
{
    return NO;
}

#pragma mark Image Gallery Datasource

- (NSURL *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;
{
//    if (index == 0) {
//        return [NSURL URLWithString:@"http://img.vast.com/original/4004703374594052526"];
//    }
//    
    CGFloat rand1 = arc4random_uniform(200) + 200;
    CGFloat rand2 = arc4random_uniform(200) + 200;
    NSURL *kittenURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://placekitten.com/%i/%i", (int)rand1, (int)rand2]];
    
    return kittenURL;
}

- (NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
{
    return 5;
}

- (CGFloat)widthForImages;
{
    return self.view.bounds.size.width - 16 - 50;
}

#pragma mark Image Gallery Delegate

- (BOOL)imageGalleryShouldDisplayPositions;
{
    return NO;
}

- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

- (BOOL)imageGalleryShouldAllowFullScreenMode;
{
    //this way you can prevent newing up the images twice if you don't need to
    return YES;
}

@end
