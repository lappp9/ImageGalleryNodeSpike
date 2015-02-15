

#import "ASDisplayNode.h"
#import "FullScreenImageGalleryNode.h"
#import <pop/POP.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit.h>

@protocol ImageGalleryDatasource;
@protocol ImageGalleryDelegate;

@interface ImageGalleryNode : ASDisplayNode <POPAnimationDelegate, FullScreenImageGalleryDelegate, ASNetworkImageNodeDelegate>

@property (weak) id <ImageGalleryDatasource> dataSource;
@property (weak) id <ImageGalleryDelegate> delegate;
@property (nonatomic) CGSize imageNodeSize;

@end

@protocol ImageGalleryDatasource <NSObject>

- (NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
- (NSURL *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;
- (CGFloat)widthForImages;

@end

@protocol ImageGalleryDelegate <NSObject>

- (BOOL)imageGalleryShouldDisplayPositions;
- (BOOL)imageGalleryShouldAllowFullScreenMode;

@end