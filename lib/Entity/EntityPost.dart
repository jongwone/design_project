import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:design_project/Entity/EntityLatLng.dart';
import 'package:design_project/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  var user;

  DocumentReference? _postDocRef;

  double _distance = 0.0;

  double get distance => _distance;

  set distance(double value) => _distance = value;

  set llName(value) => _llName = value;

  late String _upTime;

  bool _isLoaded = false;

  EntityPost(int this._postId) {
    _postDocRef = FirebaseFirestore.instance.collection("Post").doc(_postId.toString());
  }

  Future<bool> applyToPost(String userId) async {
    bool requestSuccess = true;
    DocumentReference ref = FirebaseFirestore.instance.collection("Post").doc(_postId.toString());
    try {
      await FirebaseFirestore.instance
          .collection("Post")
          .doc(_postId.toString())
          .get()
          .then((DocumentSnapshot ds) async {
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

  Future<void> loadPost() async {
    _isLoaded = true;
    await FirebaseFirestore.instance.collection("Post").doc(_postId.toString()).get().then((ds) {
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
      user = ds.get("user");
      _llName = LLName(LatLng(ds.get("lat"), ds.get("lng")), ds.get("name"));
    });
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
    const PREFIX_COOL = "[PCD]_";
    int? coolDown = LocalStorage!.getInt("${PREFIX_COOL}$_postId");
    int standardTime = 1000 * 60 * 30; // milliseconds.
    if (coolDown == null || DateTime.now().millisecondsSinceEpoch - coolDown > standardTime) {
      _viewCount += 1;
      _postDocRef!.update({"viewCount": FieldValue.increment(1)});
      LocalStorage!.setInt("${PREFIX_COOL}$_postId", DateTime.now().millisecondsSinceEpoch);
    } else {
      print("[Debug] ${1800 - ((DateTime.now().millisecondsSinceEpoch - coolDown) / 1000)}초 뒤에 조회수 증가 가능.");
    }
  }

  makeTestingPost() {
    _postId = 1;
    _writerId = "jongwon1019";
    _head = "제목 테스트 - 영화 볼 사람?!";
    _minAge = -1;
    _maxAge = 25;
    _body = "내용입니다. \n다른 이유는 없습니다.";
    _gender = 2;
    _maxPerson = 5;
    _currentPerson = 2;
    _category = "기타";
    _time = "2023-04-22 11:10:05";
    _llName = LLName(LatLng(36.833068, 127.178419), "천안시 동남구 안서동 300");
    _upTime = "2023-04-16 13:27:00";
    _viewCount = "1342";
    _isLoaded = true;
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

  int getViewCount() => _viewCount;

  bool isLoad() => _isLoaded;

  List<dynamic> getUser() => user;

  String getDateString(bool hour, bool minute) {
    if (_upTime.isEmpty) return "";
    DateTime upTime = DateTime.parse(_upTime);
    return "${upTime.month}월 ${upTime.day}일${hour ? " ${upTime.hour}시" : ""} ${minute ? " ${upTime.minute}분" : ""}";
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

Future<bool> addPost(String head, String body, int gender, int maxPerson, String time, LLName llName, String upTime,
    String category, int minAge, int maxAge, String writerNick) async {
  try {
    int? new_post_id;
    DocumentReference<Map<String, dynamic>> ref = await FirebaseFirestore.instance.collection("Post").doc("postData");
    await ref.get().then((DocumentSnapshot ds) {
      new_post_id = ds.get("last_id") + 1;
      if (new_post_id == -1) return false; // 업로드 실패
    });
    await ref.update({"last_id": new_post_id});
    String uuid = await FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection("Post").doc(new_post_id.toString()).set({
      "post_id": new_post_id,
      "writer_id": uuid,
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
    });
    return true;
  } catch (e) {
    return false;
  }
}
