import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/config.dart';
import '/food.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

final configurations = Configurations();
String selectedLanguageValue = "goods";
List<String> favorite = [];
final List<Map<String, String>> supportedLanguages = [
  {'label': 'English', 'value': 'goods'},
  {'label': '简体中文', 'value': 'zh'},
  {'label': '한국어', 'value': 'ko'},
  {'label': 'español', 'value': 'es'}
];
Future<void> main() async {
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: configurations.apiKey,
          appId: configurations.appId,
          storageBucket: configurations.storageBucket,
          messagingSenderId: configurations.messagingSenderId,
          projectId: configurations.projectId));
  await FirebaseAppCheck.instance.activate(
    webProvider:
        ReCaptchaV3Provider('6Lcubc4qAAAAADNQdfZd8R0pww8vZU1uhkvActjv'),
  );
  runApp(const firestore());
}

// ignore: camel_case_types
class firestore extends StatelessWidget {
  const firestore({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
            primarySwatch: Colors.brown, fontFamily: 'PlayfairDisplay'),
        debugShowCheckedModeBanner: false,
        home: EngPageState());
  }
}
