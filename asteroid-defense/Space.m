//
//  MyScene.m
//  asteroid-defense
//
//  Created by Adam Borzecki on 2014-04-12.
//  Copyright (c) 2014 Adam Borzecki. All rights reserved.
//

#import "Space.h"
#import "Asteroid.h"
#import "Game.h"
#import "Nuke.h"
#import "Earth.h"

#define kRADIAL_GRAVITY_FORCE 1000.0f
#define ASTEROID_SPAWN_DISTANCE 1500.0f
#define LAUNCH_INTERVAL 3.0f

@implementation Space

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size])
    {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor blackColor];
        
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f);
        
        [self placeEarth];
    }
    return self;
}

- (CGPoint)earthPoint
{
    return CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
}

- (void)placeEarth
{
    earth = [Earth new];
    earth.position = self.earthPoint;
    [self addChild:earth];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *anyTouch = [touches anyObject];
    touchLocation = [anyTouch locationInNode:self];
    
    NSString *burstPath =
    [[NSBundle mainBundle]
     pathForResource:@"FingerTracker" ofType:@"sks"];
    
    fingerTracker = [NSKeyedUnarchiver unarchiveObjectWithFile:burstPath];
    fingerTracker.targetNode = self;
    
    fingerTracker.position = touchLocation;
    
    [self addChild:fingerTracker];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    fingerTracker.position = [[touches anyObject] locationInNode:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *anyTouch = [touches anyObject];
    
    [fingerTracker removeFromParent];
    [self launchMissileTowards:[anyTouch locationInNode:self]];
}

- (void) spawnAsteroid
{
    float angle = arc4random_uniform( 360.0 ) * M_PI / 180.0;
    
    CGPoint o = earth.position;
    CGPoint p = CGPointMake( o.x + ASTEROID_SPAWN_DISTANCE, o.y );
    
    CGFloat xPoint = cosf( angle ) * ( p.x - o.x ) - sinf( angle ) * ( p.y - o.y ) + o.x;
    CGFloat yPoint = sinf( angle ) * ( p.x - o.x ) + cosf( angle ) * ( p.y - o.y ) + o.y;
    
    CGPoint spawnPoint = CGPointMake( xPoint, yPoint );
    
    Asteroid *asteroid = [Asteroid new];
    asteroid.position = spawnPoint;
    
    asteroid.velocity = CGVectorMake( o.x - spawnPoint.x, o.y - spawnPoint.y );
    
    [self addChild:asteroid];
}

- (void)launchMissileTowards:(CGPoint)targetPoint
{
    CGPoint originPoint = self.earthPoint;
    CGVector vector = CGVectorMake( targetPoint.x - originPoint.x, targetPoint.y - originPoint.y);
    
    Nuke *sprite = [Nuke new];
    
    sprite.position = originPoint;
    [sprite setVector:vector];
    
    [self addChild:sprite];
}

- (void) update:(NSTimeInterval)currentTime
{
    CGPoint earthPosition = earth.position;
    
    for( SKNode *child in self.children )
    {
        if( child && [child isKindOfClass:Asteroid.class])
        {
            Asteroid *asteroid = (Asteroid *)child;
            
            CGPoint position = child.position;
            CGFloat distance = sqrt( pow( position.x - earthPosition.x, 2.0) + (pow( position.y - earthPosition.y, 2.0 )));
            
            if( distance < 100 ) continue;
            
            CGFloat force = kRADIAL_GRAVITY_FORCE / ( distance * distance);
            CGVector radialGravityForce = CGVectorMake((earthPosition.x - position.x) * force, (earthPosition.y - position.y) * force);
            
            asteroid.radialGravity = radialGravityForce;
        }
    }
    
    if( currentTime - lastLaunch > LAUNCH_INTERVAL )
    {
        [self spawnAsteroid];
        lastLaunch = currentTime;
    }
}

@end
