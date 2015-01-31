
#import "RainbowNode.h"
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

@interface RainbowNode ()<_ASDisplayLayerDelegate>

@end

@implementation RainbowNode

+ (void)drawRect:(CGRect)bounds
  withParameters:(id<NSObject>)parameters
     isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock
   isRasterizing:(BOOL)isRasterizing
{
    // clear the backing store, but only if we're not rasterising into another layer
    if (!isRasterizing) {
        [[UIColor whiteColor] set];
        UIRectFill(bounds);
    }
    
    // UIColor sadly lacks +indigoColor and +violetColor methods
    NSArray *colors = @[ [UIColor redColor],
                         [UIColor orangeColor],
                         [UIColor yellowColor],
                         [UIColor greenColor],
                         [UIColor blueColor],
                         [UIColor colorWithRed:75/255.0 green:0/255.0 blue:130/255.0 alpha:1.0],
                         [UIColor colorWithRed:238.0/255.0 green:130.0/255.0 blue:238.0/255.0 alpha:1.0]
                          ];
    
    
    NSMutableDictionary *dic = (NSMutableDictionary *)parameters;
    BOOL isVeritcal = [[dic objectForKey:@"vertical"] boolValue];
    if (isVeritcal) {
        CGFloat stripeWidth = roundf(bounds.size.width / (float)colors.count);
        
        // draw the stripes
        for (UIColor *color in colors) {
            CGRect stripe = CGRectZero;
            CGRectDivide(bounds, &stripe, &bounds, stripeWidth, CGRectMinXEdge);
            [color set];
            UIRectFill(stripe);
        }
    }else
    {
        CGFloat stripeHeight = roundf(bounds.size.height / (float)colors.count);
        
        // draw the stripes
        for (UIColor *color in colors) {
            CGRect stripe = CGRectZero;
            CGRectDivide(bounds, &stripe, &bounds, stripeHeight, CGRectMinYEdge);
            [color set];
            UIRectFill(stripe);
        }
    }
}

- (NSObject *)drawParametersForAsyncLayer:(_ASDisplayLayer *)layer
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    [dic setObject:[NSNumber numberWithBool:self.vertical] forKey:@"vertical"];
    
    return dic;
}

/**
 @summary Delegate override for willDisplay
 */
- (void)willDisplayAsyncLayer:(_ASDisplayLayer *)layer
{
    NSLog(@"---------willDisplay----------");
}

/**
 @summary Delegate override for didDisplay
 */
- (void)didDisplayAsyncLayer:(_ASDisplayLayer *)layer
{
    NSLog(@"----------didDisplayer------------");
}

@end