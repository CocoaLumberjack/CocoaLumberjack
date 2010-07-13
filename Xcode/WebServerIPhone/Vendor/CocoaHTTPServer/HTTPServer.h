#import <Foundation/Foundation.h>

@class AsyncSocket;

#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1060 // Mac OS X 10.6
  #define IMPLEMENTED_PROTOCOLS <NSNetServiceDelegate>
#elif __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000 // iPhone 4.0
  #define IMPLEMENTED_PROTOCOLS <NSNetServiceDelegate>
#else
  #define IMPLEMENTED_PROTOCOLS 
#endif


@interface HTTPServer : NSObject IMPLEMENTED_PROTOCOLS
{
	// Underlying asynchronous TCP/IP socket
	AsyncSocket *asyncSocket;
	
	// Standard delegate
	id delegate;
	
	// HTTP server configuration
	NSURL *documentRoot;
	Class connectionClass;
	
	// NSNetService and related variables
	NSNetService *netService;
	NSString *domain;
	NSString *type;
	NSString *name;
	UInt16 port;
	NSDictionary *txtRecordDictionary;
	
	NSMutableArray *connections;
}

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSURL *)documentRoot;
- (void)setDocumentRoot:(NSURL *)value;

- (Class)connectionClass;
- (void)setConnectionClass:(Class)value;

- (NSString *)domain;
- (void)setDomain:(NSString *)value;

- (NSString *)type;
- (void)setType:(NSString *)value;

- (NSString *)name;
- (NSString *)publishedName;
- (void)setName:(NSString *)value;

- (UInt16)port;
- (void)setPort:(UInt16)value;

- (NSDictionary *)TXTRecordDictionary;
- (void)setTXTRecordDictionary:(NSDictionary *)dict;

- (BOOL)start:(NSError **)errPtr;
- (BOOL)stop;

- (NSUInteger)numberOfHTTPConnections;

@end
