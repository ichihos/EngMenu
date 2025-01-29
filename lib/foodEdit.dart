import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food.dart';
import 'drinkEdit.dart';
import 'Edit.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'courseEdit.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class EngPageEditState extends StatefulWidget {
  EngPageEdit createState() => EngPageEdit();
}

class EngPageEdit extends State<EngPageEditState> {
  List<String> favorite = [];
  Color mycolor = Colors.lightGreen;

  void _showPicker(BuildContext context, String docid) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Pick a color!'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: mycolor, //default color
                onColorChanged: (Color color) {
                  //on color picked
                  setState(() {
                    mycolor = color;
                  });
                },
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('DONE'),
                onPressed: () {
                  updateDatabase(docid, mycolor.value);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: ((context) => EngPageEditState())));
                  //dismiss the color picker
                },
              ),
            ],
          );
        });
  }

  Future<void> updateDatabase(String docid, int color) async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Food')
        .collection('color')
        .doc(docid)
        .update({'color': color});
  }

  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('編集用ページ（店舗用）'),
      ),
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            spacer(5),
            menuButtons(),
            spacer(5),
            sectionTitlenew(),
            spacer(5),
            menulist(size),
          ],
        ),
      ),
    );
  }

  Widget menulist(size) => FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Food')
            .collection("titles")
            .orderBy('order')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final titles = snapshot.data!.docs;
            return Container(
              width: double.infinity,
              height: size.height - 160,
              child: ListView.builder(
                cacheExtent: 250.0 * titles.length - 1,
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: titles.length,
                itemBuilder: (context, index) {
                  return menuSection(titles[index]);
                },
              ),
            );
          }
          return Center(child: Text('読込中...'));
        },
      );

  Widget spacer(double height) => Container(padding: EdgeInsets.all(height));

  Widget noticeText(String text, Color color) =>
      Text(text, style: TextStyle(color: color));

  Widget menuButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => EngPageState())));
            },
            child: menuButton('編集終了'),
          ),
          Container(width: 15, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => EngDrinkEditPageState())));
            },
            child: menuButton('Drink編集'),
          ),
          Container(width: 15, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => EngCoursePageEditState())));
            },
            child: menuButton('コース編集'),
          ),
        ],
      );

  Widget menuButton(String text) => Container(
        alignment: Alignment.center,
        width: 100,
        height: 50,
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 53, 52, 52),
            borderRadius: BorderRadius.all(Radius.circular(20))),
      );

  Widget menuSection(DocumentSnapshot titles) => FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Food')
            .collection(titles['title'])
            .orderBy('order')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final documents = snapshot.data!.docs;
            return Column(
              children: [
                sectionTitle(titles),
                sectionContent(documents, titles['title']),
                spacer(30)
              ],
            );
          }
          return Center(child: Text('読込中...'));
        },
      );

  Widget sectionTitle(DocumentSnapshot title) => Align(
      alignment: Alignment.centerLeft,
      child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('Eng')
              .doc('Food')
              .collection('color')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final documents = snapshot.data!.docs;
              final color = documents[0]['color'];
              return InkWell(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) =>
                            TitleEditPage(title.id, title['title'], 'Food'))));
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20))),
                    width: double.infinity,
                    height: 30,
                    child: Row(children: [
                      Text('   ${title['title']}',
                          style: TextStyle(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              color: Colors.white)),
                      SizedBox(width: 10),
                      ElevatedButton(
                          onPressed: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) =>
                                    AddPostPageFoodnew(title['title']))));
                          },
                          child: Text('メニュー追加')),
                    ]),
                  ));
            }
            return Container();
          }));

  Widget sectionTitlenew() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
              color: Colors.lightGreen,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20))),
          width: double.infinity,
          height: 30,
          child: Row(children: [
            ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: ((context) => AddPostPagenew())));
                },
                child: Text('ジャンル追加')),
            SizedBox(width: 10),
            ElevatedButton(
                onPressed: () {
                  _showPicker(context, '8orAcU3UjLN7tBdKhRgA');
                },
                child: Text('テーマ変更')),
          ]),
        ),
      );

  Widget sectionContent(List<DocumentSnapshot> documents, String collection) =>
      Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.black, width: 3)),
        ),
        child: ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return menuItem(documents[index], collection, documents.length);
          },
        ),
      );

  Widget menuItem(DocumentSnapshot document, collection, length) {
    String docid = document.id;
    return InkWell(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: ((context) => AddPostPageFood(collection, docid))));
        },
        child: Card(
          child: ListTile(
            title: Text(document['goods']),
            subtitle: Text("${document['ja']}(タップで編集)"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await uploadPicture(
                          'Food', collection, document['goods'], docid);
                    },
                    child: Text('画像UP')),
                IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('Eng')
                          .doc('Food')
                          .collection(collection)
                          .doc(docid)
                          .delete();
                      if (length == 1) {
                        await FirebaseFirestore.instance
                            .collection('Eng')
                            .doc('Food')
                            .collection('titles')
                            .where('title', isEqualTo: collection)
                            .get()
                            .then((QuerySnapshot querySnapshot) {
                          querySnapshot.docs.forEach((doc) {
                            FirebaseFirestore.instance
                                .collection('Eng')
                                .doc('Food')
                                .collection('titles')
                                .doc(doc.id)
                                .delete();
                          });
                        });
                      }
                      if (document['image'] != "") {
                        await FirebaseStorage.instance
                            .ref()
                            .child(
                                'images/food/$collection/${document['goods']}.jpeg')
                            .delete();
                      }
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: ((context) => EngPageEditState())));
                    }),
                Text(document['cost'])
              ],
            ),
          ),
        ));
  }
}

Future<void> uploadPicture(food, collection, name, docid) async {
  try {
    Uint8List? uint8list = await ImagePickerWeb.getImageAsBytes();
    if (uint8list != null) {
      var metadata = SettableMetadata(
        contentType: "image/jpeg",
      );
      Reference referenceRoot = FirebaseStorage.instance
          .ref()
          .child('images/$food/$collection/$name.jpeg');
      await referenceRoot.putData(uint8list, metadata);
      String downloadURL = await referenceRoot.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('Eng')
          .doc(food)
          .collection(collection)
          .doc(docid)
          .update({'image': downloadURL});
    }
  } catch (e) {
    print(e);
  }
}
