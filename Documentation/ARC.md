[Automatic Reference Counting](http://clang.llvm.org/docs/AutomaticReferenceCounting.html) (ARC) is an amazing new technology. It makes life easier for developers and speeds up your code at the same time. However, since it's such a radical change, it requires some new tools (Xcode 4.4+, Apple LLVM 3.0+ compiler) and some code changes (remove `retain`/`release`/`autorelease`, etc). This leaves library developers in a tough position: To ARC, or not to ARC? If the library is converted to ARC, those who haven't converted their apps will complain. If the library isn't converted to ARC, those who have converted their apps will complain! What to do?

One possibility is to maintain 2 branches: arc & non-arc. These would have to be kept in sync for every new commit and every push. Obviously this is a large burden. And library developers, especially those who actively develop and improve their libraries, don't consider this a solution. So ultimately, a decision must be made.

We believe that ARC will quickly become the defacto standard. Manual memory management has long been the single largest entrance barrier to the language, and the most common complaint. It required sometimes tedious balancing of retain/release statements, and even seasoned professionals were known to occasionally leak an object or forget a release in a dealloc method. Garbage collection was tried and largely rejected (for apparent performance reasons). But know ARC has arrived. And we believe it is the future.

If you've already adopted ARC, then you can just drop in Lumberjack and go. If not, then read on.

## Older Non-ARC versions of Lumberjack

The project was converted to ARC in version 1.3. If you are unable to use the ARC versions due to requirements, then you can grab the latest 1.2.X release.

_Note_ - The 1.2.X branch is deprecated, and no longer maintained.

## Supporting ARC versions of Lumberjack in Non-ARC projects

The first thing to note is the requirements for supporting ARC in any capacity in your project.

**Development requirements for ARC**

- Xcode 4.4
- Apple LLVM compiler 3.0+ (Build Setting)

**Minimum Deployment Targets for ARC**

- iOS: iOS 4.0 or newer
- Mac: 64-Bit processor running Snow Leopard 10.6 or newer.

If you attempt to compile the latest versions of Lumberjack in a non-arc project, you'll receive a warning:

<a href="http://www.flickr.com/photos/100714763@N06/9575917959/" title="CocoaLumberjack_arc1 by robbiehanson, on Flickr"><img src="http://farm4.staticflickr.com/3802/9575917959_308e718f03_c.jpg" width="800" height="438" alt="CocoaLumberjack_arc1"></a>

Don't ignore these warnings! You'll leak memory like crazy if you do!

(If it weren't for complications when using Xcode's "Convert to Objective-C ARC" tool, the warnings would be errors.)

First ensure you're using the Apple LLVM compiler (version 3.0 or newer):

<a href="http://www.flickr.com/photos/100714763@N06/9578711976/" title="CocoaLumberjack_arc2 by robbiehanson, on Flickr"><img src="http://farm8.staticflickr.com/7425/9578711976_29271ff45e_c.jpg" width="800" height="438" alt="CocoaLumberjack_arc2"></a>

Then tell the compiler that the Lumberjack files are ARC:

<a href="http://www.flickr.com/photos/100714763@N06/9578712266/" title="CocoaLumberjack_arc3 by robbiehanson, on Flickr"><img src="http://farm8.staticflickr.com/7355/9578712266_8752306de7_c.jpg" width="800" height="491" alt="CocoaLumberjack_arc3"></a>

The warnings will go away, and the compiler will automatically add all the proper retain/release/autorelease calls to the ARC files during compilation.