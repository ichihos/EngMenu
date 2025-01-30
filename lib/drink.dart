import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'food.dart';
import 'package:url_launcher/url_launcher.dart';
import 'course.dart';

class EngDrinkPageState extends StatefulWidget {
  const EngDrinkPageState({Key? key}) : super(key: key);

  @override
  EngDrinkPage createState() => EngDrinkPage();
}

class EngDrinkPage extends State<EngDrinkPageState> {
  final List<String> _favorite = [];
  final List<String> _image = [];

  final Uri _instagramUrl = Uri.parse(
    "https://www.instagram.com/anaza_ushinohone?igsh=MmdqMHA0ZW03NzFl",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Drink')
            .collection("titles")
            .orderBy('order')
            .get(),
        builder: (context, snapshot) {
          // ローディング時の表示
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // データが存在しない場合
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available'));
          }

          final titles = snapshot.data!.docs;
          return CustomScrollView(
            cacheExtent: 250.0 * (titles.length - 1),
            slivers: <Widget>[
              SliverAppBar(
                actions: [
                  InkWell(
                    child: Image.asset('assets/images/insta.png'),
                    onTap: () => _launchUrl(_instagramUrl),
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
                  style: TextStyle(color: Colors.brown[50]),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _spacer(5),
                    _menuButtons(),
                    _noticeTextUnderline(
                      'Additional 10% service charge will be added.',
                      Colors.red,
                      17,
                    ),
                    _noticeTextUnderline(
                      'A small appetizer(¥330) is served at the beginning.',
                      Colors.red,
                      17,
                    ),
                    _noticeText(
                      'The menu is subject to change depending on the availability of ingredients.',
                      Colors.red,
                    ),
                    _noticeText(
                      'Some menu items are subject to market value.',
                      Colors.red,
                    ),
                    _spacer(5),
                    _noticeText(
                      'No food or beverages are allowed to be brought in.',
                      Colors.red,
                    ),
                    _spacer(5),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final titleDoc = titles[index];
                    return _menuSection(titleDoc);
                  },
                  childCount: titles.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 使っていない場合は削除可能
  Widget menulist(Size size) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Eng')
          .doc('Drink')
          .collection("titles")
          .orderBy('order')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final titles = snapshot.data!.docs;
          return SizedBox(
            width: double.infinity,
            height: size.height - 160,
            child: ListView.builder(
              cacheExtent: 250.0 * (titles.length - 1),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: titles.length,
              itemBuilder: (context, index) {
                return _menuSection(titles[index]);
              },
            ),
          );
        }
        return const Center(child: Text('読込中...'));
      },
    );
  }

  /// スペーサー
  Widget _spacer(double height) {
    return SizedBox(height: height);
  }

  /// 通常の注意文言
  Widget _noticeText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color),
      textAlign: TextAlign.left,
    );
  }

  /// 下線つきの注意文言
  Widget _noticeTextUnderline(String text, Color color, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        decoration: TextDecoration.underline,
      ),
      textAlign: TextAlign.left,
    );
  }

  /// メニューボタン群
  Widget _menuButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const EngPageState()),
            );
          },
          child: _menuButtonDark('Foods'),
        ),
        const SizedBox(width: 10, height: 50),
        _menuButtonGray('Drinks'),
        const SizedBox(width: 10, height: 50),
        InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const EngCoursePage()),
            );
          },
          child: _menuButtonDark('Courses'),
        ),
      ],
    );
  }

  /// メニューボタン（ダーク・標準サイズ）
  Widget _menuButtonDark(String text) {
    return Container(
      alignment: Alignment.center,
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 53, 52, 52),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 25),
      ),
    );
  }

  /// メニューボタン（グレー・標準サイズ）
  Widget _menuButtonGray(String text) {
    return Container(
      alignment: Alignment.center,
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 221, 221),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black, fontSize: 25),
      ),
    );
  }

  /// タイトルごとのセクション（FutureBuilderでドリンクデータ取得）
  Widget _menuSection(DocumentSnapshot titles) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Eng')
          .doc('Drink')
          .collection(titles['title'])
          .orderBy('order')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final documents = snapshot.data!.docs;
          return Column(
            children: [
              _sectionTitle(titles['title']),
              SectionContent(
                documents: documents,
                collection: titles['title'],
                favorite: _favorite,
                image: _image,
              ),
              _spacer(30),
            ],
          );
        }
        return const Center(child: Text('読込中...'));
      },
    );
  }

  /// セクションタイトル部分
  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Drink')
            .collection('color')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final documents = snapshot.data!.docs;
            final colorValue = documents[0]['color'];
            return Container(
              alignment: Alignment.centerLeft,
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 30),
              decoration: BoxDecoration(
                color: Color(colorValue),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Wrap(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            );
          }
          return Container();
        },
      ),
    );
  }
}

class SectionContent extends StatefulWidget {
  final List<DocumentSnapshot> documents;
  final String collection;
  final List<String> favorite;
  final List<String> image;

  const SectionContent({
    Key? key,
    required this.documents,
    required this.collection,
    required this.favorite,
    required this.image,
  }) : super(key: key);

  @override
  _SectionContentState createState() => _SectionContentState();
}

class _SectionContentState extends State<SectionContent> {
  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.black, width: 3)),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // 上端で下方向スクロールを無視
          if (notification.metrics.pixels ==
                  notification.metrics.minScrollExtent &&
              notification is ScrollUpdateNotification &&
              notification.scrollDelta! > 0) {
            return true;
          }
          // 下端でさらに下方向にスクロールしたら親ビューへ
          if (notification.metrics.pixels ==
                  notification.metrics.maxScrollExtent &&
              notification is OverscrollNotification) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 1500),
              alignment: 0.1,
            );
            return true;
          }
          // 上端で上方向スクロールしたら親ビューへ
          if (notification.metrics.pixels ==
                  notification.metrics.minScrollExtent &&
              notification is OverscrollNotification) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 1500),
              alignment: 0.9,
            );
            return true;
          }
          return false;
        },
        child: ListView.builder(
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          itemCount: widget.documents.length,
          itemBuilder: (context, index) {
            return MenuItem(
              document: widget.documents[index],
              favorite: widget.favorite,
              image: widget.image,
            );
          },
        ),
      ),
    );
  }
}

class MenuItem extends StatefulWidget {
  final DocumentSnapshot document;
  final List<String> favorite;
  final List<String> image;

  const MenuItem({
    Key? key,
    required this.document,
    required this.favorite,
    required this.image,
  }) : super(key: key);

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.favorite.contains(widget.document['goods']);
    final isImage = widget.image.contains(widget.document['goods']);
    final hasImageUrl = widget.document['image'].toString().isNotEmpty;

    final Uri searchUrl = Uri.parse(
      "https://www.google.com/search?tbm=isch&q="
      "${Uri.encodeQueryComponent(widget.document['ja'])}",
    );

    return InkWell(
      onTap: () {
        if (!hasImageUrl) {
          // Firestoreに画像URLが無い場合はGoogle画像検索へ
          _launchUrl(searchUrl);
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
      child: Column(
        children: [
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
                      color: Colors.red,
                    ),
                  ),
                  Text(widget.document['cost']),
                ],
              ),
            ),
          ),
          if (isImage && hasImageUrl)
            Image.network(
              widget.document['image'],
              height: 150,
            ),
        ],
      ),
    );
  }
}

/// URL起動用の共通関数
Future<void> _launchUrl(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(
      url,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  } else {
    debugPrint('Cannot launch url: $url');
  }
}
