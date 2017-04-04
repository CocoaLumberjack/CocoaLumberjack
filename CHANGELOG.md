## [3.1.0 - Swift 3.0.1, Xcode 8.1 on Feb 22nd, 2017](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/3.1.0)
- Swift 3.0.1 and Xcode 8.1 support via #816
- Fix Carthage build and updated the podspec structure #819 #818 #784 #790 #782 #778 #815
- Fix CLIColor.h not included in umbrella header #781 #796 #813 #783
- Fix crash in `[DDLog log:level:flag:context:file:function:line:tag:format:]` #831 #830
- Code improvements: 
  - using class properties #779
  - nullability #803 #809 #776
  - fix static analyzer issues #822 #828
  - optimized `USE_DISPATCH_CURRENT_QUEUE_LABEL` and `USE_DISPATCH_GET_CURRENT_QUEUE` macros #829
  - fixed dispatch_source_set_timer() usage #834
  - fixed misuse of non null parameter in `DDFileLogger fileAttributes` #835
  - store calendar in logger queue specifics for multi-thread safety #837
  - reenable default `init` method for `DDLogMessage` class #838
- Added option to not copy messages #832
- Added new hooks when adding loggers and formatters #836
- Ability to create new log files every day #736
- Skip messages in ASL logger which are filtered out by the formatter #786 #742
- Fixed #823 by adding a `hash` implementation for `DDFileLogger` - same as `isEqual`, it only considers the `filePath` 7ceed08
- Fix Travis CI build #807
- Updated docs #798 #808 #811 #810 #820

## [3.0.0 - Swift 3.0, Xcode 8 on Sep 21st, 2016](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/3.0.0)
- Swift 3.0 and Xcode 8 support via #769, fixes #771 and #772. Many thanks to @ffried @max-potapov @chrisdoc @BarakRL @devxoul and the others who contributed

## [2.4.0 - Swift 2.3 on Sep 19th, 2016](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.4.0)
- Swift 2.3 explicit so that the project compiles on Xcode 8 - #747 #773 fix #762 #763 #766
- CocoaPods 1.0.0 fully adopted - 0f5a793 637dfc1 70439fe #729
- Fix CLIColor.h not found for non-AppKit binaries w/o clang modules #745
- Retrieve the `DDLogLevel` of each logger associated to `DDLog` #753 
- updated doc: #727 a9f54c9 #741, diagrams in 8bd128d
- Added CONTRIBUTING, ISSUE and PULL_REQUEST TEMPLATE and added a small Communication section to the Readme
- Fixed an issue with one demo #760

## [2.3.0 - Swift 2.2, Xcode7.3 on May 2nd, 2016](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.3.0)
- Updated to Swift 2.2 - #704 
- replaced deprecated `__FUNCTION__`, `__FILE__`, `__LINE__` with newly added to Swift 2.2: `#function`, `#file`, `#line`
- Xcode 7.3 update - #692 #662 
- simplify usage and integration of the static library target - #657 
- DDLog usable via instances - #679 
- Swift cleanup - #649 
- Enable Application extension API only for tvOS - #701 
- Added `appletvos` and `appletvsimulator` to `SUPPORTED_PLATFORMS` and set  `TVOS_DEPLOYMENT_TARGET` - #707 
- fixed `OSSpinLock` init issue - #653 
- Added check to prevent duplicate loggers - #682 
- fixed typo in import - #693 
- updated the docs - #646 #650 #656 #655 #661 #664 #667 #684 #724 

## [2.2.0 - TVOS, Xcode7.1 on Oct 28th, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.2.0)
- added `tvOS` support (thanks [@sinoru](https://github.com/sinoru)) - [#634](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/634) [#640](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/640) [#630](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/630) [#628](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/628) [#618](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/618) [#611](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/611)
- Remove `(escaping)` from the Swift `@autoclosure` parameters - [#642](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/642)

## [2.1.0 - Swift 2.0, WatchOS, Xcode7 on Oct 23rd, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.1.0)
- Fixed the version for the Carthage builds - see [#633](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/633)
- Improved documentation

## [2.1.0 RC - Swift 2.0, WatchOS, Xcode7 on Oct 22nd, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.1.0-rc)
- Refactored the `NSDateFormatter` related code to fix a bunch of issues: [#621](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/621)
- Fix Issue [#488](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/488): Support `DDLog` without `AppKit Dependency` (`#define DD_CLI`): [#627](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/627)
- Re-add `NS_DESIGNATED_INITIALIZER` [#619](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/619)

## [2.1.0 Beta - Swift 2.0, WatchOS, Xcode7 on Oct 12th, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.1.0-beta)
- Updated the library to use Swift 2.0 and Xcode 7 [#617](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/617) [#545](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/545) [#534](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/534)
- WatchOS support (2.0) [#583](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/583) [#581](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/581) [#579](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/579) 

## [2.0.3 Patch for 2.0.0 on Oct 13th, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.3)

- Compatibility with Xcode 6 that was broken by the 2.0.2 patch - [f042fd3](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/f042fd3)

## [2.0.2 Patch for 2.0.0 on Oct 12th, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.2)

- Swift 1.2 fixes [#546](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/546) [#578](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/578) plus and update to Swift 2.0 [5627dff](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/5627dff) imported from our swift_2.0 branch
- Make build work on `tvOS` [#597](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/597) 
- Make `CocoaLumberjackSwift-iOS` target depends on `CocoaLumberjack-iOS` [#575](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/575) 
- `APPLICATION_EXTENSION_API_ONLY` to `YES` for Extensions [#576](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/576) 
- Remove unnecessary `NS_DESIGNATED_INITIALIZER`s [#593](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/593) fixes [#592](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/592)  
- Add ignore warning mark for `DDMakeColor` [#553](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/553) 
- Kill unused function warnings from `DDTTYLogger.h` [#613](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/613) 
- Flag unused parameters as being unused to silence strict warnings [#566](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/566) 
- Extend ignore unused warning pragma to cover all platforms [#559](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/559) 
- Removed images.xcassets from Mobile project [#580](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/580) 
- Silence the Xcode 7 upgrade check - [#595](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/595) 
- Fix import for when CL framework files are manually imported into project [#560](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/560) 
- Don't override defines in case they're already set at project level [#551](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/551) 
- log full filepath when failing to set attribute [#550](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/550) 
- Fix issue in standalone build with `DDLegacyMacros.h` [#552](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/552) 
- Update `CustomFormatters.md` with proper thread-safe blurb [#555](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/555) 
- typo in parameter's variable name fixed [#568](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/568) 
- Typo: minor fix [#571](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/571) 
- Surely we should be adding 1, not 0 for `OSAtomicAdd32` ? [#587](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/587) 
- `rollLogFileWithCompletionBlock` calls back on background queue instead of main queue [#589](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/589) 
- Removing extraneous `\` on line 55 [#600](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/600) 
- Updated `GettingStarted.md` to include `ddLogLevel` [#602](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/602) 
- Remove redundant check for `processorCount` availability [#604](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/604) 

## [2.0.1 Patch for 2.0.0 on Jun 25th, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.1)

- **Carthage support** [#521](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/521) [#526](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/526) 
- fixed crash on `DDASLLogCapture` when `TIME` or `TIME_NSEC` is `NULL` [#484](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/484) 
- **Swift** fixes and improvements: [#483](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/483) [#509](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/509) [#518](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/518) [#522](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/522) [5eafceb](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/5eafceb)
- Unit tests: [#500](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/500) [#498](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/498) [#499](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/499) 
- Fix [#478](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/478) by reverting [#473](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/473) 
- Add `armv7s` to static library [#538](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/538)
- Fix `NSLog` `threadid` mismatch with iOS 8+/OSX 10.10+ [#514](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/514) 
- Fixed the `LogV` macros so that avalist is no longer undefined [#511](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/511) 
- Using type safe `DDColor` alias instead of #define directive [#506](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/506) 
- Several fixes/tweaks to `DDASLLogCapture` [#512](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/512) 
- Prevent duplicate log entries when both `DDASLLogCapture` and `DDASLLogger` are used [#515](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/515) 
- Fix memory leaks in `DDTTYLogger`, add self annotations to blocks [#536](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/536) 
- Update older syntax to modern subscripting for array access [#482](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/482) 
- Remove execute permission on non-executable files [#517](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/517) 
- Change code samples to use `DDLogFlagWarning` [#520](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/520) 
- Fix seemingly obvious typo in the `toLogLevel` function [#508](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/508) 

## [CocoaLumberjack 2.0.0 on Mar 13th, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.0)

The library was strongly refactored, with a few goals in mind:
- Swift support - that we will release in a separate milestone, since CocoaPods 0.36.0 just got out
- Unit tests support
- reorganised things (on disk)
- better coding style

See [Migration from 1.x to 2.x](https://github.com/CocoaLumberjack/CocoaLumberjack#migrating-to-2x)

## [2.0.0-rc2 on Feb 20th, 2015](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.0-rc2)

- Bucket of Swift improvements - [#434](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/434) [#437](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/437) [#449](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/449) [#440](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/440) 
- Fixed [#433](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/433) (build issue due to dispatch_queue properties) - [#455](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/455) 
- Enable codesign for iOS device framework builds - [#444](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/444)
- Declare `automaticallyAppendNewlineForCustomFormatters` properties as `nonatomic` - [#443](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/443) 
- Warning fixes & type standardization - [#419](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/419) 
- Legacy checks updated - [#424](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/424) 
- Documentation updates

## [2.0.0-rc on Dec 11th, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.0-rc)

- Fix `dispatch_queue_t` properties.
- Fix `registeredClasses` crashes at launch.

## [2.0.0-beta4 on Nov 7th, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.0-beta4)

- Major refactoring and clean up.
- Remove superfluous `log` from property names and use underscore for direct variable access.
- Preliminar Swift support through `CocoaLumberjack.swift`.
- Automatic 1.9.x legacy support when `DDLog.h` is imported instead of the new `CocoaLumberjack.h`.

## [2.0.0-beta3 on Oct 21st, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.0-beta3)

- Modernize flag variables to be `NS_OPTIONS`/`NS_ENUM`.
- Change the log flags and levels to `NSUInteger`.
- Fix warning when compiled with assertions blocked.
- Crash fixes.

## [2.0.0-beta2 on Sep 30th, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.0-beta2)

- Cleanup code.
- Match `NSLog` read UID functionality in `DDASLLogger`.
- Update framework and static libraries.

## [2.0.0 Beta on Aug 12th, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/2.0.0-beta)

See [Migrate from 1.x to 2.x](https://github.com/CocoaLumberjack/CocoaLumberjack#migrating-to-2x)

## [1.9.2 Updated patch release for 1.9.0 on Aug 11th, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.9.2)

- Fixed `NSCalendar components:fromDate:` crash - [#140](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/140) [#307](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/307) [#216](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/216) 
- New `DDAssert` macros - [#306](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/306) 
- Limit log growth by disk space only, not the number of files - [#195](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/195) [#303](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/303) 
- Change the mechanism for adding new line character (i.e. '\n\) to log messages in some logger - [#308](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/308) [#310](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/310) 
- Fixed deprecations - [#320](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/320) [#312](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/312) [#317](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/317) 
- `aslmsg` not freed and causing memory leak - [#314](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/314) 
- Fixed `CompresingLogFileManager` compression bug - [#315](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/315) 
- Remove unnecessary `NULL` check before `free()` - [#316](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/316) 

## [1.9.1 Patch release for 1.9.0 on Jun 30th, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.9.1)

- Fixed issues in rolling frequency - [#243](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/243) [#295](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/295) [@georgekola](https://github.com/georgekola)
- Fixed critical issue, `addLogger` method should use a full bit mask instead of `LOG_LEVEL_VERBOSE`, otherwise extended logs or extra flags are ignored [fe6824c](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/fe6824c) [@robbiehanson](https://github.com/robbiehanson) 
- Performance optimisation: use compiler macros to skip iOS version checks - [4656d3b](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/4656d3b) [#298](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/298) [#291](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/291) [@robbiehanson](https://github.com/robbiehanson) [@liviur](https://github.com/liviur)
- Changed the `Build Active Architecture Only` to `NO` [#294](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/294) [#293](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/293) 
- Optimisation by reusing `NSDateFormatter` instances [#296](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/296) [#301](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/301) 

## [1.9.0 New ASL capture module, several File logger fixes on May 23rd, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.9.0)

- New ASL capture module [#242](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/242) [#263](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/263) 
- Override default `NSFileProtection` handling [#285](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/285) 
- Replaced warnings when ARC was not enabled with errors [#284](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/284) 
- Fix for issue [#278](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/278) where really large log files can keep growing [#280](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/280) 
- Fixed Xcode warnings [#279](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/279) 
- Update `calendarUnitFlags` with new iOS SDK values [#277](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/277) 
- Fix possible crash in `[NSCalendar components:fromDate:]` [#277](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/277) 
- Fix [#262](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/262) inverted ifs when renaming log [#264](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/264) 
- Proper way of doing singletons (via `dispatch_once`) [#259](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/259) 
- Explicitly declare `DDFileLogger` and `DDDispatchQueueLogFormatter ` properties as atomic to avoid Xcode warnings [#258](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/258)
- Set `NSFileProtectionKey` on the temporary file created during compression [#256](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/256) 
- Fix a rare crash in `CompressingLogFileManager` caused by an unchecked result from read [#255](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/255) 
- Add explicit casts for integer conversion [#253](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/253) 
- Replace use of `NSThread.detachNewThreadSelector` [#251](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/251) 
- Add a constructor override for `initWithLogsDirectory:` [#252](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/252) 
- Check and log the streamError whenever we fail to write during compression and log any failures when removing the original file or cleaning up the temporary file after compression failed [#250](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/250) 
- Following Apple's guidelines for iOS Static Libraries [#249](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/249) 
- Some extra warnings for the mobile framework xcode project [a2e5666](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/a2e5666)
- Update `FineGrainedLoggingAppDelegate.m` [#244](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/244) 
- New `[DDLog log:message:]` primitive [7f8af2e](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/7f8af2e)
- Fixed issue [#181](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/181) when logging messages in iOS7 devices aren't properly retrieved by `asl_search` [#240](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/240) 
- Allow prevention of log file reuse [#238](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/238) 
- `DDTTYLogger`: Favour XcodeColors environment variable [#237](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/237) 
- `DDLog`: calling `atexit_b` in CLI applications, that use Foundation framework [#234](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/234) 

## [1.8.1 AllLoggers and bugfixes on Feb 14th, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.8.1)

- read access to all loggers - [#217](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/217) [#219](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/219) 
- fixed bug with archived logs not being handled correctly on iOS simulator - [#218](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/218) 
- log the `strerror(errno)` value when `setxattr()` fails - [#211](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/211) 
- Add a check for an archived log before overwriting - [#214](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/214) 
- improved safety by using assertions instead of comments (`DDLog` in the core) - [#221](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/221) 
- added Lumberjack logo :)

## [1.8.0 Better CL support, custom logfile name format, bugfixes on Jan 21st, 2014](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.8.0)

- `DDFileLogger` custom logfile (name) format - [#208](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/208) 
- Security static analysis fix - [#202](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/202) 
- `DDFileLogger`: using `CFBundleIdentifier` as a log filename prefix on OSX and iOS - [#206](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/206) 
- Allow disabling of specific levels per-logger - [#204](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/204) 
- Improve support for OS X command line tools - [#194](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/194) 
- `DDFileLogger`: fixed crash that occurred in case if application name == nil - [#198](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/198) 
- `DDFileLogger`: fixed comment - [#199](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/199) 
- Fix Travis - [#205](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/205) 

## [1.7.0 New log file naming convention and CocoaLumberjack organisation on Dec 10th, 2013](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.7.0)

- new log file naming convention - [#191](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/191)
- completed transition to **CocoaLumberjack** organisation - [#188](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/188)

## [1.6.5.1 Patch release for Xcode 4.4+ compatibility on Dec 4th, 2013](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.6.5.1)

- fixed compatibility with Xcode 4.4+ [#187](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/187)

## [1.6.5 File Logger refactoring, Multi Formatter, preffixed extension classes on Dec 3rd, 2013](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.6.5)

`DDFileLogger` refactoring and fixes (thanks [@dvor](https://github.com/dvor) and [@an0](https://github.com/an0)):
- Fixed [#63](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/63) Loggers don't flush in Command Line Tool [#184](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/184) 
- Fixed [#52](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/52) Force log rotation [#183](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/183)
- Fixed [#55](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/55) After deleting log file or log dir they aren't created again without relaunching the app [#183](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/183)
- Fixed [#129](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/129) [iOS] `DDFileLogger` causes crash when logging from background app [#183](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/183)
- Fixed [#153](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/153) Log file on iPhone only contains a single line [#177](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/177)
- Fixed [#155](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/155) How do I combine all my log levels into one file? [#177](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/177)
- Fixed [#175](https://github.com/CocoaLumberjack/CocoaLumberjack/issues/175) `DFileLogger` `creationDate` bug on 64-bit iOS system [#177](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/177)
- Allow customizing the naming convention for log files to use timestamps [#174](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/174)

Other:
- Implemented multiple formatter (`DDMultiFormatter` - alows chaining of formatters) [#178](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/178)
- Added DD preffix to extension classes (`ContextFilterLogFormatter` and `DispatchQueueLogFormatter`) [#178](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/178)
- Updated code indentation: Tabs changed to spaces [#180](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/180)
- Included `DDLog+LOGV.h` in Cocoapods sources [d253bd7](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/d253bd7)
- other fixes/improvements

## [1.6.4 Fix compatibility with 3rd party frameworks on Nov 21st, 2013](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.6.4)

* "Fix" conflicts with 3rd party libraries using `CocoaLumberjack` [#172](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/172) 
* Ignore deprecated warning for `dispatch_get_current_queue` [#167](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/167) 
* Add new `DEBUG` log level support to included loggers [#166](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/166) 
* Method declarations that make it easier to extend/modify `DispatchQueueLogFormatter` [#164](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/164) 

## [1.6.3 New macros, updated podspec and bug fixes on Apr 2nd, 2013](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.6.3)

* Add `LOGV`-style macros [#161](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/161) 
* Fix getting queue's label [#159](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/159)  
* New log level `DEBUG` [#145](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/145) 
* Use `DISPATCH_CURRENT_QUEUE_LABEL` if available [#159](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/159) 
* Different `logLevel` per each logger [#151](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/151) 
* Created 2 subspecs, `Core` and `Extensions` [#152](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/152) 
* Updated observer for keypath using `NSStringFromSelector` + `@selector` [38e5da3](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/38e5da3)
* Replaced `id` return type with `instancetype` [ebee454](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/ebee454)
* Remove implicit conversion warnings [#149](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/149) 
* `DDTTYLogger`: Allow to set default color profiles for all contexts at once [#146](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/146) [#158](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/158) 
* `DDTTYLogger`: By default apply `setForegroundColor:backgroundColor:forFlag:` to `LOG_CONTEXT_ALL` [#154](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/154) 
* `DispatchQueueLogFormatter`: Use modern Objective-C [#142](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/142) 
* `DispatchQueueLogFormatter`: Make sure to always use a `NSGregorianCalendar` for date formatter [#142](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/142) 
* Replaced explicit reference to class name in `logFileWithPath` factory method [#131](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/131) 
* Catch exceptions in `logMessage:` [#130](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/130) 
* Fix enum type conversion warnings [#124](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/124) 
* Add deployment target condition for workaround [#121](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/121) 
* Fix static analyzer warnings about `nil` values in dictionary [#122](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/122) 
* Fix `dispatch_get_current_queue` crash [#121](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/121) 
* Fixing colors in greyscale color-space not working [d019cfd](https://github.com/CocoaLumberjack/CocoaLumberjack/commit/d019cfd)
* Guard around `dispatch_resume()` being called with null pointer [#107](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/107) 
* `NULL` safety checks [#107](https://github.com/CocoaLumberjack/CocoaLumberjack/pull/107)

## [1.6.2 on Apr 2nd, 2013](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.6.2)

## [1.6.1 on Apr 2nd, 2013](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.6.1)

## [1.6 on Jul 3rd, 2012](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.6)

## [1.5.1 on Jul 3rd, 2012](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.5.1)

## [1.5 on Jul 3rd, 2012](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.5)

## [1.4.1 on Jul 3rd, 2012](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.4.1)

## [1.4 on Jul 3rd, 2012](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.4)

## [1.3.3 on Mar 30th, 2012](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.3.3)

## [1.3.2 on Dec 23rd, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.3.2)

## [1.3.1 on Dec 9th, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.3.1)

## [1.3 on Dec 9th, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.3)

## [1.2.3 on Dec 9th, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.2.3)

## [1.2.2 on Dec 9th, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.2.2)

## [1.2.1 on Oct 13th, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.2.1)

## [1.2 on Oct 13th, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.2)

## [1.1 on Oct 13th, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.1)

## [1.0 on Oct 13th, 2011](https://github.com/CocoaLumberjack/CocoaLumberjack/releases/tag/1.0)
