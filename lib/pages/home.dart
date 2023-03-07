import 'package:admin/blocs/admin_bloc.dart';
import 'package:admin/customized_packages/vertical_tab.dart';
import 'package:admin/configs/config.dart';
import 'package:admin/pages/change_password.dart';
import 'package:admin/pages/sign_in.dart';
import 'package:admin/services/auth_service.dart';
import 'package:admin/utils/cover_widget.dart';
import 'package:admin/utils/next_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'categories.dart';
import 'contents.dart';
import 'data_info.dart';
import 'upload_item.dart';
import 'users.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _pageIndex = 0;
  final List<String> titles = [
    'Data Statistics',
    'All Items',
    'Upload Item',
    'Categories',
    'Admin',
    'Users'
  ];

  final List icons = [
    LineIcons.pieChart,
    LineIcons.list,
    LineIcons.arrowCircleUp,
    CupertinoIcons.grid,
    LineIcons.userSecret,
    LineIcons.users
  ];

  Future handleLogOut() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    await AuthService().adminLogout().then((value)async{
      await sp.clear().then((value) {
      NextScreen().nextScreenCloseOthers(context, const SignInPage());
    });
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar() as PreferredSizeWidget?,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: Colors.white,
                child: VerticalTabs(
                  tabBackgroundColor: Colors.white,
                  backgroundColor: Colors.grey[200],
                  tabsElevation: 0,
                  tabsShadowColor: Colors.grey[500],
                  tabsWidth: 200,
                  indicatorColor: Colors.deepPurpleAccent,
                  selectedTabBackgroundColor:
                      Colors.deepPurpleAccent.withOpacity(0.1),
                  indicatorWidth: 5,
                  disabledChangePageFromContentView: true,
                  initialIndex: _pageIndex,
                  changePageDuration: const Duration(microseconds: 1),
                  tabs: <Tab>[
                    tab(titles[0], icons[0]) as Tab,
                    tab(titles[1], icons[1]) as Tab,
                    tab(titles[2], icons[2]) as Tab,
                    tab(titles[3], icons[3]) as Tab,
                    tab(titles[4], icons[4]) as Tab,
                    tab(titles[5], icons[5]) as Tab
                  ],
                  contents: const <Widget>[
                    DataInfoPage(),
                    CoverWidget(widget: ContentsPage()),
                    CoverWidget(widget: UploadItem()),
                    CoverWidget(widget: CategoryPage()),
                    CoverWidget(widget: ChangePassword()),
                    CoverWidget(widget: UsersPage())
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tab(title, icon) {
    return Tab(
        child: Container(
      padding: const EdgeInsets.only(
        left: 10,
      ),
      height: 45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 20,
            color: Colors.grey[800],
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            title,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey[900],
                fontWeight: FontWeight.w700),
          )
        ],
      ),
    ));
  }

  Widget _appBar (){
    String? userRole = context.read<AdminBloc>().userRole;
    final bool hasAccess = userRole != null && userRole == 'admin';

    return PreferredSize(
    preferredSize: const Size.fromHeight(80),
    child: Container(
      height: 60,
      padding: const EdgeInsets.only(left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 10,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: Row(
        children: <Widget>[
          RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.deepPurpleAccent
            ),
            text: Config.appName,
            children: <TextSpan>[
              TextSpan(
                text: ' - Admin Panel',
                style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w400, color: Colors.grey[800]
                )
              )
            ])),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.only(left: 10, right: 10,),
            decoration: BoxDecoration(
            color: Colors.deepPurpleAccent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.grey[400]!,
                blurRadius: 10,
                offset: const Offset(2, 2)
              )
            ]

            ),
            child: TextButton.icon(
              style: ButtonStyle(
                padding: MaterialStateProperty.resolveWith((states) => const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15)),
                
              ),
              icon: const Icon(LineIcons.alternateSignOut, color: Colors.white, size: 20,),
              label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w400, color: Colors.white, fontSize: 16),),
              onPressed: () => handleLogOut(), 
              ),
          ),
          const SizedBox(width: 5,),
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
            border: Border.all(color: Colors.deepPurpleAccent),
            borderRadius: BorderRadius.circular(20),
            

            ),
            child: TextButton.icon(
              style: ButtonStyle(
                padding: MaterialStateProperty.resolveWith((states) => const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 15)),
              ),
              icon: Icon(LineIcons.user, color: Colors.grey[800], size: 20,),
              label: Text(
                hasAccess ? 'Signed as Admin' : 'Signed as Tester', 
                style: const TextStyle(fontWeight: FontWeight.w400, color: Colors.deepPurpleAccent, fontSize: 16),),
              // ignore: avoid_returning_null_for_void
              onPressed: () => null, 
              ),
          ),
          const SizedBox(width: 20,)
          
        ],
      ),
    )
      
  );
  }
}
