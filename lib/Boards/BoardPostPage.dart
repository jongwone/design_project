import 'dart:async';
import 'package:design_project/Boards/List/BoardPostListPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../Entity/EntityPost.dart';
import '../Entity/EntityProfile.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:design_project/resources.dart';
import '../Boards/BoardProfilePage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoardPostPage extends StatefulWidget {
  final int postId;
  const BoardPostPage({super.key, required this.postId});
  @override
  State<StatefulWidget> createState() => _BoardPostPage();
}

class _BoardPostPage extends State<BoardPostPage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  bool _btnVisible = false;
  User? loggedUser; // loggedUser 변수 선언

  final List<Marker> _markers = [];
  bool isSameId = false;

  static const CameraPosition _kSeoul = CameraPosition(
    target: LatLng(36.833068, 127.178419),
    zoom: 17.4746,
  );

  var postId;
  EntityPost? postEntity;
  EntityProfiles? profileEntity;
  bool isLoaded = false;
  bool postTimeIsLoaded = false;
  var postTime;
  Size? mediaSize;
  String userID = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
    return !isLoaded
        ? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 5,
              color: Colors.black,
              backgroundColor: Colors.white,
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text(
                "게시글",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  height: 55,
                  width: 55,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.black,
                  ),
                ),
              ),
              backgroundColor: Colors.white,
              toolbarHeight: 40,
              elevation: 1,
            ),
            backgroundColor: Colors.white,
            body: Stack(children: [
              SingleChildScrollView(
                  child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 3 / 8,
                          child: GoogleMap(
                            markers: Set.from(_markers),
                            mapType: MapType.normal,
                            initialCameraPosition: CameraPosition(
                              target: postEntity!.getLLName().latLng,
                              zoom: 17.4746,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                            },
                          ),
                        ),
                        // 지도 표시 구간
                        const Padding(
                          padding: EdgeInsets.fromLTRB(0, 16, 0, 4),
                        ),
                        // 제목 및 카테고리
                        buildPostContext(postEntity!, profileEntity!, context),

                      ]),
                ),
              )),
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child:
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: InkWell(
                            onTap: () {
                              if(isSameId){
                                showModalBottomSheet(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        _buildModalSheet(context, postEntity!.getPostId()),
                                    backgroundColor: Colors.transparent);
                              } else{
                                postEntity!.applyToPost(userID);
                                showAlert("신청이 완료되었습니다!", context, Colors.grey);
                              }
                            },
                          child: SizedBox(
                            height: 50,
                            width: MediaQuery.of(context).size.width - 40,
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: colorSuccess,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey,
                                          offset: Offset(1, 1),
                                          blurRadius: 4.5)
                                    ]),
                                child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.emoji_people,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          isSameId ? "신청 현황 보기" : "  신청하기 - ${postEntity!.getPostMaxPerson() == -1 ? "현재 ${postEntity!.getPostCurrentPerson()}명" :
                                          "(${postEntity!.getPostCurrentPerson()} / ${postEntity!.getPostMaxPerson()})"}",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    )
                                ),
                              ),
                          )),
                    ),
                  ),
                ),
                ]));
  }

  @override
  void initState() {
    super.initState();
    postId = widget.postId;
    postEntity = EntityPost(postId);
    postEntity!.loadPost().then((value) {
      profileEntity = EntityProfiles(postEntity!.getWriterId());
      profileEntity!.loadProfile().then((value){
        _markers.add(Marker(
            markerId: const MarkerId('1'),
            draggable: true,
            onTap: () => print("marker tap"),
            position: postEntity!.getLLName().latLng));
        loadPostTime();
        checkWriterId(postEntity!.getWriterId());
      });
    });
  }


  loadPostTime() {
    String ptime = getTimeBefore(postEntity!.getUpTime());
    postTime = ptime;
    setState(() {
      postTimeIsLoaded = true;
      isLoaded = true;
    });
  }

  checkWriterId(writerId) {
    if(writerId != Null) {
      if (FirebaseAuth.instance.currentUser!.uid == writerId)
        isSameId = true;
    }
  }

  Widget _buildModalSheet(BuildContext context, int postId) {
    return SingleChildScrollView(
      child: Container(
              margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                  padding: EdgeInsets.all(13),
                  child: buildPostMember(profileEntity!, context))),
    );
  }
}

Column buildPostMember(EntityProfiles profiles, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      drawProfile(profiles, context), // 프로필
      const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Divider(
          thickness: 1,
        ),
      ),
      drawProfile(profiles, context),
      const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Divider(
          thickness: 1,
        ),
      ),
      drawProfile(profiles, context),
    ],
  );
}

Column buildPostContext(EntityPost post, EntityProfiles profiles, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(post.getPostHead(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFBFBFBF)),
                child: const Padding(
                  padding:
                      EdgeInsets.only(right: 5, left: 5, top: 3, bottom: 3),
                  child: Text("20~24세",
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 1, right: 1),
              ),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFBFBFBF)),
                child: const Padding(
                  padding:
                      EdgeInsets.only(right: 5, left: 5, top: 3, bottom: 3),
                  child: Text("남자만",
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 1, right: 1),
              ),
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFBFBFBF)),
                child: const Padding(
                  padding:
                      EdgeInsets.only(right: 5, left: 5, top: 3, bottom: 3),
                  child: Text("영화",
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 1, right: 1),
              ),
            ],
          )
        ],
      ),

      const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Divider(
          thickness: 1,
        ),
      ),
      drawProfile(profiles, context),
      // 프로필
      const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Divider(
          thickness: 1,
        ),
      ),
      Text(post.getPostBody(), style: const TextStyle(fontSize: 15)),
      // 내용
      const Padding(
        padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
      ),
      Text("조회수 ${post.viewCount}, ${getTimeBefore(post.getUpTime())}",
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF888888))),
      // 조회수 및 게시글 시간
      const Padding(
        padding: EdgeInsets.fromLTRB(0, 12, 0, 0),
        child: Divider(
          thickness: 1,
        ),
      ),
      // const Text("모임 장소 및 시간",
      //     style: TextStyle(
      //         fontWeight: FontWeight.bold, fontSize: 16)),
      const Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
      ),
      Text("시간 : ${getMeetTimeText(post)}"),
      Text("장소 : ${post.getLLName().AddressName}"),
      SizedBox(
        height: 20,
      ),
    ],
  );
}

Widget drawProfile(EntityProfiles profileEntity, BuildContext context) {
  final color = getColorForScore(profileEntity.mannerGroup);
  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => BoardProfilePage(profileId: profileEntity.profileId)));
      print(profileEntity.profileId);
    },
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              profileEntity.profileImagePath,
              width: 45,
              height: 45,
            ),
            const Padding(padding: EdgeInsets.only(left: 10)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${profileEntity.name}",
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Padding(padding: EdgeInsets.only(top: 4)),
                Text(
                  "${profileEntity.major}, ${profileEntity.age}세",
                  style:
                      const TextStyle(color: Color(0xFF777777), fontSize: 13),
                )
              ],
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 7, top: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "매너 지수 ${profileEntity.mannerGroup}점",
                style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 2),
              ),
              SizedBox(
                  height: 6,
                  width: 105,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: profileEntity.mannerGroup / 100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      backgroundColor: color.withOpacity(0.3),
                    ),
                  ))
            ],
          ),
        )
      ],
    ),
  );
}
