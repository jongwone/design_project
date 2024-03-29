import 'dart:convert';

import 'package:design_project/boards/post.dart';
import 'package:design_project/boards/post_list/page_hub.dart';
import 'package:design_project/entity/profile.dart';
import 'package:design_project/resources/icon_set.dart';
import 'package:design_project/resources/loading_indicator.dart';
import 'package:design_project/resources/resources.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import '../../entity/entity_post.dart';
import '../../main.dart';
import '../../resources/geolocator.dart';

class BoardLocationPage extends StatefulWidget {
  const BoardLocationPage({super.key});

  @override
  State<StatefulWidget> createState() => _BoardLocationPage();
}

class _BoardLocationPage extends State<BoardLocationPage> with AutomaticKeepAliveClientMixin {
  int markerid = 2;

  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  String? nowPosition;
  List<Marker> _markers = [];
  EntityProfiles? profileEntity;

  double lat = 36.833068;
  double lng = 127.178419;
  CameraPosition temp = CameraPosition(target: LatLng(36.833068, 127.178419), zoom: 16.3);

  bool isMarkerSeleced = false;
  bool _buttonLoading = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: SizedBox(
          height: 60,
          width: 60,
          child: FittedBox(
            child: FloatingActionButton.small(
              splashColor: _buttonLoading ? Colors.transparent : colorLightGrey,
              heroTag: "fab3",
              elevation: 2,
              backgroundColor: colorGrey,
              onPressed: () {
                if (_buttonLoading) return;
                setState(() {
                  _buttonLoading = true;
                });
                _reloadMarkers();
                Future.delayed(Duration(milliseconds: 1000), () => setState(() => _buttonLoading = false));
              },
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: _buttonLoading
                  ? buildLoadingProgress(size: 10, color: Colors.white)
                  : const Icon(
                      Icons.refresh,
                      color: Color(0xFFFFFFFF),
                    ),
            ),
          ),
        ),
        body: postManager.isLoading
            ? buildLoadingProgress()
            : SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                            child: SizedBox(
                          child: GoogleMap(
                            mapToolbarEnabled: false,
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            compassEnabled: false,
                            buildingsEnabled: false,
                            gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())},
                            markers: Set.from(_markers),
                            mapType: MapType.normal,
                            initialCameraPosition: temp,
                            onMapCreated: (GoogleMapController controller) {
                              changeMapMode(controller);
                              if (!_controller.isCompleted) _controller.complete(controller);
                            },
                            onCameraMove: ((_position) => _updatePosition(_position)),
                            onCameraIdle: (() => _getPlaceAddress()),
                          ),
                        ))
                      ],
                    ),
                    SizedBox(
                      height: 50,
                      child: Center(
                        child: Text("${nowPosition ?? "불러오는 중"}"),
                      ),
                    ),
                  ],
                )));
  }

  void _updatePosition(CameraPosition _position) {
    lat = _position.target.latitude;
    lng = _position.target.longitude;
  }

  Widget _buildModalSheet(BuildContext context, int markerId) {
    EntityPost postEntity = postManager.list[markerId];
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 40,
            width: MediaQuery.of(context).size.width - 16,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => BoardPostPage(postId: postEntity.getPostId())));
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Color(0xD7EEEEEE),
                ),
                child: Center(
                    child: Stack(
                  children: [
                    Center(
                      child: Text(
                        "게시물 보기",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.black,
                          ),
                        )),
                  ],
                )),
              ),
            ),
          ),
          SizedBox(height: 5),
          Container(
              margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(padding: EdgeInsets.all(13), child: buildPostContext(postEntity, profileEntity!, context))),
        ],
      ),
    );
  }

  void _initMarkers() {
    for (int i = 0; i < postManager.list.length; i++) {
      _markers.add(
        Marker(
            markerId: MarkerId("$markerid"),
            position: postManager.list[i].getLLName().latLng,
            onTap: () async {
              try {
                hubLoadingStateSetter!(() {
                  hubLoadingContainerVisible = true;
                });
                profileEntity = EntityProfiles(postManager.list[i].getWriterId());
                await profileEntity!.loadProfile();
                hubLoadingStateSetter!(() {
                  hubLoadingContainerVisible = false;
                });
                showModalBottomSheet(
                    context: context, builder: (BuildContext context) => _buildModalSheet(context, i), backgroundColor: Colors.transparent);
              } catch (e) {
                showAlert("삭제됐거나 완료된 모임이에요!", context, colorError);
                await postManager.reloadPages("").then((value) => _reloadMarkers());
                hubLoadingStateSetter!(() {
                  hubLoadingContainerVisible = false;
                });
              }
            },
            draggable: true,
            icon: postManager.list[i].getMarker()),
      );
      markerid++;
    }
    _initLocations();
  }

  void _reloadMarkers() {
    _markers.clear();
    _loading();
  }

  Future<void> _getPlaceAddress() async {
    try {

      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=AIzaSyDBMRfh4ETwbEdvkQav0Rp4PWLHCMvTE7w&language=ko';
      final res = await http.get(Uri.parse(url));
      var value = jsonDecode(res.body)['results'][0]['address_components'];
      setState(() {
        nowPosition = "${value[3]['long_name']} ${value[2]['long_name']} ${value[1]['long_name']} ${value[0]['long_name']}";
      });
    } catch (e) {
      nowPosition = "불러오는 중";
    }
  }

  _initLocations() async {
    await determinePosition(LocationAccuracy.best).then((pos) {
      setState(() {
        try {
          LatLng newLatLng = LatLng(pos.latitude, pos.longitude);
          _controller.future.then((value) => value.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                // target: newLatLng
                target: LatLng(lat, lng), // 애뮬레이터 테스트시 상명대학교 초기화
                zoom: 16.3,
              ))));
          _getPlaceAddress();
          _markers.add(
            Marker(markerId: MarkerId('1'), position: newLatLng, onTap: () {}, draggable: true, icon: MyIcon.my_position),
          );
        } catch (e) {
          showAlert("위치 서비스를 활성화해주세요!", context, colorError);
        }
      });
    });
  }

  _loading() async {
    if (postManager.isLoading) {
      await Future.delayed(Duration(milliseconds: 1000)).then((value) => _loading());
      return;
    } else {
      _initMarkers();
    }
  }

  @override
  void initState() {
    super.initState();
    _loading();
  }

  @override
  bool get wantKeepAlive => true;
}

