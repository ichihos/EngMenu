import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'main.dart';
import 'Edit.dart';
import 'foodEdit.dart';
import 'drink.dart';
import 'courseEdit.dart';

class EngDrinkEditPageState extends StatefulWidget {
  const EngDrinkEditPageState({Key? key}) : super(key: key);

  @override
  _EngDrinkEditPageState createState() => _EngDrinkEditPageState();
}

class _EngDrinkEditPageState extends State<EngDrinkEditPageState> {
  Color _selectedColor = Colors.lightGreen;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('編集用ページ（店舗用）'),
      ),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            _spacer(5),
            _buildMenuButtons(),
            _buildNewSectionTitle(),
            _spacer(5),
            _buildMenuList(size),
          ],
        ),
      ),
    );
  }

  /// カラーピッカー用ダイアログを表示
  void _showColorPickerDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor, // デフォルト色
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
                await _updateDatabase(docId, _selectedColor.value);
                // ダイアログを閉じてリロード
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const EngDrinkEditPageState()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Firestoreにテーマカラーを更新
  Future<void> _updateDatabase(String docId, int colorValue) async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Drink')
        .collection('color')
        .doc(docId)
        .update({'color': colorValue});
  }

  /// 上部メニュー操作ボタン
  Widget _buildMenuButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMenuButton(
          label: 'Food編集',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EngPageEditState()),
            );
          },
        ),
        const SizedBox(width: 15),
        _buildMenuButton(
          label: '編集終了',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EngDrinkPageState()),
            );
          },
        ),
        const SizedBox(width: 15),
        _buildMenuButton(
          label: 'コース編集',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EngCoursePageEditState()),
            );
          },
        ),
        const SizedBox(width: 10, height: 50),
        _languageDropdownEdit(),
      ],
    );
  }

  Widget _languageDropdownEdit() {
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

  Widget _buildMenuButton(
      {required String label, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
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

  /// 新しいジャンル追加やテーマ変更用のタイトル領域
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
                  MaterialPageRoute(
                      builder: (_) => const AddPostPagenewDrink()),
                );
              },
              child: const Text('ジャンル追加'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                _showColorPickerDialog(context, 'uFqxIrQ9JPpUjqxVn7iY');
              },
              child: const Text('テーマ変更'),
            ),
          ],
        ),
      ),
    );
  }

  /// ジャンル（titles）の一覧を表示
  Widget _buildMenuList(Size size) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Eng')
          .doc('Drink')
          .collection("titles")
          .orderBy('order')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final titleDocs = snapshot.data!.docs;
          return SizedBox(
            width: double.infinity,
            height: size.height - 160,
            child: ListView.builder(
              cacheExtent: 250.0 * titleDocs.length - 1,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: titleDocs.length,
              itemBuilder: (context, index) {
                return _buildMenuSection(titleDocs[index]);
              },
            ),
          );
        }
        return const Center(child: Text('読込中...'));
      },
    );
  }

  /// 各ジャンル（titles）のセクション
  Widget _buildMenuSection(DocumentSnapshot titleDoc) {
    final titleName = titleDoc['title'] as String;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Eng')
          .doc('Drink')
          .collection(titleName)
          .orderBy('order')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final itemDocs = snapshot.data!.docs;
          return Column(
            children: [
              _buildSectionTitle(titleDoc),
              _buildSectionContent(itemDocs, titleName),
              _spacer(30),
            ],
          );
        }
        return const Center(child: Text('読込中...'));
      },
    );
  }

  /// ジャンルのタイトル部分
  Widget _buildSectionTitle(DocumentSnapshot titleDoc) {
    final titleName = titleDoc['title'] as String;

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TitleEditPage(
                titleDoc.id,
                titleName,
                'Drink',
              ),
            ),
          );
        },
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('Eng')
              .doc('Drink')
              .collection('color')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final colorValue = snapshot.data!.docs[0]['color'] as int?;
              final color = colorValue != null
                  ? Color(colorValue)
                  : Colors.lightGreen; // 万が一nullの場合の保険

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
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddPostPageDrinknew(titleName),
                          ),
                        );
                      },
                      child: const Text('メニュー追加'),
                    ),
                  ],
                ),
              );
            }
            return Container(); // まだ読込中の場合やデータが無い場合
          },
        ),
      ),
    );
  }

  /// 各ジャンルに属するメニューをリスト表示
  Widget _buildSectionContent(
      List<DocumentSnapshot> documents, String collectionName) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.black, width: 3)),
      ),
      child: ListView.builder(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          return _buildMenuItem(
              documents[index], collectionName, documents.length);
        },
      ),
    );
  }

  /// メニューアイテム表示
  Widget _buildMenuItem(
      DocumentSnapshot doc, String collectionName, int totalCount) {
    final docId = doc.id;
    final goodsName = doc['goods'] as String;
    final imageUrl = doc['image'] as String? ?? '';
    final cost = doc['cost'] as String? ?? '';
    final jaName = doc['ja'] as String? ?? '';

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddPostPageDrink(collectionName, docId),
          ),
        );
      },
      child: Card(
        child: ListTile(
          title: Text(goodsName),
          subtitle: Text('$jaName (タップで編集)'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await uploadPicture(
                      'Drink', collectionName, goodsName, docId);
                },
                child: const Text('画像UP'),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  // メニュー削除処理
                  await FirebaseFirestore.instance
                      .collection('Eng')
                      .doc('Drink')
                      .collection(collectionName)
                      .doc(docId)
                      .delete();

                  // もし該当ジャンルのメニューが1つしか無かった場合はtitles内のジャンルも削除
                  if (totalCount == 1) {
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Drink')
                        .collection('titles')
                        .where('title', isEqualTo: collectionName)
                        .get()
                        .then((querySnapshot) {
                      for (var title in querySnapshot.docs) {
                        FirebaseFirestore.instance
                            .collection('Eng')
                            .doc('Drink')
                            .collection('titles')
                            .doc(title.id)
                            .delete();
                      }
                    });
                  }

                  // ストレージの画像があれば削除
                  if (imageUrl.isNotEmpty) {
                    await FirebaseStorage.instance
                        .ref()
                        .child('images/Drink/$collectionName/$goodsName.jpeg')
                        .delete();
                  }

                  // 画面リフレッシュ
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const EngDrinkEditPageState(),
                      ),
                    );
                  }
                },
              ),
              Text(cost),
            ],
          ),
        ),
      ),
    );
  }

  /// 余白
  Widget _spacer(double size) {
    return SizedBox(height: size);
  }
}

/// 画像をアップロードし、FireStoreの該当ドキュメントを更新する
Future<void> uploadPicture(
  String food,
  String collection,
  String name,
  String docId,
) async {
  try {
    final Uint8List? uint8list = await ImagePickerWeb.getImageAsBytes();
    if (uint8list != null) {
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final ref = FirebaseStorage.instance
          .ref()
          .child('images/$food/$collection/$name.jpeg');

      await ref.putData(uint8list, metadata);
      final downloadURL = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Eng')
          .doc(food)
          .collection(collection)
          .doc(docId)
          .update({'image': downloadURL});
    }
  } catch (e) {
    // エラー処理（必要に応じてログなど追加）
    debugPrint(e.toString());
  }
}
