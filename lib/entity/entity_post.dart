import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:design_project/entity/latlng.dart';
import 'package:design_project/resources/icon_set.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../boards/post_list/page_hub.dart';
import '../resources/resources.dart';
import '../main.dart';

class EntityPost {
  int _postId;
  var _writerId;
  var _writerNick;
  var _head;
  var _body;
  var _gender;
  var _maxPerson;
  var _currentPerson;
  var _minAge;
  var _maxAge;
  var _time;
  var _llName;
  var _category;
  var _viewCount;
  var _isVoluntary;

  var user;

  DocumentReference? _postDocRef;

  double _distance = 0.0;

  double get distance => _distance;

  set distance(double value) => _distance = value;

  set llName(value) => _llName = value;

  late String _upTime;

  bool _isLoaded = false;

  EntityPost(int this._postId, {bool? isProcessing}) {
    _postDocRef = FirebaseFirestore.instance.collection(isProcessing != null && isProcessing ? "ProcessingPost" : "Post").doc(_postId.toString());
  }

  int getTimeRemainInSeconds() {
    DateTime now = DateTime.now();
    return DateTime.parse(_time).difference(now).inSeconds;
  }

  Future<bool> applyToPost(String userId) async {
    bool requestSuccess = true;
    DocumentReference ref = FirebaseFirestore.instance.collection("Post").doc(_postId.toString());
    try {
      await FirebaseFirestore.instance.collection("Post").doc(_postId.toString()).get().then((DocumentSnapshot ds) async {
        List<Map<String, dynamic>> userList = (ds.get("user") as List).map((e) => e as Map<String, dynamic>).toList();
        if (userList.where((element) => element["id"] == userId).length != 0) {
          // 이미 신청을 했던 적이 있는 유저일 경우
          requestSuccess = false;
        } else {
          await ref.update({
            "user": FieldValue.arrayUnion([
              {"id": userId, "status": 0}
            ])
          });
        }
      });
    } catch (error) {
      if (error.toString().contains("field does not exist within the DocumentSnapshotPlatform")) {
        await ref.update({
          "user": FieldValue.arrayUnion([
            {"id": userId, "status": 0}
          ])
        });
      } else {
        print("[신청하기 오류] : $error");
      }
      requestSuccess = false;
    }
    return requestSuccess;
  }

  Future<void> acceptToPost(String userId) async {
    try {
      DocumentReference reference = FirebaseFirestore.instance.collection("Post").doc(_postId.toString());
      var postDoc = await reference.get();
      var users = postDoc.get("user") as List<dynamic>;
      var index = users.indexWhere((user) => user["id"] == userId);

      if (index != -1) {
        users[index]["status"] = 1;
        reference.update({
          "user": users,
        }).then((value) async {
          reference.update({"currentPerson": FieldValue.increment(1)});
        });
      }
    } catch (e) {
      print("수락 실패: $e");
    }
  }

  Future<void> rejectToPost(String userId) async {
    try {
      var postDoc = await _postDocRef!.get();
      var users = postDoc.get("user") as List<dynamic>;
      var index = users.indexWhere((user) => user["id"] == userId);

      if (index != -1) {
        users[index]["status"] = 2;
        _postDocRef!.update({
          "user": users,
        });
      }
    } catch (e) {
      print("거절 실패: $e");
    }
  }

  loadField(DocumentSnapshot ds) {
    _writerId = ds.get("writer_id");
    _head = ds.get("head");
    _body = ds.get("body");
    _gender = ds.get("gender");
    _maxPerson = ds.get("maxPerson");
    _currentPerson = ds.get("currentPerson");
    _writerNick = ds.get("writer_nick");
    _minAge = ds.get("minAge");
    _maxAge = ds.get("maxAge");
    _time = ds.get("time");
    _upTime = ds.get("upTime");
    _category = ds.get("category");
    _viewCount = ds.get("viewCount");
    _isVoluntary = ds.get("voluntary");
    user = ds.get("user");
    _llName = LLName(LatLng(ds.get("lat"), ds.get("lng")), ds.get("name"));
  }

  Future<void> removePost() async {
    DocumentReference reference = FirebaseFirestore.instance.collection("Post").doc(_postId.toString());
    var postDoc = await reference.get();
    var users = postDoc.get("user") as List<dynamic>;
    users.add({"status": 1, "id": myUuid});
    users.retainWhere((user) => user["status"] == 1);
    await Future.forEach(users, (user) async {
      try {
        DocumentReference userDoc = FirebaseFirestore.instance.collection("UserMeetings").doc(user["id"]);
        userDoc.update({
          "meetingPost": FieldValue.arrayRemove([_postId])
        });
      } catch (e) {
        print("Remove user meetingPost error : $e");
      }
    });
    await FirebaseFirestore.instance.collection("UserProfile").doc(myUuid).update({
      "post": FieldValue.arrayRemove([_postId])
    });
    await reference.delete();
    return;
  }

  Future<void> loadPost() async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot ds = await transaction.get(_postDocRef!);
      if (!ds.exists) {
        throw Exception("게시물을 찾을 수 없음");
      }
      try {
        await loadField(ds);
      } catch (e) {
        Map<String, dynamic> map = ds.data() as Map<String, dynamic>;
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          for (String key in postFieldDefault.keys) {
            if (!map.containsKey(key)) {
              await transaction.update(_postDocRef!, {key: postFieldDefault[key]});
            }
          }
        });
        await loadField(ds);
        print("오류 발생");
      }
    });
    return;
  }

  Future<void> postMoveToProcess() async {
    try {
      await Future.wait([
        FirebaseFirestore.instance.collection("Post").doc(_postId.toString()).delete(),
        addPost(
            writerId: _writerId,
            head: _head,
            body: _body,
            gender: _gender,
            maxPerson: _maxPerson,
            time: _time,
            llName: _llName,
            upTime: _upTime,
            category: _category,
            minAge: _minAge,
            maxAge: _maxAge,
            writerNick: _writerNick,
            isVoluntary: _isVoluntary,
            isProcessingPost: true,
            postId: _postId),
      ]);
      return;
    } catch (e) {
      print(e);
    }
  }

  bool isFull() {
    return _maxPerson != -1 && _currentPerson >= _maxPerson;
  }

  int getNewRequest() {
    List<Map<String, dynamic>> userList = (user as List).map((e) => e as Map<String, dynamic>).toList();
    return userList.where((element) => element["status"] == 0).length;
  }

  String getRequestState(String uuid) {
    List<Map<String, dynamic>> userList = (user as List).map((e) => e as Map<String, dynamic>).toList();
    userList.retainWhere((element) => element["id"] == uuid);
    if (userList.length == 0) {
      return "none";
    }
    Map<String, dynamic> userStatus = userList.first;
    return userStatus["status"] == 0
        ? "wait"
        : userStatus["status"] == 1
            ? "accept"
            : "reject";
  }

  addViewCount(String uuid) async {
    try {
      const PREFIX_COOL = "[PCD]_";
      int? coolDown = LocalStorage!.getInt("${PREFIX_COOL}$_postId");
      int standardTime = 1000 * 60 * 30; // milliseconds.
      if (coolDown == null || DateTime.now().millisecondsSinceEpoch - coolDown > standardTime) {
        _viewCount += 1;
        _postDocRef!.update({"viewCount": FieldValue.increment(1)});
        LocalStorage!.setInt("${PREFIX_COOL}$_postId", DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {}
  }

  // Getter, (ReadOnly)
  int getPostId() => _postId;

  String getWriterId() => _writerId;

  String getPostHead() => _head;

  String getPostBody() => _body;

  int getPostGender() => _gender;

  int getPostMaxPerson() => _maxPerson;

  int getPostCurrentPerson() => _currentPerson;

  String getWriterNick() => _writerNick;

  String getTime() => _time;

  String getCategory() => _category;

  String getUpTime() => _upTime;

  LLName getLLName() => _llName;

  int getMinAge() => _minAge;

  int getMaxAge() => _maxAge;

  bool isLoad() => _isLoaded;

  int getViewCount() => _viewCount;

  bool isVoluntary() => _isVoluntary;

  List<dynamic> getUser() => user;

  String getDateString(bool hour, bool minute) {
    if (_upTime.isEmpty) return "";
    DateTime upTime = DateTime.parse(_upTime);
    return "${upTime.month}월 ${upTime.day}일${hour ? " ${upTime.hour}시" : ""} ${minute ? " ${upTime.minute}분" : ""}";
  }

  List<String> getCompletedMembers() {
    List<String> memberList = [];
    List<Map<String, dynamic>> userList = (user as List).map((e) => e as Map<String, dynamic>).toList();
    userList.retainWhere((element) => element["status"] == 1);
    userList.forEach((element) => memberList.add(element["id"]));
    return memberList;
  }

  BitmapDescriptor getMarker() {
    switch (_category) {
      case "밥":
        return MyIcon.food;
      case "술":
        return MyIcon.drink;
      case "공예":
        return MyIcon.art;
      case "기타":
        return MyIcon.etc;
      case "게임":
        return MyIcon.game;
      case "운동":
        return MyIcon.gym;
      case "취미":
        return MyIcon.hobby;
      case "영화":
        return MyIcon.movie;
      case "음악":
        return MyIcon.music;
      case "쇼핑":
        return MyIcon.shop;
      case "공연":
        return MyIcon.show;
      case "공부":
        return MyIcon.study;
      case "여행":
        return MyIcon.trip;
      case "산책":
        return MyIcon.walk;
      default:
        return MyIcon.etc;
    }
  }
}

String getTimeBefore(String upTime) {
  DateTime currentTime = DateTime.now();
  currentTime = currentTime.toUtc(); // 한국 시간
  DateTime beforeTime = DateTime.parse(upTime);
  Duration timeGap = currentTime.difference(beforeTime);

  if (timeGap.inDays > 365) {
    return "${timeGap.inDays ~/ 365}년 전";
  } else if (timeGap.inDays >= 30) {
    return "${timeGap.inDays ~/ 30}개월 전";
  } else if (timeGap.inDays >= 1) {
    return timeGap.inDays == 1 ? "하루 전" : ("${timeGap.inDays}일 전");
  } else if (timeGap.inHours >= 1) {
    return "${timeGap.inHours}시간 전";
  } else if (timeGap.inMinutes >= 1) {
    return "${timeGap.inMinutes}분 전";
  } else {
    return "방금 전";
  }
}

Future<bool> addPost(
    {required String writerId,
    required String head,
    required String body,
    required int gender,
    required int maxPerson,
    required String time,
    required LLName llName,
    required String upTime,
    required String category,
    required int minAge,
    required int maxAge,
    required String writerNick,
    required bool isVoluntary,
    bool? isProcessingPost,
    int? postId}) async {
  try {
    bool processingPost = isProcessingPost != null && isProcessingPost && postId != null;
    int? new_post_id;
    if (!processingPost) {
      DocumentReference<Map<String, dynamic>> ref = await FirebaseFirestore.instance.collection("Post").doc("postData");
      await ref.get().then((DocumentSnapshot ds) {
        new_post_id = ds.get("last_id") + 1;
        if (new_post_id == -1) return false; // 업로드 실패
      });
      await ref.update({"last_id": new_post_id});
    } else {
      new_post_id = postId;
    }
    await FirebaseFirestore.instance.collection(processingPost ? "ProcessingPost" : "Post").doc(new_post_id.toString()).set({
      "post_id": new_post_id,
      "writer_id": writerId,
      "head": head,
      "body": body,
      "gender": gender,
      "maxPerson": maxPerson,
      "time": time,
      "lat": llName.latLng.latitude,
      "lng": llName.latLng.longitude,
      "name": llName.AddressName,
      "currentPerson": 1,
      "category": category,
      "minAge": minAge,
      "writer_nick": writerNick,
      "maxAge": maxAge,
      "upTime": upTime,
      "viewCount": 1,
      "user": FieldValue.arrayUnion([]),
      "voluntary": isVoluntary
    });
    return true;
  } catch (e) {
    return false;
  }
}
