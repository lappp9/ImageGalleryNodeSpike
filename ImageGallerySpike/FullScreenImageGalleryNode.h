
#import "ASDisplayNode.h"

@protocol FullScreenImageGalleryDelegate;

@interface FullScreenImageGalleryNode : ASDisplayNode

@property (weak) id <FullScreenImageGalleryDelegate> delegate;

- (instancetype)initWithImageUrls:(NSArray *)imageUrls;
- (void)hide;
- (void)showAtIndex;

@end

@protocol FullScreenImageGalleryDelegate <NSObject>

- (void)fullScreenImageGalleryDidAdvance;
- (void)fullScreenImageGalleryDidRetreat;

@end