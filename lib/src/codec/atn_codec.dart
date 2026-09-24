import 'dart:convert';
import 'dart:typed_data';

import 'package:atnkit/src/codec/atn_decoder.dart';
import 'package:atnkit/src/codec/atn_encoder.dart';
import 'package:atnkit/src/model/atn_file.dart';
import 'package:atnkit/src/model/atn_options.dart';

/// Converts ATN models to and from their binary representation.
final class AtnCodec extends Codec<AtnFile, List<int>> {
  /// Options applied while decoding.
  final AtnDecodeOptions decodeOptions;

  /// Options applied while encoding.
  final AtnEncodeOptions encodeOptions;

  /// Creates a reusable codec with fixed policies.
  const AtnCodec({
    this.decodeOptions = const AtnDecodeOptions(),
    this.encodeOptions = const AtnEncodeOptions(),
  });

  @override
  AtnDecoder get decoder => AtnDecoder(options: decodeOptions);

  @override
  AtnEncoder get encoder => AtnEncoder(options: encodeOptions);

  @override
  Uint8List encode(AtnFile input) => encoder.convert(input);
}
