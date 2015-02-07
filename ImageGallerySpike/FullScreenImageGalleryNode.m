
#import "FullScreenImageGalleryNode.h"

@interface FullScreenImageGalleryNode ()
@property (nonatomic) NSArray *imageUrls;
@property (nonatomic) NSMutableArray *imageNodes;
@property (nonatomic) NSUInteger zoomedInLevel;
@end

@implementation FullScreenImageGalleryNode

- (instancetype)initWithImageUrls:(NSArray *)imageUrls;
{
    if (!(self = [super init])) { return nil; }
    
    self.imageUrls = imageUrls;
    self.imageNodes = @[].mutableCopy;
    self.zoomedInLevel = 0;
    self.view.userInteractionEnabled = YES;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
//    [self.view addGestureRecognizer:tap];
    self.view.userInteractionEnabled = YES;
    
    for (NSInteger i = 0; i < self.imageUrls.count; i++) {
        ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
        node.view.userInteractionEnabled = YES;

        [node.view addGestureRecognizer:tap];
        node.contentMode = UIViewContentModeScaleAspectFit;
        node.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
        node.URL = self.imageUrls[i];
        node.placeholderColor = [UIColor orangeColor];

        self.imageNodes[i] = node;
    }
    
    return self;
}

- (void)tapped:(UITapGestureRecognizer *)tap;
{
    NSLog(@"tapped");
}

- (void)imageTouchedDown:(ASNetworkImageNode *)node;
{
    NSLog(@"image touched down");
}

- (void)imageTouchedUpInside:(ASNetworkImageNode *)node;
{
    NSLog(@"image touched up inside");
    
    //animate the height and width and center so the image is zoomed in
    // center goes to view center
    //height goes to screen height
    //width goes to whatever is proportionate
    
    if (self.zoomedInLevel == 0) {
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewSize];
        anim.toValue = [NSValue valueWithCGSize:CGSizeMake(self.view.frame.size.width * 2, self.view.frame.size.height * 2)];
        [node pop_addAnimation:anim forKey:nil];
        self.zoomedInLevel = 1;
    } else {
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewSize];
        anim.toValue = [NSValue valueWithCGSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height)];
        [node pop_addAnimation:anim forKey:nil];
        self.zoomedInLevel = 0;
    }

//    [self hide];
}

- (void)imageTapped:(UITapGestureRecognizer *)tap;
{
    NSLog(@"image tapped");
}

- (void)hide;
{
    self.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
    for (ASNetworkImageNode *node in self.subnodes) {
        [node removeFromSupernode];
    }
}

- (void)showAtIndex:(NSInteger)index;
{
    //maybe just have the image's to the sides loaded and when you swipe make the next one visible so you only have to worry about
    //three frame positions at a time?
    self.hidden = NO;
    self.backgroundColor = [UIColor blackColor];
    ASNetworkImageNode *node = (ASNetworkImageNode *)self.imageNodes[index];
    [self addSubnode:node];
}

@end
