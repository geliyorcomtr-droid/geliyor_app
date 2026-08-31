#import "FirebaseAuthURLHandler.h"

@implementation FirebaseAuthURLHandler

+ (BOOL)handleURL:(NSURL *)url {
  Class authClass = NSClassFromString(@"FIRAuth");
  if (authClass == nil) {
    return NO;
  }
  SEL authSelector = NSSelectorFromString(@"auth");
  if (![authClass respondsToSelector:authSelector]) {
    return NO;
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  id auth = [authClass performSelector:authSelector];
#pragma clang diagnostic pop
  SEL handleSelector = NSSelectorFromString(@"canHandleURL:");
  if (auth == nil || ![auth respondsToSelector:handleSelector]) {
    return NO;
  }
  NSMethodSignature *signature = [auth methodSignatureForSelector:handleSelector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setSelector:handleSelector];
  [invocation setTarget:auth];
  NSURL *argument = url;
  [invocation setArgument:&argument atIndex:2];
  [invocation invoke];
  BOOL handled = NO;
  [invocation getReturnValue:&handled];
  return handled;
}

+ (BOOL)handleNotification:(NSDictionary *)userInfo {
  Class authClass = NSClassFromString(@"FIRAuth");
  if (authClass == nil) {
    return NO;
  }
  SEL authSelector = NSSelectorFromString(@"auth");
  if (![authClass respondsToSelector:authSelector]) {
    return NO;
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  id auth = [authClass performSelector:authSelector];
#pragma clang diagnostic pop
  SEL handleSelector = NSSelectorFromString(@"canHandleNotification:");
  if (auth == nil || ![auth respondsToSelector:handleSelector]) {
    return NO;
  }
  NSMethodSignature *signature = [auth methodSignatureForSelector:handleSelector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  [invocation setSelector:handleSelector];
  [invocation setTarget:auth];
  NSDictionary *argument = userInfo;
  [invocation setArgument:&argument atIndex:2];
  [invocation invoke];
  BOOL handled = NO;
  [invocation getReturnValue:&handled];
  return handled;
}

@end
