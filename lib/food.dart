import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'drink.dart';
import 'package:url_launcher/url_launcher.dart';
import 'course.dart';
import 'Edit.dart';
import 'main.dart';

class EngPageState extends StatefulWidget {
  const EngPageState({Key? key}) : super(key: key);

  @override
  EngPage createState() => EngPage();
}

class EngPage extends State<EngPageState> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<String> _image = [];
  int _count = 0;

  final Uri _instagramUrl = Uri.parse(
    "https://www.instagram.com/anaza_ushinohone?igsh=MmdqMHA0ZW03NzFl",
  );

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin の場合は必須
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
          // ローディング時
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // データがない場合
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
                  )
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _spacer(5),
                    _menuButtons(),
                    _languageDropdown(),
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

  Widget _spacer(double height) {
    return SizedBox(height: height);
  }

  Widget _noticeText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color),
      textAlign: TextAlign.left,
    );
  }

  Widget _noticeTextUnderline(String text, Color color, double size) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        decoration: TextDecoration.underline,
      ),
      textAlign: TextAlign.left,
    );
  }

  /// メニューボタン群
  Widget _menuButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: () async {
            if (_count < 7) {
              _count += 1;
            } else {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: ((context) => const Password())),
              );
              _count = 0;
            }
          },
          child: _menuButtonGray('Foods'),
        ),
        const SizedBox(width: 10, height: 50),
        InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: ((context) => EngDrinkPageState())),
            );
          },
          child: _menuButtonDark('Drinks'),
        ),
        const SizedBox(width: 10, height: 50),
        InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: ((context) => EngCoursePage())),
            );
          },
          child: _menuButtonDark('Courses'),
        ),
      ],
    );
  }

  Widget _languageDropdown() {
    return DropdownButton<String>(
      value: selectedLanguageValue,
      items: supportedLanguages.map((lang) {
        return DropdownMenuItem<String>(
          // 実際の value は内部で利用したい値をセット
          value: lang['value'],
          // 表示ラベルは label を使う
          child: Row(
            children: [
              Text(lang['label'] ?? ''),
              const SizedBox(width: 5),
              const Icon(Icons.language),
            ],
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            selectedLanguageValue = newValue;
          });
        }
      },
    );
  }

  Widget _menuButtonDark(String text) {
    return Container(
      alignment: Alignment.center,
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 53, 52, 52),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 25),
      ),
    );
  }

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

  Widget _menuSection(DocumentSnapshot titleDoc) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Eng')
          .doc('Food')
          .collection(titleDoc['title'])
          .orderBy('order')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final documents = snapshot.data!.docs;
          return Column(
            children: [
              _sectionTitle(titleDoc['title']),
              SectionContent(
                documents: documents,
                collection: titleDoc['title'],
                favorite: favorite,
                image: _image,
                selectedlanguageValue: selectedLanguageValue,
              ),
              _spacer(30),
            ],
          );
        }
        return const Center(child: Text('loading中...'));
      },
    );
  }

  /// セクションタイトル（背景色付き）
  Widget _sectionTitle(String title) {
    return Align(
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
            final colorValue = documents[0]['color'];
            return Container(
              alignment: Alignment.centerLeft,
              width: double.infinity,
              height: 30,
              decoration: BoxDecoration(
                color: Color(colorValue),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Text(
                '   $title',
                style: const TextStyle(
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
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
  final String selectedlanguageValue;

  const SectionContent({
    Key? key,
    required this.documents,
    required this.collection,
    required this.favorite,
    required this.image,
    required this.selectedlanguageValue,
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
              duration: const Duration(milliseconds: 1500),
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
              duration: const Duration(milliseconds: 1500),
              alignment: 0.9, // 親ビューのスクロール位置を上端に調整
            );
            return true; // イベントを消費
          }
          return false; // 他のリスナーにも通知を伝える
        },
        child: ListView.builder(
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          itemCount: widget.documents.length,
          itemBuilder: (context, index) {
            // 各ドキュメントに対して MenuItem ウィジェットを構築
            return MenuItem(
              document: widget.documents[index],
              favorite: widget.favorite,
              image: widget.image,
              selectedlanguageValue: widget.selectedlanguageValue,
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
  final String selectedlanguageValue;

  const MenuItem({
    Key? key,
    required this.document,
    required this.favorite,
    required this.image,
    required this.selectedlanguageValue,
  }) : super(key: key);

  @override
  _MenuItemState createState() => _MenuItemState();
}

class _MenuItemState extends State<MenuItem> {
  @override
  Widget build(BuildContext context) {
    // ドキュメントデータの取得。無い場合は空Map
    final data = widget.document.data() as Map<String, dynamic>? ?? {};

    // まずは「選択言語のキー」が存在するかチェック
    final hasSelectedLangField = data.containsKey(widget.selectedlanguageValue);

    if (!hasSelectedLangField) {
      // "en" フィールドの存在チェック
      final hasEnField = data.containsKey('goods');
      if (!hasEnField) {
        // en すらない場合 → フォールバックメッセージ
        data['fallback'] = 'Not available in this language.';
      } else {
        data[widget.selectedlanguageValue] = data['goods'];
      }
    }

    // 実際に表示するフィールドを取得する
    final displayedName = data[widget.selectedlanguageValue] ??
        data['fallback'] ?? // enも無い場合に備えたメッセージ
        '';

    // お気に入り判定・画像表示判定
    final isFavorite = widget.favorite.contains(displayedName);
    final isImage = widget.image.contains(displayedName);

    // 画像URL
    final imageExists = (data['image'] ?? "").toString().isNotEmpty;
    final imageUrl = data['image'] ?? "";

    // Google 画像検索用URL
    final Uri searchUrl = Uri.parse(
      "https://www.google.com/search?tbm=isch&q="
      "${Uri.encodeQueryComponent(data['ja'] ?? '')}",
    );

    return InkWell(
      onTap: () {
        // 画像が無い場合は Google 画像検索へ遷移
        if (!imageExists) {
          _launchUrl(searchUrl);
        } else {
          setState(() {
            if (isImage) {
              widget.image.remove(displayedName);
            } else {
              widget.image.add(displayedName);
            }
          });
        }
      },
      child: Column(
        children: [
          Card(
            child: ListTile(
              title: Text(displayedName),
              subtitle: Text(data['ja'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (isFavorite) {
                          widget.favorite.remove(displayedName);
                        } else {
                          widget.favorite.add(displayedName);
                        }
                      });
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                  ),
                  Text(data['cost'] ?? ''),
                ],
              ),
            ),
          ),
          if (isImage && imageExists)
            Image.network(
              imageUrl,
              height: 150,
            ),
        ],
      ),
    );
  }
}

/// URL起動用
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
