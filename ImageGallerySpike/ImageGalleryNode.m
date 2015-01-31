
#import "ImageGalleryNode.h"

@interface ImageGalleryNode ()<_ASDisplayLayerDelegate, POPAnimationDelegate>
@property (nonatomic) NSMutableArray *imageNodes;
@property (nonatomic) CGFloat touchXPosition;
@property (nonatomic) CGFloat newX;
@property (nonatomic) CGFloat difference;
@property (nonatomic) NSMutableArray *initialCenters;
@property (nonatomic) NSMutableArray *finalCenters;
@property (nonatomic) CGFloat kSubViewWidth;
@end

@implementation ImageGalleryNode



/*
 
 //TODO:
 1) allow asynchronous images
 
 2) allow swiping up to transfer to full screen
 
 */

//-drawParametersForAsyncLayer:
// this should return a dictionary that configures this view
// just get teh config stuff from the datasource and then pass it along! i think...
//right now the time at which to stop the scrolling is hardcoded to like > 50 or < 110
//in the future do 50 and the windows width - the image's width - 20 or something


// move drawing code into drawRect and move all the gesture stuff into didlayoutsubviews or something

#pragma mark View Drawing

+ (void)drawRect:(CGRect)bounds
  withParameters:(id<NSObject>)parameters
     isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock
   isRasterizing:(BOOL)isRasterizing
{
    //FOURTH
    if (!isRasterizing) {
        [[UIColor blackColor] set];
        UIRectFill(bounds);
    }
}

- (void)layout;
{
    [super layout];
    //SECOND
    //remove all subnodes so theres no duplication, i assume i should do this stuff somewhere else
    
    if (self.view.subviews.count != 0) {
        return;
    }
    
    self.imageNodes = @[].mutableCopy;
    self.initialCenters = @[].mutableCopy;
    self.finalCenters = @[].mutableCopy;
    _kSubViewWidth = self.bounds.size.width/2.5;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(galleryDidPan:)];
    
    [self.view addGestureRecognizer:pan];
    
    NSInteger numberOfImages = [self.dataSource numberOfImagesInImageGallery:self];
    
    for (int i = 0; i < numberOfImages; i++) {
//        ASNetworkImageNode *imageNode = [[ASNetworkImageNode alloc] init];
//        imageNode.backgroundColor = [UIColor lightGrayColor];
//        imageNode.URL = [NSURL URLWithString:[self.dataSource imageGallery:self urlForImageAtIndex:i]];
//        self.imageNodes[i] = imageNode;
        
        ASDisplayNode *node = [[ASDisplayNode alloc] init];
        node.frame = CGRectMake(self.bounds.origin.x + (50 * i) + 10,
                                self.bounds.origin.y,
                                self.bounds.size.width - 100,
                                500);
        CGFloat imageNodeWidth = self.bounds.size.width/2.5;
        CGFloat imageNodeHeight = self.bounds.size.height;
        
        CGFloat rand1 = arc4random_uniform(255);
        CGFloat rand2 = arc4random_uniform(255);
        CGFloat rand3 = arc4random_uniform(255);
        
        UIColor *randomColor = [UIColor colorWithRed:rand1/255 green:rand2/255 blue:rand3/255 alpha:1.0];
        
        node.frame = CGRectMake(((i * imageNodeWidth) + (i * 4)), 0, imageNodeWidth, imageNodeHeight);
        node.backgroundColor = randomColor;
        node.cornerRadius = 4;
        
        UILabel *number = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 51, 51)];
        number.text = [NSString stringWithFormat:@"%d", i+1];
        number.backgroundColor = [UIColor whiteColor];
        number.textAlignment = NSTextAlignmentCenter;
        number.textColor = [UIColor lightGrayColor];
        number.layer.borderWidth = 1;
        number.layer.borderColor = [UIColor darkGrayColor].CGColor;
        
        [node.view addSubview:number];
        
        self.imageNodes[i] = node;
        self.initialCenters[i] = [NSValue valueWithCGPoint:node.view.center];
        [self.view addSubview:node.view];
    }
    
    [self calcualteFinalCenters];
}

- (void)didLoad;
{
    [super didLoad];
    
    //FIRST
    
}

- (NSObject *)drawParametersForAsyncLayer:(_ASDisplayLayer *)layer;
{
    //THIRD
    NSMutableDictionary *dict = @{}.mutableCopy;
    
    return dict;
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

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
    [self removeAnimationsFromNodes];
}

- (void)galleryDidPan:(UIPanGestureRecognizer *)pan;
{
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            self.touchXPosition = [pan locationInView:self.view].x;
            break;
        case UIGestureRecognizerStateChanged:
            _newX = [pan locationInView:self.view].x;
            _difference = _newX - _touchXPosition;
            
            [self moveAllNodesHorizontallyByDifference];
            
            _touchXPosition = _newX;
            break;
        case UIGestureRecognizerStateEnded:
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

- (void)calcualteFinalCenters;
{
    for (int i = 0; i <[self.dataSource numberOfImagesInImageGallery:self]; i++) {
        
        CGFloat distanceFromRightSide = 0;
        if (i == 0) {
            distanceFromRightSide = self.view.bounds.size.width - (self.kSubViewWidth/2);
        } else {
            distanceFromRightSide = self.view.bounds.size.width - (self.kSubViewWidth/2);
            distanceFromRightSide -= ((i * _kSubViewWidth) + (4 * i));
        }

        CGPoint finalCenter = CGPointMake(distanceFromRightSide, 120);

        [self.finalCenters addObject:[NSValue valueWithCGPoint:finalCenter]];
        
    }
    
    self.finalCenters = [[self.finalCenters reverseObjectEnumerator] allObjects].mutableCopy;
}

//- (void)moveAllImageNodesHorizontallyByDifference;
//{
//    for (ASNetworkImageNode *imageNode in self.imageNodes) {
//        CGPoint newCenter = CGPointMake((imageNode.view.center.x + _difference), imageNode.view.center.y);
//        imageNode.view.center = newCenter;
//    }
//}
//
//- (void)removeAnimations;
//{
//    for (ASNetworkImageNode *imageNode in self.imageNodes) {
//        [imageNode pop_removeAllAnimations];
//    }
//}

@end


