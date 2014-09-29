CocoaLumberjack works by default in AppCode, but colours are not supported out of the box. To enable colours:

1. Install the 'Grep Console' plugin (http://plugins.jetbrains.com/plugin/7125)
2. Enable ANSI colouring (Settings > Grep Console)
3. Go to Run > Edit configurations...
4. Add TERM=color to the 'Environment variables' (edit them by clicking on the ellipsis)
5. `[[DDTTYLogger sharedInstance] setColorsEnabled:YES];`

Kudos to @davidlawson for this documentation.