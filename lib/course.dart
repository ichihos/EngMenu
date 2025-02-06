import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food.dart';
import 'drink.dart';
import 'package:url_launcher/url_launcher.dart';

class EngCoursePage extends StatefulWidget {
  const EngCoursePage({super.key});

  @override
  _EngCoursePageState createState() => _EngCoursePageState();
}

class _EngCoursePageState extends State<EngCoursePage> {
  List<String> image = [];
  final Uri instagramUrl = Uri.parse(
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
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data available'));
          }
          final titles = snapshot.data!.docs;
          return CustomScrollView(
            cacheExtent: 250.0 * titles.length - 1,
            slivers: <Widget>[
              SliverAppBar(
                actions: [
                  IconButton(
                    icon: Image.asset('assets/images/insta.png'),
                    onPressed: () => _launchUrl(instagramUrl),
                  ),
                ],
                centerTitle: true,
                floating: true,
                flexibleSpace: Image.asset(
                  'assets/images/anaza.jpg',
                  fit: BoxFit.cover,
                ),
                title: Text(
                  'Ushinohone-anaza\n ~ English menu ~',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),
                    menuButtons(),
                    noticeText('Additional 10% service charge will be added.',
                        Colors.red, 15, true),
                    noticeText(
                        'The menu is subject to change depending on the availability of ingredients.',
                        Colors.red,
                        12,
                        false),
                    noticeText(
                        'Courses are not available without reservations.',
                        Colors.red,
                        12,
                        false),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => sectionTitle(titles[index], size),
                  childCount: titles.length,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget noticeText(String text, Color color, double size, bool underline) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        decoration: underline ? TextDecoration.underline : TextDecoration.none,
      ),
      textAlign: TextAlign.left,
    );
  }

  Widget menuButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: ((context) => EngPageState())));
            },
            child: menuButton('Foods'),
          ),
          Container(width: 10, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => EngDrinkPageState())));
            },
            child: menuButton('Drinks'),
          ),
          Container(width: 10, height: 50),
          menuButton3('Courses'),
        ],
      );

  Widget sectionTitle(title, size) => Column(children: <Widget>[
        Align(
            alignment: Alignment.centerLeft,
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
                    final coursetitle = title['title'];
                    return Container(
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                          color: Color(color),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20))),
                      width: double.infinity,
                      height: 30,
                      child: Text('   $coursetitle',
                          style: TextStyle(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              color: Colors.white)),
                    );
                  }
                  return Container();
                })),
        Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
              color: Colors.black, // 下線の色
              width: 2.0, // 下線の太さ
            )))),
        menulist(title['title'], size, image),
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
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 25)),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 53, 52, 52),
            borderRadius: BorderRadius.all(Radius.circular(16))),
      );

  Widget menuButton3(String text) => Container(
        alignment: Alignment.center,
        width: 100,
        height: 50,
        child: Text(text, style: TextStyle(color: Colors.black, fontSize: 25)),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 223, 221, 221),
            borderRadius: BorderRadius.all(Radius.circular(20))),
      );
}

class menulist extends StatelessWidget {
  final String name;
  final Size size;
  final List<String> image;
  menulist(this.name, this.size, this.image);

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
                      children: titles
                          .map((title) => coursemenu(title, image))
                          .toList(),
                    )));
          }
          return Center(child: Text('読込中...'));
        });
  }
}

class coursemenu extends StatelessWidget {
  final DocumentSnapshot title;
  final List<String> image;
  coursemenu(this.title, this.image);

  @override
  Widget build(BuildContext context) {
    final isImage = image.contains(title['ja']);
    final imageok = title['image'] != "";
    return InkWell(
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
