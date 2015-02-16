
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

@property (nonatomic) CGSize currentImageActualSize;
@property (nonatomic) CGPoint currentImageActualPosition;

@property NSUInteger currentlyDisplayedNodeIndex;

@end

@implementation FullScreenImageGalleryNode

- (void)didLoad;
{
    [super didLoad];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(galleryDidPan:)];
    [self.view addGestureRecognizer:pan];
}

- (instancetype)initWithImages:(NSArray *)images;
{
    if (!(self = [super init])) { return nil; }
    
    self.imageNodes = @[].mutableCopy;
    _currentlyDisplayedNodeIndex = 0;
    
    self.backgroundColor = [UIColor blackColor];
    
    for (NSInteger i = 0; i < images.count; i++) {
        ASImageNode *node = [[ASImageNode alloc] init];
        node.image = images[i];
        node.userInteractionEnabled = YES;
        node.clipsToBounds = YES;
        node.contentMode = UIViewContentModeScaleAspectFill;
        
        CGFloat nodeXPosition = ((i * UIScreen.mainScreen.bounds.size.width) + (i * 8));
        
        node.frame = CGRectMake(nodeXPosition, 0, UIScreen.mainScreen.bounds.size.width, [self proportionateHeightForImage:images[i]]);
        node.position = CGPointMake(node.position.x, UIScreen.mainScreen.bounds.size.height/2);
        
        [self addSubnode:node];
        self.imageNodes[i] = node;
    }

    return self;
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
                
                self.currentImageActualPosition = self.currentImageNode.position;
                self.currentImageActualSize     = self.currentImageNode.frame.size;
                
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
            // when this ends, if it's been animating left and right then figure out which direction it ended up going and move it by one that direction
            NSLog(@"ENDEDDDDD!");
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
    for (ASDisplayNode *node in self.imageNodes) {
        CGPoint newCenter = CGPointMake((node.view.center.x + _difference), node.view.center.y);
        node.view.center = newCenter;
    }
}

- (void)hide;
{
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
        if (![self isAnimatingOutOfFullscreen]) {
            [self.delegate unhideHiddenView];

            self.hidden = YES;
            
            self.currentImageNode.bounds = CGRectMake(0, 0, self.currentImageActualSize.width, self.currentImageActualSize.height);
            self.currentImageNode.position = self.currentImageActualPosition;
        }
    };
    
    anim.completionBlock = completion;
    sizeAnim.completionBlock = completion;
    cornerAnim.completionBlock = completion;
    
    [self.currentImageNode pop_addAnimation:anim forKey:@"position"];
    [self.currentImageNode pop_addAnimation:cornerAnim forKey:@"cornerRadius"];
    [self.currentImageNode pop_addAnimation:sizeAnim forKey:@"size"];
}

- (BOOL)isAnimatingOutOfFullscreen;
{
    POPAnimation *position = [self.currentImageNode pop_animationForKey:@"position"];
    POPAnimation *size = [self.currentImageNode pop_animationForKey:@"size"];
    POPAnimation *cornerRadius = [self.currentImageNode pop_animationForKey:@"cornerRadius"];
    
    return (position || size || cornerRadius);
}

- (void)showAtIndex:(NSInteger)index;
{
    //they should all be fine as far as the y position goes but i should calculate the desired X position of each
    // one and move it to the correct spot
    
    self.hidden = NO;
    self.backgroundColor = [UIColor blackColor];
    
    NSInteger numberOfSpots = index - _currentlyDisplayedNodeIndex;
    _currentlyDisplayedNodeIndex = index;
    
    //((i * UIScreen.mainScreen.bounds.size.width) + (i * 8))
    CGFloat distanceToMove = -((numberOfSpots * UIScreen.mainScreen.bounds.size.width) + (numberOfSpots * 8));
    [self moveAllNodesHorizontallyBy:distanceToMove];

    self.currentImageNode = self.imageNodes[index];
}

- (CGFloat)xPositionForIndex;
{
    return 0;
}

- (void)moveAllNodesHorizontallyBy:(NSInteger)amount;
{
    for (ASNetworkImageNode *node in self.imageNodes) {
        CGPoint newCenter = CGPointMake((node.view.center.x + amount), node.view.center.y);
        node.position = newCenter;
    }
}

@end
