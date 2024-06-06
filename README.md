# jpg-stream

A streaming JPEG encoder and decoder for Node and the browser. It is a direct compilation
of [libjpeg](http://www.ijg.org) to JavaScript using [Emscripten](http://emscripten.org/).

This fork:
- makes the build repeatable using docker, nix, and emscripten v1
- exposes the libjpeg optimize_coding option on `JPEGEncoder` as `optimizeCoding`
- is compiled with emscripten's `ALLOW_MEMORY_GROWTH=1`

Original embind work done by @devongovett in [jpg-stream](https://github.com/devongovett/jpg-stream)

## Installation

    npm install @stealthybox/jpg-stream

### Building

Compiling this package currently depends on Emscripten v1.
This fork publishes a public docker image that can be used like so:
```shell
make docker-compile
```
You can also rebuild the image for yourself:
```shell
ORG=$USER make docker-image
ORG=$USER make docker-push
ORG=$USER make docker-compile
```

For the browser, you can build using [Browserify](http://browserify.org/).

## Decoding

This example uses the [concat-frames](https://github.com/devongovett/concat-frames)
module to collect the output of the JPEG decoder into a single buffer.
It also shows how to get EXIF metadata contained in the JPEG file.

```javascript
var JPEGDecoder = require('jpg-stream/decoder');
var concat = require('concat-frames');

// decode a JPEG file to RGB pixels
fs.createReadStream('in.jpg')
  .pipe(new JPEGDecoder)
  .on('meta', function(meta) {
    // meta contains an exif object as decoded by
    // https://github.com/devongovett/exif-reader
  })
  .pipe(concat(function(frames) {
    // frames is an array of frame objects (one for JPEGs)
    // each element has a `pixels` property containing
    // the raw RGB pixel data for that frame, as
    // well as the width, height, etc.
  }));
```

### Scaling

Large JPEGs from DSLRs can be somewhat slow to decode.  If you don't need the image at
its full size for preview, or will be resizing the image anyway, there is an option to
perform scaling at decode time.  This improves performance dramatically since only the
DCT coefficients necessary for the desired size are decoded.

To specify decode scaling, provide `width` and `height` options to the decoder.  This
represents the minimum size you want, and the decoder will output an image of at least
this size, but likely not exactly that size. For exact resizing, provide your minimum
allowed size to the decoder and use the [resize-pixels](https://github.com/devongovett/resize-pixels)
module to resize the JPEG decoder's output to the exact size.

```javascript
fs.createReadStream('large.jpg')
  .pipe(new JPEGDecoder({ width: 600, height: 400 }))
  .pipe(concat(function(frames) {
    // frames[0].width >= 600 and frames[0].height >= 400
  }));
```

## Encoding

You can encode a JPEG by writing or piping pixel data to a `JPEGEncoder` stream.
You can set the `quality` option to a number between 1 and 100 to control the
size vs quality tradeoff made by the encoder.

The `optimizeCoding` option defaults to `false` and will use the JPEG standard
huffman tables to produce output data as input pixels are processed.

You can set the `optimizeCoding` option to `true` to tell the encoder optimize the
huffman tables used to code/compress the image data. This requires a second pass
over all of 8x8 MCU's (after DCT and quantization has been performed). This can
result in significantly smaller jpeg output, but at the cost of blocking the output
stream until the input has been fully processed.
Memory usage with `optimizeCoding` enabled is much higher.
This fork has been compiled with ALLOW_MEMORY_GROWTH=1 to support the internal buffer
needed for libjpeg to compute the tables.

The JPEG encoder supports writing data in the RGB, grayscale, or CMYK color spaces.
If you need to convert from another unsupported color space, first pipe your data
through the [color-transform](https://github.com/devongovett/color-transform) module.

```javascript
var PNGDecoder = require('png-stream/decoder');
var JPEGEncoder = require('jpg-stream/encoder');
var ColorTransform = require('color-transform');

// convert a PNG to a JPEG
fs.createReadStream('in.png')
  .pipe(new PNGDecoder)
  .pipe(new JPEGEncoder({ quality: 80 }))
  .pipe(fs.createWriteStream('out.jpg'));

// produce a smaller, optimized JPEG
fs.createReadStream('in.png')
  .pipe(new PNGDecoder)
  .pipe(new JPEGEncoder({ quality: 80, optimizeCoding: true }))
  .pipe(fs.createWriteStream('out.jpg'));
  
// colorspace conversion to convert from RGBA to RGB
fs.createReadStream('rgba.png')
  .pipe(new PNGDecoder)
  .pipe(new ColorTransform('rgb'))
  .pipe(new JPEGEncoder)
  .pipe(fs.createWriteStream('rgb.jpg'));
```

## License

MIT
