import 'package:ffigen/ffigen.dart';

final config = FfiGenerator(
  headers: Headers(
    entryPoints: [
      Uri.file(
        '$macSdkPath/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioPlayer.h',
      ),
    ],
  ),
  objectiveC: ObjectiveC(
    interfaces: Interfaces.includeSet({'AVAudioPlayer'}),
  ),
	output: Output(
    dartFile: Uri.file('lib/avf_audio_bindings.dart'),
    preamble: '''
// ignore_for_file: camel_case_types, non_constant_identifier_names, unused_element, unused_field, void_checks, annotate_overrides, no_leading_underscores_for_local_identifiers, library_private_types_in_public_api
'''
  ),
);

void main() => config.generate();
