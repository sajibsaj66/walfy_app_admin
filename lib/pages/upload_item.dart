import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/configs/config.dart';
import 'package:admin/services/firebase_service.dart';
import 'package:admin/utils/content_preview.dart';
import 'package:admin/utils/dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';

class UploadItem extends StatefulWidget {
  const UploadItem({Key? key}) : super(key: key);

  @override
  State<UploadItem> createState() => _UploadItemState();
}

class _UploadItemState extends State<UploadItem> {
  var formKey = GlobalKey<FormState>();
  var imageUrlCtrl = TextEditingController();
  var scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String? date;
  int? loves;
  String? _selectedCategory;
  bool uploadStarted = false;
  late Future _categories;
  String? _selectedImagePath;

  Future _pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(
        source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
        imageUrlCtrl.text = image.path;
      });
    }
  }

  Future<String?> _uploadToFirebaseHosting() async {
    //return download link
    String? imageUrl;
    Uint8List imageData = await XFile(_selectedImagePath!).readAsBytes();
    final Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('images/${_selectedImagePath.hashCode}.png');
    final SettableMetadata metadata =
        SettableMetadata(contentType: 'image/png');
    final UploadTask uploadTask = storageReference.putData(imageData, metadata);
    await uploadTask.whenComplete(() async {
      imageUrl = await storageReference.getDownloadURL();
    });
    return imageUrl;
  }

  @override
  void initState() {
    _categories = FirebaseService().getCategories();
    super.initState();
  }

  void handleSubmit() async {
    String? userRole = context.read<AdminBloc>().userRole;
    final bool hasAccess = userRole != null && userRole == 'admin';

    if (_selectedCategory == null) {
      openDialog(context, 'Select Category First', '');
    } else {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();
        if (!hasAccess) {
          openDialog(context, Config.testingDialog, '');
        } else {
          if (_selectedImagePath != null) {
            //local image
            setState(() => uploadStarted = true);
            await _uploadToFirebaseHosting().then((String? imageUrl) {
              if (imageUrl != null) {
                setState(() => imageUrlCtrl.text = imageUrl);
                _uploadProcedure();
              } else {
                setState(() {
                  _selectedImagePath = null;
                  imageUrlCtrl.clear();
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
  }

  Future _uploadProcedure() async {
    await saveToDatabase().then((value) =>
        FirebaseService().increaseCount('contents_count').then((value) {
          setState(() => uploadStarted = false);
          openDialog(context, 'Uploaded Successfully', '');
          clearTextFeilds();
        }));
  }


  Future saveToDatabase() async {
    DateTime now = DateTime.now();
    final String timestamp = DateFormat('yyyyMMddHHmmss').format(now);
    final DocumentReference ref = firestore.collection('contents').doc(timestamp);
    await ref.set({
      'image url': imageUrlCtrl.text,
      'loves': 0,
      'category': _selectedCategory,
      'timestamp': timestamp,
    });
  }

  clearTextFeilds() {
    imageUrlCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  handlePreview() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      await showContentPreview(context, imageUrlCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            const Text(
              'Content Details',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            Container(
              margin: const EdgeInsets.only(top: 5, bottom: 10),
              height: 3,
              width: 150,
              decoration: BoxDecoration(
                  color: Colors.indigoAccent,
                  borderRadius: BorderRadius.circular(15)),
            ),
            const SizedBox(
              height: 40,
            ),
            FutureBuilder(
              future: _categories,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  List<Category> categories = snapshot.data;
                  return categoryDropdown(categories);
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
            const SizedBox(
              height: 25,
            ),
            TextFormField(
              controller: imageUrlCtrl,
              validator: (value) {
                if (value!.isEmpty) return 'Value is empty';
                return null;
              },
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                hintText: 'Enter Image Url or Select Image',
                suffixIcon: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        imageUrlCtrl.clear();
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
            ),
            const SizedBox(
              height: 100,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                    icon: const Icon(
                      Icons.remove_red_eye,
                      size: 25,
                      color: Colors.blueAccent,
                    ),
                    label: const Text(
                      'Preview',
                      style: TextStyle(
                          fontWeight: FontWeight.w400, color: Colors.black),
                    ),
                    onPressed: () {
                      handlePreview();
                    })
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
                color: Colors.deepPurpleAccent,
                height: 45,
                width: double.infinity,
                child: uploadStarted == true
                    ? const Center(
                        child: SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator()),
                      )
                    : TextButton(
                        child: const Text(
                          'Upload Content',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          handleSubmit();
                        })),
            const SizedBox(
              height: 200,
            ),
          ],
        ));
  }

  Widget categoryDropdown(List<Category> categories) {
    return Container(
        height: 50,
        padding: const EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(30)),
        child: DropdownButtonFormField(
            itemHeight: 50,
            decoration: const InputDecoration(border: InputBorder.none),
            onChanged: (dynamic value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            value: _selectedCategory,
            hint: const Text('Select Category'),
            items: categories.map((f) {
              return DropdownMenuItem(
                value: f.name,
                child: Text(f.name!),
              );
            }).toList()));
  }
}
