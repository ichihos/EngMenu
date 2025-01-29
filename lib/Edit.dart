import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ushinohone_anaza/main.dart';
import 'food.dart';
import 'drinkEdit.dart';
import 'foodEdit.dart';
import 'courseEdit.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

Future<void> translateMenu(
    String japanesemenu, ValueNotifier<String> translated) async {
  final model =
      FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.0-flash-exp');

  final prompt =
      '次の日本の料理屋のメニューを英語にしてください。厳密に訳す必要はありません。どういった料理か伝わるようにお願いします。返答は翻訳後の料理名のみで。料理名：$japanesemenu';

  final response = await model.generateContent([Content.text(prompt)]);

  if (response.text != null) {
    translated.value = response.text!;
  } else {
    throw Exception('Failed to load data');
  }
}

class AddPostPageFood extends StatefulWidget {
  final String collection;
  final String docid;

  const AddPostPageFood(this.collection, this.docid, {super.key});

  @override
  _AddPostPageFoodState createState() => _AddPostPageFoodState();
}

class _AddPostPageFoodState extends State<AddPostPageFood> {
  // 入力した投稿メッセージ
  String goods = '';
  String cost = '';
  String japanese = '';
  String order = '';
  final goodsController = TextEditingController();
  final costController = TextEditingController();
  final japaneseController = TextEditingController();
  final orderController = TextEditingController();
  final ValueNotifier<String> translated = ValueNotifier<String>('');

  @override
  void dispose() {
    // コントローラを破棄
    goodsController.dispose();
    costController.dispose();
    japaneseController.dispose();
    orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー編集'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Food')
            .collection(widget.collection)
            .doc(widget.docid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("エラーが発生しました"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("データが存在しません"));
          }

          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            goodsController.text = data['goods'] ?? '';
            costController.text = data['cost'] ?? '';
            japaneseController.text = data['ja'] ?? '';
            orderController.text = data['order'] ?? '';
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          goods = data['goods'] ?? '';
          cost = data['cost'] ?? '';
          japanese = data['ja'] ?? '';
          order = data['order'] ?? '';

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  buildTextFormField('品名(日本語)', japaneseController),
                  ElevatedButton(
                      onPressed: () async {
                        String japanesemenu = japaneseController.text;
                        await translateMenu(japanesemenu, translated);
                        goodsController.text = translated.value;
                      },
                      child: const Text('↑翻訳↓')),
                  ValueListenableBuilder<String>(
                      valueListenable: translated,
                      builder: (context, value, child) {
                        return buildTextFormField('品名(英語)', goodsController);
                      }),
                  buildTextFormField('値段', costController),
                  buildTextFormField('順番', orderController),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                          onPressed: () async {
                            await updateDatabase(
                                widget.collection, widget.docid);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => EngPageEditState())));
                          },
                          child: const Text("続けて編集")),
                      ElevatedButton(
                          onPressed: () async {
                            await updateDatabase(
                                widget.collection, widget.docid);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => EngPageState())));
                          },
                          child: const Text("ホームに戻る")),
                      ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          child: const Text("キャンセル"))
                    ],
                  ),
                  Container(
                    height: 150,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTextFormField(String label, TextEditingController controller) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.multiline,
      controller: controller,
      maxLines: 3,
    );
  }

  Future<void> updateDatabase(String collection, String docid) async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Food')
        .collection(collection)
        .doc(docid)
        .update({
      'goods': goodsController.text,
      'cost': costController.text,
      'ja': japaneseController.text,
      'order': orderController.text
    });
  }
}

class AddPostPageDrink extends StatefulWidget {
  final String collection;
  final String docid;

  const AddPostPageDrink(this.collection, this.docid, {super.key});

  @override
  _AddPostPageDrinkState createState() => _AddPostPageDrinkState();
}

class _AddPostPageDrinkState extends State<AddPostPageDrink> {
  // 入力した投稿メッセージ
  String goods = '';
  String cost = '';
  String japanese = '';
  String order = '';
  final goodsController = TextEditingController();
  final costController = TextEditingController();
  final japaneseController = TextEditingController();
  final orderController = TextEditingController();
  final ValueNotifier<String> translated = ValueNotifier<String>('');

  @override
  void dispose() {
    // コントローラを破棄
    goodsController.dispose();
    costController.dispose();
    japaneseController.dispose();
    orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー編集'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Drink')
            .collection(widget.collection)
            .doc(widget.docid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("エラーが発生しました"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("データが存在しません"));
          }

          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            goodsController.text = data['goods'] ?? '';
            costController.text = data['cost'] ?? '';
            japaneseController.text = data['ja'] ?? '';
            orderController.text = data['order'] ?? '';
          }

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  buildTextFormField('品名(日本語)', japaneseController),
                  ElevatedButton(
                      onPressed: () async {
                        String japanesemenu = japaneseController.text;
                        await translateMenu(japanesemenu, translated);
                        goodsController.text = translated.value;
                      },
                      child: const Text('↑翻訳↓')),
                  ValueListenableBuilder<String>(
                      valueListenable: translated,
                      builder: (context, value, child) {
                        return buildTextFormField('品名(英語)', goodsController);
                      }),
                  buildTextFormField('値段', costController),
                  buildTextFormField('順番', orderController),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                          onPressed: () async {
                            await updateDatabase(
                                widget.collection, widget.docid);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) =>
                                    EngDrinkEditPageState())));
                          },
                          child: const Text("続けて編集")),
                      ElevatedButton(
                          onPressed: () async {
                            await updateDatabase(
                                widget.collection, widget.docid);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => EngPageState())));
                          },
                          child: const Text("ホームに戻る")),
                      ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          child: const Text("キャンセル"))
                    ],
                  ),
                  Container(
                    height: 150,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTextFormField(String label, TextEditingController controller) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.multiline,
      controller: controller,
      maxLines: 3,
    );
  }

  Future<void> updateDatabase(String collection, String docid) async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Drink')
        .collection(collection)
        .doc(docid)
        .update({
      'goods': goodsController.text,
      'cost': costController.text,
      'ja': japaneseController.text,
      'order': orderController.text
    });
  }
}

class AddPostPageFoodnew extends StatefulWidget {
  final String collection;

  const AddPostPageFoodnew(this.collection, {super.key});
  @override
  _AddPostPageFoodnewState createState() => _AddPostPageFoodnewState();
}

class _AddPostPageFoodnewState extends State<AddPostPageFoodnew> {
  // 入力した投稿メッセージ
  String goods = '';
  String cost = '';
  String japanese = '';
  String image = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  TextEditingController goodsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('メニュー追加${widget.collection}'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: '品名(日本語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    japanese = value;
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    String japanesemenu = japanese;
                    await translateMenu(japanesemenu, translated);
                    goodsController.text = translated.value;
                    goods = translated.value;
                  },
                  child: const Text('↑翻訳↓')),
              ValueListenableBuilder<String>(
                  valueListenable: translated,
                  builder: (context, value, child) {
                    return TextFormField(
                        decoration: const InputDecoration(labelText: '品名(英語)'),
                        // 複数行のテキスト入力
                        keyboardType: TextInputType.multiline,
                        // 最大3行
                        maxLines: 3,
                        controller: goodsController,
                        onChanged: (String value) {
                          setState(() {
                            goods = value;
                          });
                        });
                  }),
              TextFormField(
                decoration: const InputDecoration(labelText: '値段'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    cost = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '順番(辞書順)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    order = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    // 投稿メッセージ用ドキュメント作成
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Food')
                        .collection(widget.collection)
                        .doc() // ドキュメントID自動生成
                        .set({
                      'goods': goods,
                      'cost': cost,
                      'ja': japanese,
                      'image': image,
                      'order': order
                    });
                    // 1つ前の画面に戻る
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => EngPageEditState())));
                  },
                ),
              ),
              Container(
                height: 150,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AddPostPageDrinknew extends StatefulWidget {
  final String collection;

  const AddPostPageDrinknew(this.collection, {super.key});
  @override
  _AddPostPageDrinknewState createState() => _AddPostPageDrinknewState();
}

class _AddPostPageDrinknewState extends State<AddPostPageDrinknew> {
  // 入力した投稿メッセージ
  String goods = '';
  String cost = '';
  String japanese = '';
  String image = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  TextEditingController goodsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('メニュー追加${widget.collection}'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: '品名(日本語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    japanese = value;
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    String japanesemenu = japanese;
                    await translateMenu(japanesemenu, translated);
                    goodsController.text = translated.value;
                    goods = translated.value;
                  },
                  child: const Text('↑翻訳↓')),
              ValueListenableBuilder<String>(
                  valueListenable: translated,
                  builder: (context, value, child) {
                    return TextFormField(
                        decoration: const InputDecoration(labelText: '品名(英語)'),
                        // 複数行のテキスト入力
                        keyboardType: TextInputType.multiline,
                        // 最大3行
                        maxLines: 3,
                        controller: goodsController,
                        onChanged: (String value) {
                          setState(() {
                            goods = value;
                          });
                        });
                  }),
              TextFormField(
                decoration: const InputDecoration(labelText: '値段'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    cost = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '順番(辞書順)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    order = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    // 投稿メッセージ用ドキュメント作成
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Drink')
                        .collection(widget.collection)
                        .doc() // ドキュメントID自動生成
                        .set({
                      'goods': goods,
                      'cost': cost,
                      'ja': japanese,
                      'image': image,
                      'order': order
                    });
                    // 1つ前の画面に戻る
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => EngDrinkEditPageState())));
                  },
                ),
              ),
              Container(
                height: 150,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AddPostPagenew extends StatefulWidget {
  const AddPostPagenew({super.key});

  @override
  _AddPostPagenewState createState() => _AddPostPagenewState();
}

class _AddPostPagenewState extends State<AddPostPagenew> {
  // 入力した投稿メッセージ
  String genre = '';
  String goods = '';
  String cost = '';
  String japanese = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  TextEditingController goodsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ジャンル追加(食べ物)'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'ジャンル名(英語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    genre = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '品名(日本語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    japanese = value;
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    String japanesemenu = japanese;
                    await translateMenu(japanesemenu, translated);
                    goodsController.text = translated.value;
                    goods = translated.value;
                  },
                  child: const Text('↑翻訳↓')),
              ValueListenableBuilder<String>(
                  valueListenable: translated,
                  builder: (context, value, child) {
                    return TextFormField(
                        decoration: const InputDecoration(labelText: '品名(英語)'),
                        // 複数行のテキスト入力
                        keyboardType: TextInputType.multiline,
                        // 最大3行
                        maxLines: 3,
                        controller: goodsController,
                        onChanged: (String value) {
                          setState(() {
                            goods = value;
                          });
                        });
                  }),
              TextFormField(
                decoration: const InputDecoration(labelText: '値段'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    cost = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '順番(数字)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    order = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    // 投稿メッセージ用ドキュメント作成
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Food')
                        .collection(genre)
                        .doc() // ドキュメントID自動生成
                        .set({
                      'goods': goods,
                      'cost': cost,
                      'ja': japanese,
                      'image': '',
                      'order': '0'
                    });
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Food')
                        .collection('titles')
                        .doc() // ドキュメントID自動生成
                        .set({'title': genre, 'order': order});
                    // 1つ前の画面に戻る
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => EngPageEditState())));
                  },
                ),
              ),
              Container(
                height: 150,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AddPostPagenewDrink extends StatefulWidget {
  const AddPostPagenewDrink({super.key});

  @override
  _AddPostPagenewDrinkState createState() => _AddPostPagenewDrinkState();
}

class _AddPostPagenewDrinkState extends State<AddPostPagenewDrink> {
  // 入力した投稿メッセージ
  String genre = '';
  String goods = '';
  String cost = '';
  String japanese = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  TextEditingController goodsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ジャンル追加(飲み物)'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'ジャンル名(英語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    genre = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '品名(日本語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    japanese = value;
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    String japanesemenu = japanese;
                    await translateMenu(japanesemenu, translated);
                    goodsController.text = translated.value;
                    goods = translated.value;
                  },
                  child: const Text('↑翻訳↓')),
              ValueListenableBuilder<String>(
                  valueListenable: translated,
                  builder: (context, value, child) {
                    return TextFormField(
                        decoration: const InputDecoration(labelText: '品名(英語)'),
                        // 複数行のテキスト入力
                        keyboardType: TextInputType.multiline,
                        // 最大3行
                        maxLines: 3,
                        controller: goodsController,
                        onChanged: (String value) {
                          setState(() {
                            goods = value;
                          });
                        });
                  }),
              TextFormField(
                decoration: const InputDecoration(labelText: '値段'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    cost = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '順番(数字)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    order = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    // 投稿メッセージ用ドキュメント作成
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Drink')
                        .collection(genre)
                        .doc() // ドキュメントID自動生成
                        .set({
                      'goods': goods,
                      'cost': cost,
                      'ja': japanese,
                      'image': '',
                      'order': '0'
                    });
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Drink')
                        .collection('titles')
                        .doc() // ドキュメントID自動生成
                        .set({'title': genre, 'order': order});
                    // 1つ前の画面に戻る
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => EngDrinkEditPageState())));
                  },
                ),
              ),
              Container(
                height: 150,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AddPostPageCourse extends StatefulWidget {
  final String docid;
  final String name;

  const AddPostPageCourse(this.docid, this.name, {super.key});

  @override
  _AddPostPageCourseState createState() => _AddPostPageCourseState();
}

class _AddPostPageCourseState extends State<AddPostPageCourse> {
  // 入力した投稿メッセージ
  String goods = '';
  String cost = '';
  String japanese = '';
  final goodsController = TextEditingController();
  final costController = TextEditingController();
  final japaneseController = TextEditingController();
  final orderController = TextEditingController();
  final ValueNotifier<String> translated = ValueNotifier<String>('');

  @override
  void dispose() {
    // コントローラを破棄
    goodsController.dispose();
    costController.dispose();
    japaneseController.dispose();
    orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー編集'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc('Course')
            .collection(widget.name)
            .doc(widget.docid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("エラーが発生しました"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("データが存在しません"));
          }

          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            goodsController.text = data['title'] ?? '';
            costController.text = data['discription'] ?? '';
            japaneseController.text = data['ja'] ?? '';
            orderController.text = data['order'] ?? '';
          }

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  buildTextFormField('役割（例:main)', goodsController),
                  buildTextFormField('品名(日本語)', japaneseController),
                  ElevatedButton(
                      onPressed: () async {
                        String japanesemenu = japaneseController.text;
                        await translateMenu(japanesemenu, translated);
                        costController.text = translated.value;
                      },
                      child: const Text('↑翻訳↓')),
                  ValueListenableBuilder<String>(
                      valueListenable: translated,
                      builder: (context, value, child) {
                        return buildTextFormField('品名(英語)', costController);
                      }),
                  buildTextFormField('順番', orderController),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                          onPressed: () async {
                            await updateDatabase(widget.name, widget.docid);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) =>
                                    EngCoursePageEditState())));
                          },
                          child: const Text("続けて編集")),
                      ElevatedButton(
                          onPressed: () async {
                            await updateDatabase(widget.name, widget.docid);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => EngPageState())));
                          },
                          child: const Text("ホームに戻る")),
                      ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          child: const Text("キャンセル"))
                    ],
                  ),
                  Container(
                    height: 150,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTextFormField(String label, TextEditingController controller) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.multiline,
      controller: controller,
      maxLines: 3,
    );
  }

  Future<void> updateDatabase(String collection, String docid) async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc('Course')
        .collection(collection)
        .doc(docid)
        .update({
      'title': goodsController.text,
      'discription': costController.text,
      'ja': japaneseController.text,
      'order': orderController.text
    });
  }
}

class TitleEditPage extends StatefulWidget {
  final String docid;
  final String name;
  final String genre;

  const TitleEditPage(this.docid, this.name, this.genre, {super.key});

  @override
  TitleEditPageState createState() => TitleEditPageState();
}

class TitleEditPageState extends State<TitleEditPage> {
  // 入力した投稿メッセージ
  String name = '';
  final orderController = TextEditingController();

  @override
  void dispose() {
    orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー編集'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Eng')
            .doc(widget.genre)
            .collection('titles')
            .doc(widget.docid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("エラーが発生しました"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("データが存在しません"));
          }

          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            orderController.text = data['order'] ?? '';
          }

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  buildTextFormField('順番', orderController),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                          onPressed: () async {
                            await updateDatabase(
                                widget.name, widget.docid, widget.genre);
                            if (widget.genre == 'Food') {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) => EngPageEditState())));
                            } else if (widget.genre == 'Drink') {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) =>
                                      EngDrinkEditPageState())));
                            } else if (widget.genre == 'Course') {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) =>
                                      EngCoursePageEditState())));
                            }
                          },
                          child: const Text("続けて編集")),
                      ElevatedButton(
                          onPressed: () async {
                            await updateDatabase(
                                widget.name, widget.docid, widget.genre);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) => EngPageState())));
                          },
                          child: const Text("ホームに戻る")),
                      ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          child: const Text("キャンセル"))
                    ],
                  ),
                  Container(
                    height: 150,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTextFormField(String label, TextEditingController controller) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.multiline,
      controller: controller,
      maxLines: 3,
    );
  }

  Future<void> updateDatabase(
      String collection, String docid, String genre) async {
    await FirebaseFirestore.instance
        .collection('Eng')
        .doc(genre)
        .collection('titles')
        .doc(docid)
        .update({'order': orderController.text});
  }
}

class AddPostPagenewCourse extends StatefulWidget {
  final String name;

  const AddPostPagenewCourse(this.name, {super.key});
  @override
  _AddPostPagenewCourseState createState() => _AddPostPagenewCourseState();
}

class _AddPostPagenewCourseState extends State<AddPostPagenewCourse> {
  // 入力した投稿メッセージ
  String genre = '';
  String goods = '';
  String cost = '';
  String japanese = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  TextEditingController goodsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コースメニュー追加'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: '役割(例:main)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    genre = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '名前(日本語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    japanese = value;
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    String japanesemenu = japanese;
                    await translateMenu(japanesemenu, translated);
                    goodsController.text = translated.value;
                    goods = translated.value;
                  },
                  child: const Text('↑翻訳↓')),
              ValueListenableBuilder<String>(
                  valueListenable: translated,
                  builder: (context, value, child) {
                    return TextFormField(
                        decoration: const InputDecoration(labelText: '品名(英語)'),
                        // 複数行のテキスト入力
                        keyboardType: TextInputType.multiline,
                        // 最大3行
                        maxLines: 3,
                        controller: goodsController,
                        onChanged: (String value) {
                          setState(() {
                            goods = value;
                          });
                        });
                  }),
              TextFormField(
                decoration: const InputDecoration(labelText: '順番'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    order = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    // 投稿メッセージ用ドキュメント作成
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Course')
                        .collection(widget.name)
                        .doc() // ドキュメントID自動生成
                        .set({
                      'title': genre,
                      'discription': goods,
                      'ja': japanese,
                      'image': '',
                      'order': order
                    });
                    // 1つ前の画面に戻る
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => EngCoursePageEditState())));
                  },
                ),
              ),
              Container(
                height: 150,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AddPostnewCourse extends StatefulWidget {
  const AddPostnewCourse({super.key});

  @override
  _AddPostnewCourseState createState() => _AddPostnewCourseState();
}

class _AddPostnewCourseState extends State<AddPostnewCourse> {
  // 入力した投稿メッセージ
  String genre = '';
  String goods = '';
  String coursename = '';
  String japanese = '';
  String order = '';
  final ValueNotifier<String> translated = ValueNotifier<String>('');
  TextEditingController goodsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('コース追加'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'コース名(英語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    coursename = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '役割(例:main)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    genre = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '名前(日本語)'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    japanese = value;
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () async {
                    String japanesemenu = japanese;
                    await translateMenu(japanesemenu, translated);
                    goodsController.text = translated.value;
                    goods = translated.value;
                  },
                  child: const Text('↑翻訳↓')),
              ValueListenableBuilder<String>(
                  valueListenable: translated,
                  builder: (context, value, child) {
                    return TextFormField(
                        decoration: const InputDecoration(labelText: '品名(英語)'),
                        // 複数行のテキスト入力
                        keyboardType: TextInputType.multiline,
                        // 最大3行
                        maxLines: 3,
                        controller: goodsController,
                        onChanged: (String value) {
                          setState(() {
                            goods = value;
                          });
                        });
                  }),
              TextFormField(
                decoration: const InputDecoration(labelText: '順番'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    order = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    // 投稿メッセージ用ドキュメント作成
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Course')
                        .collection(coursename)
                        .doc() // ドキュメントID自動生成
                        .set({
                      'title': genre,
                      'discription': goods,
                      'ja': japanese,
                      'image': '',
                      'order': order
                    });
                    await FirebaseFirestore.instance
                        .collection('Eng')
                        .doc('Course')
                        .collection('titles')
                        .doc() // ドキュメントID自動生成
                        .set({'title': coursename, 'order': order});
                    // 1つ前の画面に戻る
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: ((context) => EngCoursePageEditState())));
                  },
                ),
              ),
              Container(
                height: 150,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Password extends StatefulWidget {
  const Password({super.key});

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
                          builder: (context) => EngPageEditState()),
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
