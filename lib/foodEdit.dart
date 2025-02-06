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
import 'main.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class EngPageEditState extends StatefulWidget {
  const EngPageEditState({Key? key}) : super(key: key);

  @override
  EngPageEdit createState() => EngPageEdit();
}

class EngPageEdit extends State<EngPageEditState> {
  Color _myColor = Colors.lightGreen;
  bool isTranslating = false;
  int translationTotal = 0;
  int translationProgress = 0;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
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
            _menuButtons(),
            _spacer(5),
            _sectionTitleNew(),
            _spacer(5),
            if (isTranslating)
              Column(
                children: [
                  Text('翻訳中... $translationProgress / $translationTotal'),
                  // プログレスバーを表示する例
                  LinearProgressIndicator(
                    value: translationTotal == 0
                        ? 0
                        : translationProgress / translationTotal,
                  ),
                ],
              )
            else
              _menuList(size),
          ],
        ),
      ),
    );
  }

  /// カラーPickerを表示
  void _showPicker(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Pick a color!'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _myColor,
              onColorChanged: (Color color) {
                setState(() {
                  _myColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('DONE'),
              onPressed: () async {
                await _updateDatabase(docId, _myColor.value);
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EngPageEditState()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Firestore のカラー情報を更新
  Future<void> _updateDatabase(String docId, int color) async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Food')
        .collection('color')
        .doc(docId)
        .update({'color': color});
  }

  /// ListView（フードタイトル一覧）を表示
  Widget _menuList(Size size) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Eng')
          .doc('Food')
          .collection("titles")
          .orderBy('order')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('読込中...'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('データがありません'));
        }

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
      },
    );
  }

  /// メニューセクション（各フードタイトルに紐づくリスト）
  Widget _menuSection(DocumentSnapshot titles) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Eng')
          .doc('Food')
          .collection(titles['title'])
          .orderBy('order')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text('読込中...'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('データがありません'));
        }

        final documents = snapshot.data!.docs;
        return Column(
          children: [
            _sectionTitle(titles),
            _sectionContent(documents, titles['title']),
            _spacer(30),
          ],
        );
      },
    );
  }

  /// ジャンル追加・テーマ変更のボタンがあるタイトルセクション
  Widget _sectionTitleNew() {
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
                  MaterialPageRoute(builder: (_) => AddPostPagenew()),
                );
              },
              child: const Text('ジャンル追加'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                _showPicker(context, '8orAcU3UjLN7tBdKhRgA');
              },
              child: const Text('テーマ変更'),
            ),
          ],
        ),
      ),
    );
  }

  /// タイトル行（色付きの背景 + タップでタイトル編集 + メニュー追加ボタン）
  Widget _sectionTitle(DocumentSnapshot title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Food')
            .collection('color')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Container();
          }

          final documents = snapshot.data!.docs;
          final colorValue = documents[0]['color'];

          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      TitleEditPage(title.id, title['title'], 'Food'),
                ),
              );
            },
            child: Container(
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
              child: Row(
                children: [
                  Text(
                    '   ${title['title']}',
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
                          builder: (_) => AddPostPageFoodnew(title['title']),
                        ),
                      );
                    },
                    child: const Text('メニュー追加'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// セクション内部（Foodリスト）
  Widget _sectionContent(
    List<DocumentSnapshot> documents,
    String collection,
  ) {
    return Container(
      width: double.infinity,
      height: 190,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.black, width: 3)),
      ),
      child: ListView.builder(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          return _menuItem(documents[index], collection, documents.length);
        },
      ),
    );
  }

  /// 個々のメニューアイテム
  Widget _menuItem(
    DocumentSnapshot document,
    String collection,
    int length,
  ) {
    final String docId = document.id;
    return InkWell(
      onTap: () async {
        // タップで編集画面へ遷移
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddPostPageFood(collection, docId),
          ),
        );
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
                  await _uploadPicture(
                      'Food', collection, document['goods'], docId);
                },
                child: const Text('画像UP'),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  // 削除処理
                  await FirebaseFirestore.instance
                      .collection('Eng')
                      .doc('Food')
                      .collection(collection)
                      .doc(docId)
                      .delete();

                  // 最後の1件を削除した場合、タイトル自体も削除
                  if (length == 1) {
                    final query = await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Food')
                        .collection('titles')
                        .where('title', isEqualTo: collection)
                        .get();
                    for (var doc in query.docs) {
                      await FirebaseFirestore.instance
                          .collection('Eng')
                          .doc('Food')
                          .collection('titles')
                          .doc(doc.id)
                          .delete();
                    }
                  }

                  // 画像があればストレージも削除
                  if (document['image'] != "") {
                    await FirebaseStorage.instance
                        .ref()
                        .child(
                            'images/food/$collection/${document['goods']}.jpeg')
                        .delete();
                  }

                  if (!mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EngPageEditState()),
                  );
                },
              ),
              Text(document['cost']),
            ],
          ),
        ),
      ),
    );
  }

  /// スペーサー
  Widget _spacer(double height) {
    return SizedBox(height: height);
  }

  /// メニューボタン群
  Widget _menuButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () async {
            // 編集を終了して通常画面へ
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EngPageState()),
            );
          },
          child: _menuButton('編集終了'),
        ),
        const SizedBox(width: 15, height: 50),
        InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EngDrinkEditPageState()),
            );
          },
          child: _menuButton('Drink編集'),
        ),
        const SizedBox(width: 15, height: 50),
        InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EngCoursePageEditState()),
            );
          },
          child: _menuButton('コース編集'),
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
          value: lang['value'],
          child: Row(
            children: [
              Text(lang['label'] ?? ''),
              const SizedBox(width: 8),
              const Icon(Icons.language),
            ],
          ),
        );
      }).toList(),
      onChanged: (newValue) async {
        if (newValue != null) {
          setState(() {
            selectedLanguageValue = newValue;
          });
          // 言語変更後、Firestore に翻訳がないデータがあればまとめて翻訳を実行する
          await _checkAndTranslateMissingMenus();
        }
      },
    );
  }

  final int maxRetries = 10; // 最大リトライ回数
  final Duration retryDelay = Duration(seconds: 5);

  Future<void> translateMenu(
    String japaneseMenu,
    ValueNotifier<String> translated,
  ) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        final vertexAI =
            await FirebaseVertexAI.instanceFor(location: 'asia-northeast1');
        final model = vertexAI.generativeModel(model: 'gemini-1.5-flash');

        final prompt = '''
次の日本の料理屋のメニューを${selectedLanguageValue}に翻訳してください。厳密に訳す必要はありません。
どういった料理か伝わるようにお願いします。返答は翻訳後の料理名のみで。
料理名：$japaneseMenu
''';

        await Future.delayed(const Duration(seconds: 2));

        final response = await model.generateContent([Content.text(prompt)]);
        if (response.text != null) {
          translated.value = response.text!;
          return;
        } else {
          throw Exception('No text in response');
        }
      } catch (e) {
        attempts++;

        if (attempts < maxRetries) {
          await Future.delayed(retryDelay);
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> _checkAndTranslateMissingMenus() async {
    // すべての翻訳が必要なドキュメントを保持するリスト
    final List<QueryDocumentSnapshot> docsNeedingTranslation = [];

    final QuerySnapshot<Map<String, dynamic>> titlesSnapshot =
        await FirebaseFirestore.instance
            .collection('Eng')
            .doc('Food')
            .collection("titles")
            .orderBy('order')
            .get();

    final titles = titlesSnapshot.docs;

    // titles コレクション内のドキュメントを順番に処理
    for (var titleDoc in titles) {
      // titleDoc に格納されている 'title' フィールドをコレクション名に利用
      final subCollectionName = titleDoc.data()['title'];
      if (subCollectionName == null || subCollectionName is! String) {
        // 'title' フィールドが存在しないか、文字列でない場合はスキップ
        continue;
      }

      // サブコレクションを取得
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('Eng')
              .doc('Food')
              .collection(subCollectionName)
              .get();

      // 翻訳が必要なドキュメントを抽出（選択中の言語のフィールドが無いもの）
      final needingDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data[selectedLanguageValue] == null;
      }).toList();

      // docsNeedingTranslation に不足分をまとめて追加
      docsNeedingTranslation.addAll(needingDocs);
    }

    // 翻訳が必要なドキュメントが無ければ終了
    if (docsNeedingTranslation.isEmpty) {
      return;
    }

    setState(() {
      isTranslating = true; // 「翻訳中」表示用のフラグ
      translationTotal = docsNeedingTranslation.length;
      translationProgress = 0;
    });

    // 一件ずつ翻訳を実行して、Firestore に反映
    for (final doc in docsNeedingTranslation) {
      // doc.data() の戻り値を明示的に Map<String, dynamic> へキャスト
      final data = doc.data() as Map<String, dynamic>;

      // こうすることで data['ja'] が安全に書ける
      final jaMenu = data['ja'];

      // jaMenu が null や String 以外の場合もあるので必要ならチェック
      if (jaMenu == null || jaMenu is! String || jaMenu.isEmpty) {
        continue;
      }
      // 翻訳先を格納する ValueNotifier
      final translated = ValueNotifier<String>('');
      await translateMenu(jaMenu, translated);

      // 翻訳結果を Firestore にアップデート
      await doc.reference.update({selectedLanguageValue: translated.value});

      setState(() {
        translationProgress += 1;
      });
    }

    setState(() {
      isTranslating = false;
    });
  }

  /// メニューボタンの共通UI
  Widget _menuButton(String text) {
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
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

/// 画像を選択＆Firebase Storageにアップロードし、FirestoreのURLを更新
Future<void> _uploadPicture(
  String food,
  String collection,
  String name,
  String docId,
) async {
  try {
    Uint8List? uint8list = await ImagePickerWeb.getImageAsBytes();
    if (uint8list != null) {
      final metadata = SettableMetadata(contentType: "image/jpeg");
      final referenceRoot = FirebaseStorage.instance
          .ref()
          .child('images/$food/$collection/$name.jpeg');

      await referenceRoot.putData(uint8list, metadata);
      final String downloadURL = await referenceRoot.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Eng')
          .doc(food)
          .collection(collection)
          .doc(docId)
          .update({'image': downloadURL});
    }
  } catch (e) {
    // アップロードやFirestore更新の失敗時
    debugPrint('Error in _uploadPicture: $e');
  }
}
