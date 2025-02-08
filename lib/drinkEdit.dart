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
import 'package:firebase_vertexai/firebase_vertexai.dart';

class EngDrinkEditPageState extends StatefulWidget {
  const EngDrinkEditPageState({Key? key}) : super(key: key);

  @override
  _EngDrinkEditPageState createState() => _EngDrinkEditPageState();
}

class _EngDrinkEditPageState extends State<EngDrinkEditPageState> {
  Color _selectedColor = Colors.lightGreen;
  bool isTranslating = false;
  int translationTotal = 0;
  int translationProgress = 0;

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _spacer(5),
            _buildMenuButtons(),
            if (isTranslating) Text("wait") else _languageDropdownEdit(),
            _buildNewSectionTitle(),
            _spacer(5),
            if (isTranslating)
              Column(
                children: [
                  Text('翻訳中... $translationProgress / $translationTotal'),
                  LinearProgressIndicator(
                    value: translationTotal == 0
                        ? 0
                        : translationProgress / translationTotal,
                  ),
                ],
              )
            else
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
          label: 'Drink編集',
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
            .doc('Drink')
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
              .doc('Drink')
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
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20))),
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 30),
                child: Wrap(children: [
                  Text('   $titleName',
                      style: TextStyle(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: Colors.white)),
                  SizedBox(width: 10),
                  ElevatedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: ((context) =>
                                AddPostPageDrinknew(titleName))));
                      },
                      child: Text('メニュー追加'))
                ]),
              );
            }
            return Container();
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
    DocumentSnapshot document,
    String collection,
    int length,
  ) {
    // ドキュメントデータを取得（null なら空の Map）
    final data = document.data() as Map<String, dynamic>? ?? {};

    // 1. 「selectedLanguageValue」キーを持っているかチェック
    final hasSelectedLangField = data.containsKey(selectedLanguageValue);
    if (!hasSelectedLangField) {
      // 「goods」キーがあるかチェック
      final hasGoodsField = data.containsKey('goods');
      if (!hasGoodsField) {
        // どちらも無い場合 → フォールバック用メッセージ
        data['fallback'] = 'Not available in this language.';
      } else {
        // selectedLanguageValue フィールドが無いので、代わりに goods を使う
        data[selectedLanguageValue] = data['goods'];
      }
    }

    // 2. 表示用の文字列を決定
    final displayedName = data[selectedLanguageValue] ?? data['fallback'] ?? '';

    // 「ja」フィールドの値（日本語表示用）。無い場合は空文字にしておく
    final displayedJa = data['ja'] ?? '';

    // 価格情報があれば表示したい
    final costText = data['cost'] ?? '';

    // 画像 URL
    final imageUrl = data['image'] ?? '';

    // _uploadPicture や削除時のファイル名に使用するために
    // 「goods」フィールドがあればそれを優先。無い場合は表示名を使う
    final goodsForFileName = data['goods'] ?? displayedName;

    // ドキュメントのID
    final String docId = document.id;

    return InkWell(
      onTap: () async {
        // タップで編集画面へ遷移
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddPostPageDrink(collection, docId),
          ),
        );
      },
      child: Card(
        child: ListTile(
          // 3. 多言語対応した `displayedName` を表示
          title: Text(displayedName),
          // 日本語の原文（ja）をサブタイトルに表示（編集誘導文付き）
          subtitle: Text("$displayedJa (タップで編集)"),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 画像アップロードボタン
              ElevatedButton(
                onPressed: () async {
                  await _uploadPicture(
                    'Drink',
                    collection,
                    goodsForFileName,
                    docId,
                  );
                },
                child: const Text('画像UP'),
              ),

              // 削除アイコン
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  // 1. Firestore で該当ドキュメントを削除
                  await FirebaseFirestore.instance
                      .collection('Eng')
                      .doc('Drink')
                      .collection(collection)
                      .doc(docId)
                      .delete();

                  // 2. 最後の1件なら「titles」コレクションのタイトル自体も削除
                  if (length == 1) {
                    final query = await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Drink')
                        .collection('titles')
                        .where('title', isEqualTo: collection)
                        .get();

                    for (var doc in query.docs) {
                      await FirebaseFirestore.instance
                          .collection('Eng')
                          .doc('Drink')
                          .collection('titles')
                          .doc(doc.id)
                          .delete();
                    }
                  }

                  // 3. 画像があればストレージも削除
                  if (imageUrl.isNotEmpty) {
                    await FirebaseStorage.instance
                        .ref()
                        .child(
                            'images/drink/$collection/$goodsForFileName.jpeg')
                        .delete();
                  }

                  // 4. 画面を再読み込みまたは別画面へ
                  if (!mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EngPageEditState()),
                  );
                },
              ),

              // 価格表示
              Text(costText),
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
Future<void> _uploadPicture(
  String drink,
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
          .child('images/$drink/$collection/$name.jpeg');

      await referenceRoot.putData(uint8list, metadata);
      final String downloadURL = await referenceRoot.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('Eng')
          .doc(drink)
          .collection(collection)
          .doc(docId)
          .update({'image': downloadURL});
    }
  } catch (e) {
    // アップロードやFirestore更新の失敗時
    debugPrint('Error in _uploadPicture: $e');
  }
}
