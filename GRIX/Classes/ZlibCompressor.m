//
//  ZlibCompressor.m
//  eboy
//
//  Created by Lucius Kwok on 12/7/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "ZlibCompressor.h"
#import <zlib.h>


@implementation ZlibCompressor
// Compress and uncompress with zlib

+ (NSData*)compressData:(NSData *)inputData {
	const NSUInteger kCompressedDataBufferSize = 32 * 1024;
	NSMutableData *outputData = [NSMutableData dataWithLength:kCompressedDataBufferSize];

	// Init
	int zErr;
	z_stream stream;
	bzero(&stream, sizeof(stream));
	stream.next_in = (Bytef *)[inputData bytes];
	stream.avail_in = (int)inputData.length;
	stream.next_out = [outputData mutableBytes];
	stream.avail_out = (int)outputData.length;
	zErr = deflateInit(&stream, 1);
	if (zErr != Z_OK) {
		NSLog (@"deflateInit() error: %d", zErr);
		return nil;
	}
	
	// Compress and finish.
	zErr = deflate(&stream, Z_FINISH);
	if (zErr < Z_OK) {
		NSLog (@"deflate(Z_FINISH) error: %d", zErr);
		return nil;
	}
	
	// End.
	zErr = deflateEnd(&stream);
	if (zErr < Z_OK) {
		NSLog (@"deflateEnd() error: %d", zErr);
	}
	
	// Adjust size of data object.
	[outputData setLength:stream.total_out];
	return outputData;
}

+ (NSData *)uncompressData:(NSData *)inputData {
	const NSUInteger kBufferSize = 256 * 1024;
	NSMutableData *outputData = [NSMutableData dataWithLength:kBufferSize];
	
	// Init
	int zErr;
	z_stream stream;
	bzero(&stream, sizeof(stream));
	stream.next_in = (Bytef *)[inputData bytes];
	stream.avail_in = (int)inputData.length;
	stream.next_out = [outputData mutableBytes];
	stream.avail_out = (int)outputData.length;
	zErr = inflateInit(&stream);
	if (zErr != Z_OK) {
		NSLog (@"inflateInit() error: %d", zErr);
		return nil;
	}

	// Decompress and finish.
	zErr = inflate(&stream, Z_FINISH);
	if (zErr < Z_OK) {
		NSLog (@"inflate() error: %d", zErr);
		return nil;
	}
	
	// End.
	zErr = inflateEnd(&stream);
	if (zErr < Z_OK)
		NSLog (@"inflateEnd() error: %d", zErr);

	// Adjust size of data object.
	[outputData setLength:stream.total_out];
	return outputData;
}

+ (NSData *)uncompressFile:(NSURL *)inputFile {
	// Open input file.
	const char *path = [[inputFile path] cStringUsingEncoding:NSMacOSRomanStringEncoding];
	if (path == nil)
		return nil;
	gzFile file = gzopen(path, "rb");
	
	// Read bytes
	const NSUInteger kBufferSize = 128 * 1024;
	NSMutableData *outputData = [NSMutableData data];
	int bytesRead = kBufferSize;

	while (bytesRead == kBufferSize) {
		NSMutableData *bufferData = [NSMutableData dataWithLength:kBufferSize];
		bytesRead = gzread(file, [bufferData mutableBytes], (int)bufferData.length);
		if (bytesRead > 0) {
			bufferData.length = bytesRead;
			[outputData appendData:bufferData];
		}
	}
	
	return outputData;
}

@end
