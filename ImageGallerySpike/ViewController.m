
#import "ViewController.h"

@interface ViewController ()

@property (nonatomic) ImageGalleryNode *imageGallery;
@property (nonatomic) RainbowNode *rainbow;
@property (nonatomic) CGFloat screenWidth;
@property (nonatomic) CGFloat screenHeight;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _screenWidth = [UIScreen mainScreen].bounds.size.width;
    _screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    ImageGalleryNode *imageGallery = [[ImageGalleryNode alloc] init];
//    imageGallery.frame = CGRectMake(0, self.view.frame.size.height - 250, self.view.frame.size.width, 250);
    imageGallery.frame = CGRectMake(0, 0, _screenWidth, _screenHeight/2);
    imageGallery.backgroundColor = [UIColor blueColor];
    imageGallery.cornerRadius = 4;
    imageGallery.dataSource = self;
    imageGallery.delegate = self;

    [self.view addSubview:imageGallery.view];
}

- (BOOL)shouldAutorotate;
{
    return NO;
}

#pragma mark Image Gallery Datasource

- (NSURL *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;
{
    u_int32_t deltaX = arc4random_uniform(10) - 5;
    u_int32_t deltaY = arc4random_uniform(10) - 5;
    CGSize size = CGSizeMake(350 + 2 * deltaX, 350 + 4 * deltaY);
    NSURL *kittenURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://placekitten.com/%i/%i", (int)size.width, (int)size.height]];
    
    return kittenURL;
}

- (NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
{
    return 10;
}

- (CGFloat)widthForImages;
{
    return self.view.bounds.size.width - 16 - 50;
}

- (NSInteger)numberOfRowsInImageGallery:(ImageGalleryNode *)imageGallery;
{
    return 2;
}

- (CGFloat)numberOfVisibleColumnsInImageGallery:(ImageGalleryNode *)imageGallery;
{
    return 2.25;
}

- (NSInteger)paddingForImagesInImageGallery:(ImageGalleryNode *)imageGallery;
{
    return 2;
}

#pragma mark Image Gallery Delegate

- (BOOL)imageGalleryShouldDisplayPositions;
{
    return YES;
}

- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

- (BOOL)imageGalleryShouldAllowFullScreenMode;
{
    //this way you can prevent newing up the images twice if you don't need to
    return NO;
}

@end
