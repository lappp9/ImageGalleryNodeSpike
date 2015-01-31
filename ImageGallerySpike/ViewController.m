
#import "ViewController.h"

@interface ViewController ()

@property (nonatomic) ImageGalleryNode *imageGallery;
@property (nonatomic) RainbowNode *rainbow;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
//    RainbowNode *rainBowNode = [[RainbowNode alloc] init];
//    rainBowNode.vertical = NO;
//    rainBowNode.frame  = CGRectMake(10, 50, self.view.bounds.size.width-20, 240);
    
    CGFloat galleryWidth = self.view.bounds.size.width;
    
    ImageGalleryNode *imageGallery = [[ImageGalleryNode alloc] init];
    imageGallery.frame = CGRectMake(0, self.view.bounds.size.height - 240, galleryWidth, 240);
    imageGallery.dataSource = self;
    imageGallery.clipsToBounds = YES;
    
//    [self.view addSubview:rainBowNode.view];
    [self.view addSubview:imageGallery.view];

}

- (NSString *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;
{
    CGFloat rand1 = arc4random_uniform(255) + 200;
    CGFloat rand2 = arc4random_uniform(255) + 200;
    return [NSString stringWithFormat:@"http://placekitten.com/%f/%f", rand1, rand2];
}

-(NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
{
    return 10;
}

- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

@end
