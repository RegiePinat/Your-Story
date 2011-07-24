#import "Room.h"

@implementation Room

@synthesize layers, mainLayer;

- (mapSize)getSize {
	return mainLayer.size;
}

- (id)initWithName:(NSString *)roomName {
	if ([super init]==nil) return nil;
	
	// dictionary to cache maps used
	maps = [[NSMutableDictionary alloc] initWithCapacity:0];
	// populate dictionary from plist
	NSString *roomFilePath = [[NSBundle mainBundle] pathForResource:roomName ofType:@"plist"];
	NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:roomFilePath];
	
	
	// create layer objects
	layers = [NSMutableArray arrayWithCapacity:0];
	for (NSDictionary *layerInfo in [info valueForKey:@"Layers"]) {
		Layer *layer = [[Layer alloc] initWithDictionary:layerInfo];
		[layers addObject:layer];
		if ([[layerInfo valueForKey:@"Main"] boolValue]) {
			mainLayer = layer;
		}
	}
		
	return self;
}
// 
// - (void)writeToFile:(NSString *)path {
// 	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:0];
// 	[info setValue:
// }

- (TileMap *)getMap:(NSString *)mapName {
	// get the map with the given name, caching the results for future use
	if ([maps valueForKey:mapName]) {
		return [maps valueForKey:mapName];
	}
	
	TileMap *newMap = [[TileMap alloc] initWithImage:[NSImage imageNamed:mapName]];
	[maps setValue:newMap forKey:mapName];
	return newMap;
}

@end
