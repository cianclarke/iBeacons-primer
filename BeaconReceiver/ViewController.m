//
//  ViewController.m
//  BeaconReceiver
//
//  Created by Cian Clarke on 29/04/2014.
//

#import "ViewController.h"
#import "FH/FH.h"
#import "FH/FHResponse.h"
#import "Math.h"


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
    self.beaconCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)beacons.count];
    if (beacons.count == 3){
        CLBeacon *a = [[beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"minor = %d", 4977]] firstObject];
        CLBeacon *b = [[beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"minor = %d", 4990]] firstObject];
        CLBeacon *c = [[beacons filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"minor = %d", 4929]] firstObject];
        NSDictionary *aConfig = [self.beaconData objectForKey: [a.minor stringValue]];
        NSDictionary *bConfig = [self.beaconData objectForKey: [b.minor stringValue]];
        NSDictionary *cConfig = [self.beaconData objectForKey: [c.minor stringValue]];
        float xa = 0; //[[aConfig valueForKey:@"locationX"] floatValue];
        float ya = 1; //[[aConfig valueForKey:@"locationY"] floatValue];
        float xb = -1; //[[bConfig valueForKey:@"locationX"] floatValue];
        float yb = -1; //[[bConfig valueForKey:@"locationY"] floatValue];
        float xc = 1; //[[bConfig valueForKey:@"locationX"] floatValue];
        float yc = -1; //[[bConfig valueForKey:@"locationY"] floatValue];
        float ra =  (double)[self calculateAccuracyWithRSSI:(double)[[a valueForKey:@"rssi"] floatValue]];
        float rb =  (double)[self calculateAccuracyWithRSSI:(double)[[b valueForKey:@"rssi"] floatValue]];
        float rc =  (double)[self calculateAccuracyWithRSSI:(double)[[c valueForKey:@"rssi"] floatValue]];
        
        float S = (powf(xc, 2.) - powf(xb, 2.) + powf(yc, 2.) - powf(yb, 2.) + powf(rb, 2.) - powf(rc, 2.)) / 2.0;
        float T = (pow(xa, 2.) - pow(xb, 2.) + pow(ya, 2.) - pow(yb, 2.) + pow(rb, 2.) - pow(ra, 2.)) / 2.0;
        float y = ((T * (xb - xc)) - (S * (xb - xa))) / (((ya - yb) * (xb - xc)) - ((yc - yb) * (xb - xa)));
        float x = ((y * (ya - yb)) - T) / (xb - xa);
        
        NSLog(@"Tianged to x:%f, y:%f", x, y);

        self.xLabel.text = [NSString stringWithFormat:@"%f",x];
        self.yLabel.text = [NSString stringWithFormat:@"%f",y];
        
        CGPoint point = CGPointMake(x, y);
        //return point;


    }

    self.statusLabel.text = label;
    self.subLabel.text = sublabel;
    self.view.backgroundColor = background;
}

- (double)calculateAccuracyWithRSSI:(double)rssi {
    //formula adapted from David Young's Radius Networks Android iBeacon Code
    if (rssi == 0) {
        return -1.0; // if we cannot determine accuracy, return -1.
    }
    
    
    double txPower = -70;
    double ratio = rssi*1.0/txPower;
    if (ratio < 1.0) {
        return pow(ratio,10);
    }
    else {
        double accuracy =  (0.89976) * pow(ratio,7.7095) + 0.111;
        return accuracy;
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
