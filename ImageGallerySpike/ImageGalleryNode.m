
#import "ImageGalleryNode.h"

@interface ImageGalleryNode ()<POPAnimationDelegate, UIGestureRecognizerDelegate>
@property (nonatomic) NSMutableArray *imageNodes;
@property (nonatomic) NSMutableArray *imageUrls;

@property (nonatomic) FullScreenImageGalleryNode *fullScreenImageGalleryNode;

@property (nonatomic) CGFloat touchXPosition;
@property (nonatomic) CGFloat touchYPosition;
@property (nonatomic) CGFloat newX;
@property (nonatomic) CGFloat newY;
@property (nonatomic) CGPoint oldTouch;
@property (nonatomic) CGFloat difference;

//when hitting an edge, you can just animte all the views back to their initial or ending places
@property (nonatomic) NSMutableArray *initialCenters;

@property (nonatomic) NSMutableArray *finalCenters;

//tracking the state of the subviews
@property (nonatomic) BOOL isPanningVertically;
@property (nonatomic) BOOL isFullScreen;
@property (nonatomic) CGRect fullScreenFrame;
@property (nonatomic) ASDisplayNode *touchedNode;
@property (nonatomic) SwipeGestureDirection direction;

//keep this around to go back to small view
@property (nonatomic) CGRect initialFrame;

//maybe i should be keeping track of the frame of every subview in small mode
//then in large mode i can update these views in the back ground based on you swiping around
//that way when you go back into small mode i can just animate all these subviews to the appropriate place

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
    
    -- tapping should transfer from small to large and back again
 
    -- since this isn't necessarily at the bottom of the screen, panning vertically in any direction should make the whole gallery
       scale up and then down when the pan continues in the other direction
 
    -- add pinching to resize image and rotate at any given time
 
 2) Make the fullscreen view a different view controller that gets navigated to and gets passed the same objects as this one via the same delegate methods...
    -- not sure how smart that is but whatevs
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

- (void)layout;
{
    [super layout];

    if (self.view.subviews.count != 0) {
        return;
    }
    
    [self setupInitialState];

    NSInteger numberOfImages = [self.dataSource numberOfImagesInImageGallery:self];
    
    for (int i = 0; i < numberOfImages; i++) {
        CGFloat imageNodeWidth = [self.dataSource widthForImages];
        CGFloat imageNodeHeight = self.bounds.size.height;
        
        ASNetworkImageNode *imageNode = [[ASNetworkImageNode alloc] init];
        self.imageNodes[i] = imageNode;

        imageNode.backgroundColor = [UIColor lightGrayColor];
        imageNode.URL = [self.dataSource imageGallery:self urlForImageAtIndex:i];
        self.imageUrls[i] = [self.dataSource imageGallery:self urlForImageAtIndex:i];
        imageNode.frame = CGRectMake(((i * imageNodeWidth) + (i * 4)), 0, imageNodeWidth, imageNodeHeight);
        imageNode.cornerRadius = 4;
        imageNode.clipsToBounds = YES;
        imageNode.view.userInteractionEnabled = YES;
        
        [imageNode addTarget:self action:@selector(imageTouchedDown:) forControlEvents:ASControlNodeEventTouchDown];
        [imageNode addTarget:self action:@selector(imageTouchedUpInside:) forControlEvents:ASControlNodeEventTouchUpInside];
        
        self.initialCenters[i] = [NSValue valueWithCGPoint:imageNode.view.center];
        [self.view addSubview:imageNode.view];
    }
    
    if ([self.delegate imageGalleryShouldAllowFullScreenMode]) {
        self.fullScreenImageGalleryNode = [[FullScreenImageGalleryNode alloc] initWithImageUrls:self.imageUrls];
        self.fullScreenImageGalleryNode.delegate = self;
        self.fullScreenImageGalleryNode.frame = CGRectMake(0, 0, self.view.superview.frame.size.width, self.view.superview.frame.size.height);
        self.fullScreenImageGalleryNode.backgroundColor = [UIColor blackColor];
        self.fullScreenImageGalleryNode.hidden = YES;
        [self.view.superview addSubview:self.fullScreenImageGalleryNode.view];
    }

    if ([self.delegate imageGalleryShouldDisplayPositions]) {
        [self addPositionLabelsToImageNodes];
    }
    
    [self calculateFinalCenters];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(galleryDidPan:)];
    [self.view addGestureRecognizer:pan];
}

- (void)imageTouchedDown:(ASNetworkImageNode *)imageNode;
{
    if ([[imageNode.view pop_animationKeys] containsObject:@"scroll"] || [[imageNode.view pop_animationKeys] containsObject:@"firstNodeScroll"] || [[imageNode.view pop_animationKeys] containsObject:@"lastNodeScroll"]) {
        [self removeAnimationsFromNodes];
        NSLog(@"touched down on image");
    }
}

- (void)imageTouchedUpInside:(ASNetworkImageNode *)imageNode;
{
//    [self animateGalleryBackToStartOrEndingIfNecessary];
    
    NSInteger index = [self.imageNodes indexOfObject:imageNode];
    [self presentFullScreenImageGalleryStartingAtIndex:index];
}

- (void)presentFullScreenImageGalleryStartingAtIndex:(NSInteger)index;
{
    [self.fullScreenImageGalleryNode showAtIndex:index];
}

- (void)goIntoFullScreenModeFocusedOnView:(UIView *)imageView;
{
    _isFullScreen = YES;
    
    POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    spring.fromValue = [NSValue valueWithCGRect:self.frame];
    spring.toValue = [NSValue valueWithCGRect:_fullScreenFrame];
    spring.springBounciness = 1;
    spring.springSpeed = 20;
    
    POPSpringAnimation *imageSpring = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    imageSpring.fromValue = [NSValue valueWithCGRect:imageView.frame];
    imageSpring.toValue = [NSValue valueWithCGRect:_fullScreenFrame];
    imageSpring.springBounciness = 1;
    imageSpring.springSpeed = 20;
    
    for (ASNetworkImageNode *node in self.imageNodes) {
        NSInteger i = [self.imageNodes indexOfObject:node];
        
        if ([node.view isEqual:imageView]) {
            NSLog(@"you tapped the %ld image", (long)i);
            node.URL = [self.dataSource imageGallery:self urlForImageAtIndex:i];
            //figure out how to change content mode to aspect fit and blow up
            [self.view bringSubviewToFront:node.view];
            //don't make this one disappear
        } else {
//            node.alpha = 0.0;
        }
    }
   
    [self pop_addAnimation:spring forKey:nil];
    [imageView pop_addAnimation:imageSpring forKey:nil];
}

- (void)setupInitialState
{
    self.imageNodes = @[].mutableCopy;
    self.initialCenters = @[].mutableCopy;
    self.finalCenters = @[].mutableCopy;
    _fullScreenFrame = CGRectMake(0, 0, self.view.superview.bounds.size.width, self.view.superview.bounds.size.height);
    self.backgroundColor = [UIColor darkGrayColor];
    _initialFrame = self.frame;
    self.clipsToBounds = NO;
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
        
        NSString *labelString = [NSString stringWithFormat:@"%lu of %ld", [self.imageNodes indexOfObject:imageNode]+1, self.imageNodes.count];
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

#pragma mark Touch Events and Moving the Gallery

- (void)removeAnimationsFromNodes;
{
    for (ASDisplayNode *node in self.imageNodes) {
        [node.view pop_removeAllAnimations];
    }
}

- (void)moveAllNodesHorizontallyByDifference;
{
    ASDisplayNode *firstNode = (ASDisplayNode *)self.imageNodes[0];
    ASDisplayNode *lastNode = (ASDisplayNode *)self.imageNodes.lastObject;
    CGFloat sweetSpotXValue = self.frame.size.width - lastNode.frame.size.width;
    
    if ( !(firstNode.frame.origin.x > 50 || lastNode.frame.origin.x < sweetSpotXValue) ) {
        for (ASDisplayNode *node in self.imageNodes) {
            CGPoint newCenter = CGPointMake((node.view.center.x + _difference), node.view.center.y);
            node.view.center = newCenter;
        }
    } else {
        for (ASDisplayNode *node in self.imageNodes) {
            CGPoint newCenter = CGPointMake((node.view.center.x + (_difference/2)), node.view.center.y);
            node.view.center = newCenter;
        }
    }
}

- (void)moveAllNodesyByDifferenceWithTouchLocation:(CGPoint)touch;
{
    //Whenever this is called i need to add some animations to chnage the scale and the
    
    //animate to the new center?
//    CGFloat xDifference = touch.x - _oldTouch.x;
//    CGFloat yDifference = touch.y - _oldTouch.y;
//
//    CGPoint newCenterForView = CGPointMake(self.view.center.x + xDifference, self.view.center.y + yDifference);
//    self.view.center = newCenterForView;
//    
//    _oldTouch = touch;
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
            [self removeAnimationsFromNodes];
            //set up the bool values for what direction this pan is going
            if (abs(vel.y) > abs(vel.x)){
                
                _isPanningVertically = YES;
                _oldTouch = [pan locationInView:self.view];
//                _touchXPosition = [pan locationInView:self.view].x;
//                _touchYPosition = [pan locationInView:self.view].y;
                
                if (vel.y > 0) {
                    self.direction = SwipeGestureDirectionDown;
                    NSLog(@"DOWN!! at %f velocity", vel.y);
                } else {
                    NSLog(@"UP!! at %f velocity", vel.y);
                    self.direction = SwipeGestureDirectionUp;
                }
            } else {
                _isPanningVertically = NO;
                if (vel.x > 0) {
                    NSLog(@"RIGHT!! at %f velocity", vel.x);
                    self.direction = SwipeGestureDirectionRight;

                } else {
                    NSLog(@"LEFT!! at %f velocity", vel.x);
                    self.direction = SwipeGestureDirectionLeft;
                }
            }
            self.touchXPosition = [pan locationInView:self.view].x;
            break;
        case UIGestureRecognizerStateChanged:
            if (_isPanningVertically) {
                NSLog(@"PANNING VERT!!");
                //when you're panning vertically
                //the chnages in y position should translate to a chnage in the scale of all the cards
                //the changes in x position should translate to the centers of the all the cards shifting horizontally
                
                //for now just make the whole gallery follow the pan
                
                [self moveAllNodesyByDifferenceWithTouchLocation: [pan locationInView:self.view]];
//                [self ]
            } else {
                //when you're panning horizontally
                //the changes in x position should translate to the centers of the all the cards shifting horizontally

                _newX = [pan locationInView:self.view].x;
                _difference = _newX - _touchXPosition;
                [self moveAllNodesHorizontallyByDifference];
                _touchXPosition = _newX;
            }

            break;
        case UIGestureRecognizerStateEnded:
            
            _isPanningVertically = NO;
            //when you were panning vertically,
                //if isFullscreen is YES then change it to NO and animate back to the small screen
                //if isFullscreen is NO then change it to YES and animate the card you touched on the initial pan to be the full screen view
            
            CGFloat rightSide = (self.frame.size.width - ((ASNetworkImageNode *)self.imageNodes[self.imageNodes.count-1]).frame.size.width);
            CGFloat lastX = ((ASDisplayNode *)self.imageNodes[self.imageNodes.count-1]).frame.origin.x;
        
//            NSLog(@"The last images X origin is %f", lastX);
            //when you were panning horizontally, add a decay animation to scroll and make sure to watch out for the edges
            if (((ASDisplayNode *)self.imageNodes[0]).frame.origin.x > 1) {
                [self animateViewsBackToStartingPosition];
            } else if (lastX >= 0 && lastX < rightSide + 1) {
//            } else if (((ASDisplayNode *)self.imageNodes[self.imageNodes.count-1]).frame.origin.x < 130) {
                
                // origin.x distance from the right side
                //if the last image's frame.origin.x is between 0 self.view.width - node.view.width
                [self animateViewsBackToEndingPosition];
            } else {
                [self addDecayAnimationToAllSubviewsWithVelocity:[pan velocityInView:self.view].x];
            }
            break;
        default:
            break;
    }
}

#pragma mark Pop Delegate Methods

- (void)animateGalleryBackToStartOrEndingIfNecessary
{
    CGPoint finalPoint = [((NSValue *)self.finalCenters.lastObject) CGPointValue];
    ASNetworkImageNode *finalNode = self.imageNodes.lastObject;
    CGFloat smallestXValue = finalPoint.x - (finalNode.frame.size.width/2);
    
    ASNetworkImageNode *firstNode = self.imageNodes.firstObject;
    
    if (finalNode.frame.origin.x < smallestXValue) {
        [self animateViewsBackToEndingPosition];
    }
    if (firstNode.frame.origin.x > 0) {
        [self animateViewsBackToStartingPosition];
    }
}

-(void)pop_animationDidReachToValue:(POPAnimation *)anim;
{
    [self animateGalleryBackToStartOrEndingIfNecessary];
}

- (void)pop_animationDidApply:(POPAnimation *)anim;
{
    ASDisplayNode *lastNode = (ASDisplayNode *)self.imageNodes.lastObject;
    CGFloat sweetSpotXValue = self.frame.size.width - lastNode.frame.size.width;
    
    if (((ASDisplayNode *)self.imageNodes[0]).frame.origin.x > 50) {
        POPAnimation *lastDecay = [((ASDisplayNode *)self.imageNodes.lastObject).view pop_animationForKey:@"lastNodeScroll"];
        
        if ([anim isEqual:lastDecay]) {
            [self removeAnimationsFromNodes];
            [self animateViewsBackToStartingPosition];
        }
    }
    if (((ASDisplayNode *)self.imageNodes.lastObject).frame.origin.x < sweetSpotXValue - 55) {
        POPAnimation *lastDecay = [((ASDisplayNode *)self.imageNodes.lastObject).view pop_animationForKey:@"lastNodeScroll"];
        
        if ([anim isEqual:lastDecay]) {
            [self removeAnimationsFromNodes];
            [self animateViewsBackToEndingPosition];
        }
    }
}

#pragma mark Animating gallery

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

#pragma mark Full Screen View Delegate Methods

- (void)fullScreenImageGalleryDidAdvance;
{
    NSLog(@"The fullscreen gallery moved forward so move the small one to the right\n then update where the image should animate back to when its all done");
}

- (void)fullScreenImageGalleryDidRetreat;
{
    NSLog(@"The fullscreen gallery moved backward so move the small one to the left\n then update where the image should animate back to when its all done");
}

@end


