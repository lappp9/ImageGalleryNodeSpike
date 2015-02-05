

#import "ASDisplayNode.h"
#import <pop/POP.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit.h>

@protocol ImageGalleryDatasource;
@protocol ImageGalleryDelegate;

typedef NS_ENUM(NSInteger, SwipeGestureDirection) {
    SwipeGestureDirectionUp,
    SwipeGestureDirectionDown,
    SwipeGestureDirectionLeft,
    SwipeGestureDirectionRight
};

@interface ImageGalleryNode : ASDisplayNode <_ASDisplayLayerDelegate, POPAnimationDelegate>

@property (weak) id <ImageGalleryDatasource> dataSource;
@property (weak) id <ImageGalleryDelegate> delegate;

@end

@protocol ImageGalleryDatasource <NSObject>

- (NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
- (NSURL *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;
- (CGFloat)widthForImages;

@end

@protocol ImageGalleryDelegate <NSObject>

- (BOOL)imageGalleryShouldDisplayPositions;

@end