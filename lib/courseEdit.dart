import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'foodEdit.dart';
import 'Edit.dart';
import 'drinkEdit.dart';
import 'food.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';

class EngCoursePageEditState extends StatefulWidget {
  EngCoursePageEdit createState() => EngCoursePageEdit();
}

class EngCoursePageEdit extends State<EngCoursePageEditState> {
  List<String> favorite = [];
  List<String> image = [];

  @override
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
                      title: Text('Ushinohone-anaza\n ~ English menu ~'),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          spacer(5),
                          menuButtons(),
                          noticeText(
                              'The menu is subject to change depending on the availability of ingredients.',
                              Colors.red),
                          noticeText(
                              'Courses is not available without reservations.',
                              Colors.red),
                          spacer(5),
                          noticeText(
                              'No food or beverages are allowed to be brought in.',
                              Colors.red),
                          spacer(10),
                          sectionTitlenew(),
                          spacer(10)
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
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => EngPageState())));
            },
            child: menuButton('編集終了'),
          ),
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
                child: Text('コース追加'))
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
                    Text('   ${name['title']}',
                        style: TextStyle(
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            color: Colors.white)),
                    ElevatedButton(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                              builder: ((context) =>
                                  AddPostPagenewCourse(name['title']))));
                        },
                        child: Text('コースメニュー追加')),
                  ]))),
        ),
        Container(width: double.infinity, height: 30),
        menulist(name['title'], size)
      ]);

  Widget menuButton(String text) => Container(
        alignment: Alignment.center,
        width: 120,
        height: 50,
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 20)),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 53, 52, 52),
            borderRadius: BorderRadius.all(Radius.circular(20))),
      );

  Widget courselist(size) => FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Course')
            .collection("titles")
            .orderBy('order')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final names = snapshot.data!.docs;
            return Container(
                width: double.infinity,
                height: size.height - 160,
                child: ListView(
                  cacheExtent: 250.0 * names.length - 1,
                  physics: ClampingScrollPhysics(),
                  children:
                      names.map((name) => sectionTitle(name, size)).toList(),
                ));
          }
          return Center(child: Text('読込中...'));
        },
      );

  Widget menulist(name, size) => FutureBuilder<QuerySnapshot>(
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
                height: size.height - 160,
                child: ListView(
                  shrinkWrap: true,
                  children: titles
                      .map((title) => coursemenu(title, name, titles.length))
                      .toList(),
                ));
          }
          return Center(child: Text('読込中...'));
        },
      );

  Widget coursemenu(DocumentSnapshot title, String name, length) {
    String docid = title.id;
    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(
            builder: ((context) => AddPostPageCourse(docid, name))));
      },
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
    );
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
