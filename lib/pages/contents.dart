import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/configs/config.dart';
import 'package:admin/pages/edit_content.dart';
import 'package:admin/services/firebase_service.dart';
import 'package:admin/utils/content_preview.dart';
import 'package:admin/utils/dialog.dart';
import 'package:admin/utils/empty.dart';
import 'package:admin/utils/next_screen.dart';
import 'package:admin/utils/styles.dart';
import 'package:admin/utils/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContentsPage extends StatefulWidget {
  const ContentsPage({Key? key}) : super(key: key);

  @override
  State<ContentsPage> createState() => _ContentsPageState();
}

class _ContentsPageState extends State<ContentsPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  final List<DocumentSnapshot> _data = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool? _hasData;
  late bool _descending;
  late String _orderBy;
  String? _sortByText;

  @override
  void initState() {
    controller = ScrollController()..addListener(_scrollListener);
    super.initState();
    _isLoading = true;
    _sortByText = 'Newest First';
    _orderBy = 'timestamp';
    _descending = true;
    _getData();
  }

  Future<void> _getData() async {
    QuerySnapshot data;
    if (_lastVisible == null) {
      data = await firestore
          .collection('contents')
          .orderBy(_orderBy, descending: _descending)
          .limit(10)
          .get();
    } else {
      data = await firestore
          .collection('contents')
          .orderBy(_orderBy, descending: _descending)
          .startAfter([_lastVisible![_orderBy]])
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
    controller!.removeListener(_scrollListener);
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

  refreshData() {
    setState(() {
      _isLoading = true;
      _lastVisible = null;
      _data.clear();
    });

    _getData();
  }

  navigateToEditPage(context, snap) {
    NextScreen.nextScreenNormal(
        context,
        EditContent(
          imageUrl: snap['image url'],
          loves: snap['loves'],
          timestamp: snap['timestamp'],
          category: snap['category'],
        ));
  }

  handlePreview(context, imageUrl) async {
    await showContentPreview(context, imageUrl);
  }

  handleDelete(context, timestamp) {
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
              Text('Want to delete this item from the database?',
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
                      final bool hasAccess = userRole != null && userRole == 'admin';
                      if (!hasAccess) {
                        Navigator.pop(context);
                        openDialog(context, Config.testingDialog, '');
                      } else {
                        await FirebaseService().deleteContent('contents', timestamp)
                        .then((value) async => await FirebaseService().decreaseCount('contents_count', null).then((value){
                          refreshData();
                          Navigator.pop(context);
                          openDialog(context, 'Deleted Successfully', '');
                        }));
                        
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
                'All Images',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              sortingPopup()
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 5, bottom: 10),
            height: 3,
            width: 50,
            decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(15)),
          ),
          Expanded(
            child: _hasData == false
                ? emptyPage(Icons.content_paste,
                    'No data available.\nUpload contents first!')
                : RefreshIndicator(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 30, bottom: 20),
                      controller: controller,
                      itemCount: _data.length + 1,
                      itemBuilder: (_, int index) {
                        if (index < _data.length) {
                          final DocumentSnapshot d = _data[index];
                          return _buildContentList(d);
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

  Widget _buildContentList(d) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      padding: const EdgeInsets.all(15),
      height: 150,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: <Widget>[
          Container(
            height: 130,
            width: 130,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                    fit: BoxFit.cover, image: NetworkImage(d['image url']))),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 15,
              left: 15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  d['category'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: <Widget>[
                    Container(
                      height: 35,
                      width: 45,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.grey,
                          ),
                          Text(
                            d['loves'].toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                        child: Container(
                            height: 35,
                            width: 45,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.remove_red_eye,
                                size: 16, color: Colors.grey[800])),
                        onTap: () {
                          handlePreview(context, d['image url']);
                        }),
                    const SizedBox(width: 10),
                    InkWell(
                      child: Container(
                          height: 35,
                          width: 45,
                          decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.edit,
                              size: 16, color: Colors.grey[800])),
                      onTap: () => navigateToEditPage(context, d),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      child: Container(
                          height: 35,
                          width: 45,
                          decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.delete,
                              size: 16, color: Colors.grey[800])),
                      onTap: () {
                        handleDelete(context, d['timestamp']);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sortingPopup() {
    return PopupMenuButton(
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 20, right: 20),
        decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.sort_down,
              color: Colors.grey[800],
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              'Sort By - $_sortByText',
              style: TextStyle(
                  color: Colors.grey[900], fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return <PopupMenuItem>[
          const PopupMenuItem(
            value: 'new',
            child: Text('Newest First'),
          ),
          const PopupMenuItem(
            value: 'old',
            child: Text('Oldest First'),
          ),
          const PopupMenuItem(
            value: 'love',
            child: Text('Most Loved'),
          ),
        ];
      },
      onSelected: (dynamic value) {
        if (value == 'new') {
          setState(() {
            _sortByText = 'Newest First';
            _orderBy = 'timestamp';
            _descending = true;
          });
        } else if (value == 'old') {
          setState(() {
            _sortByText = 'Oldest First';
            _orderBy = 'timestamp';
            _descending = false;
          });
        } else if (value == 'love') {
          setState(() {
            _sortByText = 'Most Loved';
            _orderBy = 'loves';
            _descending = true;
          });
        }
        refreshData();
      },
    );
  }
}
