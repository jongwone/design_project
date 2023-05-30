import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:design_project/Entity/EntityLatLng.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EntityProfiles {
  var profileId;
  var name;
  var age;
  var major; // 학과
  late String profileImagePath;
  var mannerGroup; // 소모임 매너지수

  var nickname;
  List<String>? hobby;
  var mbti;
  var commute;
  var commuteIndex;
  var birth;
  var gender;
  var textInfo;
  var post;

  bool isLoaded = false;

  EntityProfiles(var this.profileId) {
    print("프로필 연결됨");
  }

  Future<void> loadProfile() async {
    // 포스팅 로드
    print(profileId);
    await FirebaseFirestore.instance.collection("UserProfile").doc(
        profileId.toString()).get().then((ds) {
      birth = ds.get("birth");
      commute = ds.get("commute");
      commuteIndex = ds.get("commuteIndex");
      // gender = ds.get("gender");
      // hobby = ds.get("hobby");
      // _hobbyIndex = ds.get("hobbyIndex");
      mbti = ds.get("mbti");
      //_mbtiIndex = ds.get("mbtiIndex");
      name = ds.get("nickName");
      major = "소프트웨어학과";
      textInfo = ds.get("textInfo");
      mannerGroup = ds.get("mannerGroup");
      post = ds.get("post");
      print(post);
    });
    isLoaded = true;
    print("프로필 정보 불러오기 성공");
  }

  String getProfileId() => profileId;

  makeTestingProfile() {
    name = "홍길동";
    age = 23;
    major = "소프트웨어학과";
    profileImagePath = "assets/images/userImage.png";
    mannerGroup = 80;

    nickname = "테스트";
    hobby = ["술", "영화"];
    birth = "1999-10-19";
    commute = "통학";
  }
}
