import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/configs/config.dart';
import 'package:admin/services/firebase_service.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/utils/empty.dart';
import 'package:admin/utils/styles.dart';
import 'package:admin/utils/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  final List<DocumentSnapshot> _snap = [];
  final List _data = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final String collectionName = 'categories';
  bool? _hasData;

  @override
  void initState() {
    controller = ScrollController()..addListener(_scrollListener);
    super.initState();
    _isLoading = true;
    _getData();
  }

  Future<void> _getData() async {
    QuerySnapshot data;
    if (_lastVisible == null) {
      data = await firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
    } else {
      data = await firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .startAfter([_lastVisible!['timestamp']])
          .limit(10)
          .get();
    }

    if (data.docs.isNotEmpty) {
      _lastVisible = data.docs[data.docs.length - 1];
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasData = true;
          _data.addAll(data.docs);
        });
      }
    } else {
      if (_lastVisible == null) {
        setState(() {
          _isLoading = false;
          _hasData = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasData = true;
        });
        // ignore: use_build_context_synchronously
        openToast(context, 'No more content available');
      }
    }
    return;
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_isLoading) {
      if (controller!.position.pixels == controller!.position.maxScrollExtent) {
        setState(() => _isLoading = true);
        _getData();
      }
    }
  }

  refreshData() async {
    setState(() {
      _data.clear();
      _snap.clear();
      _lastVisible = null;
    });
    await _getData();
  }

  handleDelete(context, timestamp1) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(50),
            elevation: 0,
            children: <Widget>[
              const Text('Delete?',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(
                height: 10,
              ),
              Text('Want to delete this category from the database?',
                  style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(
                height: 30,
              ),
              Center(
                  child: Row(
                children: <Widget>[
                  TextButton(
                    style: buttonStyle(Colors.redAccent),
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      String? userRole = context.read<AdminBloc>().userRole;
                      final bool hasAccess =
                          userRole != null && userRole == 'admin';
                      if (!hasAccess) {
                        Navigator.pop(context);
                        openDialog(context, Config.testingDialog, '');
                      } else {
                        await FirebaseService().deleteContent('categories', timestamp1)
                        .then((value) => FirebaseService().decreaseCount('categories_count', 1)).then((value){
                          Navigator.pop(context);
                          openDialog(context, 'Deleted Successfully', '');
                          clearTextfields();
                          refreshData();
                        });
                        
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    style: buttonStyle(Colors.deepPurpleAccent),
                    child: const Text(
                      'No',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.05,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Categories',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            Container(
              width: 300,
              height: 40,
              padding: const EdgeInsets.only(left: 15, right: 15),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(30)),
              child: TextButton.icon(
                  onPressed: () {
                    openUploadDialog();
                  },
                  icon: const Icon(LineIcons.plus),
                  label: const Text('Add Category')),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 5, bottom: 10),
          height: 3,
          width: 100,
          decoration: BoxDecoration(
              color: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(15)),
        ),
        Expanded(
          child: _hasData == false
              ? emptyPage(Icons.content_paste,
                  'No categories found.\nUpload categories first!')
              : RefreshIndicator(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 30, bottom: 20),
                    controller: controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _data.length + 1,
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(
                      height: 10,
                    ),
                    itemBuilder: (_, int index) {
                      if (index < _data.length) {
                        return dataList(_data[index]);
                      }
                      return Center(
                        child: Opacity(
                          opacity: _isLoading ? 1.0 : 0.0,
                          child: const SizedBox(
                              width: 32.0,
                              height: 32.0,
                              child: CircularProgressIndicator()),
                        ),
                      );
                    },
                  ),
                  onRefresh: () async {
                    await refreshData();
                  },
                ),
        ),
      ],
    );
  }

  Widget dataList(d) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          height: 150,
          width: MediaQuery.of(context).size.width * 0.80,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                  image: NetworkImage(d['thumbnail']), fit: BoxFit.cover)),
          child: Text(
            d['name'].toUpperCase(),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        Positioned(
          top: 50,
          right: 25,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  handleDelete(context, d['timestamp']);
                }),
          ),
        )
      ],
    );
  }

  var formKey = GlobalKey<FormState>();
  var nameCtrl = TextEditingController();
  var thumbnailCtrl = TextEditingController();
  String? timestamp;
  bool uploadStarted = false;
  String? _selectedImagePath;

  Future _pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
        thumbnailCtrl.text = image.path;
      });
    }
  }

  Future<String?> _uploadToFirebaseHosting() async {
    //return download link
    String? imageUrl;
    Uint8List imageData = await XFile(_selectedImagePath!).readAsBytes();
    final Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('category_thumbnails/${_selectedImagePath.hashCode}.png');
    final SettableMetadata metadata =
        SettableMetadata(contentType: 'image/png');
    final UploadTask uploadTask = storageReference.putData(imageData, metadata);
    await uploadTask.whenComplete(() async {
      imageUrl = await storageReference.getDownloadURL();
    });
    return imageUrl;
  }

  Future getDate() async {
    DateTime now = DateTime.now();
    String timestamp = DateFormat('yyyyMMddHHmmss').format(now);
    setState(() {
      timestamp = timestamp;
    });
  }

  Future saveToDatabase() async {
    final DocumentReference ref =
        firestore.collection('categories').doc(timestamp);
    await ref.set({
      'name': nameCtrl.text,
      'thumbnail': thumbnailCtrl.text,
      'timestamp': timestamp,
    });
  }

  clearTextfields() {
    nameCtrl.clear();
    thumbnailCtrl.clear();
  }

  openUploadDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(100),
            children: <Widget>[
              const Text(
                'Add Category to Database',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(
                height: 50,
              ),
              Form(
                  key: formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        decoration: inputDecoration(
                            'Enter Category Name', 'Category Name', nameCtrl),
                        controller: nameCtrl,
                        validator: (value) {
                          if (value!.isEmpty) return 'Category Name is empty';
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5)),
                          hintText: 'Enter Thumbnail Url or Select Image',
                          suffixIcon: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  thumbnailCtrl.clear();
                                  setState(() {
                                    _selectedImagePath = null;
                                  });
                                },
                              ),
                              IconButton(
                                tooltip: 'Select Image',
                                icon: const Icon(Icons.image_outlined),
                                onPressed: () => _pickImage(),
                              ),
                            ],
                          ),
                        ),
                        controller: thumbnailCtrl,
                        validator: (value) {
                          if (value!.isEmpty) return 'Url is empty';
                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 50,
                      ),
                      Center(
                          child: Row(
                        children: <Widget>[
                          TextButton(
                            style: buttonStyle(Colors.deepPurpleAccent),
                            child: const Text(
                              'Add',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () async {
                              handleUpload();
                            },
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            style: buttonStyle(Colors.redAccent),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ))
                    ],
                  ))
            ],
          );
        });
  }

  handleUpload() async {
    String? userRole = context.read<AdminBloc>().userRole;
    final bool hasAccess = userRole != null && userRole == 'admin';

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (!hasAccess) {
        Navigator.pop(context);
        openDialog(context, Config.testingDialog, '');
      } else {
        if (_selectedImagePath != null) {
          //local image
          setState(() => uploadStarted = true);
          await _uploadToFirebaseHosting().then((String? imageUrl) {
            if (imageUrl != null) {
              setState(() => thumbnailCtrl.text = imageUrl);
              _uploadProcedure();
            } else {
              setState(() {
                _selectedImagePath = null;
                thumbnailCtrl.clear();
                uploadStarted = false;
              });
            }
          });
        } else {
          //network image
          setState(() => uploadStarted = true);
          _uploadProcedure();
        }
      }
    }
  }

  _uploadProcedure() async {
    await getDate().then((value) => saveToDatabase()).then((value) =>
        FirebaseService().increaseCount('categories_count').then((value) {
          Navigator.pop(context);
          setState(() => uploadStarted = false);
          openDialog(context, 'Added Successfully', '');
          refreshData();
          clearTextfields();
        }));
  }
}
