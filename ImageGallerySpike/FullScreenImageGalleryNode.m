
#import "FullScreenImageGalleryNode.h"

@interface FullScreenImageGalleryNode ()

typedef NS_ENUM(NSInteger, HorizontalScrollDirection) {
    HorizontalScrollDirectionLeft,
    HorizontalScrollDirectionRight
};

@property (nonatomic) BOOL isPanningVertically;
@property (nonatomic) ASImageNode *currentImageNode;
@property (nonatomic) CGPoint previousTouchLocation;
@property (nonatomic) CGFloat difference;

@property (nonatomic) CGFloat previousTouchXPosition;
@property (nonatomic) HorizontalScrollDirection horizontalScrollDirection;

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

    return self;
}

- (void)didLoad;
{
    [super didLoad];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(galleryDidPan:)];
    [self.view addGestureRecognizer:pan];
}

- (CGFloat)proportionateHeightForImage:(UIImage *)image;
{
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
                _previousTouchXPosition = [pan locationInView:self.view].x;
                if (vel.x > 0) {
                    NSLog(@"RIGHT!! at %f velocity", vel.x);
                    _horizontalScrollDirection = HorizontalScrollDirectionRight;
                } else {
                    NSLog(@"LEFT!! at %f velocity", vel.x);
                    _horizontalScrollDirection = HorizontalScrollDirectionLeft;
                }
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (_isPanningVertically) {
                CGFloat xDifference = [pan locationInView:self.view].x - _previousTouchLocation.x;
                CGFloat yDifference = [pan locationInView:self.view].y - _previousTouchLocation.y;
                CGPoint newImagePosition = CGPointMake(self.currentImageNode.position.x + xDifference, self.currentImageNode.position.y + yDifference);
                
                self.currentImageNode.position = newImagePosition;
                _previousTouchLocation = [pan locationInView:self.view];
            } else {
                CGFloat newX = [pan locationInView:self.view].x;
                _difference = newX - _previousTouchXPosition;
                
                [self moveAllNodesHorizontallyByDifference];
                
                _previousTouchXPosition = newX;
                
                if (vel.x > 0) {
                    NSLog(@"RIGHT!! at %f velocity", vel.x);
                    _horizontalScrollDirection = HorizontalScrollDirectionRight;
                } else {
                    NSLog(@"LEFT!! at %f velocity", vel.x);
                    _horizontalScrollDirection = HorizontalScrollDirectionLeft;
                }
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

- (void)moveAllNodesHorizontallyByDifference;
{
    ASDisplayNode *firstNode = (ASDisplayNode *)self.imageNodes[0];
    ASDisplayNode *lastNode = (ASDisplayNode *)self.imageNodes.lastObject;
    CGFloat sweetSpotXValue = self.frame.size.width - lastNode.frame.size.width;
    
    for (ASDisplayNode *node in self.imageNodes) {
        CGPoint newCenter = CGPointMake((node.view.center.x + _difference), node.view.center.y);
        node.view.center = newCenter;
    }
    
}

- (void)hide;
{
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
            
            for (ASNetworkImageNode *node in self.subnodes) {
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
    self.hidden = NO;
    self.backgroundColor = [UIColor blackColor];
    ASImageNode *node = (ASImageNode *)self.imageNodes[index];
    node.position = self.view.center;

    self.currentImageNode = node;
    [self addSubnode:node];
}

@end
