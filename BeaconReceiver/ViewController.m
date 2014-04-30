//
//  ViewController.m
//  BeaconReceiver
//
//  Created by Cian Clarke on 29/04/2014.
//

#import "ViewController.h"

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
    
    self.statusLabel.text = @"Searching for beacons...";
    self.subLabel.text = @"";
    self.view.backgroundColor = [UIColor blackColor];


    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
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
        NSString *uuid = nearestBeacon.proximityUUID.UUIDString;

        int minor = [nearestBeacon.minor intValue];
        
        
        switch (minor)
        {
            // Take note of your minor IDs and replace them in this switch..
            case 4977:
                label = @"Product Office";
                sublabel = @"Serious work happens here";
                background = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
                break;
            case 4990:
                label = @"Sales Office";
                sublabel = @"Careful - salesguys abound";
                background = [UIColor redColor];
                break;
            case 4929:
                label = @"Biz";
                sublabel = @"D'business";
                background = [UIColor orangeColor];
                break;
            default:
                label = @"Where?";
                sublabel = @"Not sure where we are";
                background = [UIColor orangeColor];
                break;
        }
        NSLog(@"uuid: %@", uuid);
        NSLog(@"prox: %d", nearestBeacon.proximity);
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
