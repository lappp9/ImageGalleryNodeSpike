
#import "FullScreenImageGalleryNode.h"

@interface FullScreenImageGalleryNode ()
@property (nonatomic) NSArray *imageUrls;
@property (nonatomic) NSMutableArray *imageNodes;
@property (nonatomic) NSMutableArray *images;

@property (nonatomic) BOOL isPanningVertically;
@property (nonatomic) ASImageNode *currentImageNode;
@property (nonatomic) CGPoint previousTouchLocation;
@end

@implementation FullScreenImageGalleryNode

- (instancetype)initWithImages:(NSArray *)images;
{
    if (!(self = [super init])) { return nil; }
    
    self.imageNodes = @[].mutableCopy;
    
    for (NSInteger i = 0; i < images.count; i++) {
        ASImageNode *node = [[ASImageNode alloc] init];
        node.image = images[i];
        node.view.userInteractionEnabled = YES;
        node.clipsToBounds = YES;
        node.contentMode = UIViewContentModeScaleAspectFill;
        node.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, [self proportionateHeightForImage:images[i]]);
        node.placeholderColor = [UIColor orangeColor];
        
        self.imageNodes[i] = node;
    }
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(galleryDidPan:)];
    [self.view addGestureRecognizer:pan];
    return self;
}


- (instancetype)initWithImageUrls:(NSArray *)imageUrls;
{
    if (!(self = [super init])) { return nil; }
    
    self.imageUrls = imageUrls;
    self.imageNodes = @[].mutableCopy;
    
    for (NSInteger i = 0; i < self.imageUrls.count; i++) {
        ASImageNode *node = [[ASImageNode alloc] init];
        node.view.userInteractionEnabled = YES;
        node.clipsToBounds = YES;
        node.contentMode = UIViewContentModeScaleAspectFill;
        node.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 200);
        node.placeholderColor = [UIColor orangeColor];

        self.imageNodes[i] = node;
    }
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(galleryDidPan:)];
    [self.view addGestureRecognizer:pan];
    
    return self;
}

- (void)imageNode:(ASImageNode *)imageNode didLoadImage:(UIImage *)image;
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
                
                CGPoint newImagePosition = CGPointMake(self.currentImageNode.position.x + xDifference, self.currentImageNode.position.y + yDifference);
                
                self.currentImageNode.position = newImagePosition;
                _previousTouchLocation = [pan locationInView:self.view];
                
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

- (void)imageTouchedDown:(ASImageNode *)node;
{
    NSLog(@"image touched down");
}

- (void)imageTouchedUpInside:(ASImageNode *)node;
{
    NSLog(@"image touched up inside");
}

- (void)hide;
{
    NSLog(@"\n\n\nThe image's width is animating from %f and height is animating from %f\n\n\n", self.currentImageNode.frame.size.width, self.currentImageNode.frame.size.height);

    NSLog(@"\n\n\nThe image's width is animating to %f and height is animating to %f\n\n\n", self.sizeToAnimateBackTo.width, self.sizeToAnimateBackTo.height);
    
    CGSize  originalSize         = self.currentImageNode.frame.size;
    CGPoint originalPosition     = self.currentImageNode.position;
    CGFloat originalCornerRadius = 0;
    
    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
    anim.toValue = [NSValue valueWithCGPoint: self.positionToAnimateBackTo];
    anim.springBounciness = 5;
    anim.springSpeed = 12;
    
    POPSpringAnimation *sizeAnim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerSize];
    sizeAnim.fromValue = [NSValue valueWithCGSize:self.currentImageNode.frame.size];
    sizeAnim.toValue = [NSValue valueWithCGSize:self.sizeToAnimateBackTo];
    sizeAnim.springBounciness = 5;
    sizeAnim.springSpeed = 12;
    
    POPBasicAnimation *cornerAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerCornerRadius];
    cornerAnim.toValue = @(4);
    
    void (^completion)(POPAnimation *anim, BOOL completed) = ^(POPAnimation *anim, BOOL completed){
        if (completed) {
            [self.delegate unhideHiddenView];

            self.hidden = YES;
            
            self.currentImageNode.frame = CGRectMake(0, 0, originalSize.width, originalSize.height);
            self.currentImageNode.position = originalPosition;
            self.currentImageNode.cornerRadius = originalCornerRadius;
            
            for (ASImageNode *node in self.subnodes) {
                [node removeFromSupernode];
            }
        }
    };
    
    anim.completionBlock = completion;
    sizeAnim.completionBlock = completion;
    cornerAnim.completionBlock = completion;
    
    [self.currentImageNode.layer pop_addAnimation:anim forKey:nil];
    [self.currentImageNode.layer pop_addAnimation:cornerAnim forKey:nil];
    [self.currentImageNode.layer pop_addAnimation:sizeAnim forKey:nil];
    
    }

- (void)showAtIndex:(NSInteger)index;
{
    //maybe just have the image's to the sides loaded and when you swipe make the next one visible so you only have to worry about
    //three frame positions at a time?
    self.hidden = NO;
    self.backgroundColor = [UIColor blackColor];
    ASImageNode *node = (ASImageNode *)self.imageNodes[index];
    node.position = self.view.center;

    self.currentImageNode = node;
    [self addSubnode:node];
}

@end
