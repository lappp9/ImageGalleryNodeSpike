
#import "ASDisplayNode.h"
#import <pop/POP.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit.h>

@protocol FullScreenImageGalleryDelegate;

@interface FullScreenImageGalleryNode : ASDisplayNode

@property (weak) id <FullScreenImageGalleryDelegate> delegate;

- (instancetype)initWithImageUrls:(NSArray *)imageUrls;
- (void)hide;
- (void)showAtIndex:(NSInteger)index;

@end

@protocol FullScreenImageGalleryDelegate <NSObject>

- (void)fullScreenImageGalleryDidAdvance;
- (void)fullScreenImageGalleryDidRetreat;

@end