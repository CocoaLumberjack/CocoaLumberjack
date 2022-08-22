---
name: Bug report
about: Create a report to help us improve CocoaLumberjack
title: ''
labels: Bug
assignees: ''

---

**Checklist**
- [ ] I have read and understood the [CONTRIBUTING guide](https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/.github/CONTRIBUTING.md)
- [ ] I have read the [Documentation](https://github.com/CocoaLumberjack/CocoaLumberjack#documentation)
- [ ] I have searched for a similar issue in the [project](https://github.com/CocoaLumberjack/CocoaLumberjack/issues) and found none

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Create logger '...'
2. Log message '...'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment info**
  Info                    | Value                               |
-------------------------|-------------------------------------|
 Platform Name           | e.g. ios / macos / tvos / watchos
 Platform Version        | e.g. 13.0
 CocoaLumberjack Version | e.g. 3.7.4
 Integration Method      | e.g. spm / carthage / cocoapods / manually
 Xcode Version           | e.g. Xcode 13.4
 Repro rate              | e.g. all the time (100%) / sometimes x% / only once
 Repro project link      | e.g. link to a reproduction project that highlights the issue

**Additional context**
Add any other context about the problem here.
Are you reporting a queue deadlock? If so, please include a complete backtrace of all threads, which you can generate by typing `bt all` in the debugger after you hit the deadlock. We might not be able to fix deadlock reports without a backtrace!
