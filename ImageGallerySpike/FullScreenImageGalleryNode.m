
#import "FullScreenImageGalleryNode.h"

@interface FullScreenImageGalleryNode ()
@property (nonatomic) NSArray *imageUrls;
@property (nonatomic) NSMutableArray *imageNodes;
@property (nonatomic) NSMutableArray *images;

@property (nonatomic) BOOL isPanningVertically;
@property (nonatomic) ASNetworkImageNode *currentImageNode;
@property (nonatomic) CGPoint previousTouchLocation;
@end

@implementation FullScreenImageGalleryNode

- (instancetype)initWithImageUrls:(NSArray *)imageUrls;
{
    if (!(self = [super init])) { return nil; }
    
    self.imageUrls = imageUrls;
    self.imageNodes = @[].mutableCopy;
    
    for (NSInteger i = 0; i < self.imageUrls.count; i++) {
        ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
        node.view.userInteractionEnabled = YES;
        node.defaultImage = [UIImage imageNamed:@"cat"];
        node.delegate = self;

        node.contentMode = UIViewContentModeScaleAspectFill;
        node.URL = self.imageUrls[i];

        node.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 200);
        node.placeholderColor = [UIColor orangeColor];

        self.imageNodes[i] = node;
    }
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(galleryDidPan:)];
    [self.view addGestureRecognizer:pan];
    
    return self;
}

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image;
{
    imageNode.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, [self proportionateHeightForImage:image]);
    imageNode.position = self.view.center;
}

- (CGFloat)proportionateHeightForImage:(UIImage *)image;
{
    NSLog(@"\n Image: %@", image);
    
    return (UIScreen.mainScreen.bounds.size.width * image.size.height)/image.size.width;
}

- (void)galleryDidPan:(UIPanGestureRecognizer *)pan;
{
    CGPoint vel = [pan velocityInView:self.view];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            
            if (abs(vel.y) > abs(vel.x)){
                _isPanningVertically = YES;
                self.backgroundColor = [UIColor clearColor];

                _previousTouchLocation = [pan locationInView:self.view];
                
                if (vel.y > 0) {
                    NSLog(@"DOWN!! at %f velocity", vel.y);
                } else {
                    NSLog(@"UP!! at %f velocity", vel.y);
                }
            } else {
                _isPanningVertically = NO;
                if (vel.x > 0) {
                    NSLog(@"RIGHT!! at %f velocity", vel.x);
//                    self.direction = SwipeGestureDirectionRight;
                    
                } else {
                    NSLog(@"LEFT!! at %f velocity", vel.x);
//                    self.direction = SwipeGestureDirectionLeft;
                }
            }
//            self.touchXPosition = [pan locationInView:self.view].x;
            break;
        case UIGestureRecognizerStateChanged:
            if (_isPanningVertically) {
                CGFloat xDifference = [pan locationInView:self.view].x - _previousTouchLocation.x;
                CGFloat yDifference = [pan locationInView:self.view].y - _previousTouchLocation.y;
                
                CGPoint newImageCenter = CGPointMake(self.currentImageNode.view.center.x + xDifference, self.currentImageNode.view.center.y + yDifference);
                
                self.currentImageNode.view.center = newImageCenter;
                _previousTouchLocation = [pan locationInView:self.view];


                NSLog(@"PANNING VERT!!");
                
            } else {
                //when you're panning horizontally
                //the changes in x position should translate to the centers of the all the cards shifting horizontally

            }
            
            break;
        case UIGestureRecognizerStateEnded:
            if (_isPanningVertically) {
                self.currentImageNode.view.center = self.view.center;
                _isPanningVertically = NO;
                [self hide];
            }
            break;
        default:
            break;
    }
}

- (void)imageTouchedDown:(ASNetworkImageNode *)node;
{
    NSLog(@"image touched down");
}

- (void)imageTouchedUpInside:(ASNetworkImageNode *)node;
{
    NSLog(@"image touched up inside");
}

- (void)hide;
{
    //animate view back to right spot
    
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
    anim.toValue = [NSValue valueWithCGPoint: self.positionToAnimateBackTo];
    anim.springBounciness = 5;
    anim.springSpeed = 12;
    
    POPSpringAnimation *sizeAnim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerSize];
    sizeAnim.toValue = [NSValue valueWithCGSize:self.sizeToAnimateBackTo];
    sizeAnim.springBounciness = 5;
    sizeAnim.springSpeed = 12;
    
    POPBasicAnimation *cornerAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerCornerRadius];
    cornerAnim.toValue = @(4);
    
    void (^completion)(POPAnimation *anim, BOOL completed) = ^(POPAnimation *anim, BOOL completed){
        if (completed) {
            self.hidden = YES;
            self.backgroundColor = [UIColor clearColor];
            [self.delegate unhideHiddenView];
            for (ASNetworkImageNode *node in self.subnodes) {
                [node removeFromSupernode];
            }
        }
    };
    
    anim.completionBlock = completion;
    sizeAnim.completionBlock = completion;
    cornerAnim.completionBlock = completion;
    
    [self.currentImageNode pop_addAnimation:anim forKey:nil];
    [self.currentImageNode pop_addAnimation:cornerAnim forKey:nil];
    
//    POPBasicAnimation colorAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerBackgroundColor];
//    colorAnim.toValue = [UIColor clearColor];
    
    }

- (void)showAtIndex:(NSInteger)index;
{
    //maybe just have the image's to the sides loaded and when you swipe make the next one visible so you only have to worry about
    //three frame positions at a time?
    self.hidden = NO;
    self.backgroundColor = [UIColor blackColor];
    ASNetworkImageNode *node = (ASNetworkImageNode *)self.imageNodes[index];
    node.position = self.view.center;

    self.currentImageNode = node;
    [self addSubnode:node];
}

@end
