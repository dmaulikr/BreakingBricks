//
//  MyScene.m
//  BreakingBricks
//
//  Created by Dulio Denis on 8/31/14.
//  Copyright (c) 2014 Dulio Denis. All rights reserved.
//

#import "MyScene.h"
#import "EndScene.h"
#import "HUDNode.h"

static const int BrickPoint = 1;
static const int BrickTier1 = 4; // Number of Bricks in Level
static const int BrickTier2 = 8; // Number of Bricks in Level


@interface MyScene()
@property (nonatomic) SKSpriteNode *paddle;
@property (nonatomic) SKAction *paddleSound;
@property (nonatomic) SKAction *brickSound;
@property (nonatomic) NSInteger level;
@property (nonatomic) NSInteger bricks;
@end


#pragma mark - Categories
static const uint32_t ballCategory       = 0x1;
static const uint32_t brickCategory      = 0x1 << 1;
static const uint32_t paddleCategory     = 0x1 << 2;
static const uint32_t edgeCategory       = 0x1 << 3;
static const uint32_t bottomEdgeCategory = 0x1 << 4;


@implementation MyScene

#pragma mark - Add the Ball, Add Impulse to the Ball

- (void)addBall:(CGSize)size {
    // create a new sprite node from an image
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"ball"];
    
    // create a CGPoint for position
    CGPoint point = CGPointMake(size.width/2, size.height/2);
    ball.position = point;
    ball.name = @"ball";
    
    // add a physics body
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ball.frame.size.width/2];
    ball.physicsBody.friction = 0;
    ball.physicsBody.linearDamping = 0;
    ball.physicsBody.restitution = 1;
    
    // add the category
    ball.physicsBody.categoryBitMask = ballCategory;
    
    // add the contact category notification with bricks and paddle
    ball.physicsBody.contactTestBitMask = brickCategory | paddleCategory | bottomEdgeCategory;
    
    // add the collision bitmask of the edge and the brick - ball passes right thru paddle
    // ball.physicsBody.collisionBitMask = edgeCategory | brickCategory;
    
    // add the sprite node to the scene
    [self addChild:ball];
    
    [self addImpulse];
}


- (void)addImpulse {
    // create a vector
    CGVector vector = CGVectorMake(10, 10);
    //apply the vector
    SKSpriteNode *ball = (SKSpriteNode*)[self childNodeWithName:@"ball"];
    [ball.physicsBody applyImpulse:vector];
}

#pragma mark - Add the Player

- (void)addPlayer:(CGSize)size {
    // create paddle sprite
    self.paddle = [SKSpriteNode spriteNodeWithImageNamed:@"paddle"];
    self.paddle.position = CGPointMake(size.width/2, 100);
    self.paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.paddle.frame.size];
    
    // make it static
    self.paddle.physicsBody.dynamic = NO;
    
    // add category
    self.paddle.physicsBody.categoryBitMask = paddleCategory;
    
    // add to scene
    [self addChild:self.paddle];
}


#pragma mark - Control the player

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        CGPoint newPosition = CGPointMake(location.x, 100);
        
        // stop the paddle from going to far
        if (newPosition.x < self.paddle.size.width/2) {
            newPosition.x = self.paddle.size.width/2;
        }
        if (newPosition.x > self.size.width - (self.paddle.size.width/2)) {
            newPosition.x = self.size.width - (self.paddle.size.width/2);
        }
        
        self.paddle.position = newPosition;
    }
}


#pragma mark - Add Bricks

- (void)addBricks:(CGSize)size atLevel:(NSInteger)brickTier {
    for (int i = 0; i < 4; i++) {
        SKSpriteNode *brick = [SKSpriteNode spriteNodeWithImageNamed:@"brick"];
        
        // add a static physics body
        brick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:brick.frame.size];
        brick.physicsBody.dynamic = NO;
        
        // add category
        brick.physicsBody.categoryBitMask = brickCategory;
        
        int xPosition = size.width/5 * (i+1);
        int yPosition = size.height - 50;
        brick.position = CGPointMake(xPosition, yPosition);
        
        [self addChild:brick];
    }
    
    // if brickTier == 2 draw a second row
    if (brickTier == BrickTier2) {
        for (int i = 0; i < 4; i++) {
            SKSpriteNode *brick = [SKSpriteNode spriteNodeWithImageNamed:@"brick"];
            
            // add a static physics body
            brick.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:brick.frame.size];
            brick.physicsBody.dynamic = NO;
            
            // add category
            brick.physicsBody.categoryBitMask = brickCategory;
            
            int xPosition = size.width/5 * (i+1);
            int yPosition = size.height - 100;
            brick.position = CGPointMake(xPosition, yPosition);
            
            [self addChild:brick];
        }
    }
}


#pragma mark - Add Bottom Edge

- (void)addBottomEdge:(CGSize)size {
    SKNode *bottomEdge = [SKNode node];
    bottomEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(0, 1)
                                                          toPoint:CGPointMake(size.width, 1)];
    bottomEdge.physicsBody.categoryBitMask = bottomEdgeCategory;
    [self addChild:bottomEdge];
}


#pragma mark - Initialize the Scene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        self.backgroundColor = [SKColor blackColor];
        
        // add a physics body to the scene
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
        self.physicsBody.categoryBitMask = edgeCategory;
        
        // change the gravity settings of the physics world
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        self.physicsWorld.contactDelegate = self;
        
        // add the objects to the scene
        [self addBall:size];
        [self addPlayer:size];
        [self addBricks:size atLevel:BrickTier1];
        [self addBottomEdge:size];
        
        // preload sound effects
        self.paddleSound = [SKAction playSoundFileNamed:@"blip.caf" waitForCompletion:NO];
        self.brickSound = [SKAction playSoundFileNamed:@"brickhit.caf" waitForCompletion:NO];
        
        // initialize level and bricks: Level 1 = 4 Bricks
        self.level = 1;
        self.bricks = 4;
        
        HUDNode *hud = [HUDNode hudAtPosition:CGPointMake(0, self.frame.size.height-20)
                                      inFrame:self.frame];
        [self addChild:hud];
        [hud loadHighScore];
    }
    return self;
}


#pragma mark - Physics Contact Delegate Methods

- (void)didBeginContact:(SKPhysicsContact *)contact {
    // create a placeholder reference for the non-ball object
    SKPhysicsBody *notTheBall;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        notTheBall = contact.bodyB;
    } else {
        notTheBall = contact.bodyA;
    }
    
    if (notTheBall.categoryBitMask == brickCategory) {
        NSString *explosionPath = [[NSBundle mainBundle] pathForResource:@"BrickExplosion" ofType:@"sks"];
        SKEmitterNode *brickExplosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath ];
        brickExplosion.position = notTheBall.node.position;
        [self addChild:brickExplosion];
        [brickExplosion runAction:[SKAction waitForDuration:2.0] completion:^{
            [brickExplosion removeFromParent];
            [self ballSpeedAdjust];
        }];
        
        [notTheBall.node removeFromParent];
        
        // increment score
        [self addPoints:BrickPoint]; // the score is the number of demolished bricks
        
        // remove a brick
        self.bricks--;
        [self runAction:self.brickSound];
    }
    
    if (notTheBall.categoryBitMask == paddleCategory) {
        [self runAction:self.paddleSound];
    }
    
    if (notTheBall.categoryBitMask == bottomEdgeCategory) {
        // Game Over
        HUDNode *hud = (HUDNode*)[self childNodeWithName:@"hud"];
        [hud saveHighScore];
        
        EndScene *gameOver = [[EndScene alloc] initWithSize:self.size andScore:hud.score];
        
        [self.view presentScene:gameOver transition:[SKTransition doorsCloseHorizontalWithDuration:1.0]];
    }
}

#pragma mark - Check to see if the ball is slowing down or speeding up and adjust

- (void)ballSpeedAdjust {
    SKNode* ball = [self childNodeWithName: @"ball"];
    static int maxSpeed = 600;
    CGVector velocity = ball.physicsBody.velocity;
    float speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy);
    NSLog(@"SPEED = %f", speed);
    if (speed > maxSpeed) {
        ball.physicsBody.linearDamping = 0.4f;
    } else {
        ball.physicsBody.linearDamping = 0.0f;
    }
    if (speed < 275) [self addImpulse];
}


#pragma mark - Add Points to the Score, Save High Score
- (void)addPoints:(NSInteger)points {
    HUDNode *hud = (HUDNode*)[self childNodeWithName:@"hud"];
    [hud addPoints:points];
}


#pragma mark - Update Loop Actions

- (void)update:(NSTimeInterval)currentTime {
    // check to see if we have no more bricks
    
    if (self.bricks <= 0) {
        NSLog(@"Level Complete: %ld", (long)self.level);
        
        // check if level 1 make level 2 by adding 4 bricks
        if (self.level == 1) {
            self.bricks = BrickTier1;
            self.level++;
            [self addBricks:self.size atLevel:BrickTier1];
        }
        
        // level 2 and above get two row of 4 bricks
        if (self.level >= 2) {
            self.bricks = BrickTier2;
            self.level++;
            [self addBricks:self.size atLevel:BrickTier2];

            // Add a bit more force to the ball
            // [self addImpulse];
        }
    }
    [self ballSpeedAdjust];
}


- (void)didEvaluateActions {
    [self ballSpeedAdjust];
}

- (void)didSimulatePhysics {
    [self ballSpeedAdjust];
}

@end
