import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login/calendar.dart';

//[메모] 이미 로그인한 유저의 비밀번호를 입력받아 재인증하는 코드 예시
/*
import 'package:firebase_auth/firebase_auth.dart';

void reauthenticateUser(String email, String password) async {
  User user = FirebaseAuth.instance.currentUser;
  AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);

  try {
    await user.reauthenticateWithCredential(credential);
    print('User successfully reauthenticated.');
  } catch (e) {
    print('Failed to reauthenticate user: ${e.toString()}');
  }
}
 */

class Server
{
  Random random = Random();   //랜덤값 생성 기능을 사용하기 위해 random 객체를 생성

  //서버 컬렉션의 info에 저장된 유저 정보를 불러오거나, 저장하기 위해 사용한다.
  List<String> USERNUM = ['user1', 'user2', 'user3', 'user4', 'user5', 'user6'];

  ///앱을 실행할 때 한 번 서버와 연결하는 초기 설정을 하기 위해 사용한다.
  Future<void> init() async
  {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  //=============================FirebaseAuth 기능==============================
  /// 로그인 기능, 아이디와 비밀번호 문자열을 받아서 로그인을 한다.
  /// 로그인 성공 시 true를, 실패 시 false를 반환한다.
  /// 로그인 실패 시 에러 코드와 함깨 그 원인을 토스트 알림으로 사용자에게 보여 준다.
  Future<bool> login(String id, String pw) async
  {
    if(id == "")
    {
      _alert("이메일이 입력되지 않았습니다.");
      return false;
    }
    if(pw == "")
    {
      _alert("비밀번호가 입력되지 않았습니다.");
      return false;
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: id, password: pw);
      return true;
    }
    on FirebaseAuthException catch (e) {
      _authErrorCodePrint(e.code);
      return false;
    }
  }

  ///회원가입 기능, 아이디와 비밀번호, 닉네임 문자열을 받아서 회원가입을 한다.
  ///회원가입 성공 시 true, 실패 시 false를 반환한다.
  Future<bool> createAccount(String id, String pw, String checkpw, String nickName) async
  {
    if(id == '') {
      _alert("이메일이 입력되지 않았습니다.");
      return false;
    }
    if(pw == '') {
      _alert("비밀번호가 입력되지 않았습니다.");
      return false;
    }
    if(pw != checkpw) {
      _alert("비밀번호와 비밀번호 확인란이 동일하지 않습니다.");
      return false;
    }
    if(nickName == '') {
      _alert("닉네임이 입력되지 않았습니다.");
      return false;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: id, password: pw);
      await login(id, pw);                                                                      //계정 생성 후 자동으로 로그인한다.
      await FirebaseAuth.instance.currentUser?.updateDisplayName(nickName);                     //유저가 저장한 닉네임을 서버에 저장한다.
    }
    on FirebaseAuthException catch (e) {
      _authErrorCodePrint(e.code);
      return false;
    }

    await FirebaseFirestore.instance.collection('user-room-info').doc(FirebaseAuth.instance.currentUser?.uid).set({
      //유저가 어떤 방에 들어가 있는지 저장하는 문서를 DB에 생성한다.
      'room': [],
    });
    _alert("회원가입이 완료되었습니다.");
    return true;
  }

  ///로그아웃 기능이다.
  Future<void> logout() async
  {
    await FirebaseAuth.instance.signOut();
  }

  ///계정 삭제 기능이다.
  ///유저가 모든 방에서 나간 후에 회원 탈퇴가 가능하다.
  ///현재 비밀번호를 매개변수로 입력받은 후 이를 확인하는 과정을 거친다.
  ///회원 탈퇴에 성공했을 시 true, 실패 시 false를 반환한다.
  Future<bool> deleteAccount(curPassword) async
  {
    if(curPassword == "")
    {
      _alert("비밀번호가 입력되지 않았습니다.");
      return false;
    }
    AuthCredential credential = EmailAuthProvider.credential(email: getUserEmail() ?? 'error', password: curPassword);
    try
    {
      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
    }
    on FirebaseAuthException catch (e)
    {
      _authErrorCodePrint(e.code);
      return false;
    }

    var userData = await FirebaseFirestore.instance.collection('user-room-info').doc(FirebaseAuth.instance.currentUser?.uid).get();
    if (userData.data()?['room'].length == 0)
    {
      await FirebaseFirestore.instance.collection('user-room-info').doc(FirebaseAuth.instance.currentUser?.uid).delete();
    }
    else {
      _alert("모든 방에서 나간 후 탈퇴해 주세요.");
      return false;
    }
    await FirebaseAuth.instance.currentUser?.delete();
    _alert("회원 탈퇴가 완료되었습니다.");
    return true;
  }

  ///현재 로그인한 유저의 닉네임은 변경합니다.
  ///닉네임을 입력하지 않을 시 오류 메시지와 함께 false를 반환한다.
  Future<bool> changeNickName(String newNickName) async
  {
    if(newNickName == "")
    {
      _alert("닉네임이 입력되지 않았습니다.");
      return false;
    }
    String? postNickName = FirebaseAuth.instance.currentUser?.displayName;
    await FirebaseAuth.instance.currentUser?.updateDisplayName(newNickName);
    var docMap = await FirebaseFirestore.instance.collection('user-room-info').doc(FirebaseAuth.instance.currentUser?.uid).get();
    var joinedRoom = docMap['room'];
    for (int i in joinedRoom)
    {
      var roomDoc = await FirebaseFirestore.instance.collection(i.toString()).doc('info').get();
      for(String name in USERNUM)
      {
        if(roomDoc["${name}Name"] == postNickName)
        {
          await FirebaseFirestore.instance.collection(i.toString()).doc('info').update({
            "${name}Name": newNickName
          });
          break;
        }
      }
    }
    _alert("닉네임이 변경되었습니다.");
    return true;
  }

  ///비밀번호 변경 기능이다. 현재 비밀번호와 새 비밀번호를 매개변수로 입력받는다.
  ///비밀번호 변경 성공 시 True, 실패 시 False를 반환한다.
  Future<bool> changePassword(String curPassword, String newPassword) async
  {
    AuthCredential credential = EmailAuthProvider.credential(email: getUserEmail() ?? 'error', password: curPassword);
    if(curPassword == "" || newPassword == "")
    {
      _alert("비밀번호가 입력되지 않았습니다.");
      return false;
    }
    if(curPassword == newPassword)
    {
      _alert("현재 비밀번호와 새로운 비밀번호가 동일합니다. 다른 비밀번호를 입력해 주세요.");
      return false;
    }
    try
    {
      await FirebaseAuth.instance.currentUser?.reauthenticateWithCredential(credential);
    }
    on FirebaseAuthException catch (e)
    {
      _authErrorCodePrint(e.code);
      return false;
    }

    try
    {
      await FirebaseAuth.instance.currentUser?.updatePassword(newPassword);
      _alert("비밀번호가 변경되었습니다.");
      return true;
    }
    on FirebaseAuthException catch(e)
    {
      _authErrorCodePrint(e.code);
      return false;
    }

  }

  ///현재 로그인한 유저의 이름(닉네임)을 반환한다.
  String? getUserName()
  {
    return FirebaseAuth.instance.currentUser?.displayName;
  }

  ///현재 로그인한 유저의 이메일을 반환한다.
  String? getUserEmail()
  {
    return FirebaseAuth.instance.currentUser?.email;
  }

  ///FirebaseAuth 기능을 사용하는 도중 에러가 발생했을 시, 에러 메시지와 에러 코드를 합한 문자열을 반환한다.
  void _authErrorCodePrint(String error)
  {
    String message;
    switch(error)
    {
      //에러 코드에 해당하는 메시지를 여기에 추가할 수 있다.
      case 'user-not-found':
        message = '등록된 이메일이 아닙니다. ($error)';
        break;
      case 'invalid-email':
      case 'invalid-email-verified':
        message = '잘못된 이메일입니다. ($error)';
        break;
      case 'wrong-password':
        message = '잘못된 비밀번호입니다. ($error)';
        break;
      case 'weak-password':
        message = '6자리 이상의 비밀번호를 입력해 주세요. ($error)';
        break;
      case 'email-already-in-use':
        message = '이미 사용중인 이메일입니다. ($error)';
        break;
      case 'invalid-display-name':
        message = '잘못된 닉네임입니다. ($error)';
        break;
      case 'missing-password':
        message = '비밀번호가 입력되지 않았습니다. ($error)';
        break;
      default:
        message = 'Unknown Error. ($error)';
        break;
    }
    _alert(message);
  }

  //=============================FirebaseFirestore 기능=========================

  ///현재 로그인한 유저가 어떤 방에 들어가 있는지 정보를 반환한다.
  ///받아오는 정보는 방의 이름과 방 번호이다.
  ///방의 정보는 Map 타입으로 저장되어 있으며, 'name'은 방 이름을 가져오고 'num'은 방 번호를 가져온다.
  ///그리고 이러한 방의 정보를 저장하는 Map은 List 타입으로 저장되어 있다.
  Future<List<Map<String, dynamic>>> getRoomInfo() async{
    var data = await FirebaseFirestore.instance.collection('user-room-info').doc(FirebaseAuth.instance.currentUser?.uid).get();
    var roomNumList = data.data()?['room'];
    List<Map<String, dynamic>> roomList = [];
    for (int num in roomNumList)
    {
      var roomNameData = await FirebaseFirestore.instance.collection(num.toString()).doc('info').get();
      String roomName = roomNameData.data()?['name'];
      roomList.add({
        'name': roomName,
        'num': num
      });
    }
    return roomList;
  }

  ///새로운 방을 만드는 기능이다.
  ///방 이름, 시작 날짜와 마지막 날짜를 입력받는다.
  ///무작위로 생성한 6자리의 방 번호를 반환한다.
  Future<int> createRoom(String roomName, DateTime startDate, DateTime endDate) async
  {
    int roomNum = 0;  //새로 만들 방 번호를 저장한다.
    bool docIsNull = true;

    //새로 만들 방 번호로 6자리의 숫자를 랜덤으로 정한다.
    //이미 존재하는 방일 숫자를 다시 지정한다.
    while(docIsNull)
    {
      roomNum = random.nextInt(1000000);
      if (roomNum < 100000) {
        //방 번호가 6자리 이상이 될 수 있도록 한다.
        continue;
      }
      var collectionRef = await FirebaseFirestore.instance.collection(roomNum.toString()).get();
      if (collectionRef.docs.isEmpty)
      {
        docIsNull = false;
      }
    }

    //방에 대한 새로운 컬렉션을 구성한다.
    // 이 컬렉션에는 방 이름, 최대 6명의 유저의 이름과 uid 값, 그리고 캘린더 이벤트가 들어간다.
    await FirebaseFirestore.instance.collection(roomNum.toString()).doc('info').set({
      'name': roomName,
      'startDate': startDate,
      'endDate': endDate,
      'user1': FirebaseAuth.instance.currentUser?.uid,
      'user2': "",
      'user3': "",
      'user4': "",
      'user5': "",
      'user6': "",
      'user1Name': FirebaseAuth.instance.currentUser?.displayName,
      'user2Name': "",
      'user3Name': "",
      'user4Name': "",
      'user5Name': "",
      'user6Name': ""

    });
    await FirebaseFirestore.instance.collection('user-room-info').doc(FirebaseAuth.instance.currentUser?.uid).update({
      //현재 로그인된 유저의 문서에 새로운 방 번호를 저장한다.
      'room': FieldValue.arrayUnion([roomNum]),
    });
    return roomNum;
  }

  ///캘린더 페이지에서 방 정보를 불러오기 위해 사용한다.
  ///방 번호를 매개변수로 입력받는다.
  ///이벤트 정보는 loadEvent를 통해 따로 불러와야 한다.
  Future<Map<String, dynamic>> loadRoom(int roomNum) async
  {
    var dbData = await FirebaseFirestore.instance.collection(roomNum.toString()).doc('info').get();
    int ownerNum = 0;

    //현재 로그인한 유저가 방에서 어떠한 고유 색상을 가지고 있는지 확인한다.
    for (String user in USERNUM) {
      if (dbData.data()?[user] == FirebaseAuth.instance.currentUser?.uid) {
        break;
      }
      ownerNum++;
    }
    return {
      'name': dbData.data()?['name'],
      'startDate': dbData.data()?['startDate'].toDate(),
      'endDate': dbData.data()?['endDate'].toDate(),
      'owner': ownerNum,
      'user1Name': dbData.data()?['user1Name'],
      'user2Name': dbData.data()?['user2Name'],
      'user3Name': dbData.data()?['user3Name'],
      'user4Name': dbData.data()?['user4Name'],
      'user5Name': dbData.data()?['user5Name'],
      'user6Name': dbData.data()?['user6Name']
    };
  }

  ///이미 존재하는 방에 들어가고자 할 때 사용한다.
  ///6자리의 방 번호를 입력받는다.
  ///방에 성공적으로 들어가면 true를, 들어가지 못하면 false를 반환하며 들어가지 못한 이유를 토스트메시지로 띄워 준다.
  Future<bool> inviteRoom(int roomNum) async
  {
    //유저가 입력한 번호를 가진 방이 존재하는지 확인한다.
    var exists = await FirebaseFirestore.instance.collection(roomNum.toString()).get();
    if(exists.docs.isEmpty){
      _alert("잘못된 방 번호입니다.");
      return false;
    }

    //유저가 입력한 방 번호를 가진 방의 정보를 서버에서 불러온다.
    var userData = await FirebaseFirestore.instance.collection(roomNum.toString()).doc('info').get();

    //이미 유저가 참여한 방인지 확인한다.
    for (String i in USERNUM)
    {
      if(userData.data()?[i] == FirebaseAuth.instance.currentUser?.uid)
      {
        _alert("이미 참여한 방입니다.");
        return false;
      }
    }

    //방에 남은 자리가 있는지 확인하고 자리가 있을 경우 빈 자리에 새로운 유저를 할당해 준다.
    for (String i in USERNUM)
    {
      if(userData.data()?[i] == '')
      {
        await FirebaseFirestore.instance.collection(roomNum.toString()).doc('info').update({
          i: FirebaseAuth.instance.currentUser?.uid,
          '${i}Name': FirebaseAuth.instance.currentUser?.displayName,
        });
        break;
      }
      else if(i == 'user6'){
        _alert("방에 남은 자리가 없습니다.");
        return false;
      }
    }

    //현재 로그인한 유저의 문서에 방 번호를 추가해 준다.
    await FirebaseFirestore.instance.collection('user-room-info').doc(FirebaseAuth.instance.currentUser?.uid).update({
      'room': FieldValue.arrayUnion([roomNum]),
    });

    return true;
  }

  ///방에서 나가는 기능이다.
  Future<void> exitRoom(int roomNum) async
  {
    int ownerNum = 0;
    //현재 유저 문서에서 방 번호를 삭제한다.
    await FirebaseFirestore.instance.collection('user-room-info').doc(FirebaseAuth.instance.currentUser?.uid).update({
      'room': FieldValue.arrayRemove([roomNum]),
    });

    //방 문서에서 현재 유저에 관련된 정보를 삭제한다.
    var roomData = await FirebaseFirestore.instance.collection(roomNum.toString()).doc('info').get();
    for (String i in USERNUM)
    {
      if (roomData.data()?[i] == FirebaseAuth.instance.currentUser?.uid){
        await FirebaseFirestore.instance.collection(roomNum.toString()).doc('info').update({
          i: "",
          '${i}Name': "",
        });
        break;
      }
      ownerNum++;
    }

    QuerySnapshot allData = await FirebaseFirestore.instance.collection(roomNum.toString()).get();

    //유저가 작성한 모든 이벤트들을 삭제한다.
    for (QueryDocumentSnapshot data in allData.docs)
    {
      if(data.id != 'info'){
        if (data.get('owner') == ownerNum){
          await FirebaseFirestore.instance.collection(roomNum.toString()).doc(data.id).delete();
        }
      }
    }

    //방에서 모든 유저가 나갔을 경우 방을 DB에서 삭제한다.
    roomData = await FirebaseFirestore.instance.collection(roomNum.toString()).doc('info').get();
    int emptyCount = 0;
    for (String i in USERNUM)
    {
      if(roomData.data()?[i] == "")
      {
        emptyCount++;
      }
      else {
        break;
      }
    }
    if (emptyCount == 6)
    {
      await FirebaseFirestore.instance.collection(roomNum.toString()).doc('info').delete();
    }
  }

  ///서버에 저장된 이벤트 정보들을 불러 온다.
  ///불러올 이벤트가 있는 방 정보를 매개변수로 받는다.
  Future<List<Event>> loadEvent(int roomNum) async
  {
    QuerySnapshot allData = await FirebaseFirestore.instance.collection(roomNum.toString()).get();
    List<Event> eventList = [];
    for (QueryDocumentSnapshot data in allData.docs)
    {
      if (data.id != 'info')
      {
        eventList.add(Event.forServer(
          data.get('desc'),
          data.get('startDate').toDate().toUtc(),
          data.get('endDate').toDate().toUtc(),
          data.get('owner'),
          data.id
        ));
      }
    }
    return eventList;
  }

  ///새로운 이벤트를 서버에 저장한다.
  ///이벤트를 저장할 방의 번호와 이벤트 정보를 매개변수로 받는다.
  ///서버에서 랜덤으로 생성한 이벤트 문서의 키 값을 반환한다.
  Future<String> createEvent(int roomNum, Event event) async
  {
    var db = FirebaseFirestore.instance.collection(roomNum.toString());
    var infoData = await db.doc('info').get();
    event.owner = 0;

    //현재 접속한 유저가 방에서 어떠한 고유 색상을 가지고 있는지 확인한다.
    for (String user in USERNUM) {
      if (infoData.data()?[user] == FirebaseAuth.instance.currentUser?.uid) {
        break;
      }
      event.owner++;
    }
    DocumentReference docRef = await db.add({
      'desc': event.desc,
      'owner': event.owner,
      'startDate': event.startDate,
      'endDate': event.endDate,
    });
    return docRef.id;
  }

  ///이미 존재하는 이벤트를 삭제하기 위해 사용한다.
  ///매개변수로 방 번호와 서버에서 생성한 이벤트 고유 코드를 입력받는다.
  Future<void> deleteEvent(int roomNum, String code) async
  {
    await FirebaseFirestore.instance.collection(roomNum.toString()).doc(code).delete();
  }

  ///이미 존재하는 이벤트를 수정하기 위해 사용한다.
  ///매개변수로 방 번호와 서버에서 생성한 이벤트 고유 코드, 그리고 수정할 이벤트 정보를 입력받는다.
  Future<void> editEvent(int roomNum, String code, Event event) async
  {
    await FirebaseFirestore.instance.collection(roomNum.toString()).doc(code).set({
      'desc': event.desc,
      'owner': event.owner,
      'startDate': event.startDate,
      'endDate': event.endDate,
    });
  }

  ///서버 알림 메시지를 토스트 메시지로 사용자에게 보여 주기 위해 사용한다.
  void _alert(String message)
  {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey,
      fontSize: 20,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG
    );
    debugPrint(message);
  }
}