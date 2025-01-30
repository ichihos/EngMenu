import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker_web/image_picker_web.dart';

import 'Edit.dart';
import 'foodEdit.dart';
import 'drinkEdit.dart';
import 'food.dart';

class EngCoursePageEditState extends StatefulWidget {
  const EngCoursePageEditState({Key? key}) : super(key: key);

  @override
  _EngCoursePageEditState createState() => _EngCoursePageEditState();
}

class _EngCoursePageEditState extends State<EngCoursePageEditState> {
  /// テーマカラー
  Color _selectedColor = Colors.lightGreen;

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
          // 読込中の場合
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // データがない場合
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final titleDocs = snapshot.data!.docs;
          return CustomScrollView(
            cacheExtent: 250.0 * titleDocs.length - 1,
            slivers: <Widget>[
              SliverAppBar(
                centerTitle: true,
                floating: true,
                flexibleSpace: Image.asset(
                  'assets/images/anaza.jpg',
                  fit: BoxFit.cover,
                ),
                title: const Text(
                  '編集用ページ（店舗用）',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _spacer(5),
                    _buildMenuButtons(),
                    _spacer(10),
                    _buildNewSectionTitle(),
                    _spacer(15),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final titleDoc = titleDocs[index];
                    return _buildSection(titleDoc, size);
                  },
                  childCount: titleDocs.length,
                ),
              )
            ],
          );
        },
      ),
    );
  }

  /// カラーピッカーのダイアログ表示
  void _showColorPickerDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('DONE'),
              onPressed: () async {
                await _updateThemeColor(docId, _selectedColor.value);
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const EngCoursePageEditState(),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Firestoreのテーマカラー更新
  Future<void> _updateThemeColor(String docId, int colorValue) async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Course')
        .collection('color')
        .doc(docId)
        .update({'color': colorValue});
  }

  /// 上部のメニューボタン群
  Widget _buildMenuButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMenuButton(
          label: 'Food編集',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EngPageEditState(),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildMenuButton(
          label: 'Drink編集',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EngDrinkEditPageState(),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildMenuButton(
          label: '編集終了',
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EngPageState(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// メニューボタンの共通ウィジェット
  Widget _buildMenuButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 53, 52, 52),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  /// 「コース追加」「テーマ変更」ボタンのセクション
  Widget _buildNewSectionTitle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        alignment: Alignment.centerLeft,
        width: double.infinity,
        height: 30,
        decoration: const BoxDecoration(
          color: Colors.lightGreen,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddPostnewCourse()),
                );
              },
              child: const Text('コース追加'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                _showColorPickerDialog(context, 'L6IBx5dELRCbv5Qp9tUK');
              },
              child: const Text('テーマ変更'),
            ),
          ],
        ),
      ),
    );
  }

  /// コースのセクションタイトルやメニュー一覧をまとめたウィジェット
  Widget _buildSection(DocumentSnapshot titleDoc, Size size) {
    final titleName = titleDoc['title'] as String;

    return Column(
      children: <Widget>[
        // セクションのタイトル
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TitleEditPage(titleDoc.id, titleName, 'Course'),
                ),
              );
            },
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Eng')
                  .doc('Course')
                  .collection('color')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final colorValue = snapshot.data!.docs[0]['color'] as int?;
                  final color = colorValue != null
                      ? Color(colorValue)
                      : Colors.lightGreen; // 万が一nullの場合

                  return Container(
                    alignment: Alignment.centerLeft,
                    width: double.infinity,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '   $titleName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddPostPagenewCourse(titleName),
                              ),
                            );
                          },
                          child: const Text('コースメニュー追加'),
                        ),
                      ],
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
        ),
        // セクションタイトル下のライン
        Container(
          width: double.infinity,
          height: 30,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: 2.0,
              ),
            ),
          ),
        ),
        // メニュー一覧部分
        _MenuList(titleName: titleName, size: size),
        // セクション下のライン
        Container(
          width: double.infinity,
          height: 40,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.black,
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 余白用ウィジェット
  Widget _spacer(double height) => SizedBox(height: height);
}

/// コースの各アイテム一覧表示ウィジェット
class _MenuList extends StatelessWidget {
  final String titleName;
  final Size size;

  const _MenuList({
    Key? key,
    required this.titleName,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Eng')
          .doc('Course')
          .collection(titleName)
          .orderBy('order')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          return SizedBox(
            width: double.infinity,
            height: size.height / 2 - 100,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                // 上下端のオーバースクロールを親へ伝搬させない処理
                if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.minScrollExtent &&
                    scrollInfo is ScrollUpdateNotification &&
                    scrollInfo.scrollDelta! > 0) {
                  // 上端での下方向スクロールを無視
                  return true;
                }
                if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent &&
                    scrollInfo is OverscrollNotification) {
                  // 下端でさらに下方向にスクロール
                  Scrollable.ensureVisible(
                    context,
                    duration: const Duration(milliseconds: 1500),
                    alignment: 0.1,
                  );
                  return true;
                }
                if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.minScrollExtent &&
                    scrollInfo is OverscrollNotification) {
                  // 上端で上方向スクロール
                  Scrollable.ensureVisible(
                    context,
                    duration: const Duration(milliseconds: 1500),
                    alignment: 0.9,
                  );
                  return true;
                }

                return false;
              },
              child: ListView(
                shrinkWrap: true,
                children: docs.map(
                  (doc) {
                    return _CourseMenu(
                      doc: doc,
                      titleName: titleName,
                      totalCount: docs.length,
                    );
                  },
                ).toList(),
              ),
            ),
          );
        }
        return const Center(child: Text('読込中...'));
      },
    );
  }
}

/// 各コースのメニューアイテム
class _CourseMenu extends StatelessWidget {
  final DocumentSnapshot doc;
  final String titleName;
  final int totalCount;

  const _CourseMenu({
    Key? key,
    required this.doc,
    required this.titleName,
    required this.totalCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final docId = doc.id;
    final menuTitle = doc['title'] as String? ?? '';
    final description = doc['discription'] as String? ?? '';
    final jaText = doc['ja'] as String? ?? '';
    final imageUrl = doc['image'] as String? ?? '';

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => AddPostPageCourse(docId, titleName)),
        );
      },
      child: Container(
        width: 300,
        constraints: const BoxConstraints(minHeight: 30),
        child: Column(
          children: [
            Text(menuTitle, style: const TextStyle(fontSize: 20)),
            Text(description, style: const TextStyle(fontSize: 15)),
            Text('$jaText(タップで編集)'),
            ElevatedButton(
              onPressed: () async {
                await _uploadPicture('Course', titleName, menuTitle, docId);
              },
              child: const Text('画像UP'),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                // ドキュメント削除
                await FirebaseFirestore.instance
                    .collection('Eng')
                    .doc('Course')
                    .collection(titleName)
                    .doc(docId)
                    .delete();

                // もしメニューが1つだけなら、titles のドキュメントも削除
                if (totalCount == 1) {
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('Eng')
                      .doc('Course')
                      .collection('titles')
                      .where('title', isEqualTo: titleName)
                      .get();
                  for (var titleDoc in querySnapshot.docs) {
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Course')
                        .collection('titles')
                        .doc(titleDoc.id)
                        .delete();
                  }
                }

                // ストレージ画像があれば削除
                if (imageUrl.isNotEmpty) {
                  await FirebaseStorage.instance
                      .ref()
                      .child('images/Course/$titleName/$menuTitle.jpeg')
                      .delete();
                }

                // リロード
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const EngCoursePageEditState(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 画像をアップロードし、FireStore の該当ドキュメントを更新
Future<void> _uploadPicture(
  String food,
  String collection,
  String name,
  String docId,
) async {
  try {
    final Uint8List? uint8list = await ImagePickerWeb.getImageAsBytes();
    if (uint8list != null) {
      final metadata = SettableMetadata(contentType: "image/jpeg");
      final referenceRoot = FirebaseStorage.instance
          .ref()
          .child('images/$food/$collection/$name.jpeg');

      await referenceRoot.putData(uint8list, metadata);
      final downloadURL = await referenceRoot.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('Eng')
          .doc(food)
          .collection(collection)
          .doc(docId)
          .update({'image': downloadURL});
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}
