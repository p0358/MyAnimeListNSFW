%hook NSURLSession

- (id)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(id)completionHandler{
	if ([[[request URL] host] isEqualToString:@"api.myanimelist.net"] && [[[request URL] query] length]) {
    	NSMutableURLRequest *hookUrlRequest = [request mutableCopy];
		NSURL *url = [NSURL URLWithString:[[[hookUrlRequest URL] absoluteString] stringByAppendingString:@"&nsfw=true"]];
		[hookUrlRequest setURL:url];
    	return %orig(hookUrlRequest, completionHandler);
	}
	return %orig;
}

%end
