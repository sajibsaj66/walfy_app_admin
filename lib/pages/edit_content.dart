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
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';

class EditContent extends StatefulWidget {
  final String? imageUrl, timestamp, category;
  final int? loves;

  const EditContent(
      {Key? key,
      required this.imageUrl,
      this.timestamp,
      this.loves,
      this.category})
      : super(key: key);

  @override
  State<EditContent> createState() => _EditContentState();
}

class _EditContentState extends State<EditContent> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  var formKey = GlobalKey<FormState>();
  var imageUrlCtrl = TextEditingController();
  var scaffoldKey = GlobalKey<ScaffoldState>();
  bool updateStarted = false;
  late Future _categories;
  late String _selectedCategory;
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
    final Reference storageReference = FirebaseStorage.instance.ref().child('images/${_selectedImagePath.hashCode}.png');
    final SettableMetadata metadata = SettableMetadata(contentType: 'image/png');
    final UploadTask uploadTask = storageReference.putData(imageData, metadata);
    await uploadTask.whenComplete(() async {
      imageUrl = await storageReference.getDownloadURL();
    });
    return imageUrl;
  }

  void handleUpdate() async {
    String? userRole = context.read<AdminBloc>().userRole;
    final bool hasAccess = userRole != null && userRole == 'admin';

    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (!hasAccess) {
        openDialog(context, Config.testingDialog, '');
      } else {
        if(_selectedImagePath != null){
            //local image
            setState(()=> updateStarted = true);
            await _uploadToFirebaseHosting().then((String? imageUrl){
              if(imageUrl != null){
                setState(()=> imageUrlCtrl.text = imageUrl);
                _updateProcedure(); 
              }else{
                setState(() {
                  _selectedImagePath = null;
                  imageUrlCtrl.clear();
                  updateStarted = false;
                });
              }
            });
          }else{
            //network image
            setState(()=> updateStarted = true);
            _updateProcedure();  
          }
      }
    }
  }

  Future _updateProcedure () async{
    await updateDatabase().then((value){
      setState(() => updateStarted = false);
      openDialog(context, 'Updated Successfully', '');
    });
  }



  void handlePreview() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      await showContentPreview(context, imageUrlCtrl.text);
    }
  }

  Future updateDatabase() async {
    final DocumentReference ref = firestore.collection('contents').doc(widget.timestamp);
    await ref.update({'image url': imageUrlCtrl.text, 'category': _selectedCategory});
  }

  @override
  void initState() {
    super.initState();
    imageUrlCtrl.text = widget.imageUrl!;
    _selectedCategory = widget.category!;
    _categories = FirebaseService().getCategories();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Center(
          child: AppBar(
            elevation: 1,
            title: const Text('Edit Content Data'),
            actions: <Widget>[
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.only(left: 10, right: 10),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextButton.icon(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.resolveWith((states) =>
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)))),
                  icon: const Icon(
                    LineIcons.eye,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Preview',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontSize: 16),
                  ),
                  onPressed: () {
                    handlePreview();
                  },
                ),
              ),
              const SizedBox(
                width: 20,
              )
            ],
          ),
        ),
      ),
      key: scaffoldKey,
      body: Container(
        margin: const EdgeInsets.only(left: 30, right: 30, top: 30),
        padding: EdgeInsets.only(
          left: w * 0.05,
          right: w * 0.20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.grey[300]!, blurRadius: 10, offset: const Offset(3, 3))
          ],
        ),
        child: Form(
            key: formKey,
            child: ListView(
              children: <Widget>[
                SizedBox(
                  height: h * 0.10,
                ),
                const Text(
                  'Edit Content',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5)),
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
                Container(
                    color: Colors.deepPurpleAccent,
                    height: 45,
                    child: updateStarted == true
                        ? const Center(
                            child: SizedBox(
                                height: 35,
                                width: 35,
                                child: CircularProgressIndicator()),
                          )
                        : TextButton(
                            child: const Text(
                              'Update Data',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              handleUpdate();
                            })),
                const SizedBox(
                  height: 200,
                ),
              ],
            )),
      ),
    );
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
