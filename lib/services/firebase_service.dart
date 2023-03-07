import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';

class FirebaseService {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<int> getTotalDocuments (String documentName) async {
    const String fieldName = 'count';
    final DocumentReference ref = firestore.collection('item_count').doc(documentName);
      DocumentSnapshot snap = await ref.get();
      debugPrint(snap.exists.toString());
      if(snap.exists == true){
        int itemCount = snap[fieldName] ?? 0;
        return itemCount;
      }
      else{
        await ref.set({
          fieldName : 0
        });
        return 0;
      }
  }

  Future increaseCount (String documentName) async {
    await getTotalDocuments(documentName)
    .then((int documentCount)async {
      await firestore.collection('item_count')
      .doc(documentName)
      .update({
        'count' : documentCount + 1
      });
    }).catchError((e){
      debugPrint('error: $e');
    });
  }



  Future decreaseCount (String documentName, int? itemSize) async {
    int size = itemSize ?? 1;
    await getTotalDocuments(documentName)
    .then((int documentCount)async {
      await firestore.collection('item_count')
      .doc(documentName)
      .update({
        'count' : documentCount - size
      });
    }).catchError((e){
      debugPrint('error: $e');
    });
  }



  Future deleteContent(String collectionName, String documentName) async {
    await firestore.collection(collectionName).doc(documentName).delete();
  }



  Future<List<Category>> getCategories() async {
    List<Category> data = [];
    await firestore.collection('categories').get().then((QuerySnapshot? snapshot){
      data = snapshot!.docs.map((e) => Category.fromFirestore(e)).toList();
    });
    return data;
  }

  // Future<List<Quiz>> getCategoryBasedQuizes(String catId) async {
  //   List<Quiz> data = [];
  //   await firestore.collection('quizes').where('parent_id', isEqualTo: catId).get().then((QuerySnapshot? snapshot){
  //     data = snapshot!.docs.map((e) => Quiz.fromFirestore(e)).toList();
  //   });
  //   return data;
  // }


}