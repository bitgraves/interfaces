
#import "RSOSCListener.h"
#import "F53OSC.h"

@interface RSOSCListener () <F53OSCPacketDestination>

@property (nonatomic, strong) F53OSCServer *listener;

@end

@implementation RSOSCListener

- (instancetype)initWithPort:(UInt16)port
{
  if (self = [super init]) {
    _listener = [[F53OSCServer alloc] init];
    _listener.delegate = self;
    _listener.port = port;
  }
  return self;
}

- (BOOL)start
{
  if (![_listener startListening]) {
    return NO;
  }
  NSLog(@"OSC listening on port %u...", _listener.port);
  return YES;
}

- (void)stop
{
  [_listener stopListening];
}

#pragma mark - F53OSC delegate

- (void)takeMessage:(F53OSCMessage *)message
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self _parseMessage:message];
  });
}

#pragma mark - internal

- (void)_parseMessage:(F53OSCMessage *)message
{
  if (_delegate) {
    [_delegate oscListener:self didReceiveMessageWithAddress:message.addressParts arguments:message.arguments];
  }
}

@end
