# NiblesTestPrj
Experiments with Carbon/Cocoa mix

So, this should be an experiment with the older Carbon code that will have to change from 32 bit Carbon to 64 bit Cocoa.

General idea is to convert as little Carbon code to Cocoa and continue using CarbonCore for everything that is still possible with CarbonCore so it compiles on M1 and latest Xcode having the deprecations warnings off.

There is no NIB/XIB file and everything is created in code excepto for the things from an old Resource file in Classic Mac resorce format.

I don't think this file will be handled well by GitHub, but I have added a zip archive so at least it can be extracted into a good resource file. 
