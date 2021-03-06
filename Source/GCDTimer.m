//
//  GCDTimer.m
//

#import "GCDTimer.h"

#if (TARGET_OS_IPHONE && (__IPHONE_OS_VERSION_MIN_REQUIRED >= 60000)) || (MAC_OS_X_VERSION_MIN_REQUIRED >= 1080)
    #define GCDTIMER_DISPATCH_RELEASE(q)
#else
    #define GCDTIMER_DISPATCH_RELEASE(q) (dispatch_release(q))
#endif

@interface GCDTimer ()

@property NSTimer *countdownTimer;

@end;

@implementation GCDTimer {
    dispatch_source_t timer;
}

- (instancetype) initScheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats queue:(dispatch_queue_t)queue block:(dispatch_block_t)block
{
    NSAssert(queue != NULL, @"queue can't be NULL");

    if ((self = [super init]))
    {
        self.interval = interval;
        self.startDate = [NSDate date];
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);

        dispatch_source_set_timer(timer,
                                  dispatch_time(DISPATCH_TIME_NOW, 0),
                                  interval * NSEC_PER_SEC,
                                  0);

        dispatch_source_set_event_handler(timer, ^
        {
            if (block) {
                block();
            }
            if (!repeats) {
                [self.countdownTimer invalidate];
                self.countdownTimer = nil;
                dispatch_source_cancel(timer);
            }
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), queue, ^{
            dispatch_resume(timer);
        });
        
        self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateCountdown:) userInfo:nil repeats:YES];
    }
    return self;
}

- (instancetype) initScheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(dispatch_block_t)block
{
    return self = [self initScheduledTimerWithTimeInterval:interval repeats:repeats queue:dispatch_get_main_queue() block:block];
}

- (void) dealloc
{
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
    dispatch_source_cancel(timer);
    GCDTIMER_DISPATCH_RELEASE(timer);
}

- (void) invalidate
{
    dispatch_source_cancel(timer);
}

- (NSTimeInterval)timeRemaining
{
    return self.interval - [[NSDate date] timeIntervalSinceDate:self.startDate];
}

- (void)updateCountdown:(NSTimer *)timer
{
    [self willChangeValueForKey:@"timeRemaining"];
    [self didChangeValueForKey:@"timeRemaining"];
}

+ (instancetype) scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats queue:(dispatch_queue_t)queue block:(dispatch_block_t)block
{
    return [[GCDTimer alloc] initScheduledTimerWithTimeInterval:interval repeats:repeats queue:queue block:block];
}

+ (instancetype) scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(dispatch_block_t)block
{
    return [self scheduledTimerWithTimeInterval:interval repeats:repeats queue:dispatch_get_main_queue() block:block];
}

@end
