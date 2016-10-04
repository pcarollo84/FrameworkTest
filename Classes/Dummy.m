//
//  Dummy.m
//  FrameworkTest
//
//  Created by Paolo on 16/09/2016.
//  Copyright © 2016 Paolo. All rights reserved.
//

#import "Dummy.h"
#import <FMDB/FMDB.h>
#import <sqlite3.h>

@implementation Dummy

- (void)attachSystemFunctions:(FMDatabase *)db
{
    // Create User Defined Functions
    [db makeFunctionNamed:@"udf_DistanceBetweenLocations"
         maximumArguments:5
                withBlock:^(void *context, int argc, void **argv) {
                    
#define DEG2RAD(degrees) (degrees * 0.01745327) // degrees * pi over 180
                    
                    context = (sqlite3_context *) context;
                    *argv = (sqlite3_value *)argv;
                    
                    // check that we have four arguments (lat1, lon1, lat2, lon2)
                    assert(argc == 5);
                    // check that all four arguments are non-null
                    if (sqlite3_value_type(argv[0]) == SQLITE_NULL || sqlite3_value_type(argv[1]) == SQLITE_NULL || sqlite3_value_type(argv[2]) == SQLITE_NULL || sqlite3_value_type(argv[3]) == SQLITE_NULL || sqlite3_value_type(argv[4]) == SQLITE_NULL) {
                        sqlite3_result_null(context);
                        return;
                    }
                    // get the four argument values
                    double lat1 = sqlite3_value_double(argv[0]);
                    double lon1 = sqlite3_value_double(argv[1]);
                    double lat2 = sqlite3_value_double(argv[2]);
                    double lon2 = sqlite3_value_double(argv[3]);
                    NSString *units = [NSString stringWithUTF8String:(const char *)sqlite3_value_text(argv[4])];
                    // convert lat1 and lat2 into radians now, to avoid doing it twice below
                    double lat1rad = DEG2RAD(lat1);
                    double lat2rad = DEG2RAD(lat2);
                    // apply the spherical law of cosines to our latitudes and longitudes, and set the result appropriately
                    // 6378.1 is the approximate radius of the earth in kilometres
                    
                    // 3956.0 miles
                    // 6376.5 kms
                    // 3437.7 NAUTICAL  (symbol M, NM or nmi)
                    
                    float unitsMultiplier = 3956.0; // mi
                    
                    if([units isEqualToString:@"km"])
                    {
                        unitsMultiplier = 6376.5f;
                    }
                    
                    sqlite3_result_double(context, acos(sin(lat1rad) * sin(lat2rad) + cos(lat1rad) * cos(lat2rad) * cos(DEG2RAD(lon2) - DEG2RAD(lon1))) * unitsMultiplier);
                }];
    
    // ConvertRentPrice Equalize the price
    //  Uniform Price to PCM  ConvertRentalPrice( let.Price, let.Frequence, 'pcm')
    [db makeFunctionNamed:@"udf_ConvertRentalPrice"
         maximumArguments:3
                withBlock:^(void *context, int argc, void **argv) {
                    
                    context = (sqlite3_context *) context;
                    *argv = (sqlite3_value *)argv;

                    
                    assert(argc == 3);
                    // check that all three arguments are non-null
                    if (sqlite3_value_type(argv[0]) == SQLITE_NULL || sqlite3_value_type(argv[1]) == SQLITE_NULL || sqlite3_value_type(argv[2]) == SQLITE_NULL ) {
                        sqlite3_result_null(context);
                        return;
                    }
                    
                    double price = sqlite3_value_double(argv[0]);
                    // Frequency of the
                    NSString *frequency = [NSString stringWithFormat:@"%s",(char*)sqlite3_value_text(argv[1])];
                    // Get the required format pcm,pcw, etc
                    NSString *format = [NSString stringWithFormat:@"%s",(char*)sqlite3_value_text(argv[2])];
                    //[format lowercaseString]
                    
                    double conversionValue = price;
                    // Convert to PCM
                    
                    NSString *frequencyUpperCase = [frequency uppercaseString];
                    NSString *formatUpperCase = [format uppercaseString];
                    
                    if (![frequencyUpperCase isEqualToString:formatUpperCase])
                    {
                        if([frequencyUpperCase isEqualToString:@"PW"] || [frequencyUpperCase isEqualToString:@"WEEKLY"])
                        {
                            conversionValue = ((price * 52)/12);
                        }
                        else if([frequencyUpperCase isEqualToString:@"QUARTERLY"])
                        {
                            conversionValue = price/3;
                        }
                        else if([frequencyUpperCase isEqualToString:@"ANNUAL"] || [frequencyUpperCase isEqualToString:@"YEARLY"])
                        {
                            conversionValue = price/12;
                        }
                        
                        if([formatUpperCase isEqualToString:@"PW"] || [formatUpperCase isEqualToString:@"WEEKLY"])
                        {
                            conversionValue =  ((conversionValue * 12)/52);
                        }
                        else if([formatUpperCase isEqualToString:@"QUARTERLY"])
                        {
                            conversionValue = conversionValue*3;
                        }
                        else if([formatUpperCase isEqualToString:@"ANNUAL"] || [formatUpperCase isEqualToString:@"YEARLY"])
                        {
                            conversionValue = conversionValue*12;
                        }
                    }
                    
                    sqlite3_result_double(context, conversionValue);
                }];
}

@end
