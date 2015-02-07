
#import "FullScreenImageGalleryNode.h"
#import "ASDisplayNode.h"
#import <pop/POP.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit.h>

@interface FullScreenImageGalleryNode ()
@property (nonatomic) NSArray *imageUrls;
@property (nonatomic) NSMutableArray *imageNodes;
@end

@implementation FullScreenImageGalleryNode

- (instancetype)initWithImageUrls:(NSArray *)imageUrls;
{
    if (!(self = [super init])) { return nil; }
    
    NSInteger i = 0;
    for (NSURL *url in self.imageUrls) {
        ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
        node.URL = url;
        self.imageNodes[i] = node;
        i++;
    }
    
    // right now i'll just recreate all the image nodes cause i'm not sure how to make them change from
    // being aspect fill to aspect fit
    self.imageUrls = imageUrls;
    
    return self;
}

- (void)hide;
{
    
}

- (void)showAtIndex:(NSInteger)index;
{
    self.hidden = NO;
    self.backgroundColor = [UIColor blackColor];
}

@end
