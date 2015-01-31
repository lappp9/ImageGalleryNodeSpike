

#import "ASDisplayNode.h"
#import <pop/POP.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit.h>

@protocol ImageGalleryDatasource;
@protocol ImageGalleryDelegate;

@interface ImageGalleryNode : ASDisplayNode <_ASDisplayLayerDelegate, POPAnimationDelegate>

@property (weak) id <ImageGalleryDatasource> dataSource;
@property (weak) id <ImageGalleryDelegate> delegate;

@end

@protocol ImageGalleryDatasource <NSObject>

- (NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
- (NSURL *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;

@end

@protocol ImageGalleryDelegate <NSObject>

- (BOOL)imageGalleryShouldDisplayPositions;

@optional

//defaults to 1/3 the screen size
- (NSInteger)heightForImageGallery;

@end