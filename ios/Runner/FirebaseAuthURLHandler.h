#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FirebaseAuthURLHandler : NSObject
+ (BOOL)handleURL:(NSURL *)url;
+ (BOOL)handleNotification:(NSDictionary *)userInfo;
@end

NS_ASSUME_NONNULL_END
