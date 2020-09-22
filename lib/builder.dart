import 'package:build/build.dart';
import 'package:firebase_model_generator/builders/builders.dart';
import 'package:source_gen/source_gen.dart';

Builder firebaseModel(BuilderOptions options) =>
    SharedPartBuilder([FirebaseModelGenerator()], 'firebase_model');
