//SharedPreference Service
import 'package:shared_preferences/shared_preferences.dart';

class SPService {


  Future<String> getUserRole ()async{
    final prefs = await SharedPreferences.getInstance();
    String userRole = prefs.getString('role') ?? 'user';
    return userRole;
  }

  Future setUserType (String userRole)async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', userRole);
  }

  Future clearUserType ()async{
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}