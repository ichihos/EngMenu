import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food.dart';
import 'drink.dart';
import 'package:url_launcher/url_launcher.dart';

class EngCoursePageState extends StatefulWidget {
  EngCoursePage createState() => EngCoursePage();
}

class EngCoursePage extends State<EngCoursePageState> {
  List<String> favorite = [];
  List<String> image = [];
  final url = Uri.parse(
      "https://www.instagram.com/anaza_ushinohone?igsh=MmdqMHA0ZW03NzFl");

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
                      actions: [
                        InkWell(
                          child: Image.asset('assets/images/insta.png'),
                          onTap: () {
                            _launchUrl(url);
                          },
                        )
                      ],
                      centerTitle: true,
                      floating: true,
                      flexibleSpace: Image.asset(
                        'assets/images/anaza.jpg',
                        fit: BoxFit.cover,
                      ),
                      title: Text('Ushinohone-anaza\n ~ English menu ~', style: TextStyle(color: Colors.white)),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          spacer(5),
                          menuButtons(),
                          noticeText2(
                              'Additional 10% service charge will be added.',
                              Colors.red,
                              17),
                          noticeText(
                              'The menu is subject to change depending on the availability of ingredients.',
                              Colors.red),
                          noticeText(
                              'Courses is not available without reservations.',
                              Colors.red),
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
      Text(text, style: TextStyle(color: color), textAlign: TextAlign.left);

  Widget noticeText2(String text, Color color, double size) => Text(text,
      style: TextStyle(
          color: color, fontSize: size, decoration: TextDecoration.underline),
      textAlign: TextAlign.left);

  Widget menuButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(width: 20, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => EngPageState())));
            },
            child: menuButton('Foods'),
          ),
          Container(width: 15, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => EngDrinkPageState())));
            },
            child: menuButton('Drinks'),
          ),
          Container(width: 15, height: 50),
          menuButton('Courses'),
        ],
      );

  Widget sectionTitle(DocumentSnapshot name, size) => Column(children: <Widget>[
        Align(
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
            child: Text('   ${name['title']}',
                style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: Colors.white)),
          ),
        ),
        Container(width: double.infinity, height: 30),
        menulist(name['title'], size)
      ]);

  Widget menuButton(String text) => Container(
        alignment: Alignment.center,
        width: 100,
        height: 50,
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 25)),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 53, 52, 52),
            borderRadius: BorderRadius.all(Radius.circular(20))),
      );

  Widget menuButton2(String text) => Container(
        alignment: Alignment.center,
        width: 70,
        height: 25,
        child:
            Text(text, style: TextStyle(color: Colors.white, fontSize: 12.5)),
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
                  children: titles.map((title) => coursemenu(title)).toList(),
                ));
          }
          return Center(child: Text('読込中...'));
        },
      );

  Widget coursemenu(DocumentSnapshot title) {
    final isImage = image.contains(title['ja']);
    final imageok = title['image'] != "";
    final url = Uri.parse(
        "https://www.google.com/search?tbm=isch&q=${Uri.encodeQueryComponent(title['ja'])}");
    return InkWell(
      onTap: () {
        if (!imageok) {
          _launchUrl(url);
        } else {
          setState(() {
            if (isImage) {
              image.remove(title['ja']);
            } else {
              image.add(title['ja']);
            }
          });
        }
      },
      child: Column(
        children: [
          Text(title['title'], style: TextStyle(fontSize: 20)),
          Text(title['discription'], style: TextStyle(fontSize: 15)),
          Text(title['ja'], style: TextStyle(fontSize: 15, color: Colors.grey)),
          isImage
              ? imageok
                  ? Image.network(
                      title['image'],
                      height: 150,
                    )
                  : Container()
              : Container(),
          Container(width: 10, height: 30)
        ],
      ),
    );
  }
}

Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrl(url)) {
    launchUrl(url,
        mode: LaunchMode.platformDefault, webOnlyWindowName: '_blank');
  } else {
    print('Cannot launch url: $url');
  }
}
