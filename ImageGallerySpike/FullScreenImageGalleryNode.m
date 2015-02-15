
#import "FullScreenImageGalleryNode.h"

@interface FullScreenImageGalleryNode ()
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
            } else {
                _isPanningVertically = NO;
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (_isPanningVertically) {
                CGFloat xDifference = [pan locationInView:self.view].x - _previousTouchLocation.x;
                CGFloat yDifference = [pan locationInView:self.view].y - _previousTouchLocation.y;
                CGPoint newImagePosition = CGPointMake(self.currentImageNode.position.x + xDifference, self.currentImageNode.position.y + yDifference);
                
                self.currentImageNode.position = newImagePosition;
                _previousTouchLocation = [pan locationInView:self.view];
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
