
#import "ImageGalleryNode.h"

@interface ImageGalleryNode ()<_ASDisplayLayerDelegate, POPAnimationDelegate>
@property (nonatomic) NSMutableArray *imageNodes;
@property (nonatomic) CGFloat touchXPosition;
@property (nonatomic) CGFloat touchYPosition;
@property (nonatomic) CGFloat newX;
@property (nonatomic) CGFloat newY;
@property (nonatomic) CGFloat difference;

//when hitting an edge, you can just animte all the views back to their initial or ending places
@property (nonatomic) NSMutableArray *initialCenters;
@property (nonatomic) NSMutableArray *finalCenters;

//tracking the state of the subviews
@property (nonatomic) BOOL isPanningVertically;
@property (nonatomic) BOOL isFullScreen;
@property (nonatomic) CGRect fullScreenFrame;
@property (nonatomic) ASDisplayNode *touchedNode;

// after the pan upward has stopped
// animate all views sizes to full screen
// figure out how far the view you touched is from the center and animate all views that many points in that direction

//do i need to keep arrays of all the frames?
@end

@implementation ImageGalleryNode

/*
 //TODO:
 
 1) allow swiping up to transfer to full screen
 
    -- check where the touch lands and make sure that's the view that animates to the center of the screen

*/

#pragma mark View Drawing

+ (void)drawRect:(CGRect)bounds
  withParameters:(id<NSObject>)parameters
     isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock
   isRasterizing:(BOOL)isRasterizing
{
    if (!isRasterizing) {
        [[UIColor blackColor] set];
        UIRectFill(bounds);
    }
}

- (NSObject *)drawParametersForAsyncLayer:(_ASDisplayLayer *)layer;
{
    // this should return a dictionary that configures this view
    // just get teh config stuff from the datasource and then pass it along! i think...
    // move drawing code into drawRect and move all the gesture stuff into didlayoutsubviews or something
    NSMutableDictionary *dict = @{}.mutableCopy;
    return dict;
}

- (void)layout;
{
    [super layout];

    if (self.view.subviews.count != 0) {
        return;
    }
    
    self.imageNodes = @[].mutableCopy;
    self.initialCenters = @[].mutableCopy;
    self.finalCenters = @[].mutableCopy;
    _fullScreenFrame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    self.clipsToBounds = YES;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(galleryDidPan:)];
    
    [self.view addGestureRecognizer:pan];
    
    NSInteger numberOfImages = [self.dataSource numberOfImagesInImageGallery:self];
    
    for (int i = 0; i < numberOfImages; i++) {
        CGFloat imageNodeWidth = [self.dataSource widthForImages];
        CGFloat imageNodeHeight = self.bounds.size.height;
        
        ASNetworkImageNode *imageNode = [[ASNetworkImageNode alloc] init];
        self.imageNodes[i] = imageNode;

        imageNode.backgroundColor = [UIColor lightGrayColor];
        imageNode.URL = [self.dataSource imageGallery:self urlForImageAtIndex:i];
        imageNode.frame = CGRectMake(((i * imageNodeWidth) + (i * 4)), 0, imageNodeWidth, imageNodeHeight);
        imageNode.cornerRadius = 4;
    
        self.initialCenters[i] = [NSValue valueWithCGPoint:imageNode.view.center];
        [self.view addSubview:imageNode.view];
    }
    
    if ([self.delegate imageGalleryShouldDisplayPositions]) {
        [self addPositionLabelsToImageNodes];
    }
    
    [self calculateFinalCenters];
}

- (void)calculateFinalCenters;
{
    for (int i = 0; i < [self.dataSource numberOfImagesInImageGallery:self]; i++) {
        
        CGFloat distanceFromRightSide = 0;
        if (i == 0) {
            distanceFromRightSide = self.view.bounds.size.width - ([self.dataSource widthForImages]/2);
        } else {
            distanceFromRightSide = self.view.bounds.size.width - ([self.dataSource widthForImages]/2);
            distanceFromRightSide -= ((i * [self.dataSource widthForImages]) + (4 * i));
        }
        
        CGPoint finalCenter = CGPointMake(distanceFromRightSide, self.view.bounds.size.height/2);
        
        [self.finalCenters addObject:[NSValue valueWithCGPoint:finalCenter]];
    }
    
    self.finalCenters = [[self.finalCenters reverseObjectEnumerator] allObjects].mutableCopy;
}

- (void)addPositionLabelsToImageNodes;
{
    for (ASDisplayNode *imageNode in self.imageNodes) {
        ASDisplayNode *labelBackground = [[ASDisplayNode alloc] init];
        labelBackground.frame = CGRectMake(0, 0, 60, 20);
        labelBackground.layer.borderWidth = 1;
        labelBackground.layer.borderColor = [UIColor whiteColor].CGColor;
        labelBackground.backgroundColor = [UIColor darkGrayColor];
        labelBackground.alpha = 0.5;
        
        NSString *labelString = [NSString stringWithFormat:@"%ld of %ld", [self.imageNodes indexOfObject:imageNode]+1, self.imageNodes.count];
        UILabel *number = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 20)];
        number.text = labelString;
        number.backgroundColor = [UIColor clearColor];
        number.textAlignment = NSTextAlignmentCenter;
        number.textColor = [UIColor whiteColor];
        number.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:14];
        number.layer.borderColor = [UIColor darkGrayColor].CGColor;
        
        [imageNode.view addSubview:labelBackground.view];
        [imageNode.view addSubview:number];
    }
}

#pragma mark Animation Handling

- (void)removeAnimationsFromNodes;
{
    for (ASDisplayNode *node in self.imageNodes) {
        [node.view pop_removeAllAnimations];
    }
}

- (void)moveAllNodesHorizontallyByDifference;
{
    if (!(((ASDisplayNode *)self.imageNodes[0]).frame.origin.x > 50 || ((ASDisplayNode *)self.imageNodes[self.imageNodes.count-1]).frame.origin.x < 130)) {
        for (ASDisplayNode *node in self.imageNodes) {
            CGPoint newCenter = CGPointMake((node.view.center.x + _difference), node.view.center.y);
            node.view.center = newCenter;
        }
    } else {
        //move half as much
        for (ASDisplayNode *node in self.imageNodes) {
            CGPoint newCenter = CGPointMake((node.view.center.x + (_difference/2)), node.view.center.y);
            node.view.center = newCenter;
        }
    }
}

- (void)addDecayAnimationToAllSubviewsWithVelocity:(CGFloat)xVelocity;
{
    for (ASDisplayNode *node in self.imageNodes) {
        POPDecayAnimation *decay = [POPDecayAnimation animationWithPropertyNamed:kPOPViewCenter];
    
        decay.fromValue = [NSValue valueWithCGPoint:node.view.center];
        decay.velocity = [NSValue valueWithCGPoint:CGPointMake(xVelocity, 0)];
        decay.delegate = self;
        
        if ([self.imageNodes indexOfObject:node] == 0) {
            [node.view pop_addAnimation:decay forKey:@"firstNodeScroll"];
        } else if ([self.imageNodes indexOfObject:node] == self.imageNodes.count - 1) {
            [node.view pop_addAnimation:decay forKey:@"lastNodeScroll"];
        } else {
            [node.view pop_addAnimation:decay forKey:@"scroll"];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
    [self removeAnimationsFromNodes];
}

- (void)galleryDidPan:(UIPanGestureRecognizer *)pan;
{
    CGPoint vel = [pan velocityInView:self.view];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            //set up the bool values for what direction this pan is going
            if (abs(vel.y) > abs(vel.x)){
                _isPanningVertically = YES;
                if (vel.y > 0) {
                    NSLog(@"DOWN!! at %f velocity", vel.y);
                } else {
                    NSLog(@"UP!! at %f velocity", vel.y);
                }
            } else {
                _isPanningVertically = NO;
                if (vel.x > 0) {
                    NSLog(@"RIGHT!! at %f velocity", vel.x);
                } else {
                    NSLog(@"LEFT!! at %f velocity", vel.x);
                }
            }
            self.touchXPosition = [pan locationInView:self.view].x;
            break;
        case UIGestureRecognizerStateChanged:
            //when you're panning vertically
                //the chnages in y position should translate to a chnage in the scale of all the cards
                //the changes in x position should translate to the centers of the all the cards shifting horizontally
            
            //when you're panning horizontally
                //the changes in x position should translate to the centers of the all the cards shifting horizontally
            
            _newX = [pan locationInView:self.view].x;
            _difference = _newX - _touchXPosition;
            [self moveAllNodesHorizontallyByDifference];
            _touchXPosition = _newX;
            break;
        case UIGestureRecognizerStateEnded:
            //when you were panning vertically,
                //if isFullscreen is YES then change it to NO and animate back to the small screen
                //if isFullscreen is NO then change it to YES and animate the card you touched on the initial pan to be the full screen view
            
            
            //when you were panning horizontally, add a decay animation to scroll and make sure to watch out for the edges
            if (((ASDisplayNode *)self.imageNodes[0]).frame.origin.x > 1) {
                [self animateViewsBackToStartingPosition];
            } else if (((ASDisplayNode *)self.imageNodes[self.imageNodes.count-1]).frame.origin.x < 130) {
                [self animateViewsBackToEndingPosition];
            } else {
                [self addDecayAnimationToAllSubviewsWithVelocity:[pan velocityInView:self.view].x];
            }
            break;
        default:
            break;
    }
}

- (void)pop_animationDidApply:(POPAnimation *)anim;
{
    if (((ASDisplayNode *)self.imageNodes[0]).frame.origin.x > 50) {
        POPAnimation *lastDecay = [((ASDisplayNode *)self.imageNodes.lastObject).view pop_animationForKey:@"lastNodeScroll"];
        
        if ([anim isEqual:lastDecay]) {
            [self removeAnimationsFromNodes];
            [self animateViewsBackToStartingPosition];
        }
    }
    if (((ASDisplayNode *)self.imageNodes[self.imageNodes.count-1]).frame.origin.x < 130) {
        POPAnimation *lastDecay = [((ASDisplayNode *)self.imageNodes.lastObject).view pop_animationForKey:@"lastNodeScroll"];
        
        if ([anim isEqual:lastDecay]) {
            [self removeAnimationsFromNodes];
            [self animateViewsBackToEndingPosition];
        }
    }
}

- (void)animateViewsBackToEndingPosition;
{
    for (ASDisplayNode *node in self.imageNodes) {
        NSUInteger i = [self.imageNodes indexOfObject:node];
    
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewCenter];
        anim.fromValue = [NSValue valueWithCGPoint:node.view.center];
        anim.toValue = self.finalCenters[i];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
        [node.view pop_addAnimation:anim forKey:nil];
    }
}

- (void)animateViewsBackToStartingPosition;
{
    for (ASDisplayNode *node in self.imageNodes) {
        NSUInteger i = [self.imageNodes indexOfObject:node];
        
        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewCenter];
        anim.fromValue = [NSValue valueWithCGPoint:node.view.center];
        anim.toValue = self.initialCenters[i];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [node.view pop_addAnimation:anim forKey:nil];
    }
}

@end


