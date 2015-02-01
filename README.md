# ImageGalleryNodeSpike
Example project in the process of creating an ImageGalleryNode using Facebook's AsyncDisplayKit and Pop frameworks.  Image gallery should be a generalized version of their horizontal story view in Paper.

There are three datasource methods that allow you to configure the contents of the image gallery.
- - (NSURL *)imageGallery:(ImageGalleryNode *)imageGallery urlForImageAtIndex:(NSInteger)index;
- - (NSInteger)numberOfImagesInImageGallery:(ImageGalleryNode *)imageGallery;
- - (CGFloat)widthForImages;

And there are two delegate methods.
- - (BOOL)imageGalleryShouldDisplayPositions;
- - (BOOL)prefersStatusBarHidden;



