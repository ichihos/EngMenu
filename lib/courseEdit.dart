import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'foodEdit.dart';
import 'Edit.dart';
import 'drinkEdit.dart';
import 'food.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class EngCoursePageEditState extends StatefulWidget {
  EngCoursePageEdit createState() => EngCoursePageEdit();
}

class EngCoursePageEdit extends State<EngCoursePageEditState> {
  List<String> favorite = [];
  List<String> image = [];
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
                      builder: ((context) => EngCoursePageEditState())));
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
        .doc('Course')
        .collection('color')
        .doc(docid)
        .update({'color': color});
  }

  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
        body: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('Eng')
                .doc('Course')
                .collection('titles')
                .orderBy('order')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return Center(child: Text('No data available'));
              }
              final titles = snapshot.data!.docs;
              return CustomScrollView(
                  cacheExtent: 250.0 * titles.length - 1,
                  // physics: NeverScrollableScrollPhysics(),
                  // child:
                  slivers: <Widget>[
                    SliverAppBar(
                      centerTitle: true,
                      floating: true,
                      flexibleSpace: Image.asset(
                        'assets/images/anaza.jpg',
                        fit: BoxFit.cover,
                      ),
                      title: Text('編集用ページ（店舗用）',
                          style: TextStyle(color: Colors.white)),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          spacer(5),
                          menuButtons(),
                          spacer(10),
                          sectionTitlenew(),
                          spacer(15)
                        ],
                      ),
                    ),
                    SliverList(
                        delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        var title = snapshot.data!.docs[index];
                        return sectionTitle(title, size);
                      },
                      childCount: snapshot.data!.docs.length,
                    ))
                  ]);
            }));
  }

  Widget spacer(double height) => Container(padding: EdgeInsets.all(height));

  Widget noticeText(String text, Color color) =>
      Text(text, style: TextStyle(color: color));

  Widget menuButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => EngPageEditState())));
            },
            child: menuButton('Food編集'),
          ),
          Container(width: 10, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => EngDrinkEditPageState())));
            },
            child: menuButton('Drink編集'),
          ),
          Container(width: 10, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => EngPageState())));
            },
            child: menuButton('編集終了'),
          ),
          // Container(width: 10, height: 50),
          // InkWell(
          //   onTap: () async {
          //     await Navigator.of(context).push(MaterialPageRoute(
          //         builder: ((context) => EngLunchPageEditState())));
          //   },
          //   child: menuButton('Lunch編集'),
          // ),
        ],
      );

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
                      builder: ((context) => AddPostnewCourse())));
                },
                child: Text('コース追加')),
            SizedBox(width: 10),
            ElevatedButton(
                onPressed: () {
                  _showPicker(context, 'L6IBx5dELRCbv5Qp9tUK');
                },
                child: Text('テーマ変更')),
          ]),
        ),
      );

  Widget sectionTitle(DocumentSnapshot name, size) => Column(children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: ((context) =>
                        TitleEditPage(name.id, name['title'], 'Course'))));
              },
              child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Eng')
                      .doc('Course')
                      .collection('color')
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final documents = snapshot.data!.docs;
                      final color = documents[0]['color'];
                      return Container(
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                              color: Color(color),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20))),
                          width: double.infinity,
                          height: 30,
                          child: Row(children: [
                            Text('   ${name['title']}',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white)),
                            ElevatedButton(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                              AddPostPagenewCourse(
                                                  name['title']))));
                                },
                                child: Text('コースメニュー追加')),
                          ]));
                    }
                    return Container();
                  })),
        ),
        Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
              color: Colors.black, // 下線の色
              width: 2.0, // 下線の太さ
            )))),
        menulist(name['title'], size),
        Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
              color: Colors.black, // 下線の色
              width: 2.0, // 下線の太さ
            )))),
      ]);

  Widget menuButton(String text) => Container(
        alignment: Alignment.center,
        width: 100,
        height: 50,
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 53, 52, 52),
            borderRadius: BorderRadius.all(Radius.circular(20))),
      );
}

class menulist extends StatelessWidget {
  final String name;
  final Size size;
  menulist(this.name, this.size);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Course')
            .collection(name)
            .orderBy('order')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final titles = snapshot.data!.docs;
            return Container(
                width: double.infinity,
                height: size.height / 2 - 100,
                child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      // 上端での下方向スクロールを無視する
                      if (notification.metrics.pixels ==
                              notification.metrics.minScrollExtent &&
                          notification is ScrollUpdateNotification &&
                          notification.scrollDelta! > 0) {
                        return true; // イベントを消費して親に伝搬させない
                      }

                      // 下端でさらに下方向にスクロールした場合、親ビューをスクロール
                      if (notification.metrics.pixels ==
                              notification.metrics.maxScrollExtent &&
                          notification is OverscrollNotification) {
                        Scrollable.ensureVisible(
                          context,
                          duration: Duration(milliseconds: 1500),
                          alignment: 0.1, // 親ビューのスクロール位置を下端に調整
                        );
                        return true; // イベントを消費
                      }

                      // 上端で上方向スクロールした場合、親ビューをスクロール
                      if (notification.metrics.pixels ==
                              notification.metrics.minScrollExtent &&
                          notification is OverscrollNotification) {
                        Scrollable.ensureVisible(
                          context,
                          duration: Duration(milliseconds: 1500),
                          alignment: 0.9, // 親ビューのスクロール位置を上端に調整
                        );
                        return true; // イベントを消費
                      }

                      return false; // 他のリスナーにも通知を伝える
                    },
                    child: ListView(
                      shrinkWrap: true,
                      children: titles
                          .map(
                              (title) => coursemenu(title, name, titles.length))
                          .toList(),
                    )));
          }
          return Center(child: Text('読込中...'));
        });
  }
}

class coursemenu extends StatelessWidget {
  final DocumentSnapshot title;
  final String name;
  final length;
  coursemenu(this.title, this.name, this.length);

  @override
  Widget build(BuildContext context) {
    String docid = title.id;
    return InkWell(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: ((context) => AddPostPageCourse(docid, name))));
        },
        child: Container(
          width: 300,
          constraints: BoxConstraints(minHeight: 30),
          child: Column(
            children: [
              Text(title['title'], style: TextStyle(fontSize: 20)),
              Text(title['discription'], style: TextStyle(fontSize: 15)),
              Text("${title['ja']}(タップで編集)"),
              ElevatedButton(
                  onPressed: () async {
                    await uploadPicture('Course', name, title['title'], docid);
                  },
                  child: Text('画像UP')),
              IconButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Course')
                        .collection(name)
                        .doc(docid)
                        .delete();
                    if (length == 1) {
                      await FirebaseFirestore.instance
                          .collection('Eng')
                          .doc('Course')
                          .collection('titles')
                          .where('title', isEqualTo: name)
                          .get()
                          .then((QuerySnapshot querySnapshot) {
                        querySnapshot.docs.forEach((doc) {
                          FirebaseFirestore.instance
                              .collection('Eng')
                              .doc('Course')
                              .collection('titles')
                              .doc(doc.id)
                              .delete();
                        });
                      });
                    }
                    if (title['image'] != "") {
                      await FirebaseStorage.instance
                          .ref()
                          .child('images/Course/$name/${title['title']}.jpeg')
                          .delete();
                    }
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => EngCoursePageEditState())));
                  },
                  icon: Icon(Icons.delete))
            ],
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
