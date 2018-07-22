import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path/path.dart' as path;

import 'package:path_provider/path_provider.dart';

import 'package:flouze_flutter/flouze_flutter.dart';

import 'package:flouze/pages/account_list.dart';

class WelcomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  SledRepository _repository;

  @override
  Widget build(BuildContext context) {
    return new Container(
      color: Theme.of(context).primaryColor,
      child: Center(
        child: new Text(
          'Flouze!',
          style: Theme.of(context).textTheme.body1.apply(color: Colors.white, fontSizeFactor: 6.00)
        ),
      )
    );
  }

  Future<void> initFlouze() async {
    try {
      print('Loading Flouze library');
      await FlouzeFlutter.init();

      Directory appDocDir = await getApplicationDocumentsDirectory();
      final String dbPath = path.join(appDocDir.path, 'flouze.db');

      print('Initializing database in $dbPath');
      SledRepository repository = await SledRepository.fromFile(dbPath);

      if (!mounted) {
        return;
      }

      setState(() { _repository = repository; });

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => new AccountListPage(repository: _repository))
      );
    } on PlatformException catch (e) {
      print('Error while initializing Flouze: ${e.message}');
    }

    if (!mounted) return;
  }

  @override
  void initState() {
    super.initState();
    initFlouze();
  }
}