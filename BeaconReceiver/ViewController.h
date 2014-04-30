//
//  ViewController.h
//  BeaconReceiver
//
//  Created by Cian Clarke on 29/04/2014.
//  Copyright (c) 2014 FeedHenry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController<CLLocationManagerDelegate>

@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *subLabel;
@property (strong, nonatomic) IBOutlet UIView *view;

@end
