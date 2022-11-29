import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:http/http.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_tag_app/nfcClass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((value) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
          androidOverscrollIndicator: AndroidOverscrollIndicator.stretch),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool? dialog;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _sharePref();
    _nfc();
  }

  void _sharePref() async {
    // Obtain shared preferences.
    final prefs = await SharedPreferences.getInstance();

    var fromPref = await prefs.getStringList('NfcRecords');
    if (fromPref != null && fromPref.isNotEmpty) {
      var savedRecords = fromPref.map((e) {
        var decoded = jsonDecode(e);
        return NFCRecord(
            id: decoded["id"], name: decoded["name"], api: decoded["api"]);
      }).toList();
      records = savedRecords;
      setState(() {});
    }
  }

  void _nfc() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (isAvailable) {
      // Start Session
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          await _processTags(tag);
        },
      );
    }
  }

  List records = [NFCRecord.empty()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          // Status bar color
          statusBarColor: Colors.transparent,

          // Status bar brightness (optional)
          statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
          statusBarBrightness: Brightness.light, // For iOS (dark icons)
        ),
        backgroundColor: Colors.white,
        title: Text("NFC Tags", style: TextStyle(color: Colors.black)),
        elevation: 0.2,
        actions: [
          IconButton(
              onPressed: () => _processTags(null),
              icon: Icon(Icons.add_rounded, color: Colors.grey.shade400))
        ],
      ),
      body: Scrollbar(
        radius: Radius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: (records.length > 1
              ? AnimationLimiter(
                  child: GridView.count(
                    crossAxisCount: 3,
                    children: List.generate(
                      records.length,
                      (int index) {
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          columnCount: 10,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: ZoomTapAnimation(
                                onTap: () => (records[index].id != "hint")
                                    ? callApi(records[index].api)
                                    : null,
                                onLongTap: () => (records[index].id != "hint")
                                    ? showSettings(records[index])
                                    : null,
                                begin: 1.0,
                                end: 0.93,
                                beginDuration: const Duration(milliseconds: 20),
                                endDuration: const Duration(milliseconds: 300),
                                beginCurve: Curves.decelerate,
                                endCurve: Curves.fastOutSlowIn,
                                child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    // elevation: 10,
                                    elevation: 10,
                                    shadowColor: Colors.black.withOpacity(0.05),
                                    child: (records[index].id != "hint")
                                        ? Stack(
                                            children: [
                                              Positioned(
                                                top: 10,
                                                right: 5,
                                                child: GestureDetector(
                                                    onTap: () => showSettings(
                                                        records[index]),
                                                    child: Icon(
                                                      Icons.settings,
                                                      color: Colors.black26,
                                                    )),
                                              ),
                                              Align(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    records[index].name,
                                                  ))
                                            ],
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Center(
                                              child: Text(
                                                "Scan to add more",
                                                style: TextStyle(
                                                    color: Colors.grey[400]),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    "Place the prepared NFC tag on the phone’s NFC scanning area",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )),
        ),
      ),
    );
  }

  void callApi(String api) async {
    if (api == "" || api == null) {
      var snackBar =
          SnackBar(content: Text("Please set an api for this tag first"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      dialog = true;
      await showDialog(
          context: context,
          builder: (_) {
            return Center(
              child: Material(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: FutureBuilder(
                      future: sentRequest(api),
                      builder: (__, s) {
                        if (s.hasData && s.data is Response) {
                          closeResponseDialog(__);
                          var data = s.data as Response;
                          var body;
                          try {
                            body = jsonDecode(data.body);
                          } catch (e) {}
                          switch (data.statusCode) {
                            case 201:
                            case 202:
                            case 200:
                              return Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 100,
                              );
                            case 400:
                            case 401:
                            case 404:
                            case 500:
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Colors.red[800],
                                    size: 100,
                                  ),
                                  ...(body != null && body['message'] != null)
                                      ? [Text(body['message'])]
                                      : []
                                ],
                              );

                            default:
                              return Text("${data.statusCode}");
                          }
                        }

                        return CircularProgressIndicator();
                      }),
                ),
              ),
            );
          });
      dialog = null;
    }
  }

  void closeResponseDialog(__) async {
    await Future.delayed(Duration(seconds: 3));
    if (dialog != null) {
      Navigator.pop(__);
    }
  }

  Future<Response?> sentRequest(api) async {
    try {
      return await get(Uri.parse('$api'), headers: {
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      }).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          // Time has run out, do what you wanted to do.
          return Response('Error', 408); // Request Timeout response status code
        },
      );
    } catch (ex) {
      return Response('Error', 408);
    }
  }

  void showSettings(item) {
    showModalBottomSheet(
        barrierColor: Colors.black12,
        isScrollControlled: true,
        context: context,
        builder: (_) {
          return Container(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  onTap: () {
                    records.removeWhere((element) => element == item);
                    updateSharePref();
                    setState(() {});
                    Navigator.pop(context);
                  },
                  title: Text(
                    "Remove this record",
                    style: TextStyle(color: Colors.red[800]),
                    textAlign: TextAlign.center,
                  ),
                ),
                ListTile(
                  onTap: () async {
                    var result = await showEditingDialog(item.name, item.api);

                    if (result != null && result.isNotEmpty) {
                      var index =
                          records.indexWhere((element) => element == item);
                      if (index != -1) {
                        var newData = NFCRecord(
                            id: item.id,
                            name: result["name"],
                            api: result["api"]);

                        records.removeAt(index);
                        records.insert(index, newData);
                        updateSharePref();
                      }

                      setState(() {});
                    }
                    dialog = null;
                  },
                  title: Text(
                    "Edit this record",
                    // style: TextStyle(color: Colors.red[800]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        });
  }

  void updateSharePref() async {
    // Obtain shared preferences.
    final prefs = await SharedPreferences.getInstance();
    var toStringList = records
        .map((e) => jsonEncode({"id": e.id, "name": e.name, "api": e.api}))
        .toList();
    // print(toStringList);
    await prefs.setStringList('NfcRecords', toStringList);
  }

  Future<Map?> showAddingDialog() async {
    var result = await showModalBottomSheet(
        barrierColor: Colors.black12,
        isScrollControlled: true,
        context: context,
        builder: (_) {
          return createNewRecord(
            name: null,
            api: null,
          );
        });
    return result;
  }

  Future<Map?> showEditingDialog(String name, String api) async {
    var result = await showModalBottomSheet(
        barrierColor: Colors.black12,
        isScrollControlled: true,
        context: context,
        builder: (_) {
          return createNewRecord(
            name: name,
            api: api,
          );
        });
    return result;
  }

  _processTags(tag) async {
    if (dialog == null) {
      NFCRecord? target;
      if (tag == null) {
        target = NFCRecord(id: Uuid().v4());
      } else if (tag.data["nfca"]["identifier"] != null) {
        target = NFCRecord(id: tag.data["nfca"]["identifier"].toString());
      } else if (tag.data["mifareultralight"]["identifier"] != null) {
        target = NFCRecord(
            id: tag.data["mifareultralight"]["identifier"].toString());
      } else if (tag.data["ndef"]["identifier"] != null) {
        target = NFCRecord(id: tag.data["ndef"]["identifier"].toString());
      }

      if (target != null) {
        FlutterRingtonePlayer.playNotification();
        if ((records.any((element) => element.id == target!.id))) {
          callApi(
              records.firstWhere((element) => element.id == target!.id).api);
        } else {
          dialog = true;
          var result = await showAddingDialog();
          if (result != null && result.isNotEmpty) {
            // target.name =;
            target = NFCRecord(
                id: target.id, name: result["name"], api: result["api"]);
            records.add(target);
            updateSharePref();
            setState(() {});
          }
          dialog = null;
        }
      }
    }
  }
}

class createNewRecord extends StatefulWidget {
  final String? name;
  final String? api;
  const createNewRecord({Key? key, required this.name, required this.api})
      : super(key: key);

  @override
  State<createNewRecord> createState() => _createNewRecordState();
}

class _createNewRecordState extends State<createNewRecord> {
  TextEditingController nameController = TextEditingController();
  TextEditingController apiController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    nameController.text = widget.name ?? "";
    apiController.text = widget.api ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                (widget.name == null && widget.api == null)
                    ? "Adding new tag"
                    : "Editing tag ${widget.name}",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topRight,
                child: CupertinoButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        "name": nameController.text,
                        "api": apiController.text
                      });
                    },
                    child: Text(
                      (widget.name == null && widget.api == null)
                          ? "Add"
                          : "Save",
                      textAlign: TextAlign.center,
                    )),
              ),
            )
          ],
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.all(10.0)
              .copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                child: Text("Give a name to this tag:"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: CupertinoTextField(
                    controller: nameController, placeholder: "Name"),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                child: Text("Api to call for this tag:"),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: CupertinoTextField(
                    controller: apiController, placeholder: "Api"),
              ),
            ],
          ),
        )
      ],
    );
  }
}
