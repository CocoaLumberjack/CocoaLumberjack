//
//  GCDAsyncSocket.m
//  
//  This class is in the public domain.
//  Originally created by Robbie Hanson in Q4 2010.
//  Updated and maintained by Deusty LLC and the Mac development community.
//
//  http://code.google.com/p/cocoaasyncsocket/
//

#import "GCDAsyncSocket.h"

#if TARGET_OS_IPHONE
  #import <CFNetwork/CFNetwork.h>
#endif

#import <arpa/inet.h>
#import <fcntl.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <netinet/in.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <sys/ioctl.h>
#import <sys/poll.h>
#import <sys/uio.h>
#import <unistd.h>


#if 0

// Logging Enabled - See log level below

// Logging uses the CocoaLumberjack framework (which is also GCD based).
// http://code.google.com/p/cocoalumberjack/
// 
// It allows us to do a lot of logging without significantly slowing down the code.
#import "DDLog.h"

#define LogError(frmt, ...)     DDLogError((@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogWarn(frmt, ...)      DDLogWarn((@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogInfo(frmt, ...)      DDLogInfo((@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogVerbose(frmt, ...)   DDLogVerbose((@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)

#define LogTrace()              DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD)
#define LogTrace2(frmt, ...)    DDLogVerbose((@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)

// Log levels : off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

#else

// Logging Disabled

#define LogError(frmt, ...)     
#define LogWarn(frmt, ...)     
#define LogInfo(frmt, ...)     
#define LogVerbose(frmt, ...)  

#define LogTrace()            
#define LogTrace2(frmt, ...)  

#endif

/**
 * Seeing a return statements within an inner block
 * can sometimes be mistaken for a return point of the enclosing method.
 * This makes inline blocks a bit easier to read.
**/
#define return_from_block  return

/**
 * A socket file descriptor is really just an integer.
 * It represents the index of the socket within the kernel.
 * This makes invalid file descriptor comparisons easier to read.
**/
#define SOCKET_NULL -1


NSString *const GCDAsyncSocketException = @"GCDAsyncSocketException";
NSString *const GCDAsyncSocketErrorDomain = @"GCDAsyncSocketErrorDomain";

enum GCDAsyncSocketFlags
{
	kDidStartDelegate          = 1 <<  0,  // If set, disconnection results in delegate call
	kConnected                 = 1 <<  1,  // If set, the socket is connected
	kForbidReadsWrites         = 1 <<  2,  // If set, no new reads or writes are allowed
	kReadsPaused               = 1 <<  3,  // If set, reads are paused due to possible timeout
	kWritesPaused              = 1 <<  4,  // If set, writes are paused due to possible timeout
	kDisconnectAfterReads      = 1 <<  5,  // If set, disconnect after no more reads are queued
	kDisconnectAfterWrites     = 1 <<  6,  // If set, disconnect after no more writes are queued
	kSocketCanAcceptBytes      = 1 <<  7,  // If set, we know socket can accept bytes. If unset, it's unknown.
	kReadSourceSuspended       = 1 <<  8,  // If set, the read source is suspended
	kWriteSourceSuspended      = 1 <<  9,  // If set, the write source is suspended
	kStartingReadTLS           = 1 << 10,  // If set, we're waiting for TLS negotiation to complete
	kStartingWriteTLS          = 1 << 11,  // If set, we're waiting for TLS negotiation to complete
	kAddedHandshakeListener    = 1 << 12,  // If set, read & write stream have been added to handshake listener thread
	kSocketSecure              = 1 << 13,  // If set, socket is using secure communication via SSL/TLS
};

enum GCDAsyncSocketConfig
{
	kIPv4Disabled              = 1 << 0,  // If set, IPv4 is disabled
	kIPv6Disabled              = 1 << 1,  // If set, IPv6 is disabled
	kPreferIPv6                = 1 << 2,  // If set, IPv6 is preferred over IPv4
	kAllowHalfDuplexConnection = 1 << 3,  // If set, the socket will stay open even if the read stream closes
};

#if TARGET_OS_IPHONE
  static NSThread *sslHandshakeThread;
#endif

@interface GCDAsyncSocket (Private)

// Accepting
- (BOOL)doAccept:(int)socketFD;

// Connecting
- (void)startConnectTimeout:(NSTimeInterval)timeout;
- (void)endConnectTimeout;
- (void)doConnectTimeout;
- (void)lookup:(int)aConnectIndex host:(NSString *)host port:(UInt16)port;
- (void)lookup:(int)aConnectIndex didSucceedWithAddress4:(NSData *)address4 address6:(NSData *)address6;
- (void)lookup:(int)aConnectIndex didFail:(NSError *)error;
- (void)didConnect:(int)aConnectIndex;
- (void)didNotConnect:(int)aConnectIndex error:(NSError *)error;

// Disconnect
- (void)closeWithError:(NSError *)error;
- (void)close;
- (void)maybeClose;

// Errors
- (NSError *)badConfigError:(NSString *)msg;
- (NSError *)badParamError:(NSString *)msg;
- (NSError *)gaiError:(int)gai_error;
- (NSError *)errnoError;
- (NSError *)errnoErrorWithReason:(NSString *)reason;
- (NSError *)connectTimeoutError;
- (NSError *)otherError:(NSString *)msg;

// Diagnostics
- (NSString *)connectedHost4;
- (NSString *)connectedHost6;
- (UInt16)connectedPort4;
- (UInt16)connectedPort6;
- (NSString *)localHost4;
- (NSString *)localHost6;
- (UInt16)localPort4;
- (UInt16)localPort6;
- (NSString *)connectedHostFromSocket4:(int)socketFD;
- (NSString *)connectedHostFromSocket6:(int)socketFD;
- (UInt16)connectedPortFromSocket4:(int)socketFD;
- (UInt16)connectedPortFromSocket6:(int)socketFD;
- (NSString *)localHostFromSocket4:(int)socketFD;
- (NSString *)localHostFromSocket6:(int)socketFD;
- (UInt16)localPortFromSocket4:(int)socketFD;
- (UInt16)localPortFromSocket6:(int)socketFD;

// Utilities
- (void)getInterfaceAddress4:(NSData **)addr4Ptr
                    address6:(NSData **)addr6Ptr
             fromDescription:(NSString *)interfaceDescription
                        port:(UInt16)port;
- (void)setupReadAndWriteSourcesForNewlyConnectedSocket:(int)socketFD;
- (void)suspendReadSource;
- (void)resumeReadSource;
- (void)suspendWriteSource;
- (void)resumeWriteSource;

// Reading
- (void)maybeDequeueRead;
- (void)doReadData;
- (void)doReadEOF;
- (void)completeCurrentRead;
- (void)endCurrentRead;
- (void)setupReadTimerWithTimeout:(NSTimeInterval)timeout;
- (void)doReadTimeout;
- (void)doReadTimeoutWithExtension:(NSTimeInterval)timeoutExtension;

// Writing
- (void)maybeDequeueWrite;
- (void)doWriteData;
- (void)completeCurrentWrite;
- (void)endCurrentWrite;
- (void)setupWriteTimerWithTimeout:(NSTimeInterval)timeout;
- (void)doWriteTimeout;
- (void)doWriteTimeoutWithExtension:(NSTimeInterval)timeoutExtension;

// Security
- (void)maybeStartTLS;

// Class Methods
+ (NSString *)hostFromAddress4:(struct sockaddr_in *)pSockaddr4;
+ (NSString *)hostFromAddress6:(struct sockaddr_in6 *)pSockaddr6;
+ (UInt16)portFromAddress4:(struct sockaddr_in *)pSockaddr4;
+ (UInt16)portFromAddress6:(struct sockaddr_in6 *)pSockaddr6;

#if TARGET_OS_IPHONE
#else
- (void)continueSSLHandshake;
#endif

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The GCDAsyncReadPacket encompasses the instructions for any given read.
 * The content of a read packet allows the code to determine if we're:
 *  - reading to a certain length
 *  - reading to a certain separator
 *  - or simply reading the first chunk of available data
**/
@interface GCDAsyncReadPacket : NSObject
{
  @public
	NSMutableData *buffer;
	NSUInteger startOffset;
	NSUInteger bytesDone;
	NSUInteger maxLength;
	NSTimeInterval timeout;
	NSUInteger readLength;
	NSData *term;
	BOOL bufferOwner;
	NSUInteger originalBufferLength;
	long tag;
}
- (id)initWithData:(NSMutableData *)d
       startOffset:(NSUInteger)s
         maxLength:(NSUInteger)m
           timeout:(NSTimeInterval)t
        readLength:(NSUInteger)l
        terminator:(NSData *)e
               tag:(long)i;

- (void)ensureCapacityForReadOfLength:(NSUInteger)bytesToRead;

- (NSUInteger)readLengthForNonTermWithHint:(NSUInteger)bytesAvailable;
- (NSUInteger)readLengthForTermWithHint:(NSUInteger)bytesAvailable shouldPreBuffer:(BOOL *)shouldPreBufferPtr;
- (NSUInteger)readLengthForTermWithPreBuffer:(NSData *)preBuffer found:(BOOL *)foundPtr;

- (NSInteger)searchForTermAfterPreBuffering:(ssize_t)numBytes;

@end

@implementation GCDAsyncReadPacket

- (id)initWithData:(NSMutableData *)d
       startOffset:(NSUInteger)s
         maxLength:(NSUInteger)m
           timeout:(NSTimeInterval)t
        readLength:(NSUInteger)l
        terminator:(NSData *)e
               tag:(long)i
{
	if((self = [super init]))
	{
		bytesDone = 0;
		maxLength = m;
		timeout = t;
		readLength = l;
		term = [e copy];
		tag = i;
		
		if (d)
		{
			buffer = [d retain];
			startOffset = s;
			bufferOwner = NO;
			originalBufferLength = [d length];
		}
		else
		{
			if (readLength > 0)
				buffer = [[NSMutableData alloc] initWithLength:readLength];
			else
				buffer = [[NSMutableData alloc] initWithLength:0];
			
			startOffset = 0;
			bufferOwner = YES;
			originalBufferLength = 0;
		}
	}
	return self;
}

/**
 * Increases the length of the buffer (if needed) to ensure a read of the given size will fit.
**/
- (void)ensureCapacityForReadOfLength:(NSUInteger)bytesToRead
{
	NSUInteger buffSize = [buffer length];
	NSUInteger buffUsed = startOffset + bytesDone;
	
	NSUInteger buffSpace = buffSize - buffUsed;
	
	if (bytesToRead > buffSpace)
	{
		NSUInteger buffInc = bytesToRead - buffSpace;
		
		[buffer increaseLengthBy:buffInc];
	}
}

/**
 * For read packets without a set terminator, returns the amount of data
 * that can be read without exceeding the readLength or maxLength.
 * 
 * The given parameter indicates the number of bytes estimated to be available on the socket,
 * which is taken into consideration during the calculation.
**/
- (NSUInteger)readLengthForNonTermWithHint:(NSUInteger)bytesAvailable
{
	NSAssert(term == nil, @"This method does not apply to term reads");
	
	
	if (readLength > 0)
	{
		// Read a specific length of data
		
		return MIN(bytesAvailable, (readLength - bytesDone));
		
		// No need to avoid resizing the buffer.
		// If the user provided their own buffer,
		// and told us to read a certain length of data that exceeds the size of the buffer,
		// then it is clear that our code will resize the buffer during the read operation.
		// 
		// This method does not actually do any resizing.
		// The resizing will happen elsewhere if needed.
	}
	else
	{
		// Read all available data
		
		NSUInteger result = bytesAvailable;
		
		if (maxLength > 0)
		{
			result = MIN(result, (maxLength - bytesDone));
		}
		
		// No need to avoid resizing the buffer.
		// If the user provided their own buffer,
		// and told us to read all available data without giving us a maxLength,
		// then it is clear that our code might resize the buffer during the read operation.
		// 
		// This method does not actually do any resizing.
		// The resizing will happen elsewhere if needed.
		
		return result;
	}
}

/**
 * For read packets with a set terminator, returns the amount of data
 * that can be read without exceeding the maxLength.
 * 
 * The given parameter indicates the number of bytes estimated to be available on the socket,
 * which is taken into consideration during the calculation.
 * 
 * To optimize memory allocations, mem copies, and mem moves
 * the shouldPreBuffer boolean value will indicate if the data should be read into a prebuffer first,
 * or if the data can be read directly into the read packet's buffer.
**/
- (NSUInteger)readLengthForTermWithHint:(NSUInteger)bytesAvailable shouldPreBuffer:(BOOL *)shouldPreBufferPtr
{
	NSAssert(term != nil, @"This method does not apply to non-term reads");
	
	
	NSUInteger result = bytesAvailable;
	
	if (maxLength > 0)
	{
		result = MIN(result, (maxLength - bytesDone));
	}
	
	// Should the data be read into the read packet's buffer, or into a pre-buffer first?
	// 
	// One would imagine the preferred option is the faster one.
	// So which one is faster?
	// 
	// Reading directly into the packet's buffer requires:
	// 1. Possibly resizing packet buffer (malloc/realloc)
	// 2. Filling buffer (read)
	// 3. Searching for term (memcmp)
	// 4. Possibly copying overflow into prebuffer (malloc/realloc, memcpy)
	// 
	// Reading into prebuffer first:
	// 1. Possibly resizing prebuffer (malloc/realloc)
	// 2. Filling buffer (read)
	// 3. Searching for term (memcmp)
	// 4. Copying underflow into packet buffer (malloc/realloc, memcpy)
	// 5. Removing underflow from prebuffer (memmove)
	// 
	// Comparing the performance of the two we can see that reading
	// data into the prebuffer first is slower due to the extra memove.
	// 
	// However:
	// The implementation of NSMutableData is open source via core foundation's CFMutableData.
	// Decreasing the length of a mutable data object doesn't cause a realloc.
	// In other words, the capacity of a mutable data object can grow, but doesn't shrink.
	// 
	// This means the prebuffer will rarely need a realloc.
	// The packet buffer, on the other hand, may often need a realloc.
	// This is especially true if we are the buffer owner.
	// Furthermore, if we are constantly realloc'ing the packet buffer,
	// and then moving the overflow into the prebuffer,
	// then we're consistently over-allocating memory for each term read.
	// And now we get into a bit of a tradeoff between speed and memory utilization.
	// 
	// The end result is that the two perform very similarly.
	// And we can answer the original question very simply by another means.
	// 
	// If we can read all the data directly into the packet's buffer without resizing it first,
	// then we do so. Otherwise we use the prebuffer.
	
	if (shouldPreBufferPtr)
	{
		NSUInteger buffSize = [buffer length];
		NSUInteger buffUsed = startOffset + bytesDone;
		
		if ((buffSize - buffUsed) >= result)
			*shouldPreBufferPtr = NO;
		else
			*shouldPreBufferPtr = YES;
	}
	
	return result;
}

/**
 * For read packets with a set terminator,
 * returns the amount of data that can be read from the given preBuffer,
 * without going over a terminator or the maxLength.
 * 
 * It is assumed the terminator has not already been read.
**/
- (NSUInteger)readLengthForTermWithPreBuffer:(NSData *)preBuffer found:(BOOL *)foundPtr
{
	NSAssert(term != nil, @"This method does not apply to non-term reads");
	NSAssert([preBuffer length] > 0, @"Invoked with empty pre buffer!");
	
	// We know that the terminator, as a whole, doesn't exist in our own buffer.
	// But it is possible that a portion of it exists in our buffer.
	// So we're going to look for the terminator starting with a portion of our own buffer.
	// 
	// Example:
	// 
	// term length      = 3 bytes
	// bytesDone        = 5 bytes
	// preBuffer length = 5 bytes
	// 
	// If we append the preBuffer to our buffer,
	// it would look like this:
	// 
	// ---------------------
	// |B|B|B|B|B|P|P|P|P|P|
	// ---------------------
	// 
	// So we start our search here:
	// 
	// ---------------------
	// |B|B|B|B|B|P|P|P|P|P|
	// -------^-^-^---------
	// 
	// And move forwards...
	// 
	// ---------------------
	// |B|B|B|B|B|P|P|P|P|P|
	// ---------^-^-^-------
	// 
	// Until we find the terminator or reach the end.
	// 
	// ---------------------
	// |B|B|B|B|B|P|P|P|P|P|
	// ---------------^-^-^-
	
	BOOL found = NO;
	
	NSUInteger termLength = [term length];
	NSUInteger preBufferLength = [preBuffer length];
	
	if ((bytesDone + preBufferLength) < termLength)
	{
		// Not enough data for a full term sequence yet
		return preBufferLength;
	}
	
	NSUInteger maxPreBufferLength;
	if (maxLength > 0) {
		maxPreBufferLength = MIN(preBufferLength, (maxLength - bytesDone));
		
		// Note: maxLength >= termLength
	}
	else {
		maxPreBufferLength = preBufferLength;
	}
	
	Byte seq[termLength];
	const void *termBuf = [term bytes];
	
	NSUInteger bufLen = MIN(bytesDone, (termLength - 1));
	void *buf = [buffer mutableBytes] + startOffset + bytesDone - bufLen;
	
	NSUInteger preLen = termLength - bufLen;
	void *pre = (void *)[preBuffer bytes];
	
	NSUInteger loopCount = bufLen + maxPreBufferLength - termLength + 1; // Plus one. See example above.
	
	NSUInteger result = preBufferLength;
	
	NSUInteger i;
	for (i = 0; i < loopCount; i++)
	{
		if (bufLen > 0)
		{
			// Combining bytes from buffer and preBuffer
			
			memcpy(seq, buf, bufLen);
			memcpy(seq + bufLen, pre, preLen);
			
			if (memcmp(seq, termBuf, termLength) == 0)
			{
				result = preLen;
				found = YES;
				break;
			}
			
			buf++;
			bufLen--;
			preLen++;
		}
		else
		{
			// Comparing directly from preBuffer
			
			if (memcmp(pre, termBuf, termLength) == 0)
			{
				NSUInteger preOffset = pre - [preBuffer bytes]; // pointer arithmetic
				
				result = preOffset + termLength;
				found = YES;
				break;
			}
			
			pre++;
		}
	}
	
	// There is no need to avoid resizing the buffer in this particular situation.
	
	if (foundPtr) *foundPtr = found;
	return result;
}

/**
 * For read packets with a set terminator, scans the packet buffer for the term.
 * It is assumed the terminator had not been fully read prior to the new bytes.
 * 
 * If the term is found, the number of excess bytes after the term are returned.
 * If the term is not found, this method will return -1.
 * 
 * Note: A return value of zero means the term was found at the very end.
 * 
 * Prerequisites:
 * The given number of bytes have been added to the end of our buffer.
 * Our bytesDone variable has NOT been changed due to the prebuffered bytes.
**/
- (NSInteger)searchForTermAfterPreBuffering:(ssize_t)numBytes
{
	NSAssert(term != nil, @"This method does not apply to non-term reads");
	
	// The implementation of this method is very similar to the above method.
	// See the above method for a discussion of the algorithm used here.
	
	void *buff = [buffer mutableBytes];
	NSUInteger buffLength = bytesDone + numBytes;
	
	const void *termBuff = [term bytes];
	NSUInteger termLength = [term length];
	
	// Note: We are dealing with unsigned integers,
	// so make sure the math doesn't go below zero.
	
	NSUInteger i = ((buffLength - numBytes) >= termLength) ? (buffLength - numBytes - termLength + 1) : 0;
	
	while (i + termLength <= buffLength)
	{
		void *subBuffer = buff + startOffset + i;
		
		if (memcmp(subBuffer, termBuff, termLength) == 0)
		{
			return buffLength - (i + termLength);
		}
		
		i++;
	}
	
	return -1;
}

- (void)dealloc
{
	[buffer release];
	[term release];
	[super dealloc];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The GCDAsyncWritePacket encompasses the instructions for any given write.
**/
@interface GCDAsyncWritePacket : NSObject
{
  @public
	NSData *buffer;
	NSUInteger bytesDone;
	long tag;
	NSTimeInterval timeout;
}
- (id)initWithData:(NSData *)d timeout:(NSTimeInterval)t tag:(long)i;
@end

@implementation GCDAsyncWritePacket

- (id)initWithData:(NSData *)d timeout:(NSTimeInterval)t tag:(long)i
{
	if((self = [super init]))
	{
		buffer = [d retain];
		bytesDone = 0;
		timeout = t;
		tag = i;
	}
	return self;
}

- (void)dealloc
{
	[buffer release];
	[super dealloc];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The GCDAsyncSpecialPacket encompasses special instructions for interruptions in the read/write queues.
 * This class my be altered to support more than just TLS in the future.
**/
@interface GCDAsyncSpecialPacket : NSObject
{
  @public
	NSDictionary *tlsSettings;
}
- (id)initWithTLSSettings:(NSDictionary *)settings;
@end

@implementation GCDAsyncSpecialPacket

- (id)initWithTLSSettings:(NSDictionary *)settings
{
	if((self = [super init]))
	{
		tlsSettings = [settings copy];
	}
	return self;
}

- (void)dealloc
{
	[tlsSettings release];
	[super dealloc];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation GCDAsyncSocket

- (id)init
{
	return [self initWithDelegate:nil delegateQueue:NULL socketQueue:NULL];
}

- (id)initWithSocketQueue:(dispatch_queue_t)sq
{
	return [self initWithDelegate:nil delegateQueue:NULL socketQueue:sq];
}

- (id)initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq
{
	return [self initWithDelegate:aDelegate delegateQueue:dq socketQueue:NULL];
}

- (id)initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq
{
	if((self = [super init]))
	{
		delegate = aDelegate;
		
		if (dq)
		{
			dispatch_retain(dq);
			delegateQueue = dq;
		}
		
		socket4FD = SOCKET_NULL;
		socket6FD = SOCKET_NULL;
		connectIndex = 0;
		
		if (sq)
		{
			NSString *assertMsg = @"The given socketQueue parameter must not be a concurrent queue.";
			
			NSAssert(sq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), assertMsg);
			NSAssert(sq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), assertMsg);
			NSAssert(sq != dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), assertMsg);
			
			dispatch_retain(sq);
			socketQueue = sq;
		}
		else
		{
			socketQueue = dispatch_queue_create("GCDAsyncSocket", NULL);
		}
		
		readQueue = [[NSMutableArray alloc] initWithCapacity:5];
		currentRead = nil;
		
		writeQueue = [[NSMutableArray alloc] initWithCapacity:5];
		currentWrite = nil;
		
		partialReadBuffer = [[NSMutableData alloc] init];
	}
	return self;
}

- (void)dealloc
{
	LogInfo(@"%@ - %@", THIS_METHOD, self);
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		[self closeWithError:nil];
	}
	else
	{
		dispatch_sync(socketQueue, ^{
			[self closeWithError:nil];
		});
	}
	
	delegate = nil;
	if (delegateQueue)
		dispatch_release(delegateQueue);
	delegateQueue = NULL;
	
	dispatch_release(socketQueue);
	socketQueue = NULL;
	
	[readQueue release];
	[writeQueue release];
	
	[partialReadBuffer release];
	
#if !TARGET_OS_IPHONE
	[sslReadBuffer release];
#endif
	
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)delegate
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		return delegate;
	}
	else
	{
		__block id result;
		
		dispatch_sync(socketQueue, ^{
			result = delegate;
		});
		
		return result;
	}
}

- (void)setDelegate:(id)newDelegate
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		delegate = newDelegate;
	}
	else
	{
		dispatch_async(socketQueue, ^{
			delegate = newDelegate;
		});
	}
}

- (dispatch_queue_t)delegateQueue
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		return delegateQueue;
	}
	else
	{
		__block dispatch_queue_t result;
		
		dispatch_sync(socketQueue, ^{
			result = delegateQueue;
		});
		
		return result;
	}
}

- (void)setDelegateQueue:(dispatch_queue_t)newDelegateQueue
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (delegateQueue)
			dispatch_release(delegateQueue);
		
		if (newDelegateQueue)
			dispatch_retain(newDelegateQueue);
		
		delegateQueue = newDelegateQueue;
	}
	else
	{
		dispatch_async(socketQueue, ^{
			
			if (delegateQueue)
				dispatch_release(delegateQueue);
			
			if (newDelegateQueue)
				dispatch_retain(newDelegateQueue);
			
			delegateQueue = newDelegateQueue;
		});
	}
}

- (void)getDelegate:(id *)delegatePtr delegateQueue:(dispatch_queue_t *)delegateQueuePtr
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (delegatePtr) *delegatePtr = delegate;
		if (delegateQueuePtr) *delegateQueuePtr = delegateQueue;
	}
	else
	{
		__block id dPtr = NULL;
		__block dispatch_queue_t dqPtr = NULL;
		
		dispatch_sync(socketQueue, ^{
			dPtr = delegate;
			dqPtr = delegateQueue;
		});
		
		if (delegatePtr) *delegatePtr = dPtr;
		if (delegateQueuePtr) *delegateQueuePtr = dqPtr;
	}
}

- (void)setDelegate:(id)newDelegate delegateQueue:(dispatch_queue_t)newDelegateQueue
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		delegate = newDelegate;
		
		if (delegateQueue)
			dispatch_release(delegateQueue);
		
		if (newDelegateQueue)
			dispatch_retain(newDelegateQueue);
		
		delegateQueue = newDelegateQueue;
	}
	else
	{
		dispatch_async(socketQueue, ^{
			
			delegate = newDelegate;
			
			if (delegateQueue)
				dispatch_release(delegateQueue);
			
			if (newDelegateQueue)
				dispatch_retain(newDelegateQueue);
			
			delegateQueue = newDelegateQueue;
		});
	}
}

- (BOOL)autoDisconnectOnClosedReadStream
{
	// Note: YES means kAllowHalfDuplexConnection is OFF
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		return ((config & kAllowHalfDuplexConnection) == 0);
	}
	else
	{
		__block BOOL result;
		
		dispatch_sync(socketQueue, ^{
			result = ((config & kAllowHalfDuplexConnection) == 0);
		});
		
		return result;
	}
}

- (void)setAutoDisconnectOnClosedReadStream:(BOOL)flag
{
	// Note: YES means kAllowHalfDuplexConnection is OFF
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (flag)
			config &= ~kAllowHalfDuplexConnection;
		else
			config |= kAllowHalfDuplexConnection;
	}
	else
	{
		dispatch_async(socketQueue, ^{
			if (flag)
				config &= ~kAllowHalfDuplexConnection;
			else
				config |= kAllowHalfDuplexConnection;
		});
	}
}

- (BOOL)isIPv4Enabled
{
	// Note: YES means kIPv4Disabled is OFF
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		return ((config & kIPv4Disabled) == 0);
	}
	else
	{
		__block BOOL result;
		
		dispatch_sync(socketQueue, ^{
			result = ((config & kIPv4Disabled) == 0);
		});
		
		return result;
	}
}

- (void)setIPv4Enabled:(BOOL)flag
{
	// Note: YES means kIPv4Disabled is OFF
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (flag)
			config &= ~kIPv4Disabled;
		else
			config |= kIPv4Disabled;
	}
	else
	{
		dispatch_async(socketQueue, ^{
			if (flag)
				config &= ~kIPv4Disabled;
			else
				config |= kIPv4Disabled;
		});
	}
}

- (BOOL)isIPv6Enabled
{
	// Note: YES means kIPv6Disabled is OFF
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		return ((config & kIPv6Disabled) == 0);
	}
	else
	{
		__block BOOL result;
		
		dispatch_sync(socketQueue, ^{
			result = ((config & kIPv6Disabled) == 0);
		});
		
		return result;
	}
}

- (void)setIPv6Enabled:(BOOL)flag
{
	// Note: YES means kIPv6Disabled is OFF
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (flag)
			config &= ~kIPv6Disabled;
		else
			config |= kIPv6Disabled;
	}
	else
	{
		dispatch_async(socketQueue, ^{
			if (flag)
				config &= ~kIPv6Disabled;
			else
				config |= kIPv6Disabled;
		});
	}
}

- (BOOL)isIPv4PreferredOverIPv6
{
	// Note: YES means kPreferIPv6 is OFF
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		return ((config & kPreferIPv6) == 0);
	}
	else
	{
		__block BOOL result;
		
		dispatch_sync(socketQueue, ^{
			result = ((config & kPreferIPv6) == 0);
		});
		
		return result;
	}
}

- (void)setPreferIPv4OverIPv6:(BOOL)flag
{
	// Note: YES means kPreferIPv6 is OFF
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (flag)
			config &= ~kPreferIPv6;
		else
			config |= kPreferIPv6;
	}
	else
	{
		dispatch_async(socketQueue, ^{
			if (flag)
				config &= ~kPreferIPv6;
			else
				config |= kPreferIPv6;
		});
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accepting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)acceptOnPort:(UInt16)port error:(NSError **)errPtr
{
	return [self acceptOnInterface:nil port:port error:errPtr];
}

- (BOOL)acceptOnInterface:(NSString *)interface port:(UInt16)port error:(NSError **)errPtr
{
	LogTrace();
	
	__block BOOL result = YES;
	__block NSError *err = nil;
	
	// CreateSocket Block
	// This block will be invoked within the dispatch block below.
	
	int(^createSocket)(int, NSData*) = ^int (int domain, NSData *interfaceAddr) {
		
		int socketFD = socket(domain, SOCK_STREAM, 0);
		
		if (socketFD == SOCKET_NULL)
		{
			NSString *reason = @"Error in socket() function";
			err = [[self errnoErrorWithReason:reason] retain];
			
			return SOCKET_NULL;
		}
		
		int status;
		
		// Set socket options
		
		status = fcntl(socketFD, F_SETFL, O_NONBLOCK);
		if (status == -1)
		{
			NSString *reason = @"Error enabling non-blocking IO on socket (fcntl)";
			err = [[self errnoErrorWithReason:reason] retain];
			
			close(socketFD);
			return SOCKET_NULL;
		}
		
		int reuseOn = 1;
		status = setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &reuseOn, sizeof(reuseOn));
		if (status == -1)
		{
			NSString *reason = @"Error enabling address reuse (setsockopt)";
			err = [[self errnoErrorWithReason:reason] retain];
			
			close(socketFD);
			return SOCKET_NULL;
		}
		
		// Bind socket
		
		status = bind(socketFD, (struct sockaddr *)[interfaceAddr bytes], (socklen_t)[interfaceAddr length]);
		if (status == -1)
		{
			NSString *reason = @"Error in bind() function";
			err = [[self errnoErrorWithReason:reason] retain];
			
			close(socketFD);
			return SOCKET_NULL;
		}
		
		// Listen
		
		status = listen(socketFD, 1024);
		if (status == -1)
		{
			NSString *reason = @"Error in listen() function";
			err = [[self errnoErrorWithReason:reason] retain];
			
			close(socketFD);
			return SOCKET_NULL;
		}
		
		return socketFD;
	};
	
	// Create dispatch block and run on socketQueue
	
	dispatch_block_t block = ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (delegate == nil) // Must have delegate set
		{
			result = NO;
			
			NSString *msg = @"Attempting to accept without a delegate. Set a delegate first.";
			err = [[self badConfigError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		if (delegateQueue == NULL) // Must have delegate queue set
		{
			result = NO;
			
			NSString *msg = @"Attempting to accept without a delegate queue. Set a delegate queue first.";
			err = [[self badConfigError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		BOOL isIPv4Disabled = (config & kIPv4Disabled) ? YES : NO;
		BOOL isIPv6Disabled = (config & kIPv6Disabled) ? YES : NO;
		
		if (isIPv4Disabled && isIPv6Disabled) // Must have IPv4 or IPv6 enabled
		{
			result = NO;
			
			NSString *msg = @"Both IPv4 and IPv6 have been disabled. Must enable at least one protocol first.";
			err = [[self badConfigError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		if (![self isDisconnected]) // Must be disconnected
		{
			result = NO;
			
			NSString *msg = @"Attempting to accept while connected or accepting connections. Disconnect first.";
			err = [[self badConfigError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		NSData *interface4 = nil;
		NSData *interface6 = nil;
		
		[self getInterfaceAddress4:&interface4 address6:&interface6 fromDescription:interface port:port];
		
		if ((interface4 == nil) && (interface6 == nil))
		{
			result = NO;
			
			NSString *msg = @"Unknown interface. Specify valid interface by name (e.g. \"en1\") or IP address.";
			err = [[self badParamError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		if (isIPv4Disabled && (interface6 == nil))
		{
			result = NO;
			
			NSString *msg = @"IPv4 has been disabled and specified interface doesn't support IPv6.";
			err = [[self badParamError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		if (isIPv6Disabled && (interface4 == nil))
		{
			result = NO;
			
			NSString *msg = @"IPv6 has been disabled and specified interface doesn't support IPv4.";
			err = [[self badParamError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		BOOL enableIPv4 = !isIPv4Disabled && (interface4 != nil);
		BOOL enableIPv6 = !isIPv6Disabled && (interface6 != nil);
		
		// Create sockets, configure, bind, and listen
		
		if (enableIPv4)
		{
			LogVerbose(@"Creating IPv4 socket");
			socket4FD = createSocket(AF_INET, interface4);
			
			if (socket4FD == SOCKET_NULL)
			{
				[pool release];
				return_from_block;
			}
		}
		
		if (enableIPv6)
		{
			LogVerbose(@"Creating IPv6 socket");
			
			if (enableIPv4 && (port == 0))
			{
				// No specific port was specified, so we allowed the OS to pick an available port for us.
				// Now we need to make sure the IPv6 socket listens on the same port as the IPv4 socket.
				
				struct sockaddr_in6 *addr6 = (struct sockaddr_in6 *)[interface6 bytes];
				addr6->sin6_port = htons([self localPort4]);
			}
			
			socket6FD = createSocket(AF_INET6, interface6);
			
			if (socket6FD == SOCKET_NULL)
			{
				if (socket4FD != SOCKET_NULL)
				{
					close(socket4FD);
				}
				
				[pool release];
				return_from_block;
			}
		}
		
		// Create accept sources
		
		if (enableIPv4)
		{
			accept4Source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, socket4FD, 0, socketQueue);
			
			int socketFD = socket4FD;
			dispatch_source_t acceptSource = accept4Source;
			
			dispatch_block_t event4Block = ^{
				NSAutoreleasePool *eventPool = [[NSAutoreleasePool alloc] init];
				
				LogVerbose(@"event4Block");
				
				unsigned long i = 0;
				unsigned long numPendingConnections = dispatch_source_get_data(acceptSource);
				
				LogVerbose(@"numPendingConnections: %lu", numPendingConnections);
				
				while ([self doAccept:socketFD] && (++i < numPendingConnections));
				
				[eventPool release];
			};
			dispatch_source_set_event_handler(accept4Source, event4Block);
			
			dispatch_block_t cancel4Block = ^{
				
				LogVerbose(@"dispatch_release(accept4Source)");
				dispatch_release(acceptSource);
				
				LogVerbose(@"close(socket4FD)");
				close(socketFD);
			};
			dispatch_source_set_cancel_handler(accept4Source, cancel4Block);
			
			LogVerbose(@"dispatch_resume(accept4Source)");
			dispatch_resume(accept4Source);
		}
		
		if (enableIPv6)
		{
			accept6Source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, socket6FD, 0, socketQueue);
			
			int socketFD = socket6FD;
			dispatch_source_t acceptSource = accept6Source;
			
			dispatch_block_t event6Block = ^{
				NSAutoreleasePool *eventPool = [[NSAutoreleasePool alloc] init];
				
				LogVerbose(@"event6Block");
				
				unsigned long i = 0;
				unsigned long numPendingConnections = dispatch_source_get_data(acceptSource);
				
				LogVerbose(@"numPendingConnections: %lu", numPendingConnections);
				
				while ([self doAccept:socketFD] && (++i < numPendingConnections));
				
				[eventPool release];
			};
			dispatch_source_set_event_handler(accept6Source, event6Block);
			
			dispatch_block_t cancel6Block = ^{
				
				LogVerbose(@"dispatch_release(accept6Source)");
				dispatch_release(acceptSource);
				
				LogVerbose(@"close(socket6FD)");
				close(socketFD);
			};
			dispatch_source_set_cancel_handler(accept6Source, cancel6Block);
			
			LogVerbose(@"dispatch_resume(accept6Source)");
			dispatch_resume(accept6Source);
		}
		
		flags |= kDidStartDelegate;
		[pool release];
	};
	
	if (dispatch_get_current_queue() == socketQueue)
		block();
	else
		dispatch_sync(socketQueue, block);
	
	if (result == NO)
	{
		if (errPtr)
			*errPtr = [err autorelease];
		else
			[err release];
	}
	
	return result;
}

- (BOOL)doAccept:(int)parentSocketFD
{
	LogTrace();
	
	BOOL isIPv4;
	int childSocketFD;
	NSData *childSocketAddress;
	
	if (parentSocketFD == socket4FD)
	{
		isIPv4 = YES;
		
		struct sockaddr_in addr;
		socklen_t addrLen = sizeof(addr);
		
		childSocketFD = accept(parentSocketFD, (struct sockaddr *)&addr, &addrLen);
		
		if (childSocketFD == -1)
		{
			LogWarn(@"Accept failed with error: %@", [self errnoError]);
			return NO;
		}
		
		childSocketAddress = [NSData dataWithBytes:&addr length:addrLen];
	}
	else // if (parentSocketFD == socket6FD)
	{
		isIPv4 = NO;
		
		struct sockaddr_in6 addr;
		socklen_t addrLen = sizeof(addr);
		
		childSocketFD = accept(parentSocketFD, (struct sockaddr *)&addr, &addrLen);
		
		if (childSocketFD == -1)
		{
			LogWarn(@"Accept failed with error: %@", [self errnoError]);
			return NO;
		}
		
		childSocketAddress = [NSData dataWithBytes:&addr length:addrLen];
	}
	
	// Enable non-blocking IO on the socket
	
	int result = fcntl(childSocketFD, F_SETFL, O_NONBLOCK);
	if (result == -1)
	{
		LogWarn(@"Error enabling non-blocking IO on accepted socket (fcntl)");
		return NO;
	}
	
	// Prevent SIGPIPE signals
	
	int nosigpipe = 1;
	setsockopt(childSocketFD, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
	
	// Notify delegate
	
	if (delegateQueue)
	{
		id theDelegate = delegate;
		
		dispatch_async(delegateQueue, ^{
			NSAutoreleasePool *delegatePool = [[NSAutoreleasePool alloc] init];
			
			// Query delegate for custom socket queue
			
			dispatch_queue_t childSocketQueue = NULL;
			
			if ([theDelegate respondsToSelector:@selector(newSocketQueueForConnectionFromAddress:onSocket:)])
			{
				childSocketQueue = [theDelegate newSocketQueueForConnectionFromAddress:childSocketAddress
				                                                              onSocket:self];
			}
			
			// Create GCDAsyncSocket instance for accepted socket
			
			GCDAsyncSocket *acceptedSocket = [[GCDAsyncSocket alloc] initWithDelegate:delegate
			                                                            delegateQueue:delegateQueue
			                                                              socketQueue:childSocketQueue];
			
			if (isIPv4)
				acceptedSocket->socket4FD = childSocketFD;
			else
				acceptedSocket->socket6FD = childSocketFD;
			
			acceptedSocket->flags = (kDidStartDelegate | kConnected);
			
			// Setup read and write sources for accepted socket
			
			dispatch_async(acceptedSocket->socketQueue, ^{
				NSAutoreleasePool *socketPool = [[NSAutoreleasePool alloc] init];
				
				[acceptedSocket setupReadAndWriteSourcesForNewlyConnectedSocket:childSocketFD];
				
				[socketPool release];
			});
			
			// Notify delegate
			
			if ([theDelegate respondsToSelector:@selector(socket:didAcceptNewSocket:)])
			{
				[theDelegate socket:self didAcceptNewSocket:acceptedSocket];
			}
			
			// Release the socket queue returned from the delegate (it was retained by acceptedSocket)
			if (childSocketQueue)
				dispatch_release(childSocketQueue);
			
			// Release the accepted socket (it should have been retained by the delegate)
			[acceptedSocket release];
			
			[delegatePool release];
		});
	}
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connecting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connectToHost:(NSString*)host onPort:(UInt16)port error:(NSError **)errPtr
{
	return [self connectToHost:host onPort:port withTimeout:-1 error:errPtr];
}

- (BOOL)connectToHost:(NSString *)host
               onPort:(UInt16)port
          withTimeout:(NSTimeInterval)timeout
                error:(NSError **)errPtr
{
	return [self connectToHost:host onPort:port viaInterface:nil withTimeout:timeout error:errPtr];
}

- (BOOL)connectToHost:(NSString *)host
               onPort:(UInt16)port
         viaInterface:(NSString *)interface
          withTimeout:(NSTimeInterval)timeout
                error:(NSError **)errPtr;
{
	LogTrace();
	
	__block BOOL result = YES;
	__block NSError *err = nil;
	
	dispatch_block_t block = ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (delegate == nil) // Must have delegate set
		{
			result = NO;
			
			NSString *msg = @"Attempting to connect without a delegate. Set a delegate first.";
			err = [[self badConfigError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		if (delegateQueue == NULL) // Must have delegate queue set
		{
			result = NO;
			
			NSString *msg = @"Attempting to connect without a delegate queue. Set a delegate queue first.";
			err = [[self badConfigError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		BOOL isIPv4Disabled = (config & kIPv4Disabled) ? YES : NO;
		BOOL isIPv6Disabled = (config & kIPv6Disabled) ? YES : NO;
		
		if (isIPv4Disabled && isIPv6Disabled) // Must have IPv4 or IPv6 enabled
		{
			result = NO;
			
			NSString *msg = @"Both IPv4 and IPv6 have been disabled. Must enable at least one protocol first.";
			err = [[self badConfigError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		if (![self isDisconnected]) // Must be disconnected
		{
			result = NO;
			
			NSString *msg = @"Attempting to connect while connected or accepting connections. Disconnect first.";
			err = [[self badConfigError:msg] retain];
			
			[pool release];
			return_from_block;
		}
		
		if (interface)
		{
			NSData *interface4 = nil;
			NSData *interface6 = nil;
			
			[self getInterfaceAddress4:&interface4 address6:&interface6 fromDescription:interface port:0];
			
			if ((interface4 == nil) && (interface6 == nil))
			{
				result = NO;
				
				NSString *msg = @"Unknown interface. Specify valid interface by name (e.g. \"en1\") or IP address.";
				err = [[self badParamError:msg] retain];
				
				[pool release];
				return_from_block;
			}
			
			if (isIPv4Disabled && (interface6 == nil))
			{
				result = NO;
				
				NSString *msg = @"IPv4 has been disabled and specified interface doesn't support IPv6.";
				err = [[self badParamError:msg] retain];
				
				[pool release];
				return_from_block;
			}
			
			if (isIPv6Disabled && (interface4 == nil))
			{
				result = NO;
				
				NSString *msg = @"IPv6 has been disabled and specified interface doesn't support IPv4.";
				err = [[self badParamError:msg] retain];
				
				[pool release];
				return_from_block;
			}
			
			connectInterface4 = [interface4 retain];
			connectInterface6 = [interface6 retain];
		}
		
		// We've made it past all the checks.
		// It's time to start the connection process.
		
		flags |= kDidStartDelegate;
		
		LogVerbose(@"Dispatching DNS lookup...");
		
		// It's possible that the given host parameter is actually a NSMutableString.
		// So we want to copy it now, within this block that will be executed synchronously.
		// This way the asynchronous lookup block below doesn't have to worry about it changing.
		
		int aConnectIndex = connectIndex;
		NSString *hostCpy = [[host copy] autorelease];
		
		dispatch_queue_t globalConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_block_t lookupBlock = ^{
			NSAutoreleasePool *lookupPool = [[NSAutoreleasePool alloc] init];
			
			[self lookup:aConnectIndex host:hostCpy port:port];
			
			[lookupPool release];
		};
		dispatch_async(globalConcurrentQueue, lookupBlock);
		
		[self startConnectTimeout:timeout];
		
		[pool release];
	};
	
	if (dispatch_get_current_queue() == socketQueue)
		block();
	else
		dispatch_sync(socketQueue, block);
	
	if (result == NO)
	{
		if (errPtr)
			*errPtr = [err autorelease];
		else
			[err release];
	}
	
	return result;
}

- (void)lookup:(int)aConnectIndex host:(NSString *)host port:(UInt16)port
{
	LogTrace();
	
	// This method is executed on a global concurrent queue.
	// It posts the results back to the socket queue.
	// The lookupIndex is used to ignore the results if the connect operation was cancelled or timed out.
	
	NSError *error = nil;
	
	NSData *address4 = nil;
	NSData *address6 = nil;
	
	
	if ([host isEqualToString:@"localhost"] || [host isEqualToString:@"loopback"])
	{
		// Use LOOPBACK address
		struct sockaddr_in nativeAddr;
		nativeAddr.sin_len         = sizeof(struct sockaddr_in);
		nativeAddr.sin_family      = AF_INET;
		nativeAddr.sin_port        = htons(port);
		nativeAddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
		memset(&(nativeAddr.sin_zero), 0, sizeof(nativeAddr.sin_zero));
		
		struct sockaddr_in6 nativeAddr6;
		nativeAddr6.sin6_len       = sizeof(struct sockaddr_in6);
		nativeAddr6.sin6_family    = AF_INET6;
		nativeAddr6.sin6_port      = htons(port);
		nativeAddr6.sin6_flowinfo  = 0;
		nativeAddr6.sin6_addr      = in6addr_loopback;
		nativeAddr6.sin6_scope_id  = 0;
		
		// Wrap the native address structures
		address4 = [NSData dataWithBytes:&nativeAddr length:sizeof(nativeAddr)];
		address6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
	}
	else
	{
		NSString *portStr = [NSString stringWithFormat:@"%hu", port];
		
		struct addrinfo hints, *res, *res0;
		
		memset(&hints, 0, sizeof(hints));
		hints.ai_family   = PF_UNSPEC;
		hints.ai_socktype = SOCK_STREAM;
		hints.ai_protocol = IPPROTO_TCP;
		
		int gai_error = getaddrinfo([host UTF8String], [portStr UTF8String], &hints, &res0);
		
		if (gai_error)
		{
			error = [self gaiError:gai_error];
		}
		else
		{
			for(res = res0; res; res = res->ai_next)
			{
				if ((address4 == nil) && (res->ai_family == AF_INET))
				{
					// Found IPv4 address
					// Wrap the native address structure
					address4 = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
				}
				else if ((address6 == nil) && (res->ai_family == AF_INET6))
				{
					// Found IPv6 address
					// Wrap the native address structure
					address6 = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
				}
			}
			freeaddrinfo(res0);
			
			if ((address4 == nil) && (address6 == nil))
			{
				error = [self gaiError:EAI_FAIL];
			}
		}
	}
	
	if (error)
	{
		dispatch_async(socketQueue, ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[self lookup:aConnectIndex didFail:error];
			[pool release];
		});
	}
	else
	{
		dispatch_async(socketQueue, ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[self lookup:aConnectIndex didSucceedWithAddress4:address4 address6:address6];
			[pool release];
		});
	}
}

- (void)lookup:(int)aConnectIndex didSucceedWithAddress4:(NSData *)address4 address6:(NSData *)address6
{
	LogTrace();
	
	NSAssert(dispatch_get_current_queue() == socketQueue, @"Exectued on wrong dispatch queue");
	NSAssert(address4 || address6, @"Expected at least one valid address");
	
	if (aConnectIndex != connectIndex)
	{
		LogInfo(@"Ignoring lookupDidSucceed, already disconnected");
		
		// The connect operation has been cancelled.
		// That is, socket was disconnected, or connection has already timed out.
		return;
	}
	
	// Check for problems
	
	BOOL isIPv4Disabled = (config & kIPv4Disabled) ? YES : NO;
	BOOL isIPv6Disabled = (config & kIPv6Disabled) ? YES : NO;
	
	if (isIPv4Disabled && (address6 == nil))
	{
		NSString *msg = @"IPv4 has been disabled and DNS lookup found no IPv6 address.";
		
		[self closeWithError:[self otherError:msg]];
		return;
	}
	
	if (isIPv6Disabled && (address4 == nil))
	{
		NSString *msg = @"IPv6 has been disabled and DNS lookup found no IPv4 address.";
		
		[self closeWithError:[self otherError:msg]];
		return;
	}
	
	// Determine socket type
	
	BOOL preferIPv6 = (config & kPreferIPv6) ? YES : NO;
	
	BOOL useIPv6 = ((preferIPv6 && address6) || (address4 == nil));
	
	// Create the socket
	
	int socketFD;
	NSData *address;
	NSData *connectInterface;
	
	if (useIPv6)
	{
		LogVerbose(@"Creating IPv6 socket");
		
		socket6FD = socket(AF_INET6, SOCK_STREAM, 0);
		
		socketFD = socket6FD;
		address = address6;
		connectInterface = connectInterface6;
	}
	else
	{
		LogVerbose(@"Creating IPv4 socket");
		
		socket4FD = socket(AF_INET, SOCK_STREAM, 0);
		
		socketFD = socket4FD;
		address = address4;
		connectInterface = connectInterface4;
	}
	
	if (socketFD == SOCKET_NULL)
	{
		[self closeWithError:[self errnoErrorWithReason:@"Error in socket() function"]];
		return;
	}
	
	// Bind the socket to the desired interface (if needed)
	
	if (connectInterface)
	{
		LogVerbose(@"Binding socket...");
		
		struct sockaddr *interfaceAddr = (struct sockaddr *)[connectInterface bytes];
		
		int result = bind(socketFD, interfaceAddr, (socklen_t)[connectInterface length]);
		if (result != 0)
		{
			[self closeWithError:[self errnoErrorWithReason:@"Error in bind() function"]];
			return;
		}
	}
	
	// Start the connection process in a background queue
	
	dispatch_queue_t globalConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_block_t connectBlock = ^{
		
		int result = connect(socketFD, (const struct sockaddr *)[address bytes], (socklen_t)[address length]);
		if (result == 0)
		{
			dispatch_async(socketQueue, ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[self didConnect:aConnectIndex];
				[pool release];
			});
		}
		else
		{
			NSError *error = [self errnoErrorWithReason:@"Error in connect() function"];
			
			dispatch_async(socketQueue, ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				[self didNotConnect:aConnectIndex error:error];
				[pool release];
			});
		}
	};
	dispatch_async(globalConcurrentQueue, connectBlock);
	
	LogVerbose(@"Connecting...");
}

/**
 * This method is called if the DNS lookup fails.
 * This method is executed on the socketQueue.
 * 
 * Since the DNS lookup executed synchronously on a global concurrent queue,
 * the original connection request may have already been cancelled or timed-out by the time this method is invoked.
 * The lookupIndex tells us whether the lookup is still valid or not.
**/
- (void)lookup:(int)aConnectIndex didFail:(NSError *)error
{
	LogTrace();
	
	NSAssert(dispatch_get_current_queue() == socketQueue, @"Exectued on wrong dispatch queue");
	
	
	if (aConnectIndex != connectIndex)
	{
		LogInfo(@"Ignoring lookupDidFail, already disconnected");
		
		// The connect operation has been cancelled.
		// That is, socket was disconnected, or connection has already timed out.
		return;
	}
	
	[self endConnectTimeout];
	[self closeWithError:error];
}

- (void)didConnect:(int)aConnectIndex
{
	LogTrace();
	
	NSAssert(dispatch_get_current_queue() == socketQueue, @"Must be dispatched on socketQueue");
	
	
	if (aConnectIndex != connectIndex)
	{
		LogInfo(@"Ignoring didConnect, already disconnected");
		
		// The connect operation has been cancelled.
		// That is, socket was disconnected, or connection has already timed out.
		return;
	}
	
	flags |= kConnected;
	
	[self endConnectTimeout];
	
	NSString *host = [self connectedHost];
	UInt16 port = [self connectedPort];
	
	if (delegateQueue && [delegate respondsToSelector:@selector(socket:didConnectToHost:port:)])
	{
		id theDelegate = delegate;
		
		dispatch_async(delegateQueue, ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[theDelegate socket:self didConnectToHost:host port:port];
			
			[pool release];
		});
	}
		
	// Get the connected socket
	
	int socketFD = (socket4FD != SOCKET_NULL) ? socket4FD : socket6FD;
	
	// Enable non-blocking IO on the socket
	
	int result = fcntl(socketFD, F_SETFL, O_NONBLOCK);
	if (result == -1)
	{
		NSString *errMsg = @"Error enabling non-blocking IO on socket (fcntl)";
		[self closeWithError:[self otherError:errMsg]];
		
		return;
	}
	
	// Prevent SIGPIPE signals
	
	int nosigpipe = 1;
	setsockopt(socketFD, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, sizeof(nosigpipe));
	
	// Setup our read/write sources.
	
	[self setupReadAndWriteSourcesForNewlyConnectedSocket:socketFD];
	
	// Dequeue any pending read/write requests
	
	[self maybeDequeueRead];
	[self maybeDequeueWrite];
}

- (void)didNotConnect:(int)aConnectIndex error:(NSError *)error
{
	LogTrace();
	
	NSAssert(dispatch_get_current_queue() == socketQueue, @"Must be dispatched on socketQueue");
	
	
	if (aConnectIndex != connectIndex)
	{
		LogInfo(@"Ignoring didNotConnect, already disconnected");
		
		// The connect operation has been cancelled.
		// That is, socket was disconnected, or connection has already timed out.
		return;
	}
	
	[self endConnectTimeout];
	[self closeWithError:error];
}

- (void)startConnectTimeout:(NSTimeInterval)timeout
{
	if (timeout >= 0.0)
	{
		connectTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, socketQueue);
		
		dispatch_block_t timerEventBlock = ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[self doConnectTimeout];
			
			[pool release];
		};
		dispatch_source_set_event_handler(connectTimer, timerEventBlock);
		
		dispatch_source_t theConnectTimer = connectTimer;
		dispatch_block_t timerCancelBlock = ^{
			LogVerbose(@"dispatch_release(connectTimer)");
			dispatch_release(theConnectTimer);
		};
		dispatch_source_set_cancel_handler(connectTimer, timerCancelBlock);
		
		dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (timeout * NSEC_PER_SEC));
		dispatch_source_set_timer(connectTimer, tt, DISPATCH_TIME_FOREVER, 0);
		
		dispatch_resume(connectTimer);
	}
}

- (void)endConnectTimeout
{
	LogTrace();
	
	if (connectTimer)
	{
		dispatch_source_cancel(connectTimer);
		connectTimer = NULL;
	}
	
	// Increment connectIndex.
	// This will prevent us from processing results from any related background asynchronous operations.
	// 
	// Note: This should be called from close method even if connectTimer is NULL.
	// This is because one might disconnect a socket prior to a successful connection which had no timeout.
	
	connectIndex++;
	
	if (connectInterface4)
	{
		[connectInterface4 release];
		connectInterface4 = nil;
	}
	if (connectInterface6)
	{
		[connectInterface6 release];
		connectInterface6 = nil;
	}
}

- (void)doConnectTimeout
{
	LogTrace();
	
	[self endConnectTimeout];
	[self closeWithError:[self connectTimeoutError]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Disconnecting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)closeWithError:(NSError *)error
{
	LogTrace();
	
	NSAssert(dispatch_get_current_queue() == socketQueue, @"Must be dispatched on socketQueue");
	
	
	[self endConnectTimeout];
	
	if (currentRead != nil)  [self endCurrentRead];
	if (currentWrite != nil) [self endCurrentWrite];
	
	[readQueue removeAllObjects];
	[writeQueue removeAllObjects];
	
	[partialReadBuffer setLength:0];
	
	#if TARGET_OS_IPHONE
		if (readStream || writeStream)
		{
			if (flags & kAddedHandshakeListener)
			{
				[[self class] performSelector:@selector(removeHandshakeListener:)
				                     onThread:sslHandshakeThread
				                   withObject:self
			                waitUntilDone:YES];
			}
			
			if (readStream)
			{
				CFReadStreamSetClient(readStream, kCFStreamEventNone, NULL, NULL);
				CFReadStreamClose(readStream);
				CFRelease(readStream);
				readStream = NULL;
			}
			if (writeStream)
			{
				CFWriteStreamSetClient(writeStream, kCFStreamEventNone, NULL, NULL);
				CFWriteStreamClose(writeStream);
				CFRelease(writeStream);
				writeStream = NULL;
			}
		}
	#else
		[sslReadBuffer setLength:0];
		if (sslContext)
		{
			SSLDisposeContext(sslContext);
			sslContext = NULL;
		}
	#endif
	
	// For some crazy reason (in my opinion), cancelling a dispatch source doesn't
	// invoke the cancel handler if the dispatch source is paused.
	// So we have to unpause the source if needed.
	// This allows the cancel handler to be run, which in turn releases the source and closes the socket.
	
	if (accept4Source)
	{
		LogVerbose(@"dispatch_source_cancel(accept4Source)");
		dispatch_source_cancel(accept4Source);
		
		// We never suspend accept4Source
		
		accept4Source = NULL;
	}
	
	if (accept6Source)
	{
		LogVerbose(@"dispatch_source_cancel(accept6Source)");
		dispatch_source_cancel(accept6Source);
		
		// We never suspend accept6Source
		
		accept6Source = NULL;
	}
	
	if (readSource)
	{
		LogVerbose(@"dispatch_source_cancel(readSource)");
		dispatch_source_cancel(readSource);
		
		[self resumeReadSource];
		
		readSource = NULL;
	}
	
	if (writeSource)
	{
		LogVerbose(@"dispatch_source_cancel(writeSource)");
		dispatch_source_cancel(writeSource);
		
		[self resumeWriteSource];
		
		writeSource = NULL;
	}
	
	// The sockets will be closed by the cancel handlers of the corresponding source
	
	socket4FD = SOCKET_NULL;
	socket6FD = SOCKET_NULL;
	
	// If the client has passed the connect/accept method, then the connection has at least begun.
	// Notify delegate that it is now ending.
	BOOL shouldCallDelegate = (flags & kDidStartDelegate);
	
	// Clear stored socket info and all flags (config remains as is)
	socketFDBytesAvailable = 0;
	flags = 0;
	
	if (shouldCallDelegate)
	{
		if (delegateQueue && [delegate respondsToSelector: @selector(socketDidDisconnect:withError:)])
		{
			id theDelegate = delegate;
			
			dispatch_async(delegateQueue, ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[theDelegate socketDidDisconnect:self withError:error];
				
				[pool release];
			});
		}	
	}
}

- (void)disconnect
{
	dispatch_block_t block = ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[self closeWithError:nil];
		[pool release];
	};
	
	// Synchronous disconnection, as documented in the header file
	
	if (dispatch_get_current_queue() == socketQueue)
		block();
	else
		dispatch_sync(socketQueue, block);
}

- (void)disconnectAfterReading
{
	dispatch_async(socketQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		flags |= (kForbidReadsWrites | kDisconnectAfterReads);
		[self maybeClose];
		
		[pool release];
	});
}

- (void)disconnectAfterWriting
{
	dispatch_async(socketQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		flags |= (kForbidReadsWrites | kDisconnectAfterWrites);
		[self maybeClose];
		
		[pool release];
	});
}

- (void)disconnectAfterReadingAndWriting
{
	dispatch_async(socketQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		flags |= (kForbidReadsWrites | kDisconnectAfterReads | kDisconnectAfterWrites);
		[self maybeClose];
		
		[pool release];
	});
}

/**
 * Closes the socket if possible.
 * That is, if all writes have completed, and we're set to disconnect after writing,
 * or if all reads have completed, and we're set to disconnect after reading.
**/
- (void)maybeClose
{
	NSAssert(dispatch_get_current_queue() == socketQueue, @"Must be dispatched on socketQueue");
	
	BOOL shouldClose = NO;
	
	if (flags & kDisconnectAfterReads)
	{
		if (([readQueue count] == 0) && (currentRead == nil))
		{
			if (flags & kDisconnectAfterWrites)
			{
				if (([writeQueue count] == 0) && (currentWrite == nil))
				{
					shouldClose = YES;
				}
			}
			else
			{
				shouldClose = YES;
			}
		}
	}
	else if (flags & kDisconnectAfterWrites)
	{
		if (([writeQueue count] == 0) && (currentWrite == nil))
		{
			shouldClose = YES;
		}
	}
	
	if (shouldClose)
	{
		[self closeWithError:nil];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Errors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSError *)badConfigError:(NSString *)errMsg
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketBadConfigError userInfo:userInfo];
}

- (NSError *)badParamError:(NSString *)errMsg
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketBadParamError userInfo:userInfo];
}

- (NSError *)gaiError:(int)gai_error
{
	NSString *errMsg = [NSString stringWithCString:gai_strerror(gai_error) encoding:NSASCIIStringEncoding];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:@"kCFStreamErrorDomainNetDB" code:gai_error userInfo:userInfo];
}

- (NSError *)errnoErrorWithReason:(NSString *)reason
{
	NSString *errMsg = [NSString stringWithUTF8String:strerror(errno)];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errMsg, NSLocalizedDescriptionKey,
	                                                                    reason, NSLocalizedFailureReasonErrorKey, nil];
	
	return [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo];
}

- (NSError *)errnoError
{
	NSString *errMsg = [NSString stringWithUTF8String:strerror(errno)];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo];
}

- (NSError *)sslError:(OSStatus)ssl_error
{
	NSString *msg = @"Error code definition can be found in Apple's SecureTransport.h";
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg forKey:NSLocalizedRecoverySuggestionErrorKey];
	
	return [NSError errorWithDomain:@"kCFStreamErrorDomainSSL" code:ssl_error userInfo:userInfo];
}

- (NSError *)connectTimeoutError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"GCDAsyncSocketConnectTimeoutError",
	                                                     @"GCDAsyncSocket", [NSBundle mainBundle],
	                                                     @"Attempt to connect to host timed out", nil);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketConnectTimeoutError userInfo:userInfo];
}

/**
 * Returns a standard AsyncSocket maxed out error.
**/
- (NSError *)readMaxedOutError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"GCDAsyncSocketReadMaxedOutError",
														 @"GCDAsyncSocket", [NSBundle mainBundle],
														 @"Read operation reached set maximum length", nil);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketReadMaxedOutError userInfo:info];
}

/**
 * Returns a standard AsyncSocket write timeout error.
**/
- (NSError *)readTimeoutError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"GCDAsyncSocketReadTimeoutError",
	                                                     @"GCDAsyncSocket", [NSBundle mainBundle],
	                                                     @"Read operation timed out", nil);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketReadTimeoutError userInfo:userInfo];
}

/**
 * Returns a standard AsyncSocket write timeout error.
**/
- (NSError *)writeTimeoutError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"GCDAsyncSocketWriteTimeoutError",
	                                                     @"GCDAsyncSocket", [NSBundle mainBundle],
	                                                     @"Write operation timed out", nil);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketWriteTimeoutError userInfo:userInfo];
}

- (NSError *)connectionClosedError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"GCDAsyncSocketClosedError",
	                                                     @"GCDAsyncSocket", [NSBundle mainBundle],
	                                                     @"Socket closed by remote peer", nil);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketClosedError userInfo:userInfo];
}

- (NSError *)otherError:(NSString *)errMsg
{
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:GCDAsyncSocketErrorDomain code:GCDAsyncSocketOtherError userInfo:userInfo];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Diagnostics
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isDisconnected
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		return (socket4FD == SOCKET_NULL) && (socket6FD == SOCKET_NULL);
	}
	else
	{
		__block BOOL result = YES;
		
		dispatch_sync(socketQueue, ^{
			result = (socket4FD == SOCKET_NULL) && (socket6FD == SOCKET_NULL);
		});
		
		return result;
	}
}

- (NSString *)connectedHost
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (socket4FD != SOCKET_NULL)
			return [self connectedHostFromSocket4:socket4FD];
		if (socket6FD != SOCKET_NULL)
			return [self connectedHostFromSocket6:socket6FD];
		
		return nil;
	}
	else
	{
		__block NSString *result = nil;
		
		dispatch_sync(socketQueue, ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			if (socket4FD != SOCKET_NULL)
				result = [[self connectedHostFromSocket4:socket4FD] retain];
			else if (socket6FD != SOCKET_NULL)
				result = [[self connectedHostFromSocket6:socket6FD] retain];
			
			[pool release];
		});
		
		return [result autorelease];
	}
}

- (UInt16)connectedPort
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (socket4FD != SOCKET_NULL)
			return [self connectedPortFromSocket4:socket4FD];
		if (socket6FD != SOCKET_NULL)
			return [self connectedPortFromSocket6:socket6FD];
		
		return 0;
	}
	else
	{
		__block UInt16 result = 0;
		
		dispatch_sync(socketQueue, ^{
			// No need for autorelease pool
			
			if (socket4FD != SOCKET_NULL)
				result = [self connectedPortFromSocket4:socket4FD];
			else if (socket6FD != SOCKET_NULL)
				result = [self connectedPortFromSocket6:socket6FD];
		});
		
		return result;
	}
}

- (NSString *)localHost
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (socket4FD != SOCKET_NULL)
			return [self localHostFromSocket4:socket4FD];
		if (socket6FD != SOCKET_NULL)
			return [self localHostFromSocket6:socket6FD];
		
		return nil;
	}
	else
	{
		__block NSString *result = nil;
		
		dispatch_sync(socketQueue, ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			if (socket4FD != SOCKET_NULL)
				result = [[self localHostFromSocket4:socket4FD] retain];
			else if (socket6FD != SOCKET_NULL)
				result = [[self localHostFromSocket6:socket6FD] retain];
			
			[pool release];
		});
		
		return [result autorelease];
	}
}

- (UInt16)localPort
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (socket4FD != SOCKET_NULL)
			return [self localPortFromSocket4:socket4FD];
		if (socket6FD != SOCKET_NULL)
			return [self localPortFromSocket6:socket6FD];
		
		return 0;
	}
	else
	{
		__block UInt16 result = 0;
		
		dispatch_sync(socketQueue, ^{
			// No need for autorelease pool
			
			if (socket4FD != SOCKET_NULL)
				result = [self localPortFromSocket4:socket4FD];
			else if (socket6FD != SOCKET_NULL)
				result = [self localPortFromSocket6:socket6FD];
		});
		
		return result;
	}
}

- (NSString *)connectedHost4
{
	if (socket4FD != SOCKET_NULL)
		return [self connectedHostFromSocket4:socket4FD];
	
	return nil;
}

- (NSString *)connectedHost6
{
	if (socket6FD != SOCKET_NULL)
		return [self connectedHostFromSocket6:socket6FD];
	
	return nil;
}

- (UInt16)connectedPort4
{
	if (socket4FD != SOCKET_NULL)
		return [self connectedPortFromSocket4:socket4FD];
	
	return 0;
}

- (UInt16)connectedPort6
{
	if (socket6FD != SOCKET_NULL)
		return [self connectedPortFromSocket6:socket6FD];
	
	return 0;
}

- (NSString *)localHost4
{
	if (socket4FD != SOCKET_NULL)
		return [self localHostFromSocket4:socket4FD];
	
	return nil;
}

- (NSString *)localHost6
{
	if (socket6FD != SOCKET_NULL)
		return [self localHostFromSocket6:socket6FD];
	
	return nil;
}

- (UInt16)localPort4
{
	if (socket4FD != SOCKET_NULL)
		return [self localPortFromSocket4:socket4FD];
	
	return 0;
}

- (UInt16)localPort6
{
	if (socket6FD != SOCKET_NULL)
		return [self localPortFromSocket6:socket6FD];
	
	return 0;
}

- (NSString *)connectedHostFromSocket4:(int)socketFD
{
	struct sockaddr_in sockaddr4;
	socklen_t sockaddr4len = sizeof(sockaddr4);
	
	if (getpeername(socketFD, (struct sockaddr *)&sockaddr4, &sockaddr4len) < 0)
	{
		return nil;
	}
	return [[self class] hostFromAddress4:&sockaddr4];
}

- (NSString *)connectedHostFromSocket6:(int)socketFD
{
	struct sockaddr_in6 sockaddr6;
	socklen_t sockaddr6len = sizeof(sockaddr6);
	
	if (getpeername(socketFD, (struct sockaddr *)&sockaddr6, &sockaddr6len) < 0)
	{
		return nil;
	}
	return [[self class] hostFromAddress6:&sockaddr6];
}

- (UInt16)connectedPortFromSocket4:(int)socketFD
{
	struct sockaddr_in sockaddr4;
	socklen_t sockaddr4len = sizeof(sockaddr4);
	
	if (getpeername(socketFD, (struct sockaddr *)&sockaddr4, &sockaddr4len) < 0)
	{
		return 0;
	}
	return [[self class] portFromAddress4:&sockaddr4];
}

- (UInt16)connectedPortFromSocket6:(int)socketFD
{
	struct sockaddr_in6 sockaddr6;
	socklen_t sockaddr6len = sizeof(sockaddr6);
	
	if (getpeername(socketFD, (struct sockaddr *)&sockaddr6, &sockaddr6len) < 0)
	{
		return 0;
	}
	return [[self class] portFromAddress6:&sockaddr6];
}

- (NSString *)localHostFromSocket4:(int)socketFD
{
	struct sockaddr_in sockaddr4;
	socklen_t sockaddr4len = sizeof(sockaddr4);
	
	if (getsockname(socketFD, (struct sockaddr *)&sockaddr4, &sockaddr4len) < 0)
	{
		return nil;
	}
	return [[self class] hostFromAddress4:&sockaddr4];
}

- (NSString *)localHostFromSocket6:(int)socketFD
{
	struct sockaddr_in6 sockaddr6;
	socklen_t sockaddr6len = sizeof(sockaddr6);
	
	if (getsockname(socketFD, (struct sockaddr *)&sockaddr6, &sockaddr6len) < 0)
	{
		return nil;
	}
	return [[self class] hostFromAddress6:&sockaddr6];
}

- (UInt16)localPortFromSocket4:(int)socketFD
{
	struct sockaddr_in sockaddr4;
	socklen_t sockaddr4len = sizeof(sockaddr4);
	
	if (getsockname(socketFD, (struct sockaddr *)&sockaddr4, &sockaddr4len) < 0)
	{
		return 0;
	}
	return [[self class] portFromAddress4:&sockaddr4];
}

- (UInt16)localPortFromSocket6:(int)socketFD
{
	struct sockaddr_in6 sockaddr6;
	socklen_t sockaddr6len = sizeof(sockaddr6);
	
	if (getsockname(socketFD, (struct sockaddr *)&sockaddr6, &sockaddr6len) < 0)
	{
		return 0;
	}
	return [[self class] portFromAddress6:&sockaddr6];
}

- (NSData *)connectedAddress
{
	__block NSData *result = nil;
	
	dispatch_block_t block = ^{
		if (socket4FD != SOCKET_NULL)
		{
			struct sockaddr_in sockaddr4;
			socklen_t sockaddr4len = sizeof(sockaddr4);
			
			if (getpeername(socket4FD, (struct sockaddr *)&sockaddr4, &sockaddr4len) == 0)
			{
				result = [[NSData alloc] initWithBytes:&sockaddr4 length:sockaddr4len];
			}
		}
		
		if (socket6FD != SOCKET_NULL)
		{
			struct sockaddr_in6 sockaddr6;
			socklen_t sockaddr6len = sizeof(sockaddr6);
			
			if (getpeername(socket6FD, (struct sockaddr *)&sockaddr6, &sockaddr6len) == 0)
			{
				result = [[NSData alloc] initWithBytes:&sockaddr6 length:sockaddr6len];
			}
		}
	};
	
	if (dispatch_get_current_queue() == socketQueue)
		block();
	else
		dispatch_sync(socketQueue, block);
	
	return [result autorelease];
}

- (NSData *)localAddress
{
	__block NSData *result = nil;
	
	dispatch_block_t block = ^{
		if (socket4FD != SOCKET_NULL)
		{
			struct sockaddr_in sockaddr4;
			socklen_t sockaddr4len = sizeof(sockaddr4);
			
			if (getsockname(socket4FD, (struct sockaddr *)&sockaddr4, &sockaddr4len) == 0)
			{
				result = [[NSData alloc] initWithBytes:&sockaddr4 length:sockaddr4len];
			}
		}
		
		if (socket6FD != SOCKET_NULL)
		{
			struct sockaddr_in6 sockaddr6;
			socklen_t sockaddr6len = sizeof(sockaddr6);
			
			if (getsockname(socket6FD, (struct sockaddr *)&sockaddr6, &sockaddr6len) == 0)
			{
				result = [[NSData alloc] initWithBytes:&sockaddr6 length:sockaddr6len];
			}
		}
	};
	
	if (dispatch_get_current_queue() == socketQueue)
		block();
	else
		dispatch_sync(socketQueue, block);
	
	return [result autorelease];
}

- (BOOL)isIPv4
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		return (socket4FD != SOCKET_NULL);
	}
	else
	{
		__block BOOL result = NO;
		
		dispatch_sync(socketQueue, ^{
			result = (socket4FD != SOCKET_NULL);
		});
		
		return result;
	}
}

- (BOOL)isIPv6
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		return (socket6FD != SOCKET_NULL);
	}
	else
	{
		__block BOOL result = NO;
		
		dispatch_sync(socketQueue, ^{
			result = (socket6FD != SOCKET_NULL);
		});
		
		return result;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Finds the address of an interface description.
 * An inteface description may be an interface name (en0, en1, lo0) or corresponding IP (192.168.4.34).
 * The returned value is a 'struct sockaddr' wrapped in an NSData object.
**/
- (void)getInterfaceAddress4:(NSData **)interfaceAddr4Ptr
                    address6:(NSData **)interfaceAddr6Ptr
             fromDescription:(NSString *)interfaceDescription
                        port:(UInt16)port
{
	NSData *addr4 = nil;
	NSData *addr6 = nil;
	
	if (interfaceDescription == nil)
	{
		// ANY address
		
		struct sockaddr_in nativeAddr4;
		memset(&nativeAddr4, 0, sizeof(nativeAddr4));
		
		nativeAddr4.sin_len         = sizeof(nativeAddr4);
		nativeAddr4.sin_family      = AF_INET;
		nativeAddr4.sin_port        = htons(port);
		nativeAddr4.sin_addr.s_addr = htonl(INADDR_ANY);
		
		struct sockaddr_in6 nativeAddr6;
		memset(&nativeAddr6, 0, sizeof(nativeAddr6));
		
		nativeAddr6.sin6_len       = sizeof(nativeAddr6);
		nativeAddr6.sin6_family    = AF_INET6;
		nativeAddr6.sin6_port      = htons(port);
		nativeAddr6.sin6_addr      = in6addr_any;
		
		addr4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
		addr6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
	}
	else if ([interfaceDescription isEqualToString:@"localhost"] || [interfaceDescription isEqualToString:@"loopback"])
	{
		// LOOPBACK address
		
		struct sockaddr_in nativeAddr4;
		memset(&nativeAddr4, 0, sizeof(nativeAddr4));
		
		nativeAddr4.sin_len         = sizeof(struct sockaddr_in);
		nativeAddr4.sin_family      = AF_INET;
		nativeAddr4.sin_port        = htons(port);
		nativeAddr4.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
		
		struct sockaddr_in6 nativeAddr6;
		memset(&nativeAddr6, 0, sizeof(nativeAddr6));
		
		nativeAddr6.sin6_len       = sizeof(struct sockaddr_in6);
		nativeAddr6.sin6_family    = AF_INET6;
		nativeAddr6.sin6_port      = htons(port);
		nativeAddr6.sin6_addr      = in6addr_loopback;
		
		addr4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
		addr6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
	}
	else
	{
		const char *interface = [interfaceDescription UTF8String];
		
		struct ifaddrs *addrs;
		const struct ifaddrs *cursor;
		
		if ((getifaddrs(&addrs) == 0))
		{
			cursor = addrs;
			while (cursor != NULL)
			{
				if ((addr4 == nil) && (cursor->ifa_addr->sa_family == AF_INET))
				{
					// IPv4
					
					struct sockaddr_in *addr = (struct sockaddr_in *)cursor->ifa_addr;
					
					if (strcmp(cursor->ifa_name, interface) == 0)
					{
						// Name match
						
						struct sockaddr_in nativeAddr4 = *addr;
						nativeAddr4.sin_port = htons(port);
						
						addr4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
					}
					else
					{
						char ip[INET_ADDRSTRLEN];
						
						const char *conversion;
						conversion = inet_ntop(AF_INET, &addr->sin_addr, ip, sizeof(ip));
						
						if ((conversion != NULL) && (strcmp(ip, interface) == 0))
						{
							// IP match
							
							struct sockaddr_in nativeAddr4 = *addr;
							nativeAddr4.sin_port = htons(port);
							
							addr4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
						}
					}
				}
				else if ((addr6 == nil) && (cursor->ifa_addr->sa_family == AF_INET6))
				{
					// IPv6
					
					struct sockaddr_in6 *addr = (struct sockaddr_in6 *)cursor->ifa_addr;
					
					if (strcmp(cursor->ifa_name, interface) == 0)
					{
						// Name match
						
						struct sockaddr_in6 nativeAddr6;
						nativeAddr6.sin6_port = htons(port);
						
						addr6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
					}
					else
					{
						char ip[INET6_ADDRSTRLEN];
						
						const char *conversion;
						conversion = inet_ntop(AF_INET6, &addr->sin6_addr, ip, sizeof(ip));
						
						if ((conversion != NULL) && (strcmp(ip, interface) == 0))
						{
							// IP match
							
							struct sockaddr_in6 nativeAddr6;
							nativeAddr6.sin6_port = htons(port);
							
							addr6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
						}
					}
				}
				
				cursor = cursor->ifa_next;
			}
			
			freeifaddrs(addrs);
		}
	}
	
	if (interfaceAddr4Ptr) *interfaceAddr4Ptr = addr4;
	if (interfaceAddr6Ptr) *interfaceAddr6Ptr = addr6;
}

- (void)setupReadAndWriteSourcesForNewlyConnectedSocket:(int)socketFD
{
	readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, socketFD, 0, socketQueue);
	writeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, socketFD, 0, socketQueue);
	
	// Setup event handlers
	
	dispatch_block_t readEventBlock = ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		LogVerbose(@"readEventBlock");
		
		socketFDBytesAvailable = dispatch_source_get_data(readSource);
		if (socketFDBytesAvailable > 0)
			[self doReadData];
		else
			[self doReadEOF];
		
		[pool release];
	};
	dispatch_source_set_event_handler(readSource, readEventBlock);
	
	dispatch_block_t writeEventBlock = ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		LogVerbose(@"writeEventBlock");
		
		flags |= kSocketCanAcceptBytes;
		[self doWriteData];
		
		[pool release];
	};
	dispatch_source_set_event_handler(writeSource, writeEventBlock);
	
	// Setup cancel handlers
	
	__block int socketFDRefCount = 2;
	
	dispatch_source_t theReadSource = readSource;
	dispatch_source_t theWriteSource = writeSource;
	
	dispatch_block_t readCancelBlock = ^{
		
		LogVerbose(@"readCancelBlock");
		
		LogVerbose(@"dispatch_release(theReadSource)");
		dispatch_release(theReadSource);
		
		if (--socketFDRefCount == 0)
		{
			LogVerbose(@"close(socketFD)");
			close(socketFD);
		}
	};
	dispatch_source_set_cancel_handler(readSource, readCancelBlock);
	
	dispatch_block_t writeCancelBlock = ^{
		
		LogVerbose(@"writeCancelBlock");
		
		LogVerbose(@"dispatch_release(theWriteSource)");
		dispatch_release(theWriteSource);
		
		if (--socketFDRefCount == 0)
		{
			LogVerbose(@"close(socketFD)");
			close(socketFD);
		}
	};
	dispatch_source_set_cancel_handler(writeSource, writeCancelBlock);
	
	// We will not be able to read until data arrives.
	// But we should be able to write immediately.
	
	socketFDBytesAvailable = 0;
	flags &= ~kReadSourceSuspended;
	
	LogVerbose(@"dispatch_resume(readSource)");
	dispatch_resume(readSource);
	
	flags |= kSocketCanAcceptBytes;
	flags |= kWriteSourceSuspended;
}

- (void)suspendReadSource
{
	if (!(flags & kReadSourceSuspended))
	{
		LogVerbose(@"dispatch_suspend(readSource)");
		
		dispatch_suspend(readSource);
		flags |= kReadSourceSuspended;
	}
}

- (void)resumeReadSource
{
	if (flags & kReadSourceSuspended)
	{
		LogVerbose(@"dispatch_resume(readSource)");
		
		dispatch_resume(readSource);
		flags &= ~kReadSourceSuspended;
	}
}

- (void)suspendWriteSource
{
	if (!(flags & kWriteSourceSuspended))
	{
		LogVerbose(@"dispatch_suspend(writeSource)");
		
		dispatch_suspend(writeSource);
		flags |= kWriteSourceSuspended;
	}
}

- (void)resumeWriteSource
{
	if (flags & kWriteSourceSuspended)
	{
		LogVerbose(@"dispatch_resume(writeSource)");
		
		dispatch_resume(writeSource);
		flags &= ~kWriteSourceSuspended;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)readDataWithTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[self readDataWithTimeout:timeout buffer:nil bufferOffset:0 maxLength:0 tag:tag];
}

- (void)readDataWithTimeout:(NSTimeInterval)timeout
                     buffer:(NSMutableData *)buffer
               bufferOffset:(NSUInteger)offset
                        tag:(long)tag
{
	[self readDataWithTimeout:timeout buffer:buffer bufferOffset:offset maxLength:0 tag:tag];
}

- (void)readDataWithTimeout:(NSTimeInterval)timeout
                     buffer:(NSMutableData *)buffer
               bufferOffset:(NSUInteger)offset
                  maxLength:(NSUInteger)length
                        tag:(long)tag
{
	if (offset > [buffer length]) return;
	
	GCDAsyncReadPacket *packet = [[GCDAsyncReadPacket alloc] initWithData:buffer
	                                                          startOffset:offset
	                                                            maxLength:length
	                                                              timeout:timeout
	                                                           readLength:0
	                                                           terminator:nil
	                                                                  tag:tag];
	
	dispatch_async(socketQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (!(flags & kForbidReadsWrites))
		{
			[readQueue addObject:packet];
			[self maybeDequeueRead];
		}
		
		[pool release];
	});
	
	// Do not rely on the block being run in order to release the packet,
	// as the queue might get released without the block completing.
	[packet release];
}

- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[self readDataToLength:length withTimeout:timeout buffer:nil bufferOffset:0 tag:tag];
}

- (void)readDataToLength:(NSUInteger)length
             withTimeout:(NSTimeInterval)timeout
                  buffer:(NSMutableData *)buffer
            bufferOffset:(NSUInteger)offset
                     tag:(long)tag
{
	if (length == 0) return;
	if (offset > [buffer length]) return;
	
	GCDAsyncReadPacket *packet = [[GCDAsyncReadPacket alloc] initWithData:buffer
	                                                          startOffset:offset
	                                                            maxLength:0
	                                                              timeout:timeout
	                                                           readLength:length
	                                                           terminator:nil
	                                                                  tag:tag];
	
	dispatch_async(socketQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (!(flags & kForbidReadsWrites))
		{
			[readQueue addObject:packet];
			[self maybeDequeueRead];
		}
		
		[pool release];
	});
	
	// Do not rely on the block being run in order to release the packet,
	// as the queue might get released without the block completing.
	[packet release];
}

- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[self readDataToData:data withTimeout:timeout buffer:nil bufferOffset:0 maxLength:0 tag:tag];
}

- (void)readDataToData:(NSData *)data
           withTimeout:(NSTimeInterval)timeout
                buffer:(NSMutableData *)buffer
          bufferOffset:(NSUInteger)offset
                   tag:(long)tag
{
	[self readDataToData:data withTimeout:timeout buffer:buffer bufferOffset:offset maxLength:0 tag:tag];
}

- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout maxLength:(NSUInteger)length tag:(long)tag
{
	[self readDataToData:data withTimeout:timeout buffer:nil bufferOffset:0 maxLength:length tag:tag];
}

- (void)readDataToData:(NSData *)data
           withTimeout:(NSTimeInterval)timeout
                buffer:(NSMutableData *)buffer
          bufferOffset:(NSUInteger)offset
             maxLength:(NSUInteger)length
                   tag:(long)tag
{
	if (data == nil || [data length] == 0) return;
	if (offset > [buffer length]) return;
	if (length > 0 && length < [data length]) return;
	
	GCDAsyncReadPacket *packet = [[GCDAsyncReadPacket alloc] initWithData:buffer
	                                                          startOffset:offset
	                                                            maxLength:length
	                                                              timeout:timeout
	                                                           readLength:0
	                                                           terminator:data
	                                                                  tag:tag];
	
	dispatch_async(socketQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (!(flags & kForbidReadsWrites))
		{
			[readQueue addObject:packet];
			[self maybeDequeueRead];
		}
		
		[pool release];
	});
	
	// Do not rely on the block being run in order to release the packet,
	// as the queue might get released without the block completing.
	[packet release];
}

/**
 * This method starts a new read, if needed.
 * 
 * It is called when:
 * - a user requests a read
 * - after a read request has finished (to handle the next request)
 * - immediately after the socket opens to handle any pending requests
 * 
 * This method also handles auto-disconnect post read/write completion.
**/
- (void)maybeDequeueRead
{
	LogTrace();
	NSAssert(dispatch_get_current_queue() == socketQueue, @"Must be dispatched on socketQueue");
	
	// If we're not currently processing a read AND we have an available read stream
	if ((currentRead == nil) && (flags & kConnected))
	{
		if ([readQueue count] > 0)
		{
			// Dequeue the next object in the write queue
			currentRead = [[readQueue objectAtIndex:0] retain];
			[readQueue removeObjectAtIndex:0];
			
			
			if ([currentRead isKindOfClass:[GCDAsyncSpecialPacket class]])
			{
				// Attempt to start TLS
				flags |= kStartingReadTLS;
				
				// This method won't do anything unless both kStartingReadTLS and kStartingWriteTLS are set
				[self maybeStartTLS];
			}
			else
			{
				// Setup read timer (if needed)
				[self setupReadTimerWithTimeout:currentRead->timeout];
				
				// Immediately read, if possible
				[self doReadData];
			}
		}
		else if (flags & kDisconnectAfterReads)
		{
			if (flags & kDisconnectAfterWrites)
			{
				if (([writeQueue count] == 0) && (currentWrite == nil))
				{
					[self closeWithError:nil];
				}
			}
			else
			{
				[self closeWithError:nil];
			}
		}
	}
}

- (void)doReadData
{
	LogTrace();
	
	// This method is called on the socketQueue.
	// It might be called directly, or via the readSource when data is available to be read.
	
	if ((currentRead == nil) || (flags & kReadsPaused))
	{
		// Unable to read at this time
		// 
		// If the readSource is firing, we need to pause it
		// or else it will continue to fire over and over again.
		// 
		// If the readSource is not firing,
		// we want it to continue monitoring the socket.
		
		if (socketFDBytesAvailable > 0)
		{
			[self suspendReadSource];
		}
		return;
	}
	
	unsigned long estimatedBytesAvailable;
#if TARGET_OS_IPHONE
	estimatedBytesAvailable = socketFDBytesAvailable;
#else
	estimatedBytesAvailable = socketFDBytesAvailable + [sslReadBuffer length];
#endif
	
	if ((estimatedBytesAvailable == 0) && ([partialReadBuffer length] == 0))
	{
		// No data available to read.
		// 
		// Need to wait for readSource to fire and notify us of
		// available data in the socket's internal read buffer.
		
		[self resumeReadSource];
		return;
	}
	
	if (flags & kStartingReadTLS)
	{
		// The readQueue is waiting for SSL/TLS to complete.
		
		if (flags & kStartingWriteTLS)
		{
			#if !TARGET_OS_IPHONE
			
				// We are in the process of a SSL Handshake.
				// We were waiting for incoming data which has just arrived.
				
				[self continueSSLHandshake];
			
			#endif
		}
		else
		{
			// We are still waiting for the writeQueue to drain and start the SSL/TLS process.
			// We now know data is available to read,
			// so we suspend the read source or else it will continue to fire nonstop.
			
			[self suspendReadSource];
		}
		
		return;
	}
	
	BOOL done        = NO;  // Completed read operation
	BOOL waiting     = NO;  // Ran out of data, waiting for more
	BOOL socketEOF   = NO;  // Nothing more to read (end of file)
	NSError *error   = nil; // Error occured
	
	NSUInteger totalBytesReadForCurrentRead = 0;
	
	// 
	// STEP 1 - READ FROM PREBUFFER
	// 
	
	NSUInteger partialReadBufferLength = [partialReadBuffer length];
	
	if (partialReadBufferLength > 0)
	{
		// There are 3 types of read packets:
		// 
		// 1) Read all available data.
		// 2) Read a specific length of data.
		// 3) Read up to a particular terminator.
		
		NSUInteger bytesToCopy;
		
		if (currentRead->term != nil)
		{
			// Read type #3 - read up to a terminator
			
			bytesToCopy = [currentRead readLengthForTermWithPreBuffer:partialReadBuffer found:&done];
		}
		else
		{
			// Read type #1 or #2
			
			bytesToCopy = [currentRead readLengthForNonTermWithHint:partialReadBufferLength];
		}
		
		// Make sure we have enough room in the buffer for our read.
		
		[currentRead ensureCapacityForReadOfLength:bytesToCopy];
		
		// Copy bytes from prebuffer into packet buffer
		
		void *buffer = [currentRead->buffer mutableBytes] + currentRead->startOffset + currentRead->bytesDone;
		
		memcpy(buffer, [partialReadBuffer bytes], bytesToCopy);
		
		// Remove the copied bytes from the partial read buffer
		[partialReadBuffer replaceBytesInRange:NSMakeRange(0, bytesToCopy) withBytes:NULL length:0];
		partialReadBufferLength -= bytesToCopy;
		
		// Update totals
		
		currentRead->bytesDone += bytesToCopy;
		totalBytesReadForCurrentRead += bytesToCopy;
		
		// Check to see if the read operation is done
		
		if (currentRead->readLength > 0)
		{
			// Read type #2 - read a specific length of data
			
			done = (currentRead->bytesDone == currentRead->readLength);
		}
		else if (currentRead->term != nil)
		{
			// Read type #3 - read up to a terminator
			
			// Our 'done' variable was updated via the readLengthForTermWithPreBuffer:found: method
			
			if (!done && currentRead->maxLength > 0)
			{
				// We're not done and there's a set maxLength.
				// Have we reached that maxLength yet?
				
				if (currentRead->bytesDone >= currentRead->maxLength)
				{
					error = [self readMaxedOutError];
				}
			}
		}
		else
		{
			// Read type #1 - read all available data
			// 
			// We're done as soon as we've read all available data.
			// There might still be data in the socket to read,
			// so we're not done yet.
		}
		
	}
	
	// 
	// STEP 2 - READ FROM SOCKET
	// 
	
	if (!done && !error && (estimatedBytesAvailable > 0))
	{
		NSAssert((partialReadBufferLength == 0), @"Invalid logic");
		
		// There are 3 types of read packets:
		// 
		// 1) Read all available data.
		// 2) Read a specific length of data.
		// 3) Read up to a particular terminator.
		
		BOOL readIntoPartialReadBuffer = NO;
		NSUInteger bytesToRead;
		
		if (currentRead->term != nil)
		{
			// Read type #3 - read up to a terminator
			
			bytesToRead = [currentRead readLengthForTermWithHint:estimatedBytesAvailable
			                                     shouldPreBuffer:&readIntoPartialReadBuffer];
		}
		else
		{
			// Read type #1 or #2
			
			bytesToRead = [currentRead readLengthForNonTermWithHint:estimatedBytesAvailable];
		}
		
		// Make sure we have enough room in the buffer for our read.
		// 
		// We are either reading directly into the currentRead->buffer,
		// or we're reading into the temporary partialReadBuffer.
		
		void *buffer;
		
		if (readIntoPartialReadBuffer)
		{
			if (bytesToRead > partialReadBufferLength)
			{
				[partialReadBuffer setLength:bytesToRead];
			}
			
			buffer = [partialReadBuffer mutableBytes];
		}
		else
		{
			[currentRead ensureCapacityForReadOfLength:bytesToRead];
			
			buffer = [currentRead->buffer mutableBytes] + currentRead->startOffset + currentRead->bytesDone;
		}
		
		// Read data into buffer
		
		int socketFD = (socket4FD == SOCKET_NULL) ? socket6FD : socket4FD;
		
		if (bytesToRead > SIZE_MAX) // NSUInteger may be bigger than size_t (read param 3)
		{
			bytesToRead = SIZE_MAX;
		}
		
		size_t bytesRead = 0;
		
		if (flags & kSocketSecure)
		{
			#if TARGET_OS_IPHONE
				
				CFIndex result = CFReadStreamRead(readStream, (UInt8 *)buffer, (CFIndex)bytesToRead);
				
				if (result < 0)
				{
					error = [NSMakeCollectable(CFReadStreamCopyError(readStream)) autorelease];
				}
				else if (result == 0)
				{
					socketEOF = YES;
				}
				else
				{
					waiting = YES;
					bytesRead = (size_t)result;
				}
				
				// We only know how many decrypted bytes were read.
				// The actual number of bytes read was likely more due to the overhead of the encryption.
				// So we reset our bytes available counter, and rely on the next callback to alert us of more data.
				socketFDBytesAvailable = 0;
				
			#else
				
				OSStatus result = SSLRead(sslContext, buffer, (size_t)bytesToRead, &bytesRead);
				LogVerbose(@"read from secure socket = %u", (unsigned)bytesRead);
				
				if (result != noErr)
				{
					bytesRead = 0;
					
					if (result == errSSLWouldBlock)
						waiting = YES;
					else
						error = [self sslError:result];
				}
				
				// Do not modify socketFDBytesAvailable.
				// It will be updated via the SSLReadFunction().
				
			#endif
		}
		else
		{
			ssize_t result = read(socketFD, buffer, (size_t)bytesToRead);
			LogVerbose(@"read from socket = %i", (int)result);
			
			if (result < 0)
			{
				if (errno == EWOULDBLOCK)
					waiting = YES;
				else
					error = [self errnoErrorWithReason:@"Error in read() function"];
				
				socketFDBytesAvailable = 0;
			}
			else if (result == 0)
			{
				socketEOF = YES;
				socketFDBytesAvailable = 0;
			}
			else
			{
				bytesRead = result;
				
				if (socketFDBytesAvailable <= bytesRead)
					socketFDBytesAvailable = 0;
				else
					socketFDBytesAvailable -= bytesRead;
			}
		}
		
		if (bytesRead > 0)
		{
			// Check to see if the read operation is done
			
			if (currentRead->readLength > 0)
			{
				// Read type #2 - read a specific length of data
				
				currentRead->bytesDone += bytesRead;
				totalBytesReadForCurrentRead += bytesRead;
				
				done = (currentRead->bytesDone == currentRead->readLength);
			}
			else if (currentRead->term != nil)
			{
				// Read type #3 - read up to a terminator
				
				if (readIntoPartialReadBuffer)
				{
					// We just read a big chunk of data into the partialReadBuffer.
					// Search for the terminating sequence.
					// 
					// Note: We are depending upon [partialReadBuffer length] to tell us how much data is
					// available in the partialReadBuffer. So we need to be sure this matches how many bytes
					// have actually been read into said buffer.
					
					[partialReadBuffer setLength:bytesRead];
					
					bytesToRead = [currentRead readLengthForTermWithPreBuffer:partialReadBuffer found:&done];
					
					// Ensure there's room on the read packet's buffer
					
					[currentRead ensureCapacityForReadOfLength:bytesToRead];
					
					// Copy bytes from prebuffer into read buffer
					
					void *preBuf = buffer;
					void *readBuf = [currentRead->buffer mutableBytes] + currentRead->startOffset
					                                                   + currentRead->bytesDone;
					
					memcpy(readBuf, preBuf, bytesToRead);
					
					// Remove the copied bytes from the prebuffer
					[partialReadBuffer replaceBytesInRange:NSMakeRange(0, bytesToRead) withBytes:NULL length:0];
					
					// Update totals
					currentRead->bytesDone += bytesToRead;
					totalBytesReadForCurrentRead += bytesToRead;
					
					// Our 'done' variable was updated via the readLengthForTermWithPreBuffer:found: method above
				}
				else
				{
					// We just read a big chunk of data directly into the packet's buffer.
					// We need to move any overflow into the prebuffer.
					
					NSInteger overflow = [currentRead searchForTermAfterPreBuffering:bytesRead];
					
					if (overflow == 0)
					{
						// Perfect match!
						// Every byte we read stays in the read buffer,
						// and the last byte we read was the last byte of the term.
						
						currentRead->bytesDone += bytesRead;
						totalBytesReadForCurrentRead += bytesRead;
						done = YES;
					}
					else if (overflow > 0)
					{
						// The term was found within the data that we read,
						// and there are extra bytes that extend past the end of the term.
						// We need to move these excess bytes out of the read packet and into the prebuffer.
						
						NSInteger underflow = bytesRead - overflow;
						
						// Copy excess data into partialReadBuffer
						void *overflowBuffer = buffer + currentRead->bytesDone + underflow;
						
						[partialReadBuffer appendBytes:overflowBuffer length:overflow];
						
						// Note: The completeCurrentRead method will trim the buffer for us.
						
						currentRead->bytesDone += underflow;
						totalBytesReadForCurrentRead += underflow;
						done = YES;
					}
					else
					{
						// The term was not found within the data that we read.
						
						currentRead->bytesDone += bytesRead;
						totalBytesReadForCurrentRead += bytesRead;
						done = NO;
					}
				}
				
				if (!done && currentRead->maxLength > 0)
				{
					// We're not done and there's a set maxLength.
					// Have we reached that maxLength yet?
					
					if (currentRead->bytesDone >= currentRead->maxLength)
					{
						error = [self readMaxedOutError];
					}
				}
			}
			else
			{
				// Read type #1 - read all available data
				
				currentRead->bytesDone += bytesRead;
				totalBytesReadForCurrentRead += bytesRead;
				done = YES;
			}
			
		} // else (result > 0)
		
	} // if (!done && !maxoutError && socketFDBytesAvailable > 0)
	
	
	if (!done && currentRead->readLength == 0 && currentRead->term == nil)
	{
		// Read type #1 - read all available data
		// 
		// We might arrive here if we read data from the prebuffer but not from the socket.
		
		done = (totalBytesReadForCurrentRead > 0);
	}
	
	// Only one of the following can possibly be true:
	// 
	// - waiting
	// - socketEOF
	// - socketError
	// - maxoutError
	// 
	// They may all be false.
	// One of the above may be true even if done is true.
	// This might be the case if we completed read type #1 via data from the prebuffer.
	
	if (done)
	{
		[self completeCurrentRead];
		
		if (!socketEOF && !error)
		{
			[self maybeDequeueRead];
		}
	}
	else if (totalBytesReadForCurrentRead > 0)
	{
		// We're not done read type #2 or #3 yet, but we have read in some bytes
		
		if (delegateQueue && [delegate respondsToSelector:@selector(socket:didReadPartialDataOfLength:tag:)])
		{
			id theDelegate = delegate;
			GCDAsyncReadPacket *theRead = currentRead;
			
			dispatch_async(delegateQueue, ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[theDelegate socket:self didReadPartialDataOfLength:totalBytesReadForCurrentRead tag:theRead->tag];
				
				[pool release];
			});
		}
	}
	
	// Check for errors
	
	if (waiting)
	{
		// Monitor the socket for readability (if we're not already doing so)
		[self resumeReadSource];
	}
	else if (socketEOF)
	{
		[self doReadEOF];
	}
	else if (error)
	{
		[self closeWithError:error];
	}
	
	// Do not add any code here without first adding return statements in the error cases above.
}

- (void)doReadEOF
{
	LogTrace();
	
	BOOL shouldDisconnect;
	NSError *error = nil;
	
	if ((flags & kStartingReadTLS) || (flags & kStartingWriteTLS))
	{
		// We received an EOF during or prior to startTLS.
		// The SSL/TLS handshake is now impossible, so this is an unrecoverable situation.
		
		shouldDisconnect = YES;
		
		#if !TARGET_OS_IPHONE
			error = [self sslError:errSSLClosedAbort];
		#endif
	}
	else if (config & kAllowHalfDuplexConnection)
	{
		// We just received an EOF (end of file) from the socket's read stream.
		// Query the socket to see if it is still writeable.
		
		int socketFD = (socket4FD == SOCKET_NULL) ? socket6FD : socket4FD;
		
		struct pollfd pfd[1];
		pfd[0].fd = socketFD;
		pfd[0].events = POLLOUT;
		pfd[0].revents = 0;
		
		poll(pfd, 1, 0);
		
		shouldDisconnect = (pfd[0].revents & POLLOUT) ? NO : YES;
	}
	else
	{
		shouldDisconnect = YES;
	}
	
	
	if (shouldDisconnect)
	{
		if (error == nil)
		{
			error = [self connectionClosedError];
		}
		[self closeWithError:error];
	}
	else
	{
		// Notify the delegate
		
		if (delegateQueue && [delegate respondsToSelector:@selector(socketDidCloseReadStream:)])
		{
			id theDelegate = delegate;
			
			dispatch_async(delegateQueue, ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[theDelegate socketDidCloseReadStream:self];
				
				[pool release];
			});
		}
		
		// Suspend the read source (if needed)
		
		[self suspendReadSource];
	}
}

- (void)completeCurrentRead
{
	LogTrace();
	
	NSAssert(currentRead, @"Trying to complete current read when there is no current read.");
	
	
	NSData *result;
	
	if (currentRead->bufferOwner)
	{
		// We created the buffer on behalf of the user.
		// Trim our buffer to be the proper size.
		[currentRead->buffer setLength:currentRead->bytesDone];
		
		result = currentRead->buffer;
	}
	else
	{
		// We did NOT create the buffer.
		// The buffer is owned by the caller.
		// Only trim the buffer if we had to increase its size.
		
		if ([currentRead->buffer length] > currentRead->originalBufferLength)
		{
			NSUInteger readSize = currentRead->startOffset + currentRead->bytesDone;
			NSUInteger origSize = currentRead->originalBufferLength;
			
			NSUInteger buffSize = MAX(readSize, origSize);
			
			[currentRead->buffer setLength:buffSize];
		}
		
		void *buffer = [currentRead->buffer mutableBytes] + currentRead->startOffset;
		
		result = [NSData dataWithBytesNoCopy:buffer length:currentRead->bytesDone freeWhenDone:NO];
	}
	
	if (delegateQueue && [delegate respondsToSelector:@selector(socket:didReadData:withTag:)])
	{
		id theDelegate = delegate;
		GCDAsyncReadPacket *theRead = currentRead;
		
		dispatch_async(delegateQueue, ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[theDelegate socket:self didReadData:result withTag:theRead->tag];
			
			[pool release];
		});
	}
	
	[self endCurrentRead];
}

- (void)endCurrentRead
{
	if (readTimer)
	{
		dispatch_source_cancel(readTimer);
		readTimer = NULL;
	}
	
	[currentRead release];
	currentRead = nil;
}

- (void)setupReadTimerWithTimeout:(NSTimeInterval)timeout
{
	if (timeout >= 0.0)
	{
		readTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, socketQueue);
		
		dispatch_block_t timerEventBlock = ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[self doReadTimeout];
			[pool release];
		};
		dispatch_source_set_event_handler(readTimer, timerEventBlock);
		
		dispatch_source_t theReadTimer = readTimer;
		dispatch_block_t timerCancelBlock = ^{
			LogVerbose(@"dispatch_release(readTimer)");
			dispatch_release(theReadTimer);
		};
		dispatch_source_set_cancel_handler(readTimer, timerCancelBlock);
		
		dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (timeout * NSEC_PER_SEC));
		
		dispatch_source_set_timer(readTimer, tt, DISPATCH_TIME_FOREVER, 0);
		dispatch_resume(readTimer);
	}
}

- (void)doReadTimeout
{
	// This is a little bit tricky.
	// Ideally we'd like to synchronously query the delegate about a timeout extension.
	// But if we do so synchronously we risk a possible deadlock.
	// So instead we have to do so asynchronously, and callback to ourselves from within the delegate block.
	
	flags |= kReadsPaused;
	
	if (delegateQueue && [delegate respondsToSelector:@selector(socket:shouldTimeoutReadWithTag:elapsed:bytesDone:)])
	{
		id theDelegate = delegate;
		GCDAsyncReadPacket *theRead = currentRead;
		
		dispatch_async(delegateQueue, ^{
			NSAutoreleasePool *delegatePool = [[NSAutoreleasePool alloc] init];
			
			NSTimeInterval timeoutExtension = 0.0;
			
			timeoutExtension = [theDelegate socket:self shouldTimeoutReadWithTag:theRead->tag
			                                                             elapsed:theRead->timeout
			                                                           bytesDone:theRead->bytesDone];
			
			dispatch_async(socketQueue, ^{
				NSAutoreleasePool *callbackPool = [[NSAutoreleasePool alloc] init];
				
				[self doReadTimeoutWithExtension:timeoutExtension];
				
				[callbackPool release];
			});
			
			[delegatePool release];
		});
	}
	else
	{
		[self doReadTimeoutWithExtension:0.0];
	}
}

- (void)doReadTimeoutWithExtension:(NSTimeInterval)timeoutExtension
{
	if (currentRead)
	{
		if (timeoutExtension > 0.0)
		{
			currentRead->timeout += timeoutExtension;
			
			// Reschedule the timer
			dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (timeoutExtension * NSEC_PER_SEC));
			dispatch_source_set_timer(readTimer, tt, DISPATCH_TIME_FOREVER, 0);
			
			// Unpause reads, and continue
			flags &= ~kReadsPaused;
			[self doReadData];
		}
		else
		{
			[self closeWithError:[self readTimeoutError]];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	if (data == nil || [data length] == 0) return;
	
	LogTrace();
	
	GCDAsyncWritePacket *packet = [[GCDAsyncWritePacket alloc] initWithData:data timeout:timeout tag:tag];
	
	dispatch_async(socketQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (!(flags & kForbidReadsWrites))
		{
			[writeQueue addObject:packet];
			[self maybeDequeueWrite];
		}
		
		[pool release];
	});
	
	// Do not rely on the block being run in order to release the packet,
	// as the queue might get released without the block completing.
	[packet release];
}

/**
 * Conditionally starts a new write.
 * 
 * It is called when:
 * - a user requests a write
 * - after a write request has finished (to handle the next request)
 * - immediately after the socket opens to handle any pending requests
 * 
 * This method also handles auto-disconnect post read/write completion.
**/
- (void)maybeDequeueWrite
{
	LogTrace();
	NSAssert(dispatch_get_current_queue() == socketQueue, @"Must be dispatched on socketQueue");
	
	
	// If we're not currently processing a write AND we have an available write stream
	if ((currentWrite == nil) && (flags & kConnected))
	{
		if ([writeQueue count] > 0)
		{
			// Dequeue the next object in the write queue
			currentWrite = [[writeQueue objectAtIndex:0] retain];
			[writeQueue removeObjectAtIndex:0];
			
			
			if ([currentWrite isKindOfClass:[GCDAsyncSpecialPacket class]])
			{
				// Attempt to start TLS
				flags |= kStartingWriteTLS;
				
				// This method won't do anything unless both kStartingReadTLS and kStartingWriteTLS are set
				[self maybeStartTLS];
			}
			else
			{
				// Setup write timer (if needed)
				[self setupWriteTimerWithTimeout:currentWrite->timeout];
				
				// Immediately write, if possible
				[self doWriteData];
			}
		}
		else if (flags & kDisconnectAfterWrites)
		{
			if (flags & kDisconnectAfterReads)
			{
				if (([readQueue count] == 0) && (currentRead == nil))
				{
					[self closeWithError:nil];
				}
			}
			else
			{
				[self closeWithError:nil];
			}
		}
	}
}

- (void)doWriteData
{
	LogTrace();
	
	// This method is called by the writeSource via the socketQueue
	
	if ((currentWrite == nil) || (flags & kWritesPaused))
	{
		// Unable to write at this time
		// 
		// If the writeSource is firing, we need to pause it
		// or else it will continue to fire over and over again.
		
		if (flags & kSocketCanAcceptBytes)
		{
			[self suspendWriteSource];
		}
		return;
	}
	
	if (!(flags & kSocketCanAcceptBytes))
	{
		// Unable to write.
		// 
		// Need to wait for writeSource to fire and notify us of
		// available space in the socket's internal write buffer.
		
		[self resumeWriteSource];
		return;
	}
	
	if (flags & kStartingWriteTLS)
	{
		// The writeQueue is waiting for SSL/TLS to complete.
		
		if (flags & kStartingReadTLS)
		{
			#if !TARGET_OS_IPHONE
			
				// We are in the process of a SSL Handshake.
				// We were waiting for available space in the socket's internal OS buffer to continue writing.
			
				[self continueSSLHandshake];
			
			#endif
		}
		else
		{
			// We are still waiting for the readQueue to drain and start the SSL/TLS process.
			// We now know data we can write to the socket,
			// so we suspend the write source or else it will continue to fire nonstop.
			
			[self suspendWriteSource];
		}
		
		return;
	}
	
	// Note: This method is not called if theCurrentWrite is an GCDAsyncSpecialPacket (startTLS packet)
	
	NSUInteger totalBytesWritten = 0;
	
	BOOL done      = NO;
	BOOL waiting   = NO;
	NSError *error = nil;
	
	while (!done && !waiting && !error)
	{
		// Figure out what to write
		NSUInteger bytesToWrite = [currentWrite->buffer length] - currentWrite->bytesDone;
		
		void *buffer = (void *)[currentWrite->buffer bytes] + currentWrite->bytesDone;
		
		// Figure out what to write to
		int socketFD = (socket4FD == SOCKET_NULL) ? socket6FD : socket4FD;
		
		// Write
		
		if (bytesToWrite > SIZE_MAX) // NSUInteger may be bigger than size_t (write param 3)
		{
			bytesToWrite = SIZE_MAX;
		}
		
		size_t bytesWritten = 0;
		
		if (flags & kSocketSecure)
		{
			#if TARGET_OS_IPHONE
				
				CFIndex result = CFWriteStreamWrite(writeStream, (UInt8 *)buffer, (CFIndex)bytesToWrite);
				
				if (result < 0)
				{
					error = [NSMakeCollectable(CFWriteStreamCopyError(writeStream)) autorelease];
				}
				else
				{
					waiting = YES;
					bytesWritten = (size_t)result;
				}
				
				flags &= ~kSocketCanAcceptBytes;
				
			#else
			
				OSStatus result = SSLWrite(sslContext, buffer, bytesToWrite, &bytesWritten);
				LogVerbose(@"wrote to secure socket = %u", (unsigned)bytesWritten);
				
				if (result != noErr)
				{
					if (result == errSSLWouldBlock)
						waiting = YES;
					else
						error = [self sslError:result];
				}
			
			#endif
		}
		else
		{
			ssize_t result = write(socketFD, buffer, (size_t)bytesToWrite);
			LogVerbose(@"wrote to socket = %i", (int)result);
			
			// Check results
			if (result < 0)
			{
				if (errno == EWOULDBLOCK)
					waiting = YES;
				else
					error = [self errnoErrorWithReason:@"Error in write() function"];
				
				flags &= ~kSocketCanAcceptBytes;
			}
			else if (result == 0)
			{
				waiting = YES;
				flags &= ~kSocketCanAcceptBytes;
			}
			else
			{
				bytesWritten = result;
			}
		}
		
		if (bytesWritten > 0)
		{
			// Update total amount read for the current write
			currentWrite->bytesDone += bytesWritten;
			
			// Update total amount written in this method invocation
			totalBytesWritten += bytesWritten;
			
			// Is packet done?
			done = (currentWrite->bytesDone == [currentWrite->buffer length]);
			
			// If socket wrote fewer bytes than requested,
			// then it is likely full and we will simply await another callback.
			if (bytesWritten < bytesToWrite)
			{
				waiting = YES;
				flags &= ~kSocketCanAcceptBytes;
			}
		}
	}
	
	if (done)
	{
		[self completeCurrentWrite];
		[self maybeDequeueWrite];
	}
	else if (totalBytesWritten > 0)
	{
		// We're not done with the entire write, but we have written some bytes
		
		if (delegateQueue && [delegate respondsToSelector:@selector(socket:didWritePartialDataOfLength:tag:)])
		{
			id theDelegate = delegate;
			GCDAsyncWritePacket *theWrite = currentWrite;
			
			dispatch_async(delegateQueue, ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[theDelegate socket:self didWritePartialDataOfLength:totalBytesWritten tag:theWrite->tag];
				
				[pool release];
			});
		}
	}
	
	// Check for errors
	
	if (waiting)
	{
		[self resumeWriteSource];
	}
	else if (error)
	{
		[self closeWithError:[self errnoErrorWithReason:@"Error in write() function"]];
	}
	
	// Do not add any code here without first adding return statements in the error cases above.
}

- (void)completeCurrentWrite
{
	LogTrace();
	
	NSAssert(currentWrite, @"Trying to complete current write when there is no current write.");
	
	
	if (delegateQueue && [delegate respondsToSelector:@selector(socket:didWriteDataWithTag:)])
	{
		id theDelegate = delegate;
		GCDAsyncWritePacket *theWrite = currentWrite;
		
		dispatch_async(delegateQueue, ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			[theDelegate socket:self didWriteDataWithTag:theWrite->tag];
			
			[pool release];
		});
	}
	
	[self endCurrentWrite];
}

- (void)endCurrentWrite
{
	if (writeTimer)
	{
		dispatch_source_cancel(writeTimer);
		writeTimer = NULL;
	}
	
	[currentWrite release];
	currentWrite = nil;
}

- (void)setupWriteTimerWithTimeout:(NSTimeInterval)timeout
{
	if (timeout >= 0.0)
	{
		writeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, socketQueue);
		
		dispatch_block_t timerEventBlock = ^{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[self doWriteTimeout];
			[pool release];
		};
		dispatch_source_set_event_handler(writeTimer, timerEventBlock);
		
		dispatch_source_t theWriteTimer = writeTimer;
		dispatch_block_t timerCancelBlock = ^{
			LogVerbose(@"dispatch_release(writeTimer)");
			dispatch_release(theWriteTimer);
		};
		dispatch_source_set_cancel_handler(writeTimer, timerCancelBlock);
		
		dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (timeout * NSEC_PER_SEC));
		
		dispatch_source_set_timer(writeTimer, tt, DISPATCH_TIME_FOREVER, 0);
		dispatch_resume(writeTimer);
	}
}

- (void)doWriteTimeout
{
	// This is a little bit tricky.
	// Ideally we'd like to synchronously query the delegate about a timeout extension.
	// But if we do so synchronously we risk a possible deadlock.
	// So instead we have to do so asynchronously, and callback to ourselves from within the delegate block.
	
	flags |= kWritesPaused;
	
	if (delegateQueue && [delegate respondsToSelector:@selector(socket:shouldTimeoutWriteWithTag:elapsed:bytesDone:)])
	{
		id theDelegate = delegate;
		GCDAsyncWritePacket *theWrite = currentWrite;
		
		dispatch_async(delegateQueue, ^{
			NSAutoreleasePool *delegatePool = [[NSAutoreleasePool alloc] init];
			
			NSTimeInterval timeoutExtension = 0.0;
			
			timeoutExtension = [theDelegate socket:self shouldTimeoutWriteWithTag:theWrite->tag
			                                                              elapsed:theWrite->timeout
			                                                            bytesDone:theWrite->bytesDone];
			
			dispatch_async(socketQueue, ^{
				NSAutoreleasePool *callbackPool = [[NSAutoreleasePool alloc] init];
				
				[self doWriteTimeoutWithExtension:timeoutExtension];
				
				[callbackPool release];
			});
			
			[delegatePool release];
		});
	}
	else
	{
		[self doWriteTimeoutWithExtension:0.0];
	}
}

- (void)doWriteTimeoutWithExtension:(NSTimeInterval)timeoutExtension
{
	if (currentWrite)
	{
		if (timeoutExtension > 0.0)
		{
			currentWrite->timeout += timeoutExtension;
			
			// Reschedule the timer
			dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, (timeoutExtension * NSEC_PER_SEC));
			dispatch_source_set_timer(writeTimer, tt, DISPATCH_TIME_FOREVER, 0);
			
			// Unpause writes, and continue
			flags &= ~kWritesPaused;
			[self doWriteData];
		}
		else
		{
			[self closeWithError:[self writeTimeoutError]];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Security
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)startTLS:(NSDictionary *)tlsSettings
{
	LogTrace();
	
	if (tlsSettings == nil)
    {
        // Passing nil/NULL to CFReadStreamSetProperty will appear to work the same as passing an empty dictionary,
        // but causes problems if we later try to fetch the remote host's certificate.
        // 
        // To be exact, it causes the following to return NULL instead of the normal result:
        // CFReadStreamCopyProperty(readStream, kCFStreamPropertySSLPeerCertificates)
        // 
        // So we use an empty dictionary instead, which works perfectly.
        
        tlsSettings = [NSDictionary dictionary];
    }
	
	GCDAsyncSpecialPacket *packet = [[GCDAsyncSpecialPacket alloc] initWithTLSSettings:tlsSettings];
	
	dispatch_async(socketQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[readQueue addObject:packet];
		[writeQueue addObject:packet];
		
		[self maybeDequeueRead];
		[self maybeDequeueWrite];
		
		[pool release];
	});
	
	[packet release];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Security - Mac OS X
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if !TARGET_OS_IPHONE

- (OSStatus)sslReadWithBuffer:(void *)buffer length:(size_t *)bufferLength
{
	LogTrace2(@"sslReadWithBuffer:%p length:%lu", buffer, (unsigned long)*bufferLength);
	
	if ((socketFDBytesAvailable == 0) && ([sslReadBuffer length] == 0))
	{
		LogVerbose(@"%@ - No data available to read...", THIS_METHOD);
		
		// No data available to read.
		// 
		// Need to wait for readSource to fire and notify us of
		// available data in the socket's internal read buffer.
		
		[self resumeReadSource];
		
		*bufferLength = 0;
		return errSSLWouldBlock;
	}
	
	size_t totalBytesLeft = *bufferLength;
	size_t totalBytesRead = 0;
	
	BOOL done = NO;
	BOOL socketError = NO;
	
	// 
	// STEP 1 : READ FROM SSL PRE BUFFER
	// 
	
	NSUInteger sslReadBufferLength = [sslReadBuffer length];
	
	if (sslReadBufferLength > 0)
	{
		size_t bytesToCopy = (size_t)((sslReadBufferLength > totalBytesLeft) ? totalBytesLeft : sslReadBufferLength);
		
		LogVerbose(@"Copying %u bytes from sslReadBuffer", (unsigned)bytesToCopy);
		
		memcpy(buffer, [sslReadBuffer mutableBytes], bytesToCopy);
		
		[sslReadBuffer replaceBytesInRange:NSMakeRange(0, bytesToCopy) withBytes:NULL length:0];
		
		LogVerbose(@"sslReadBuffer.length = %lu", (unsigned long)[sslReadBuffer length]);
		
		totalBytesLeft -= bytesToCopy;
		totalBytesRead += bytesToCopy;
		
		done = (totalBytesLeft == 0);
		
		if (done) LogVerbose(@"SSLRead complete");
	}
	
	// 
	// STEP 2 : READ FROM SOCKET
	// 
	
	if (!done && (socketFDBytesAvailable > 0))
	{
		int socketFD = (socket6FD == SOCKET_NULL) ? socket4FD : socket6FD;
		
		BOOL readIntoPreBuffer;
		size_t bytesToRead;
		void *buf;
		
		if (socketFDBytesAvailable > totalBytesLeft)
		{
			// Read all available data from socket into sslReadBuffer.
			// Then copy requested amount into dataBuffer.
			
			if ([sslReadBuffer length] < socketFDBytesAvailable)
			{
				[sslReadBuffer setLength:socketFDBytesAvailable];
			}
			
			LogVerbose(@"Reading into sslReadBuffer...");
			
			readIntoPreBuffer = YES;
			bytesToRead = (size_t)socketFDBytesAvailable;
			buf = [sslReadBuffer mutableBytes];
		}
		else
		{
			// Read available data from socket directly into dataBuffer.
			
			readIntoPreBuffer = NO;
			bytesToRead = totalBytesLeft;
			buf = buffer + totalBytesRead;
		}
		
		ssize_t result = read(socketFD, buf, bytesToRead);
		LogVerbose(@"read from socket = %i", (int)result);
		
		if (result < 0)
		{
			LogVerbose(@"read errno = %i", errno);
			
			if (errno != EWOULDBLOCK)
			{
				socketError = YES;
			}
			
			socketFDBytesAvailable = 0;
			
			if (readIntoPreBuffer)
			{
				[sslReadBuffer setLength:0];
			}
		}
		else if (result == 0)
		{
			socketError = YES;
			socketFDBytesAvailable = 0;
			
			if (readIntoPreBuffer)
			{
				[sslReadBuffer setLength:0];
			}
		}
		else
		{
			ssize_t bytesReadFromSocket = result;
			
			if (socketFDBytesAvailable > bytesReadFromSocket)
				socketFDBytesAvailable -= bytesReadFromSocket;
			else
				socketFDBytesAvailable = 0;
			
			if (readIntoPreBuffer)
			{
				size_t bytesToCopy = MIN(totalBytesLeft, bytesReadFromSocket);
				
				LogVerbose(@"Copying %u bytes from sslReadBuffer", (unsigned)bytesToCopy);
				
				memcpy(buffer + totalBytesRead, [sslReadBuffer bytes], bytesToCopy);
				
				[sslReadBuffer setLength:bytesReadFromSocket];
				[sslReadBuffer replaceBytesInRange:NSMakeRange(0, bytesToCopy) withBytes:NULL length:0];
				
				totalBytesLeft -= bytesToCopy;
				totalBytesRead += bytesToCopy;
				
				LogVerbose(@"sslReadBuffer.length = %lu", (unsigned long)[sslReadBuffer length]);
			}
			else
			{
				totalBytesLeft -= bytesReadFromSocket;
				totalBytesRead += bytesReadFromSocket;
			}
			
			done = (totalBytesLeft == 0);
			
			if (done) LogVerbose(@"SSLRead complete");
		}
	}
	
	*bufferLength = totalBytesRead;
	
	if (done)
		return noErr;
	
	if (socketError)
		return errSSLClosedAbort;
	
	return errSSLWouldBlock;
}

- (OSStatus)sslWriteWithBuffer:(const void *)buffer length:(size_t *)bufferLength
{
	LogTrace2(@"sslWriteWithBuffer:length: %lu", (unsigned long)*bufferLength);
	
	if (!(flags & kSocketCanAcceptBytes))
	{
		// Unable to write.
		// 
		// Need to wait for writeSource to fire and notify us of
		// available space in the socket's internal write buffer.
		
		[self resumeWriteSource];
		
		*bufferLength = 0;
		return errSSLWouldBlock;
	}
	
	size_t bytesToWrite = *bufferLength;
	size_t bytesWritten = 0;
	
	BOOL done = NO;
	BOOL socketError = NO;
	
	int socketFD = (socket4FD == SOCKET_NULL) ? socket6FD : socket4FD;
	
	ssize_t result = write(socketFD, buffer, bytesToWrite);
	LogVerbose(@"wrote to socket = %i", (int)result);
	
	if (result < 0)
	{
		if (errno != EWOULDBLOCK)
		{
			socketError = YES;
		}
		
		flags &= ~kSocketCanAcceptBytes;
	}
	else if (result == 0)
	{
		flags &= ~kSocketCanAcceptBytes;
	}
	else
	{
		bytesWritten = result;
		done = (bytesToWrite == bytesWritten);
		
		if (done) LogVerbose(@"SSLWrite complete");
	}
	
	*bufferLength = bytesWritten;
	
	if (done)
		return noErr;
	
	if (socketError)
		return errSSLClosedAbort;
	
	return errSSLWouldBlock;
}

OSStatus SSLReadFunction(SSLConnectionRef connection, void *data, size_t *dataLength)
{
	GCDAsyncSocket *asyncSocket = (GCDAsyncSocket *)connection;
	
	NSCAssert(dispatch_get_current_queue() == asyncSocket->socketQueue, @"What the deuce?");
	
	return [asyncSocket sslReadWithBuffer:data length:dataLength];
}

OSStatus SSLWriteFunction(SSLConnectionRef connection, const void *data, size_t *dataLength)
{
	GCDAsyncSocket *asyncSocket = (GCDAsyncSocket *)connection;
	
	NSCAssert(dispatch_get_current_queue() == asyncSocket->socketQueue, @"What the deuce?");
	
	return [asyncSocket sslWriteWithBuffer:data length:dataLength];
}

- (void)maybeStartTLS
{
	LogTrace();
	
	// We can't start TLS until:
	// - All queued reads prior to the user calling startTLS are complete
	// - All queued writes prior to the user calling startTLS are complete
	// 
	// We'll know these conditions are met when both kStartingReadTLS and kStartingWriteTLS are set
	
	if ((flags & kStartingReadTLS) && (flags & kStartingWriteTLS))
	{
		LogVerbose(@"Starting TLS...");
		
		OSStatus status;
		
		GCDAsyncSpecialPacket *tlsPacket = (GCDAsyncSpecialPacket *)currentRead;
		NSDictionary *tlsSettings = tlsPacket->tlsSettings;
		
		// Create SSLContext, and setup IO callbacks and connection ref
		
		BOOL isServer = [[tlsSettings objectForKey:(NSString *)kCFStreamSSLIsServer] boolValue];
		
		status = SSLNewContext(isServer, &sslContext);
		if (status != noErr)
		{
			[self closeWithError:[self otherError:@"Error in SSLNewContext"]];
			return;
		}
		
		status = SSLSetIOFuncs(sslContext, &SSLReadFunction, &SSLWriteFunction);
		if (status != noErr)
		{
			[self closeWithError:[self otherError:@"Error in SSLSetIOFuncs"]];
			return;
		}
		
		status = SSLSetConnection(sslContext, (SSLConnectionRef)self);
		if (status != noErr)
		{
			[self closeWithError:[self otherError:@"Error in SSLSetConnection"]];
			return;
		}
		
		// Configure SSLContext from given settings
		// 
		// Checklist:
		// 1. kCFStreamSSLPeerName
		// 2. kCFStreamSSLAllowsAnyRoot
		// 3. kCFStreamSSLAllowsExpiredRoots
		// 4. kCFStreamSSLValidatesCertificateChain
		// 5. kCFStreamSSLAllowsExpiredCertificates
		// 6. kCFStreamSSLCertificates
		// 7. kCFStreamSSLLevel
		
		id value;
		
		// 1. kCFStreamSSLPeerName
		
		value = [tlsSettings objectForKey:(NSString *)kCFStreamSSLPeerName];
		if (value)
		{
			NSString *peerName = (NSString *)value;
			
			const char *peer = [peerName UTF8String];
			size_t peerLen = strlen(peer);
			
			status = SSLSetPeerDomainName(sslContext, peer, peerLen);
			if (status != noErr)
			{
				[self closeWithError:[self otherError:@"Error in SSLSetPeerDomainName"]];
				return;
			}
		}
		
		// 2. kCFStreamSSLAllowsAnyRoot
		
		value = [tlsSettings objectForKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
		if (value)
		{
			BOOL allowsAnyRoot = [value boolValue];
			
			status = SSLSetAllowsAnyRoot(sslContext, allowsAnyRoot);
			if (status != noErr)
			{
				[self closeWithError:[self otherError:@"Error in SSLSetAllowsAnyRoot"]];
				return;
			}
		}
		
		// 3. kCFStreamSSLAllowsExpiredRoots
		
		value = [tlsSettings objectForKey:(NSString *)kCFStreamSSLAllowsExpiredRoots];
		if (value)
		{
			BOOL allowsExpiredRoots = [value boolValue];
			
			status = SSLSetAllowsExpiredRoots(sslContext, allowsExpiredRoots);
			if (status != noErr)
			{
				[self closeWithError:[self otherError:@"Error in SSLSetAllowsExpiredRoots"]];
				return;
			}
		}
		
		// 4. kCFStreamSSLValidatesCertificateChain
		
		value = [tlsSettings objectForKey:(NSString *)kCFStreamSSLValidatesCertificateChain];
		if (value)
		{
			BOOL validatesCertChain = [value boolValue];
			
			status = SSLSetEnableCertVerify(sslContext, validatesCertChain);
			if (status != noErr)
			{
				[self closeWithError:[self otherError:@"Error in SSLSetEnableCertVerify"]];
				return;
			}
		}
		
		// 5. kCFStreamSSLAllowsExpiredCertificates
		
		value = [tlsSettings objectForKey:(NSString *)kCFStreamSSLAllowsExpiredCertificates];
		if (value)
		{
			BOOL allowsExpiredCerts = [value boolValue];
			
			status = SSLSetAllowsExpiredCerts(sslContext, allowsExpiredCerts);
			if (status != noErr)
			{
				[self closeWithError:[self otherError:@"Error in SSLSetAllowsExpiredCerts"]];
				return;
			}
		}
		
		// 6. kCFStreamSSLCertificates
		
		value = [tlsSettings objectForKey:(NSString *)kCFStreamSSLCertificates];
		if (value)
		{
			CFArrayRef certs = (CFArrayRef)value;
			
			status = SSLSetCertificate(sslContext, certs);
			if (status != noErr)
			{
				[self closeWithError:[self otherError:@"Error in SSLSetCertificate"]];
				return;
			}
		}
		
		// 7. kCFStreamSSLLevel
		
		value = [tlsSettings objectForKey:(NSString *)kCFStreamSSLLevel];
		if (value)
		{
			NSString *sslLevel = (NSString *)value;
			
			if ([sslLevel isEqualToString:(NSString *)kCFStreamSocketSecurityLevelSSLv2])
			{
				// kCFStreamSocketSecurityLevelSSLv2:
				// 
				// Specifies that SSL version 2 be set as the security protocol.
				
				SSLSetProtocolVersionEnabled(sslContext, kSSLProtocolAll, NO);
				SSLSetProtocolVersionEnabled(sslContext, kSSLProtocol2,   YES);
			}
			else if ([sslLevel isEqualToString:(NSString *)kCFStreamSocketSecurityLevelSSLv3])
			{
				// kCFStreamSocketSecurityLevelSSLv3:
				// 
				// Specifies that SSL version 3 be set as the security protocol.
				// If SSL version 3 is not available, specifies that SSL version 2 be set as the security protocol.
				
				SSLSetProtocolVersionEnabled(sslContext, kSSLProtocolAll, NO);
				SSLSetProtocolVersionEnabled(sslContext, kSSLProtocol2,   YES);
				SSLSetProtocolVersionEnabled(sslContext, kSSLProtocol3,   YES);
			}
			else if ([sslLevel isEqualToString:(NSString *)kCFStreamSocketSecurityLevelTLSv1])
			{
				// kCFStreamSocketSecurityLevelTLSv1:
				// 
				// Specifies that TLS version 1 be set as the security protocol.
				
				SSLSetProtocolVersionEnabled(sslContext, kSSLProtocolAll, NO);
				SSLSetProtocolVersionEnabled(sslContext, kTLSProtocol1,   YES);
			}
			else if ([sslLevel isEqualToString:(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL])
			{
				// kCFStreamSocketSecurityLevelNegotiatedSSL:
				// 
				// Specifies that the highest level security protocol that can be negotiated be used.
				
				SSLSetProtocolVersionEnabled(sslContext, kSSLProtocolAll, YES);
			}
		}
		
		// Setup the sslReadBuffer
		// 
		// If there is any data in the partialReadBuffer,
		// this needs to be moved into the sslReadBuffer,
		// as this data is now part of the secure read stream.
		
		sslReadBuffer = [[NSMutableData alloc] init];
		
		if ([partialReadBuffer length] > 0)
		{
			[sslReadBuffer appendData:partialReadBuffer];
			[partialReadBuffer setLength:0];
		}
		
		// Start the SSL Handshake process
		
		[self continueSSLHandshake];
	}
}

- (void)continueSSLHandshake
{
	LogTrace();
	
	// If the return value is noErr, the session is ready for normal secure communication.
	// If the return value is errSSLWouldBlock, the SSLHandshake function must be called again.
	// Otherwise, the return value indicates an error code.
	
	OSStatus status = SSLHandshake(sslContext);
	
	if (status == noErr)
	{
		LogVerbose(@"SSLHandshake complete");
		
		flags &= ~kStartingReadTLS;
		flags &= ~kStartingWriteTLS;
		
		flags |=  kSocketSecure;
		
		if (delegateQueue && [delegate respondsToSelector:@selector(socketDidSecure:)])
		{
			id theDelegate = delegate;
			
			dispatch_async(delegateQueue, ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[theDelegate socketDidSecure:self];
				
				[pool release];
			});
		}
		
		[self endCurrentRead];
		[self endCurrentWrite];
		
		[self maybeDequeueRead];
		[self maybeDequeueWrite];
	}
	else if (status == errSSLWouldBlock)
	{
		LogVerbose(@"SSLHandshake continues...");
		
		// Handshake continues...
		// 
		// This method will be called again from doReadData or doWriteData.
	}
	else
	{
		[self closeWithError:[self sslError:status]];
	}
}

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Security - iOS
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if TARGET_OS_IPHONE

+ (void)startHandshakeThreadIfNeeded
{
	static dispatch_once_t predicate;
	
	dispatch_block_t onceBlock = ^{
		
		sslHandshakeThread = [[NSThread alloc] initWithTarget:self
		                                             selector:@selector(sslHandshakeThread)
		                                               object:nil];
		[sslHandshakeThread start];
	};
	dispatch_once(&predicate, onceBlock);
}

+ (void)sslHandshakeThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	LogInfo(@"SSLHandshakeThread: Started");
	
	// We can't run the run loop unless it has an associated input source or a timer.
	// So we'll just create a timer that will never fire - unless the server runs for 10,000 years.
	[NSTimer scheduledTimerWithTimeInterval:DBL_MAX target:self selector:@selector(ignore:) userInfo:nil repeats:NO];
	
	[[NSRunLoop currentRunLoop] run];
	
	LogInfo(@"SSLHandshakeThread: Stopped");
	
	[pool release];
}

+ (void)addHandshakeListener:(GCDAsyncSocket *)asyncSocket
{
	LogTrace();
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	
	if (asyncSocket->readStream)
		CFReadStreamScheduleWithRunLoop(asyncSocket->readStream, runLoop, kCFRunLoopDefaultMode);
	
	if (asyncSocket->writeStream)
		CFWriteStreamScheduleWithRunLoop(asyncSocket->writeStream, runLoop, kCFRunLoopDefaultMode);
}

+ (void)removeHandshakeListener:(GCDAsyncSocket *)asyncSocket
{
	LogTrace();
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	
	if (asyncSocket->readStream)
		CFReadStreamUnscheduleFromRunLoop(asyncSocket->readStream, runLoop, kCFRunLoopDefaultMode);
	
	if (asyncSocket->writeStream)
		CFWriteStreamUnscheduleFromRunLoop(asyncSocket->writeStream, runLoop, kCFRunLoopDefaultMode);
}

- (void)finishSSLHandshake
{
	LogTrace();
	
	if ((flags & kStartingReadTLS) && (flags & kStartingWriteTLS))
	{
		flags &= ~kStartingReadTLS;
		flags &= ~kStartingWriteTLS;
		
		flags |= kSocketSecure;
		
		if (delegateQueue && [delegate respondsToSelector:@selector(socketDidSecure:)])
		{
			id theDelegate = delegate;
		
			dispatch_async(delegateQueue, ^{
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				
				[theDelegate socketDidSecure:self];
				
				[pool release];
			});
		}
		
		[self endCurrentRead];
		[self endCurrentWrite];
		
		[self maybeDequeueRead];
		[self maybeDequeueWrite];
		
		[self resumeReadSource];
		[self resumeWriteSource];
	}
}

- (void)abortSSLHandshake:(NSError *)error
{
	LogTrace();
	
	if ((flags & kStartingReadTLS) && (flags & kStartingWriteTLS))
	{
		flags &= ~kStartingReadTLS;
		flags &= ~kStartingWriteTLS;
		
		[self closeWithError:error];
	}
}

static void CFReadStreamCallback (CFReadStreamRef stream, CFStreamEventType type, void *pInfo)
{
	GCDAsyncSocket *asyncSocket = [(GCDAsyncSocket *)pInfo retain];
	
	switch(type)
	{
		case kCFStreamEventHasBytesAvailable:
		{
			dispatch_async(asyncSocket->socketQueue, ^{
				NSAutoreleasePool *blockPool = [[NSAutoreleasePool alloc] init];
				
				[asyncSocket finishSSLHandshake];
				
				[blockPool release];
			});
			
			break;
		}
		default:
		{
			NSError *error = NSMakeCollectable(CFReadStreamCopyError(stream));
			
			dispatch_async(asyncSocket->socketQueue, ^{
				NSAutoreleasePool *blockPool = [[NSAutoreleasePool alloc] init];
				
				[asyncSocket abortSSLHandshake:error];
				
				[blockPool release];
			});
			
			[error release];
			break;
		}
	}
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	
	CFReadStreamUnscheduleFromRunLoop(asyncSocket->readStream, runLoop, kCFRunLoopDefaultMode);
	CFReadStreamSetClient(asyncSocket->readStream, 0, NULL, NULL);
	
	CFWriteStreamUnscheduleFromRunLoop(asyncSocket->writeStream, runLoop, kCFRunLoopDefaultMode);
	CFWriteStreamSetClient(asyncSocket->writeStream, 0, NULL, NULL);
	
	[asyncSocket release];
}

static void CFWriteStreamCallback (CFWriteStreamRef stream, CFStreamEventType type, void *pInfo)
{
	GCDAsyncSocket *asyncSocket = [(GCDAsyncSocket *)pInfo retain];
	
	switch(type)
	{
		case kCFStreamEventCanAcceptBytes:
		{
			dispatch_async(asyncSocket->socketQueue, ^{
				NSAutoreleasePool *blockPool = [[NSAutoreleasePool alloc] init];
				
				[asyncSocket finishSSLHandshake];
				
				[blockPool release];
			});
			
			break;
		}
		default:
		{
			NSError *error = NSMakeCollectable(CFWriteStreamCopyError(stream));
			
			dispatch_async(asyncSocket->socketQueue, ^{
				NSAutoreleasePool *blockPool = [[NSAutoreleasePool alloc] init];
				
				[asyncSocket abortSSLHandshake:error];
				
				[blockPool release];
			});
			
			[error release];
			break;
		}
	}
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	
	CFReadStreamUnscheduleFromRunLoop(asyncSocket->readStream, runLoop, kCFRunLoopDefaultMode);
	CFReadStreamSetClient(asyncSocket->readStream, 0, NULL, NULL);
	
	CFWriteStreamUnscheduleFromRunLoop(asyncSocket->writeStream, runLoop, kCFRunLoopDefaultMode);
	CFWriteStreamSetClient(asyncSocket->writeStream, 0, NULL, NULL);
	
	[asyncSocket release];
}

- (BOOL)createReadAndWriteStream
{
	NSAssert((readStream == NULL && writeStream == NULL), @"Read/Write stream not null");
	
	int socketFD = (socket6FD == SOCKET_NULL) ? socket4FD : socket6FD;
	
	if (socketFD == SOCKET_NULL)
	{
		return NO;
	}
	
	LogVerbose(@"Creating read and write stream...");
	
	CFStreamCreatePairWithSocket(NULL, (CFSocketNativeHandle)socketFD, &readStream, &writeStream);
	
	// The kCFStreamPropertyShouldCloseNativeSocket property should be false by default (for our case).
	// But let's not take any chances.
	
	if (readStream)
		CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanFalse);
	if (writeStream)
		CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanFalse);
	
	if ((readStream == NULL) || (writeStream == NULL))
	{
		LogWarn(@"Unable to create read and write stream...");
		
		if (readStream)
		{
			CFReadStreamClose(readStream);
			CFRelease(readStream);
			readStream = NULL;
		}
		if (writeStream)
		{
			CFWriteStreamClose(writeStream);
			CFRelease(writeStream);
			writeStream = NULL;
		}
		
		return NO;
	}
	
	return YES;
}

- (void)maybeStartTLS
{
	LogTrace();
	
	// We can't start TLS until:
	// - All queued reads prior to the user calling startTLS are complete
	// - All queued writes prior to the user calling startTLS are complete
	// 
	// We'll know these conditions are met when both kStartingReadTLS and kStartingWriteTLS are set
	
	if ((flags & kStartingReadTLS) && (flags & kStartingWriteTLS))
	{
		LogVerbose(@"Starting TLS...");
		
		if ([partialReadBuffer length] > 0)
		{
			NSString *msg = @"Invalid TLS transition. Handshake has already been read from socket.";
			
			[self closeWithError:[self otherError:msg]];
			return;
		}
		
		[self suspendReadSource];
		[self suspendWriteSource];
		
		socketFDBytesAvailable = 0;
		flags &= ~kSocketCanAcceptBytes;
		
		if (readStream == NULL || writeStream == NULL)
		{
			if (![self createReadAndWriteStream])
			{
				[self closeWithError:[self otherError:@"Error in CFStreamCreatePairWithSocket"]];
				return;
			}
		}
		
		streamContext.version = 0;
		streamContext.info = self;
		streamContext.retain = nil;
		streamContext.release = nil;
		streamContext.copyDescription = nil;
		
		CFOptionFlags readStreamEvents = kCFStreamEventHasBytesAvailable |
		                                 kCFStreamEventErrorOccurred     |
		                                 kCFStreamEventEndEncountered    ;
		
		if (!CFReadStreamSetClient(readStream, readStreamEvents, &CFReadStreamCallback, &streamContext))
		{
			[self closeWithError:[self otherError:@"Error in CFReadStreamSetClient"]];
			return;
		}
		
		CFOptionFlags writeStreamEvents = kCFStreamEventCanAcceptBytes |
		                                  kCFStreamEventErrorOccurred  |
		                                  kCFStreamEventEndEncountered ;
		
		if (!CFWriteStreamSetClient(writeStream, writeStreamEvents, &CFWriteStreamCallback, &streamContext))
		{
			[self closeWithError:[self otherError:@"Error in CFWriteStreamSetClient"]];
			return;
		}
		
		[[self class] startHandshakeThreadIfNeeded];
		[[self class] performSelector:@selector(addHandshakeListener:)
		                     onThread:sslHandshakeThread
		                   withObject:self
		                waitUntilDone:YES];
		
		flags |= kAddedHandshakeListener;
		
		GCDAsyncSpecialPacket *tlsPacket = (GCDAsyncSpecialPacket *)currentRead;
		NSDictionary *tlsSettings = tlsPacket->tlsSettings;
		
		// Getting an error concerning kCFStreamPropertySSLSettings ?
		// You need to add the CFNetwork framework to your iOS application.
		
		BOOL r1 = CFReadStreamSetProperty(readStream, kCFStreamPropertySSLSettings, (CFDictionaryRef)tlsSettings);
		BOOL r2 = CFWriteStreamSetProperty(writeStream, kCFStreamPropertySSLSettings, (CFDictionaryRef)tlsSettings);
		
		if (!r1 || !r2)
		{
			[self closeWithError:[self otherError:@"Error in CFStreamSetProperty"]];
			return;
		}
		
		CFStreamStatus readStatus = CFReadStreamGetStatus(readStream);
		CFStreamStatus writeStatus = CFWriteStreamGetStatus(writeStream);
		
		if ((readStatus == kCFStreamStatusNotOpen) || (writeStatus == kCFStreamStatusNotOpen))
		{
			r1 = CFReadStreamOpen(readStream);
			r2 = CFWriteStreamOpen(writeStream);
			
			if (!r1 || !r2)
			{
				[self closeWithError:[self otherError:@"Error in CFStreamOpen"]];
			}
		}
		
		LogVerbose(@"Waiting for SSL Handshake to complete...");
	}
}

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Advanced
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)performBlock:(dispatch_block_t)block
{
	dispatch_sync(socketQueue, block);
}

- (int)socketFD
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (socket4FD != SOCKET_NULL)
			return socket4FD;
		else
			return socket6FD;
	}
	else
	{
		return SOCKET_NULL;
	}
}

- (int)socket4FD
{
	if (dispatch_get_current_queue() == socketQueue)
		return socket4FD;
	else
		return SOCKET_NULL;
}

- (int)socket6FD
{
	if (dispatch_get_current_queue() == socketQueue)
		return socket6FD;
	else
		return SOCKET_NULL;
}

#if TARGET_OS_IPHONE

- (CFReadStreamRef)readStream
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (readStream == NULL)
			[self createReadAndWriteStream];
		
		return readStream;
	}
	else
	{
		return NULL;
	}
}

- (CFWriteStreamRef)writeStream
{
	if (dispatch_get_current_queue() == socketQueue)
	{
		if (writeStream == NULL)
			[self createReadAndWriteStream];
		
		return writeStream;
	}
	else
	{
		return NULL;
	}
}

- (BOOL)enableBackgroundingOnSocketWithCaveat:(BOOL)caveat
{
	if (readStream == NULL || writeStream == NULL)
	{
		if (![self createReadAndWriteStream])
		{
			// Error occured creating streams (perhaps socket isn't open)
			return NO;
		}
	}
	
	BOOL r1, r2;
	
	LogVerbose(@"Enabling backgrouding on socket");
	
	r1 = CFReadStreamSetProperty(readStream, kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
	r2 = CFWriteStreamSetProperty(writeStream, kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
	
	if (!r1 || !r2)
	{
		LogError(@"Error setting voip type");
		return NO;
	}
	
	if (!caveat)
	{
		CFStreamStatus readStatus = CFReadStreamGetStatus(readStream);
		CFStreamStatus writeStatus = CFWriteStreamGetStatus(writeStream);
		
		if ((readStatus == kCFStreamStatusNotOpen) || (writeStatus == kCFStreamStatusNotOpen))
		{
			r1 = CFReadStreamOpen(readStream);
			r2 = CFWriteStreamOpen(writeStream);
			
			if (!r1 || !r2)
			{
				LogError(@"Error opening bg streams");
				return NO;
			}
		}
	}
	
	return YES;
}

- (BOOL)enableBackgroundingOnSocket
{
	LogTrace();
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		return [self enableBackgroundingOnSocketWithCaveat:NO];
	}
	else
	{
		return NO;
	}
}

- (BOOL)enableBackgroundingOnSocketWithCaveat
{
	LogTrace();
	
	if (dispatch_get_current_queue() == socketQueue)
	{
		return [self enableBackgroundingOnSocketWithCaveat:YES];
	}
	else
	{
		return NO;
	}
}

#else

- (SSLContextRef)sslContext
{
	if (dispatch_get_current_queue() == socketQueue)
		return sslContext;
	else
		return NULL;
}

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (NSString *)hostFromAddress4:(struct sockaddr_in *)pSockaddr4
{
	char addrBuf[INET_ADDRSTRLEN];
	
	if (inet_ntop(AF_INET, &pSockaddr4->sin_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL)
	{
		addrBuf[0] = '\0';
	}
	
	return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

+ (NSString *)hostFromAddress6:(struct sockaddr_in6 *)pSockaddr6
{
	char addrBuf[INET6_ADDRSTRLEN];
	
	if (inet_ntop(AF_INET6, &pSockaddr6->sin6_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL)
	{
		addrBuf[0] = '\0';
	}
	
	return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

+ (UInt16)portFromAddress4:(struct sockaddr_in *)pSockaddr4
{
	return ntohs(pSockaddr4->sin_port);
}

+ (UInt16)portFromAddress6:(struct sockaddr_in6 *)pSockaddr6
{
	return ntohs(pSockaddr6->sin6_port);
}

+ (NSString *)hostFromAddress:(NSData *)address
{
	NSString *host;
	
	if ([self getHost:&host port:NULL fromAddress:address])
		return host;
	else
		return nil;
}

+ (UInt16)portFromAddress:(NSData *)address
{
	UInt16 port;
	
	if ([self getHost:NULL port:&port fromAddress:address])
		return port;
	else
		return 0;
}

+ (BOOL)getHost:(NSString **)hostPtr port:(UInt16 *)portPtr fromAddress:(NSData *)address
{
	if ([address length] >= sizeof(struct sockaddr))
	{
		struct sockaddr *addrX = (struct sockaddr *)[address bytes];
		
		if (addrX->sa_family == AF_INET)
		{
			if ([address length] >= sizeof(struct sockaddr_in))
			{
				struct sockaddr_in *addr4 = (struct sockaddr_in *)addrX;
				
				if (hostPtr) *hostPtr = [self hostFromAddress4:addr4];
				if (portPtr) *portPtr = [self portFromAddress4:addr4];
				
				return YES;
			}
		}
		else if (addrX->sa_family == AF_INET6)
		{
			if ([address length] >= sizeof(struct sockaddr_in6))
			{
				struct sockaddr_in6 *addr6 = (struct sockaddr_in6 *)addrX;
				
				if (hostPtr) *hostPtr = [self hostFromAddress6:addr6];
				if (portPtr) *portPtr = [self portFromAddress6:addr6];
				
				return YES;
			}
		}
	}
	
	return NO;
}

+ (NSData *)CRLFData
{
	return [NSData dataWithBytes:"\x0D\x0A" length:2];
}

+ (NSData *)CRData
{
	return [NSData dataWithBytes:"\x0D" length:1];
}

+ (NSData *)LFData
{
	return [NSData dataWithBytes:"\x0A" length:1];
}

+ (NSData *)ZeroData
{
	return [NSData dataWithBytes:"" length:1];
}

@end	
