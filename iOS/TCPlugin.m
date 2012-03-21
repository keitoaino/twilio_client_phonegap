//
//  TCPlugin.h
//  Twilio Client plugin for PhoneGap
//
//  Copyright 2012 Stevie Graham.
//

#import "TCPlugin.h"

@interface TCPlugin() {
    TCDevice     *_device;
    TCConnection *_connection;
    NSString     *_callback;
}

@property(nonatomic, strong) TCDevice     *device;
@property(nonatomic, strong) NSString     *callback;
@property(atomic, strong)    TCConnection *connection;

-(void)javascriptCallback:(NSString *)event;
-(void)javascriptCallback:(NSString *)event withArguments:(NSArray *)arguments;
-(void)javascriptErrorback:(NSError *)error;

@end

@implementation TCPlugin

@synthesize device     = _device;
@synthesize callback   = _callback;
@synthesize connection = _connection;

# pragma mark device delegate method
-(void)device:(TCDevice *)device didStopListeningForIncomingConnections:(NSError *)error {
    [self javascriptErrorback:error];
}

-(void)device:(TCDevice *)device didReceiveIncomingConnection:(TCConnection *)connection {
    [self javascriptCallback:@"onincoming"];
}

-(void)device:(TCDevice *)device didReceivePresenceUpdate:(TCPresenceEvent *)presenceEvent {
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:[presenceEvent name], @"from", [presenceEvent isAvailable], nil];
    [self javascriptCallback:@"onpresence" withArguments:[NSArray arrayWithObject:object]];
}

-(void)deviceDidStartListeningForIncomingConnections:(TCDevice *)device {
    // What to do here? The JS library doesn't have an event for this.
}

# pragma mark connection delegate methods
-(void)connection:(TCConnection*)connection didFailWithError:(NSError*)error {
    [self javascriptErrorback:error];
}

-(void)connectionDidStartConnecting:(TCConnection*)connection {
    self.connection = connection;
    // What to do here? The JS library doesn't have an event for connection negotiation.
}

-(void)connectionDidConnect:(TCConnection*)connection {
    self.connection = connection;
    [self javascriptCallback:@"onconnect"];
}

-(void)connectionDidDisconnect:(TCConnection*)connection {
    self.connection = connection;
    [self javascriptCallback:@"ondisconnect"];
}

# pragma mark javascript mapper methods

-(void)deviceSetup:(NSMutableArray *)arguments withDict:(NSMutableDictionary*)options {
    self.callback = [arguments pop];
    self.device = [[TCDevice alloc] initWithCapabilityToken:[arguments pop] delegate:self];
    
    // Disable sounds. was getting EXC_BAD_ACCESS
    self.device.incomingSoundEnabled   = NO;
    self.device.outgoingSoundEnabled   = NO;
    self.device.disconnectSoundEnabled = NO;
    
    [self javascriptCallback:@"onready"];
}

-(void)connect:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {
    [self.device connect:options delegate:self];
}

-(void)disconnectAll:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options {
    [self.device disconnectAll];
}

-(void)javascriptCallback:(NSString *)event withArguments:(NSArray *)arguments {
    NSDictionary *options   = [NSDictionary dictionaryWithObjectsAndKeys:event, @"callback", arguments, @"arguments", nil];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:options];
    result.keepCallback     = [NSNumber numberWithBool:YES];
    
    [self performSelectorOnMainThread:@selector(writeJavascript:) withObject:[result toSuccessCallbackString:self.callback] waitUntilDone:NO];
}

-(void)javascriptCallback:(NSString *)event {
    [self javascriptCallback:event withArguments:nil];
}

-(void)javascriptErrorback:(NSError *)error {
    NSDictionary *object    = [NSDictionary dictionaryWithObjectsAndKeys:[error localizedDescription], @"message", nil];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:object];
    result.keepCallback     = [NSNumber numberWithBool:YES];
    
    [self performSelectorOnMainThread:@selector(writeJavascript:) withObject:[result toErrorCallbackString:self.callback] waitUntilDone:NO];
}

@end