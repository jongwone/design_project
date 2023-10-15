import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:design_project/chat/chat_list.dart';
import 'package:design_project/chat/chat_screen.dart';
import 'package:design_project/entity/profile.dart';
import 'package:design_project/profiles/profile_main.dart';
import 'package:design_project/resources/loading_indicator.dart';
import 'package:design_project/resources/resources.dart';
import 'package:design_project/boards/post_list/post_list_hub.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../main.dart';
import '../../page_alert.dart';
import '../write/writing_form.dart';

class BoardPageMainHub extends StatefulWidget {
  const BoardPageMainHub({super.key});

  @override
  State<StatefulWidget> createState() => _BoardPageMainHub();
}

EntityProfiles? myProfileEntity;
String? myUuid;

class _BoardPageMainHub extends State<BoardPageMainHub> {
  static List<Widget> _pages = <Widget>[BoardHomePage(), ChatRoomListScreen(), PageAlert(), PageProfile()];
  int _selectedIdx = 0;

  @override
  void dispose() {
    super.dispose();
    _pageController!.dispose();
  }

  PageController? _pageController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: BottomAppBar(
          child: Container(
            height: 50.7,
            child: Column(
              children: [
                Divider(
                  height: 0.7,
                  thickness: 0.7,
                  color: colorLightGrey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(
                      flex: 1,
                    ),
                    Expanded(
                        child: GestureDetector(
                            onTap: () => _onTappedItem(0),
                            behavior: HitTestBehavior.translucent,
                            child: SizedBox(
                                height: 50,
                                width: 50,
                                child:
                                Icon(Icons.home_outlined, color: _selectedIdx == 0 ? Colors.lime : Colors.black)))),
                    const Spacer(
                      flex: 1,
                    ),
                    Expanded(
                        child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _onTappedItem(1),
                            child: SizedBox(
                                height: 50,
                                width: 50,
                                child: Icon(Icons.mark_unread_chat_alt_outlined,
                                    color: _selectedIdx == 1 ? Colors.lime : Colors.black)))),
                    const Spacer(
                      flex: 3,
                    ),
                    Expanded(
                        child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _onTappedItem(2),
                            child: SizedBox(
                                height: 50,
                                width: 50,
                                child: Icon(Icons.notifications_active_outlined,
                                    color: _selectedIdx == 2 ? Colors.lime : Colors.black)))),
                    const Spacer(
                      flex: 1,
                    ),
                    Expanded(
                        child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _onTappedItem(3),
                            child: SizedBox(
                                height: 50,
                                width: 50,
                                child:
                                Icon(Icons.person_outline, color: _selectedIdx == 3 ? Colors.lime : Colors.black)))),
                    const Spacer(
                      flex: 1,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 바텀 앱바
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox(
          height: 67,
          width: 67,
          child: FittedBox(
            child: FloatingActionButton.small(
              heroTag: "fab1",
              backgroundColor: const Color(0xDD00CC88),
              onPressed: () async {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => BoardWritingPage()));
              },
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.draw_sharp,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
        // 글쓰기 플로팅 버튼
        body: SafeArea(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: _pages,
              onPageChanged: (page) {
                setState(() {
                  _selectedIdx = page;
                });
              },
            )),
      ),
        postManager.isLoading ? buildContainerLoading(135) : SizedBox()
      ],
    );
    ;
  }

  _onTappedItem(int idx) {
    setState(() {
      _pageController!.animateToPage(idx, duration: Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    });
  }
  
  Future<void> _myProfileLoad() async {
    myProfileEntity = EntityProfiles(FirebaseAuth.instance.currentUser!.uid);
    DocumentReference reference = FirebaseFirestore.instance.collection("UserProfile").doc(myUuid!);
    await reference.get().then((ds) async {
      await myProfileEntity!.loadProfile();
    });
    return;
  }

  @override
  void initState() {
    super.initState();

    _myProfileLoad().then((value) => setupGetMessages());

    if ( postManager.isLoading ) postManager.loadPages("").then((_) => setState(() {}));
    _pageController = PageController();

  }

  Future<void> setupGetMessages() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final String CHAT_ID = 'chat_id';
    if (message.data[CHAT_ID] != null) {
      if (message.data['is_group_chat'] != null) {
        int postId = int.parse(message.data[CHAT_ID]);
        Get.to(() => ChatScreen(postId: postId));
      } else {
        Get.to(() => ChatScreen(recvUserId: message.data[CHAT_ID],));
      }
    }
  }
}
