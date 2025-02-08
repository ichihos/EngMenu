import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ushinohone_anaza/main.dart';
import 'food.dart';
import 'drinkEdit.dart';
import 'foodEdit.dart';
import 'courseEdit.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

/// ------------------------------
/// 共通で使う関数やウィジェット
/// ------------------------------

/// 日本語メニューを英語に翻訳する（Vertex AI）。
Future<void> translateMenu(
  String japanesemenu,
  ValueNotifier<String> translated,
) async {
  final model =
      FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

  final prompt = '''
次の日本の料理屋のメニューを$selectedLanguageValueにしてください。厳密に訳す必要はありません。
どういった料理か伝わるようにお願いします。返答は翻訳後の料理名のみで。
料理名：$japanesemenu
''';

  final response = await model.generateContent([Content.text(prompt)]);
  if (response.text != null) {
    translated.value = response.text!;
  } else {
    throw Exception('Failed to load data');
  }
}

/// テキストフィールドの共通ウィジェット
/// テキストフィールドの共通ウィジェット
Widget buildTextFormField({
  required String label,
  TextEditingController? controller,
  ValueChanged<String>? onChanged, // ← 追加
  int maxLines = 3,
}) {
  return TextFormField(
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.multiline,
    controller: controller,
    maxLines: maxLines,
    onChanged: onChanged, // ← ここで受け取ってそのまま渡す
  );
}

/// ------------------------------
/// フード・ドリンク編集のベースクラス
/// ------------------------------

/// 「Food」や「Drink」など、トップレベルの doc を切り替えられるようにしたベースクラス。
abstract class BaseAddPostPage extends StatefulWidget {
  final String topDoc; // "Food" or "Drink" など
  final String collection;
  final String docid;

  const BaseAddPostPage({
    Key? key,
    required this.topDoc,
    required this.collection,
    required this.docid,
  }) : super(key: key);
}

/// State も共通化
abstract class BaseAddPostPageState<T extends BaseAddPostPage>
    extends State<T> {
  final TextEditingController goodsController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController japaneseController = TextEditingController();
  final TextEditingController orderController = TextEditingController();
  final ValueNotifier<String> translated = ValueNotifier<String>('');

  @override
  void dispose() {
    goodsController.dispose();
    costController.dispose();
    japaneseController.dispose();
    orderController.dispose();
    super.dispose();
  }

  /// Firestore から取得してコントローラに反映
  Future<void> _loadData() async {
    final snap = await FirebaseFirestore.instance
        .collection('Eng')
        .doc(widget.topDoc) // Food or Drink
        .collection(widget.collection)
        .doc(widget.docid)
        .get();

    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      goodsController.text = data[selectedLanguageValue] ?? '';
      costController.text = data['cost'] ?? '';
      japaneseController.text = data['ja'] ?? '';
      orderController.text = data['order'] ?? '';
    }
  }

  /// Firestore にアップデート
  Future<void> updateDatabase() async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc(widget.topDoc)
        .collection(widget.collection)
        .doc(widget.docid)
        .update({
      selectedLanguageValue: goodsController.text,
      'cost': costController.text,
      'ja': japaneseController.text,
      'order': orderController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー編集'),
      ),
      body: FutureBuilder(
        future: _loadData(),
        builder: (context, snapshot) {
          // ロード中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // エラー
          if (snapshot.hasError) {
            return const Center(child: Text("エラーが発生しました"));
          }

          // データ取得完了
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  buildTextFormField(
                    label: '品名(日本語)',
                    controller: japaneseController,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await translateMenu(
                        japaneseController.text,
                        translated,
                      );
                      goodsController.text = translated.value;
                    },
                    child: const Text('↑翻訳↓'),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: translated,
                    builder: (context, value, child) {
                      return buildTextFormField(
                        label: '品名(英語)',
                        controller: goodsController,
                      );
                    },
                  ),
                  buildTextFormField(label: '値段', controller: costController),
                  buildTextFormField(label: '順番', controller: orderController),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          await updateDatabase();
                          onPressedContinueEdit();
                        },
                        child: const Text("続けて編集"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await updateDatabase();
                          onPressedGoHome();
                        },
                        child: const Text("ホームに戻る"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("キャンセル"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 「続けて編集」ボタンの挙動（各ページでオーバーライドする場合はここでメソッドを定義）
  void onPressedContinueEdit();

  /// 「ホームに戻る」ボタンの挙動（同上）
  void onPressedGoHome();
}

/// ------------------------------
/// Food / Drink 編集ページ
/// ------------------------------

class AddPostPageFood extends BaseAddPostPage {
  const AddPostPageFood(String collection, String docid, {Key? key})
      : super(topDoc: 'Food', collection: collection, docid: docid, key: key);

  @override
  AddPostPageFoodState createState() => AddPostPageFoodState();
}

class AddPostPageFoodState extends BaseAddPostPageState<AddPostPageFood> {
  @override
  void onPressedContinueEdit() {
    // 続けて編集時の画面遷移（例：フード編集一覧ページへ）
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EngPageEditState()),
    );
  }

  @override
  void onPressedGoHome() {
    // ホーム画面へ戻る
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EngPageState()),
    );
  }
}

class AddPostPageDrink extends BaseAddPostPage {
  const AddPostPageDrink(String collection, String docid, {Key? key})
      : super(topDoc: 'Drink', collection: collection, docid: docid, key: key);

  @override
  AddPostPageDrinkState createState() => AddPostPageDrinkState();
}

class AddPostPageDrinkState extends BaseAddPostPageState<AddPostPageDrink> {
  @override
  void onPressedContinueEdit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EngDrinkEditPageState()),
    );
  }

  @override
  void onPressedGoHome() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EngPageState()),
    );
  }
}

/// ------------------------------
/// フード・ドリンクの新規追加クラス（ベース）
/// ------------------------------

/// 「Food」「Drink」共通の新規追加ベース。
abstract class BaseAddPostPageNew extends StatefulWidget {
  final String topDoc; // "Food" or "Drink"
  final String collection; // ジャンル名

  const BaseAddPostPageNew({
    Key? key,
    required this.topDoc,
    required this.collection,
  }) : super(key: key);
}

/// State
abstract class BaseAddPostPageNewState<T extends BaseAddPostPageNew>
    extends State<T> {
  String goods = '';
  String cost = '';
  String japanese = '';
  String image = '';
  String order = '';

  final ValueNotifier<String> translated = ValueNotifier<String>('');
  final TextEditingController goodsController = TextEditingController();

  Future<void> _saveData() async {
    // 新規ドキュメントを作成
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc(widget.topDoc) // Food or Drink
        .collection(widget.collection)
        .doc() // ドキュメントID自動生成
        .set({
      'goods': goods,
      'cost': cost,
      'ja': japanese,
      'image': image,
      'order': order,
    });
  }

  /// 新規追加後の遷移先(オーバーライドで実装)
  void onAdded();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('メニュー追加 ${widget.collection}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildTextFormField(
                label: '品名(日本語)',
                controller: TextEditingController(),
                maxLines: 3,
                onChanged: (value) => setState(() => japanese = value),
              ),
              ElevatedButton(
                onPressed: () async {
                  await translateMenu(japanese, translated);
                  goodsController.text = translated.value;
                  setState(() => goods = translated.value);
                },
                child: const Text('↑翻訳↓'),
              ),
              ValueListenableBuilder<String>(
                valueListenable: translated,
                builder: (context, value, child) {
                  return TextFormField(
                    decoration: const InputDecoration(labelText: '品名(英語)'),
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    controller: goodsController,
                    onChanged: (v) => setState(() => goods = v),
                  );
                },
              ),
              buildTextFormField(
                label: '値段',
                controller: TextEditingController(),
                maxLines: 3,
                onChanged: (value) => setState(() => cost = value),
              ),
              buildTextFormField(
                label: '順番(辞書順)',
                controller: TextEditingController(),
                maxLines: 3,
                onChanged: (value) => setState(() => order = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    await _saveData();
                    onAdded();
                  },
                ),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}

/// Food
class AddPostPageFoodnew extends BaseAddPostPageNew {
  const AddPostPageFoodnew(String collection, {Key? key})
      : super(topDoc: 'Food', collection: collection, key: key);

  @override
  BaseAddPostPageNewState<AddPostPageFoodnew> createState() =>
      _AddPostPageFoodnewState();
}

class _AddPostPageFoodnewState
    extends BaseAddPostPageNewState<AddPostPageFoodnew> {
  @override
  void onAdded() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EngPageEditState()),
    );
  }
}

/// Drink
class AddPostPageDrinknew extends BaseAddPostPageNew {
  const AddPostPageDrinknew(String collection, {Key? key})
      : super(topDoc: 'Drink', collection: collection, key: key);

  @override
  BaseAddPostPageNewState<AddPostPageDrinknew> createState() =>
      _AddPostPageDrinknewState();
}

class _AddPostPageDrinknewState
    extends BaseAddPostPageNewState<AddPostPageDrinknew> {
  @override
  void onAdded() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EngDrinkEditPageState()),
    );
  }
}

/// ------------------------------
/// 食べ物用ジャンル追加：AddPostPagenew
/// ------------------------------
/// こちらは「genre」を新規作成する特殊ケース（titles にも書き込みが必要）

class AddPostPagenew extends StatefulWidget {
  const AddPostPagenew({Key? key}) : super(key: key);

  @override
  _AddPostPagenewState createState() => _AddPostPagenewState();
}

class _AddPostPagenewState extends State<AddPostPagenew> {
  String genre = '';
  String goods = '';
  String cost = '';
  String japanese = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  final TextEditingController goodsController = TextEditingController();

  Future<void> _saveData() async {
    // 新規ジャンル (genre) にメニューを追加
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Food')
        .collection(genre)
        .doc()
        .set({
      'goods': goods,
      'cost': cost,
      'ja': japanese,
      'image': '',
      'order': '0',
    });

    // titles にもジャンルを追加
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Food')
        .collection('titles')
        .doc()
        .set({'title': genre, 'order': order});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ジャンル追加(食べ物)'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              buildTextFormField(
                label: 'ジャンル名(英語)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => genre = value),
              ),
              buildTextFormField(
                label: '品名(日本語)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => japanese = value),
              ),
              ElevatedButton(
                onPressed: () async {
                  await translateMenu(japanese, translated);
                  goodsController.text = translated.value;
                  setState(() => goods = translated.value);
                },
                child: const Text('↑翻訳↓'),
              ),
              ValueListenableBuilder<String>(
                valueListenable: translated,
                builder: (context, value, child) {
                  return TextFormField(
                    decoration: const InputDecoration(labelText: '品名(英語)'),
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    controller: goodsController,
                    onChanged: (v) => setState(() => goods = v),
                  );
                },
              ),
              buildTextFormField(
                label: '値段',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => cost = value),
              ),
              buildTextFormField(
                label: '順番(数字)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => order = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    await _saveData();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => EngPageEditState()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// 飲み物用ジャンル追加：AddPostPagenewDrink
/// ------------------------------
class AddPostPagenewDrink extends StatefulWidget {
  const AddPostPagenewDrink({Key? key}) : super(key: key);

  @override
  _AddPostPagenewDrinkState createState() => _AddPostPagenewDrinkState();
}

class _AddPostPagenewDrinkState extends State<AddPostPagenewDrink> {
  String genre = '';
  String goods = '';
  String cost = '';
  String japanese = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  final TextEditingController goodsController = TextEditingController();

  Future<void> _saveData() async {
    // 新規ジャンル (genre) にメニューを追加
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Drink')
        .collection(genre)
        .doc()
        .set({
      'goods': goods,
      'cost': cost,
      'ja': japanese,
      'image': '',
      'order': '0',
    });
    // titles にジャンル追加
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Drink')
        .collection('titles')
        .doc()
        .set({'title': genre, 'order': order});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ジャンル追加(飲み物)'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              buildTextFormField(
                label: 'ジャンル名(英語)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => genre = value),
              ),
              buildTextFormField(
                label: '品名(日本語)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => japanese = value),
              ),
              ElevatedButton(
                onPressed: () async {
                  await translateMenu(japanese, translated);
                  goodsController.text = translated.value;
                  setState(() => goods = translated.value);
                },
                child: const Text('↑翻訳↓'),
              ),
              ValueListenableBuilder<String>(
                valueListenable: translated,
                builder: (context, value, child) {
                  return TextFormField(
                    decoration: const InputDecoration(labelText: '品名(英語)'),
                    maxLines: 3,
                    controller: goodsController,
                    onChanged: (v) => setState(() => goods = v),
                  );
                },
              ),
              buildTextFormField(
                label: '値段',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => cost = value),
              ),
              buildTextFormField(
                label: '順番(数字)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => order = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    await _saveData();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => EngDrinkEditPageState()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// コース編集：AddPostPageCourse
/// ------------------------------
class AddPostPageCourse extends StatefulWidget {
  final String docid;
  final String name;

  const AddPostPageCourse(this.docid, this.name, {Key? key}) : super(key: key);

  @override
  _AddPostPageCourseState createState() => _AddPostPageCourseState();
}

class _AddPostPageCourseState extends State<AddPostPageCourse> {
  final goodsController = TextEditingController(); // title(役割)
  final costController = TextEditingController(); // discription(英語表記)
  final japaneseController = TextEditingController(); // 日本語
  final orderController = TextEditingController();
  final ValueNotifier<String> translated = ValueNotifier<String>('');

  @override
  void dispose() {
    goodsController.dispose();
    costController.dispose();
    japaneseController.dispose();
    orderController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final snap = await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Course')
        .collection(widget.name)
        .doc(widget.docid)
        .get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      goodsController.text = data['title'] ?? '';
      costController.text = data['discription'] ?? '';
      japaneseController.text = data['ja'] ?? '';
      orderController.text = data['order'] ?? '';
    }
  }

  Future<void> _updateDatabase() async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Course')
        .collection(widget.name)
        .doc(widget.docid)
        .update({
      'title': goodsController.text,
      'discription': costController.text,
      'ja': japaneseController.text,
      'order': orderController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー編集'),
      ),
      body: FutureBuilder(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("エラーが発生しました"));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: <Widget>[
                  buildTextFormField(
                    label: '役割 (例: main)',
                    controller: goodsController,
                  ),
                  buildTextFormField(
                    label: '品名(日本語)',
                    controller: japaneseController,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await translateMenu(japaneseController.text, translated);
                      costController.text = translated.value;
                    },
                    child: const Text('↑翻訳↓'),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: translated,
                    builder: (context, value, child) {
                      return buildTextFormField(
                        label: '品名(英語)',
                        controller: costController,
                      );
                    },
                  ),
                  buildTextFormField(
                    label: '順番',
                    controller: orderController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          await _updateDatabase();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EngCoursePageEditState(),
                            ),
                          );
                        },
                        child: const Text("続けて編集"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _updateDatabase();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EngPageState(),
                            ),
                          );
                        },
                        child: const Text("ホームに戻る"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("キャンセル"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ------------------------------
/// ジャンルの順番編集用：TitleEditPage
/// ------------------------------
class TitleEditPage extends StatefulWidget {
  final String docid;
  final String name;
  final String genre; // "Food" or "Drink" or "Course"

  const TitleEditPage(this.docid, this.name, this.genre, {Key? key})
      : super(key: key);

  @override
  TitleEditPageState createState() => TitleEditPageState();
}

class TitleEditPageState extends State<TitleEditPage> {
  final orderController = TextEditingController();

  @override
  void dispose() {
    orderController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final snap = await FirebaseFirestore.instance
        .collection('Eng')
        .doc(widget.genre)
        .collection('titles')
        .doc(widget.docid)
        .get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      orderController.text = data['order'] ?? '';
    }
  }

  Future<void> _updateDatabase() async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc(widget.genre)
        .collection('titles')
        .doc(widget.docid)
        .update({'order': orderController.text});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー編集'),
      ),
      body: FutureBuilder(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("エラーが発生しました"));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: <Widget>[
                  buildTextFormField(
                    label: '順番',
                    controller: orderController,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          await _updateDatabase();
                          if (widget.genre == 'Food') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EngPageEditState(),
                              ),
                            );
                          } else if (widget.genre == 'Drink') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EngDrinkEditPageState(),
                              ),
                            );
                          } else {
                            // コース
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EngCoursePageEditState(),
                              ),
                            );
                          }
                        },
                        child: const Text("続けて編集"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _updateDatabase();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EngPageState(),
                            ),
                          );
                        },
                        child: const Text("ホームに戻る"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("キャンセル"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ------------------------------
/// コースの新規追加
/// ------------------------------

class AddPostPagenewCourse extends StatefulWidget {
  final String name; // 追加先のコース名

  const AddPostPagenewCourse(this.name, {Key? key}) : super(key: key);

  @override
  _AddPostPagenewCourseState createState() => _AddPostPagenewCourseState();
}

class _AddPostPagenewCourseState extends State<AddPostPagenewCourse> {
  String genre = '';
  String goods = '';
  String japanese = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  final TextEditingController goodsController = TextEditingController();

  Future<void> _saveData() async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Course')
        .collection(widget.name)
        .doc()
        .set({
      'title': genre,
      'discription': goods,
      'ja': japanese,
      'image': '',
      'order': order,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('コースメニュー追加 (${widget.name})'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              buildTextFormField(
                label: '役割(例: main)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => genre = value),
              ),
              buildTextFormField(
                label: '名前(日本語)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => japanese = value),
              ),
              ElevatedButton(
                onPressed: () async {
                  await translateMenu(japanese, translated);
                  goodsController.text = translated.value;
                  setState(() => goods = translated.value);
                },
                child: const Text('↑翻訳↓'),
              ),
              ValueListenableBuilder<String>(
                valueListenable: translated,
                builder: (context, value, child) {
                  return TextFormField(
                    decoration: const InputDecoration(labelText: '品名(英語)'),
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    controller: goodsController,
                    onChanged: (v) => setState(() => goods = v),
                  );
                },
              ),
              buildTextFormField(
                label: '順番',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => order = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    await _saveData();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => EngCoursePageEditState()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// コース自体の新規追加
/// ------------------------------
class AddPostnewCourse extends StatefulWidget {
  const AddPostnewCourse({Key? key}) : super(key: key);

  @override
  _AddPostnewCourseState createState() => _AddPostnewCourseState();
}

class _AddPostnewCourseState extends State<AddPostnewCourse> {
  String coursename = '';
  String genre = '';
  String goods = '';
  String japanese = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  final TextEditingController goodsController = TextEditingController();

  Future<void> _saveData() async {
    // 新しいコース名のサブコレクションを作成し、1件目のドキュメントを追加
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Course')
        .collection(coursename)
        .doc()
        .set({
      'title': genre,
      'discription': goods,
      'ja': japanese,
      'image': '',
      'order': order,
    });

    // コースのタイトルリストにも追加
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Course')
        .collection('titles')
        .doc()
        .set({'title': coursename, 'order': order});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コース追加'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: <Widget>[
              buildTextFormField(
                label: 'コース名(英語)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => coursename = value),
              ),
              buildTextFormField(
                label: '役割(例: main)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => genre = value),
              ),
              buildTextFormField(
                label: '名前(日本語)',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => japanese = value),
              ),
              ElevatedButton(
                onPressed: () async {
                  await translateMenu(japanese, translated);
                  goodsController.text = translated.value;
                  setState(() => goods = translated.value);
                },
                child: const Text('↑翻訳↓'),
              ),
              ValueListenableBuilder<String>(
                valueListenable: translated,
                builder: (context, value, child) {
                  return TextFormField(
                    decoration: const InputDecoration(labelText: '品名(英語)'),
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    controller: goodsController,
                    onChanged: (v) => setState(() => goods = v),
                  );
                },
              ),
              buildTextFormField(
                label: '順番',
                controller: TextEditingController(),
                onChanged: (value) => setState(() => order = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    await _saveData();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => EngCoursePageEditState()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------
/// パスワードページ
/// ------------------------------
class Password extends StatefulWidget {
  const Password({Key? key}) : super(key: key);

  @override
  _PasswordState createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワード'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _passwordController,
                focusNode: _focusNode,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final password = _passwordController.text.trim();
                  if (password == configurations.password) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EngPageEditState(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('パスワードが間違っています')),
                    );
                  }
                },
                child: const Text('入力'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
