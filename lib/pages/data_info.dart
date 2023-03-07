import 'package:admin/services/firebase_service.dart';
import 'package:flutter/material.dart';

class DataInfoPage extends StatefulWidget {
  const DataInfoPage({Key? key}) : super(key: key);

  @override
  State<DataInfoPage> createState() => _DataInfoPageState();
}

class _DataInfoPageState extends State<DataInfoPage> {
  
  Future? users;
  Future? contents;
  Future? categories;

  initData() async {
    users = FirebaseService().getTotalDocuments('users_count');
    contents = FirebaseService().getTotalDocuments('contents_count');
    categories = FirebaseService().getTotalDocuments('categories_count');
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.only(left: w * 0.05, right: w * 0.05, top: w * 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FutureBuilder(
            future: users,
            builder: (BuildContext context, AsyncSnapshot snap) {
              if (!snap.hasData) return card('TOTAL USERS', 0);
              if (snap.hasError) return card('TOTAL USERS', 0);
              return card('TOTAL USERS', snap.data);
            },
          ),
          const SizedBox(
            width: 20,
          ),
          FutureBuilder(
            future: contents,
            builder: (BuildContext context, AsyncSnapshot snap) {
              if (!snap.hasData) return card('TOTAL CONTENTS', 0);
              if (snap.hasError) return card('TOTAL CONTENTS', 0);
              return card('TOTAL CONTENTS', snap.data);
            },
          ),
          const SizedBox(
            width: 20,
          ),
          FutureBuilder(
            future: categories,
            builder: (BuildContext context, AsyncSnapshot snap) {
              if (!snap.hasData) return card('TOTAL CATEGORIES', 0);
              if (snap.hasError) return card('TOTAL CATEGORIES', 0);
              return card('TOTAL CATEGORIES', snap.data);
            },
          ),
        ],
      ),
    );
  }

  Widget card(String title, int? number) {
    return Container(
      padding: const EdgeInsets.all(30),
      height: 180,
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.grey[300]!, blurRadius: 10, offset: const Offset(3, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5, bottom: 5),
            height: 2,
            width: 30,
            decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(15)),
          ),
          const SizedBox(
            height: 30,
          ),
          Row(
            children: <Widget>[
              const Icon(
                Icons.trending_up,
                size: 40,
                color: Colors.deepPurpleAccent,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                number.toString(),
                style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              )
            ],
          )
        ],
      ),
    );
  }
}
