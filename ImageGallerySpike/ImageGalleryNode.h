

#import "ASDisplayNode.h"
#import <pop/POP.h>

@protocol ImageGalleryDatasource;
@protocol ImageGalleryDelegate;

@interface ImageGalleryNode : ASDisplayNode <POPAnimationDelegate>

@property (weak) id <ImageGalleryDatasource> dataSource;
@property (weak) id <ImageGalleryDelegate> delegate;

@end

@protocol ImageGalleryDatasource <NSObject>

- (NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
- (NSString *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;

@end

@protocol ImageGalleryDelegate <NSObject>

@optional

//defaults to 1/3 the screen size
- (NSInteger)heightForImageGallery;

@end