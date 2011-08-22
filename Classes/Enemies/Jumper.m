//
//  Jumper.m
//  Your Story
//
//  Created by Max Williams on 21/08/2011.
//  Copyright 2011 Max Williams. All rights reserved.
//

#import "Jumper.h"
#import "Player.h"

#define JUMP_HEIGHT TILE_SIZE
#define JUMP_INTERVAL 1.5

@implementation Jumper

- (id)initWithPosition:(pixelCoords)position {
	if ([super init]==nil) return nil;
	
	body = cpBodyNew(5, INFINITY);
	cpBodySetPos(body, cpv(position.x, position.y));
	cpBodySetUserData(body, self);
	
	shape = cpCircleShapeNew(body, 8.0, cpvzero);
	cpShapeSetCollisionType(shape, [self class]);
	cpShapeSetFriction(shape, 0.7);
	cpShapeSetGroup(shape, self);
	
	Texture *texture = [Texture textureNamed:@"MainSprites.psd"];
	bodySprites = [NSDictionary dictionaryWithObjectsAndKeys:
		[[Sprite alloc] initWithTexture:texture texRect:pixelRectMake(0, 16, 16, 16)], @"airborne",
		[[Sprite alloc] initWithTexture:texture texRect:pixelRectMake(16, 16, 16, 16)], @"crouched",
		[[Sprite alloc] initWithTexture:texture texRect:pixelRectMake(0, 32, 16, 16)], @"idle",
	nil];
	eyesSprites = [NSDictionary dictionaryWithObjectsAndKeys:
		[[Sprite alloc] initWithTexture:texture texRect:pixelRectMake(20, 32, 8, 4)], @"bl",
		[[Sprite alloc] initWithTexture:texture texRect:pixelRectMake(20, 36, 8, 4)], @"tl",
		[[Sprite alloc] initWithTexture:texture texRect:pixelRectMake(20, 40, 8, 4)], @"tr",
		[[Sprite alloc] initWithTexture:texture texRect:pixelRectMake(20, 44, 8, 4)], @"br",
	nil];
	
	lastJumpTime = -INFINITY;
	
	return self;
}

static inline cpFloat
cpfsign(cpFloat f)
{
	return (f > 0) - (f < 0);
}

- (void)update:(Game *)game {
	UpdateGroundingContext(body, &grounding);
	
	Player *player = game.player;
	cpVect playerPos = player.position;
	cpVect pos = cpBodyGetPos(body);
	
	double elapsed = game.fixedTime - lastJumpTime;
	
	// can the jumper see the player?
	canSeePlayer = NO;
	BOOL nearPlayer = cpvnear(playerPos, pos, 96);
	if (nearPlayer) {
		cpShape *hit = cpSpaceSegmentQueryFirst(game.space, pos, playerPos, CP_ALL_LAYERS, self, NULL);
		if (hit && hit->body == player.body) {
			canSeePlayer = YES;
		}
	}
	
	// no longer just jumped?
	if (justJumped && elapsed > 0.1) {
		justJumped = NO;
	}
	
	// about to jump?
	if(grounding.body && elapsed > JUMP_INTERVAL - 0.2 && canSeePlayer){
		aboutToJump = YES;
	}
	
	// should jump?
	if(grounding.body && elapsed > JUMP_INTERVAL && canSeePlayer){
		cpFloat jump_v = cpfsqrt(2.0*JUMP_HEIGHT*GRAVITY);
		body->v = cpvadd(grounding.body->v, cpv(cpfsign(playerPos.x - pos.x)*jump_v/1.5, jump_v));
		
		lastJumpTime = game.fixedTime;
		justJumped = YES;
		aboutToJump = NO;
	}
}


// TODO duplicated code
-(pixelCoords)pixelPosition
{
	// Correct the drawn position for overlap with the grounding object.
	cpVect pos = cpvadd(cpBodyGetPos(body), cpvmult(grounding.normal, grounding.penetration - COLLISION_SLOP));
	return pixelCoordsMake(round(pos.x), round(pos.y));
}

- (void)draw {	
	pixelCoords eyePos = self.pixelPosition;
	
	NSString *bodyKey = @"idle";
	eyePos.y = self.pixelPosition.y - 1;
	
	if (aboutToJump) {
		bodyKey = @"crouched";
		eyePos.y = self.pixelPosition.y - 3;
	}
	if (justJumped) {
		bodyKey = @"airborne";
		eyePos.y = self.pixelPosition.y + 3;
	}
	Sprite *bodySprite = [bodySprites valueForKey:bodyKey];
	
	NSString *eyesKey = nil;
	if (canSeePlayer) {
		Player *player = [Game game].player;
		cpVect playerPos = player.position;
		cpVect pos = cpBodyGetPos(body);
		if (pos.x < playerPos.x && pos.y < playerPos.y - 4) eyesKey = @"tr";
		if (pos.x > playerPos.x && pos.y < playerPos.y - 4) eyesKey = @"tl";
		if (pos.x < playerPos.x && pos.y > playerPos.y - 4) eyesKey = @"br";
		if (pos.x > playerPos.x && pos.y > playerPos.y - 4) eyesKey = @"bl";
	}
	Sprite *eyesSprite = [eyesSprites valueForKey:eyesKey];
	
	[bodySprite drawAt:self.pixelPosition];
	[eyesSprite drawAt:eyePos];
}

- (void)addToSpace:(cpSpace *)space {
	cpSpaceAddBody(space, body);
	cpSpaceAddShape(space, shape);
}

- (void)removeFromSpace:(cpSpace *)space {
	cpSpaceRemoveBody(space, body);
	cpSpaceRemoveShape(space, shape);
}

- (void)finalize {
	cpShapeFree(shape);
	cpBodyFree(body);
}

- (void)shotFrom:(cpVect)shotLocation {
	cpVect pos = cpBodyGetPos(body);
	float strength = 100 - cpvdist(pos, shotLocation);
	cpVect effect = cpvnormalize(cpv(1.0, 0.6));
	if (shotLocation.x > pos.x) {
		effect.x *= -1;
	}
	effect = cpvmult(effect, strength * 5);
	cpBodyApplyImpulse(body, effect, cpvzero);
}

@end
