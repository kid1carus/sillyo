%group cydia


//Part 1: fix duplicate sources error.
@interface Source
- (NSString *) rooturi;
- (void) _remove;
@end

%hook Database

- (NSArray *) sources {
  NSArray *sourcesList = %orig;
  BOOL didRemoveSource;
  NSMutableArray *removedSources = [[NSMutableArray alloc] init];
  if ([[NSFileManager defaultManager] fileExistsAtPath:@"/etc/apt/sources.list.d/sileo.sources"]) {
    for(Source *checkingSource in sourcesList) {
      NSMutableString *checkingSourceString = [NSMutableString stringWithString:[checkingSource rooturi]];
      [checkingSourceString replaceOccurrencesOfString:@"https://" withString:@"" options:nil range:NSMakeRange(0, [checkingSourceString length])];
      [checkingSourceString replaceOccurrencesOfString:@"http://" withString:@"" options:nil range:NSMakeRange(0, [checkingSourceString length])];
      NSString *sileoSourcesString = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/sileo.sources" encoding:NSUTF8StringEncoding error:nil];
      NSString *cydiaSourcesString = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/cydia.list" encoding:NSUTF8StringEncoding error:nil];
      if ([sileoSourcesString rangeOfString:checkingSourceString].location == NSNotFound) {}
        else {
          if ([cydiaSourcesString rangeOfString:checkingSourceString].location == NSNotFound) {}
            else {
              if ([[checkingSource rooturi] isEqualToString:@"https://apt.bingner.com"]) {}
                else {
                  didRemoveSource = TRUE;
                  [removedSources addObject:[checkingSource rooturi]];
                  [checkingSource _remove];
              }
            }
        }
    }
  }
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/etc/apt/sources.list.d/sileo.list"]) {
      for(Source *checkingSource in sourcesList) {
        NSMutableString *checkingSourceString = [NSMutableString stringWithString:[checkingSource rooturi]];
        [checkingSourceString replaceOccurrencesOfString:@"https://" withString:@"" options:nil range:NSMakeRange(0, [checkingSourceString length])];
        [checkingSourceString replaceOccurrencesOfString:@"http://" withString:@"" options:nil range:NSMakeRange(0, [checkingSourceString length])];
        NSString *sileoSourcesString = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/sileo.list" encoding:NSUTF8StringEncoding error:nil];
        NSString *cydiaSourcesString = [NSString stringWithContentsOfFile:@"/etc/apt/sources.list.d/cydia.list" encoding:NSUTF8StringEncoding error:nil];
        if ([sileoSourcesString rangeOfString:checkingSourceString].location == NSNotFound) {}
          else {
            if ([cydiaSourcesString rangeOfString:checkingSourceString].location == NSNotFound) {}
              else {
                if ([[checkingSource rooturi] isEqualToString:@"https://apt.bingner.com"]) {}
                  else {
                    didRemoveSource = TRUE;
                    [removedSources addObject:[checkingSource rooturi]];
                    [checkingSource _remove];
                }
              }
          }
      }
    }
    if (didRemoveSource) {
      #pragma clang diagnostic push
  	  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  	  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sileo compatibility layer" message:[NSString stringWithFormat:@"Duplicate Sources Error Fixed!\n\nThe following repos were added to both Cydia and Sileo:\n%@\nIf you'd like to remove these repos at a later time, you must do so through Sileo.\n\nPLEASE RESTART CYDIA", [removedSources componentsJoinedByString:@"\n"]] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
  	  [alert show];
  	  [alert release];
      #pragma clang diagnostic pop
    }
  return %orig;
}

%end


%end

%group sileo

%hook URLManager
// THX sbingner!
+(NSMutableURLRequest*) urlRequestWithHeaders:(NSURL *)url includingDeviceInfo:(bool)info {
    NSMutableURLRequest *req = %orig;
    if ([req valueForHTTPHeaderField:@"X-Firmware"] == nil){
        [req setValue:[[UIDevice currentDevice] systemVersion] forHTTPHeaderField:@"X-Firmware"];
    }
    return req;
}

%end

%hook APTWrapper

+(NSString*)getOutputForArguments:(NSArray*)arguments errorOutput:(NSString**)errorOutput error:(NSError**)error {
    NSMutableArray *newargs = [arguments mutableCopy];
    [newargs removeObject:@"-oAPT::Format::for-sileo=true"];
    NSString *output = %orig(newargs, errorOutput, error);
    NSRegularExpression *instExpr = [NSRegularExpression regularExpressionWithPattern:@"^(\\S+) (\\S+) \\((\\S+) (.+\\])\\)$"
                                                            options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSRegularExpression *reinstExpr = [NSRegularExpression regularExpressionWithPattern:@"^(\\S+) (\\S+) \\[(\\S+)\\] \\((\\S+) (.+\\])\\)$"
                                                            options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSRegularExpression *removeExpr = [NSRegularExpression regularExpressionWithPattern:@"^(\\S+) (\\S+) \\[(\\S+)\\]$"
                                                            options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSMutableArray <NSString*> *outputs = [NSMutableArray new];
    for (NSTextCheckingResult *line in [instExpr matchesInString:output options:0 range:NSMakeRange(0, output.length)]) {
        NSString *json = [[NSString alloc]
            initWithData:[NSJSONSerialization dataWithJSONObject:@{
                @"Type": [output substringWithRange:[line rangeAtIndex:1]],
                @"Package": [output substringWithRange:[line rangeAtIndex:2]],
                @"Version": [output substringWithRange:[line rangeAtIndex:3]],
                @"Release": [output substringWithRange:[line rangeAtIndex:4]]
            } options:0 error:nil] encoding:NSUTF8StringEncoding];
        [outputs addObject:json];
        [json release];
    }
    for (NSTextCheckingResult *line in [reinstExpr matchesInString:output options:0 range:NSMakeRange(0, output.length)]) {
        NSString *json = [[NSString alloc]
            initWithData:[NSJSONSerialization dataWithJSONObject:@{
                @"Type": [output substringWithRange:[line rangeAtIndex:1]],
                @"Package": [output substringWithRange:[line rangeAtIndex:2]],
                @"Version": [output substringWithRange:[line rangeAtIndex:4]],
                @"Release": [output substringWithRange:[line rangeAtIndex:5]]
            } options:0 error:nil] encoding:NSUTF8StringEncoding];
        [outputs addObject:json];
        [json release];
    }
    for (NSTextCheckingResult *line in [removeExpr matchesInString:output options:0 range:NSMakeRange(0, output.length)]) {
        NSString *json = [[NSString alloc]
            initWithData:[NSJSONSerialization dataWithJSONObject:@{
                @"Type": [output substringWithRange:[line rangeAtIndex:1]],
                @"Package": [output substringWithRange:[line rangeAtIndex:2]],
                @"Version": [output substringWithRange:[line rangeAtIndex:3]]
            } options:0 error:nil] encoding:NSUTF8StringEncoding];
        [outputs addObject:json];
        [json release];
    }

    NSString *newOutput = [outputs componentsJoinedByString:@"\n"];

    NSLog(@"Sillyo: %@", newOutput);
    return [newOutput retain];
}

%end

%end

%ctor {
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.saurik.Cydia"]) {
		%init(cydia);
	} else if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"org.coolstar.SileoStore"]) {
		%init(sileo);
	}
}

