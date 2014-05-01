//
//  ViewController.m
//  BeaconReceiver
//
//  Created by Cian Clarke on 29/04/2014.
//

#import "ViewController.h"
#import "FH/FH.h"
#import "FH/FHResponse.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Init loc manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // Obtained from iBeacon manufacturer
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"8deefbb9-f738-4297-8040-96668bb44281"];

    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                             identifier:@"com.cianclarke.myregion"];
    
    // Tell location manager to start monitoring for the beacon region
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    
    self.statusLabel.text = @"Searching";
    self.subLabel.text = @"Here beacons beacons...";
    self.view.backgroundColor = [UIColor blackColor];
    
    void (^success)(FHResponse *)=^(FHResponse * res){
        FHActRequest * action = (FHActRequest *) [FH buildActRequest:@"beacons" WithArgs:[NSDictionary dictionary]];
        [action execAsyncWithSuccess:^(FHResponse * actRes){
            [self setBeaconData: [actRes parsedResponse]];
            // Now that we have the beacon data, start looking for beacons!
            [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
        } AndFailure:^(FHResponse * actFailRes){
            NSLog(@"Failed to read beacon data. Response = %@", actFailRes.rawResponse);
        }];

    };
    
    void (^failure)(id)=^(FHResponse * res){
        NSLog(@"FH init failed. Response = %@", res.rawResponse);
    };
    
    [FH initWithSuccess:success AndFailure:failure];
}

- (void)locationManager:(CLLocationManager*)manager didEnterRegion:(CLRegion*)region
{
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager*)manager didExitRegion:(CLRegion*)region
{
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    self.statusLabel.text = @"Exited region";
}

-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region
{
    // Beacon found!

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"proximity = %d", 1];
    NSArray *nearbyBeacons = [beacons filteredArrayUsingPredicate:predicate];
    NSString *label = @"";
    NSString *sublabel = @"";
    UIColor *background = [UIColor blackColor];
    
    if (nearbyBeacons.count == 0){
        label = @"Beacons found.";
        sublabel = @"None in this room.";
        // NB: This happens a lot, no apparent reason..
        return;
    }else{
        NSLog(@"Nearby beacons: %d", nearbyBeacons.count);
        CLBeacon *nearestBeacon = [nearbyBeacons firstObject];
        
        // You can retrieve the beacon data from its properties
        NSDictionary *beaconConfig = [self.beaconData objectForKey: [nearestBeacon.minor stringValue]];
        label = [beaconConfig objectForKey:@"label"];
        sublabel = [beaconConfig objectForKey:@"sublabel"];
        // Make a hex background color from our object config string : http://stackoverflow.com/questions/3056757/how-to-convert-an-nsstring-to-hex-values
        NSMutableString *tempHex=[[NSMutableString alloc] init];
        [tempHex appendString:@"0x"];
        [tempHex appendString:[beaconConfig objectForKey:@"color"]];
        unsigned colorInt = 0;
        [[NSScanner scannerWithString:tempHex] scanHexInt:&colorInt];

        background = UIColorFromRGB(colorInt);

    }

    self.statusLabel.text = label;
    self.subLabel.text = sublabel;
    self.view.backgroundColor = background;
    NSLog(@"beacons found: %d", beacons.count);
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
