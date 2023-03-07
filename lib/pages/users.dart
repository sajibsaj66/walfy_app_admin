import 'package:admin/utils/empty.dart';
import 'package:admin/utils/toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../blocs/admin_bloc.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {


  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ScrollController? controller;
  DocumentSnapshot? _lastVisible;
  late bool _isLoading;
  final List<DocumentSnapshot> _data = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();
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
          .collection('users')
          .orderBy('timestamp', descending: true)
          .limit(15)
          .get();
    } else {
      data = await firestore
          .collection('users')
          .orderBy('timestamp', descending: true)
          .startAfter([_lastVisible!['timestamp']])
          .limit(15)
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
      if(_lastVisible == null){
        setState(() {
          _isLoading = false;
          _hasData = false; 
        }); 
      }else{
        setState(() {
          _isLoading = false; 
          _hasData = true; 
        });
      // ignore: use_build_context_synchronously
      openToast(context, 'No more content available'); }
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

  @override
  Widget build(BuildContext context) {

    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            const Text(
              'All Users',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
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
              ? emptyPage(Icons.content_paste, 'No users found!')
              
              : RefreshIndicator(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 30),
                  controller: controller,
                  itemCount: _data.length + 1,
                  itemBuilder: (_, int index) {
                    if (index < _data.length) {
                      final DocumentSnapshot d = _data[index];
                      return _buildUserList(d);
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
                  setState(() {
                    _data.clear();
                    _lastVisible = null;
                  });
                  await _getData();
                },
              ),
            ),
          ],
        );
  }

  Widget _buildUserList(d) {
    String? userRole = context.read<AdminBloc>().userRole;
    final bool hasAccess = userRole != null && userRole == 'admin';

    const String dimageUrl = 'https://www.seekpng.com/png/detail/115-1150053_avatar-png-transparent-png-royalty-free-default-user.png';
    const String dEmail = '******@mail.com';
    final String dUid = '${d['uid'].toString().substring(0, 15)}**************';

    String? imageUrl = d['image url'] ?? dimageUrl;
    String? email = hasAccess ? d['email'] : dEmail;
    String? uid = hasAccess ? d['uid'] : dUid;
    String name = d['name'] ?? '';

    return ListTile(
      leading: imageUrl == null || imageUrl.isEmpty 
      ? const CircleAvatar()
      : CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(imageUrl)
      ),
      subtitle: SelectableText('$email \nUID: $uid'),
      title: SelectableText(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      isThreeLine: true,
      trailing: InkWell(
          child: CircleAvatar(
          backgroundColor: Colors.grey[200],
          radius: 18,
          child: const Icon(Icons.copy, size: 18,),
        ),
        onTap: (){
          Clipboard.setData(ClipboardData(text: uid));
          openToast(context, "Copied UID to clipboard");
        },
      ),
    );
  }

  
}
