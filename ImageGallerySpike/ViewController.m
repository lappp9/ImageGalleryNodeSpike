
#import "ViewController.h"

@interface ViewController ()

@property (nonatomic) ImageGalleryNode *imageGallery;
@property (nonatomic) RainbowNode *rainbow;
@property (weak, nonatomic) IBOutlet UIButton *tapMeButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    CGFloat galleryWidth = self.view.bounds.size.width;

    ImageGalleryNode *imageGallery = [[ImageGalleryNode alloc] init];
    imageGallery.frame = CGRectMake(0, self.view.bounds.size.height - 240, galleryWidth, 240);
    imageGallery.dataSource = self;
    imageGallery.delegate = self;

    [self.view addSubview:imageGallery.view];
}

-(BOOL)shouldAutorotate;
{
    return NO;
}

#pragma mark Image Gallery Datasource

- (NSURL *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;
{
    CGFloat rand1 = arc4random_uniform(200) + 200;
    CGFloat rand2 = arc4random_uniform(200) + 200;
    NSURL *kittenURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://placekitten.com/%i/%i", (int)rand1, (int)rand2]];
    
    
    
    return kittenURL;
}

-(NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
{
    return 20;
}

#pragma mark Image Gallery Delegate

- (BOOL)imageGalleryShouldDisplayPositions;
{
    return true;
}


- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

@end
