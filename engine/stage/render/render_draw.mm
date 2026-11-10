#include "stage/render/render_draw.h"

#import <Cocoa/Cocoa.h>

#include <cstdint>
#include <vector>

#include "stage/render/render_layers.h"
#include "stage/render/render_stage.h"

bool shoot(Stage& s, const char* path) {
    // This buffer belongs to the call: stages of other sizes, such as the window's tiles, shoot on
    // other threads at the same time. draw waits for the read to finish.
    std::vector<uint8_t> pic((size_t)s.w * s.h * 4);
    for (int i = 0; i < 3; ++i) draw(s, i == 2 ? &pic : nullptr);
    uint8_t* plane = pic.data();
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&plane pixelsWide:s.w pixelsHigh:s.h bitsPerSample:8 samplesPerPixel:4
                                                                        hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:s.w * 4 bitsPerPixel:32];
    return [[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}] writeToFile:@(path) atomically:YES];
}
