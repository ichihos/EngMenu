import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'drink.dart';
import 'package:url_launcher/url_launcher.dart';
import 'course.dart';
import 'Edit.dart';

class EngPageState extends StatefulWidget {
  EngPage createState() => EngPage();
}

class EngPage extends State<EngPageState> {
  bool get wantKeepAlive => true;
  List<String> favorite = [];
  List<String> image = [];
  int count = 0;
  final url = Uri.parse(
      "https://www.instagram.com/anaza_ushinohone?igsh=MmdqMHA0ZW03NzFl");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('Eng')
                .doc('Food')
                .collection("titles")
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
                      title: Text('Ushinohone-anaza\n ~ English menu ~',
                          style: TextStyle(color: Colors.brown[50])),
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
                          noticeText2(
                              'A small appetizer(¥330) is served at the beginning.',
                              Colors.red,
                              17),
                          noticeText(
                              'The menu is subject to change depending on the availability of ingredients.',
                              Colors.red),
                          noticeText(
                              'Some menu items are subject to market value.',
                              Colors.red),
                          spacer(5),
                          noticeText(
                              'No food or beverages are allowed to be brought in.',
                              Colors.red),
                          spacer(5),
                          // menulist(size),
                          // spacer(15)
                        ],
                      ),
                    ),
                    SliverList(
                        delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        var title = snapshot.data!.docs[index];
                        return menuSection(title);
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
              if (count < 7) {
                count += 1;
              } else {
                await Navigator.of(context).push(
                    MaterialPageRoute(builder: ((context) => Password())));
                count = 0;
              }
            },
            child: menuButton3('Foods'),
          ),
          Container(width: 15, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => EngDrinkPageState())));
            },
            child: menuButton('Drinks'),
          ),
          Container(width: 30, height: 50),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => EngCoursePageState())));
            },
            child: menuButton2('Courses'),
          ),
        ],
      );

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

  Widget menuButton3(String text) => Container(
        alignment: Alignment.center,
        width: 100,
        height: 50,
        child: Text(text, style: TextStyle(color: Colors.black, fontSize: 25)),
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 223, 221, 221),
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
                sectionTitle(titles['title']),
                sectionContent(
                    documents: documents,
                    collection: titles['title'],
                    favorite: favorite,
                    image: image),
                spacer(30)
              ],
            );
          }
          return Center(child: Text('loading中...'));
        },
      );

  Widget sectionTitle(title) => Align(
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
              return Container(
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    color: Color(color),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20))),
                width: double.infinity,
                height: 30,
                child: Text('   $title',
                    style: TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: Colors.white)),
              );
            }
            return Container();
          }));
}

class sectionContent extends StatefulWidget {
  final List<DocumentSnapshot> documents;
  final String collection;
  final List<String> favorite;
  final List<String> image;

  sectionContent(
      {Key? key,
      required this.documents,
      required this.collection,
      required this.favorite,
      required this.image})
      : super(key: key);

  @override
  _sectionContentState createState() => _sectionContentState();
}

class _sectionContentState extends State<sectionContent> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.black, width: 3))),
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
          child: ListView.builder(
            controller: _controller,
            physics: ClampingScrollPhysics(),
            itemCount: widget.documents.length,
            itemBuilder: (context, index) {
              // 各ドキュメントに対して menuItem ウィジェットを構築
              return MenuItem(
                  document: widget.documents[index],
                  favorite: widget.favorite,
                  image: widget.image);
            },
          ),
        ));
  }
}

class MenuItem extends StatefulWidget {
  final DocumentSnapshot document;
  final List<String> favorite;
  final List<String> image;

  MenuItem(
      {Key? key,
      required this.document,
      required this.favorite,
      required this.image})
      : super(key: key);

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.favorite.contains(widget.document['goods']);
    final isImage = widget.image.contains(widget.document['goods']);
    final imageok = widget.document['image'] != "";
    final url = Uri.parse(
        "https://www.google.com/search?tbm=isch&q=${Uri.encodeQueryComponent(widget.document['ja'])}");
    return InkWell(
        onTap: () {
          if (!imageok) {
            _launchUrl(url);
          } else {
            setState(() {
              if (isImage) {
                widget.image.remove(widget.document['goods']);
              } else {
                widget.image.add(widget.document['goods']);
              }
            });
          }
        },
        child: Column(children: [
          Card(
            child: ListTile(
              title: Text(widget.document['goods']),
              subtitle: Text(widget.document['ja']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (isFavorite) {
                          widget.favorite.remove(widget.document['goods']);
                        } else {
                          widget.favorite.add(widget.document['goods']);
                        }
                      });
                    },
                    icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red),
                  ),
                  Text(widget.document['cost'])
                ],
              ),
            ),
          ),
          isImage
              ? imageok
                  ? Image.network(
                      widget.document['image'],
                      height: 150,
                    )
                  : Container()
              : Container()
        ]));
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
