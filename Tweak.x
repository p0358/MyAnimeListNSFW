#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

BOOL isJSONResponse(NSURLResponse *response) {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *contentType = httpResponse.allHeaderFields[@"Content-Type"];
        if (contentType && [contentType containsString:@"application/json"]) {
            return YES;
        }
    }
    return NO;
}

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    if ([[[request URL] host] isEqualToString:@"api.myanimelist.net"] && [[[request URL] query] length]) {
        
        NSMutableURLRequest *hookUrlRequest = [request mutableCopy];
        NSString *urlString = [[hookUrlRequest URL] absoluteString];

        // nsfw=true is a generic parameter applicable to many API endpoints, so we just always append it
        urlString = [urlString stringByAppendingString:@"&nsfw=true"];

        if ([[request HTTPMethod] isEqualToString:@"GET"] && [urlString containsString:@"/v3/users/@me/animelist"]) {
            // Sadly v3 API does not respect the "nsfw=true" query param for animelist endpoint, so we have to resort to API v2 here.
            // They are mostly compatible, but v2 does not have the "total" numerical field, meaning the app
            // will not display the stats at the top of the list...
            urlString = [urlString stringByReplacingOccurrencesOfString:@"/v3/" withString:@"/v2/"];

            // To fix this, we will actually issue a request with max allowed entries in response,
            // then parse JSON and manually add the "total" field.
            urlString = [urlString stringByReplacingOccurrencesOfString:@"limit=50" withString:@"limit=1000"];

            [hookUrlRequest setURL:[NSURL URLWithString:urlString]];
            void (^newCompletionHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error || !data || !data.length || !isJSONResponse(response)) {
                    // If an error occurs or the response is not a JSON response, return as-is
                    completionHandler(data, response, error);
                } else {
                    // If normal data is returned
                    NSMutableDictionary *json = [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] mutableCopy];
                    if (!json || !json[@"data"])
                        return completionHandler(data, response, error);

                    if ([json[@"data"] isKindOfClass:[NSArray class]])
                        json[@"total"] = @([json[@"data"] count]);

                    NSError *jsonError;
                    NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:json options:0 error:&jsonError];
                    if (jsonError)
                        return completionHandler(data, response, jsonError);

                    completionHandler(dataJSON, response, error);
                }
            };
            NSURLSessionDataTask *newDataTask = %orig(hookUrlRequest, newCompletionHandler);

            [newDataTask resume];
            return newDataTask;
        }

        NSURL *url = [NSURL URLWithString:urlString];
        [hookUrlRequest setURL:url];
        return %orig(hookUrlRequest, completionHandler);
    }
    return %orig;
}

%end
