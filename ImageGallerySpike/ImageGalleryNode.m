
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
@property (nonatomic) CGPoint previousTouchLocation;

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

@property (nonatomic) ASNetworkImageNode *hiddenNode;
@property (nonatomic) ASNetworkImageNode *lastNodeTouched;
@property (nonatomic) CGRect lastNodeTouchedFrame;
@property (nonatomic) CGSize lastNodeTouchedSize;
@property (nonatomic) CGPoint lastNodeTouchedPosition;

@property (nonatomic) ASDisplayNode *darkBackground;

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
 
    -- add pinching to resize image and rotate at any given time
 
    -- right now the image you see that the small one animates to is zoomed in further than the full screen image that is shown when it transfers
       to the fullscreen view.  To fix that I'll try a few things.  
        OPTION 1:  Start each image at teh full size then scale down so maybe it will have the same focus when scaled back up.
        OPTION 2: If that doesn't work, make the image node's size the correct proportions from the beginning.  Then make it a subview of 
                  some other view that is sized to the correct size in the small gallery, that way the image's focus shouldn't be affected
 
    -- Right now the fullscreen gallery is re-downloading all the images from the same URL's.  That's dumb, just pass along all the images upon it's creation,
       then implement the network image node delegate method for when images load in this class, and when each one is loaded update the image that is in the 
       fullscreen gallery.  
 
    -- Wait, maybe just make a datasource method for the Full screen image gallery node called image at index .... wait no, that shouldn't work because then
       how would it update?  First idea is better.  The full screen gallery should just have ASImageNodes not network image nodes.
 
    -- Eventually it needs to let you swipe left and right in fullscreen mode.  When this happens this class should change which image is hidden and
       shift all the nodes to the left or right by one imagenodes width
 
*/

#pragma mark View Drawing

+ (void)drawRect:(CGRect)bounds
  withParameters:(id<NSObject>)parameters
     isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock
   isRasterizing:(BOOL)isRasterizing
{
    if (!isRasterizing) {
        [[UIColor whiteColor] set];
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

        imageNode.backgroundColor = [UIColor lightGrayColor];
        imageNode.URL = [self.dataSource imageGallery:self urlForImageAtIndex:i];
        self.imageUrls[i] = [self.dataSource imageGallery:self urlForImageAtIndex:i];
        
        imageNode.frame = CGRectMake(((i * imageNodeWidth) + (i * 4)), 0, imageNodeWidth, imageNodeHeight);
        imageNode.cornerRadius = 4;
        imageNode.clipsToBounds = YES;
        imageNode.view.userInteractionEnabled = YES;
        imageNode.contentMode = UIViewContentModeScaleAspectFill;
        imageNode.defaultImage = [UIImage imageNamed:@"cat"];
        imageNode.cropEnabled = NO;

        [imageNode addTarget:self action:@selector(imageTouchedDown:) forControlEvents:ASControlNodeEventTouchDown];
        [imageNode addTarget:self action:@selector(imageTouchedUpInside:) forControlEvents:ASControlNodeEventTouchUpInside];
        
        self.initialCenters[i] = [NSValue valueWithCGPoint:imageNode.view.center];
        self.imageNodes[i] = imageNode;
        [self addSubnode:imageNode];
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
    }
    
    [self.view bringSubviewToFront:imageNode.view];

    self.lastNodeTouched         = imageNode;
    self.lastNodeTouchedFrame    = imageNode.frame;
    self.lastNodeTouchedSize     = imageNode.frame.size;
    self.lastNodeTouchedPosition = imageNode.position;
}

- (void)imageTouchedUpInside:(ASNetworkImageNode *)imageNode;
{
    [self animateIntoFullScreenMode];
}

- (void)animateIntoFullScreenMode;
{
    NSLog(@"\n\n\nThe image's width is animating from %f and height is animating from %f\n\n\n", self.lastNodeTouchedFrame.size.width, self.lastNodeTouchedFrame.size.height);
    
    NSLog(@"\n\n\nThe image's width is animating to %f and height is animating to %f\n\n\n", UIScreen.mainScreen.bounds.size.width, [self proportionateHeightForImage:_lastNodeTouched.image]);

    
    //add full screen view as subview of our view
    //use handy conversion to get it to cover the screen
    //animate a fade of it's darkness from 0 to 1
    //remove it from the view when its done

    [self.view bringSubviewToFront:self.darkBackground.view];
    [self.view bringSubviewToFront:self.lastNodeTouched.view];
    
    CGPoint centerOfScreen = CGPointMake(UIScreen.mainScreen.bounds.size.width/2, UIScreen.mainScreen.bounds.size.height/2);
    CGPoint newPosition = [self.view.superview convertPoint:centerOfScreen toView:self.view];

    POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerPosition];
    anim.fromValue = [NSValue valueWithCGPoint:self.lastNodeTouched.position];
    anim.toValue = [NSValue valueWithCGPoint: newPosition];
    anim.springBounciness = 5;
    anim.springSpeed = 20;
    
    POPSpringAnimation *sizeAnim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerSize];
    sizeAnim.toValue = [NSValue valueWithCGSize:CGSizeMake(UIScreen.mainScreen.bounds.size.width, [self proportionateHeightForImage:_lastNodeTouched.image])];
    sizeAnim.springBounciness = 5;
    sizeAnim.springSpeed = 20;
    
    POPBasicAnimation *cornerAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerCornerRadius];
    cornerAnim.toValue = @(0);
    
    void (^completion)(POPAnimation *anim, BOOL completed) = ^(POPAnimation *anim, BOOL completed){
        
        
        
        if (completed) {
            NSInteger index = [[self imageNodes] indexOfObject:self.lastNodeTouched];
            [self presentFullScreenImageGalleryStartingAtIndex:index];
            
            self.lastNodeTouched.cornerRadius = 4;
            self.lastNodeTouched.frame = self.lastNodeTouchedFrame;
            self.hiddenNode = self.lastNodeTouched;
            self.hiddenNode.hidden = YES;
        }
    };
    
    POPBasicAnimation *alphaAnim = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
    alphaAnim.fromValue = @(0.0);
    alphaAnim.toValue = @(1.0);
    alphaAnim.completionBlock = ^(POPAnimation *anim, BOOL completed) {
        self.darkBackground.alpha = 0.0;
    };
    
    anim.completionBlock = completion;
    sizeAnim.completionBlock = completion;
    cornerAnim.completionBlock = completion;
    
    [_darkBackground pop_addAnimation:alphaAnim forKey:nil];
    [self.lastNodeTouched pop_addAnimation:sizeAnim forKey:nil];
    [self.lastNodeTouched pop_addAnimation:anim forKey:nil];
    [self.lastNodeTouched pop_addAnimation:cornerAnim forKey:nil];
}

- (void)presentFullScreenImageGalleryStartingAtIndex:(NSInteger)index;
{
    self.fullScreenImageGalleryNode.sizeToAnimateBackTo     = self.lastNodeTouchedSize;
    self.fullScreenImageGalleryNode.positionToAnimateBackTo =  [self.view convertPoint:self.lastNodeTouchedPosition toView:self.view.superview];;
    
    [self.fullScreenImageGalleryNode showAtIndex:index];
}

- (void)setupInitialState
{
    self.imageUrls = @[].mutableCopy;
    self.imageNodes = @[].mutableCopy;
    self.initialCenters = @[].mutableCopy;
    self.finalCenters = @[].mutableCopy;
    _fullScreenFrame = CGRectMake(0, 0, self.view.superview.bounds.size.width, self.view.superview.bounds.size.height);
    self.backgroundColor = [UIColor darkGrayColor];
    _initialFrame = self.frame;
    self.clipsToBounds = NO;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGRect fullscreenFrame = [self.view.superview convertRect:CGRectMake(0, 0, screenSize.width, screenSize.height) toView:self.view];

    _darkBackground = [[ASDisplayNode alloc] init];
    _darkBackground.backgroundColor = [UIColor blackColor];
    _darkBackground.frame = fullscreenFrame;
    _darkBackground.alpha = 0.0;
    
    [self addSubnode:_darkBackground];
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
                _previousTouchLocation = [pan locationInView:self.view];
                _oldTouch = [pan locationInView:self.view];
                
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
                
                CGFloat xDifference = [pan locationInView:self.view].x - _previousTouchLocation.x;
                CGFloat yDifference = [pan locationInView:self.view].y - _previousTouchLocation.y;
                
                CGPoint newImageCenter = CGPointMake(self.lastNodeTouched.view.center.x + xDifference, self.lastNodeTouched.view.center.y + yDifference);
                
                self.lastNodeTouched.view.center = newImageCenter;
                _previousTouchLocation = [pan locationInView:self.view];
            } else {
                _newX = [pan locationInView:self.view].x;
                _difference = _newX - _touchXPosition;
                [self moveAllNodesHorizontallyByDifference];
                _touchXPosition = _newX;
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (_isPanningVertically) {
                if (!_isFullScreen) {
                    [self animateIntoFullScreenMode];
                }
            } else {
            
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
            }
            
            _isPanningVertically = NO;

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
    //change which small image is hidden
    //
    NSLog(@"The fullscreen gallery moved forward so move the small one to the right\n then update where the image should animate back to when its all done");
}

- (void)fullScreenImageGalleryDidRetreat;
{
    NSLog(@"The fullscreen gallery moved backward so move the small one to the left\n then update where the image should animate back to when its all done");
}

- (void)unhideHiddenView;
{
    self.hiddenNode.hidden = NO;
}

#pragma mark Utilities

- (CGFloat)proportionateHeightForImage:(UIImage *)image;
{
    NSLog(@"\n Image: %@", image);
    
    return (UIScreen.mainScreen.bounds.size.width * image.size.height)/image.size.width;
}

@end
