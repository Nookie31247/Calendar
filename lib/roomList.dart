import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login/serverFunc.dart';
import 'package:login/calendar.dart';
import 'package:login/login.dart';
import 'package:firebase_auth/firebase_auth.dart';

class roomList extends StatelessWidget {
  const roomList({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatRoomPage(),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  Server server = Server();

  //방 리스트를 저장하기 Map 타입의 List
  //Map의 키는 'name': 방 이름, 'num': 방 번호이다
  List<Map<String, dynamic>> _roomList = [];

  _refresh() async
  {
    //새로고침 버튼을 눌렀을 때 서버로부터 방 정보를 다시 받아온다.
    _roomList = await server.getRoomInfo();
    setState(() {});
  }

  @override
  void initState()
  {
    //맨 처음 방에 들어갔을 때 서버로부터 방 정보를 불러온다.
    super.initState();
    Future.delayed(Duration.zero, () async{
      await _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //상단 앱바를 구성
      appBar: AppBar(
        title: const Text(
          "방 목록",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'GowunBatang',
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,

        backgroundColor: const Color(0xA545B0C5),
          actions:[
            //리프레쉬 버튼 추가
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _refresh();
              },
            ),
          ]
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _roomList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  //방 리스트를 보여 준다.
                  //방 리스트에는 방 이름하고 방 번호가 보인다.
                  title: Text(_roomList[index]['name']),
                  subtitle: Text("번호: ${_roomList[index]['num'].toString()}"),
                  onTap: () async {
                    //방을 클릭하면 해당 방의 정보가 담긴 캘린더 페이지로 이동한다.
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (
                      context) => CalendarPageHome(_roomList[index]['num'])));
                    if(result != null && result == 'deleteRoom')
                    {
                      //캘린더 페이지에서 방 리스트 화면으로 이동할 때 방을 삭제한 것일 때 실행
                      //캘린더 방에서 나갔을 때 방 리스트에서도 삭제하기 위해 사용
                      _roomList.removeAt(index);
                      setState(() {});
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          //하단 메뉴를 구성하기 위해 사용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                //방생성 버튼을 구현
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _createNewRoom();
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, backgroundColor: const Color(0xA545B0C5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'GowunBatang',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.40,
                      ),
                    ),
                    child: const Text('방 생성'),
                  ),
                ),
                const SizedBox(width: 20), // 버튼 사이의 간격 조정

                //방 참여 버튼을 구현
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _joinNewRoom();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black, side: const BorderSide(color: Color(0xA545B0C5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'GowunBatang',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.40,
                      ),
                    ),
                    child: const Text('방 참여'),
                  ),
                ),
                const SizedBox(width: 20), // 버튼 사이의 간격 조정
                //==========================수정
                // 설정 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showSettingsDialog(context),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: const Color(0xA545B0C5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'GowunBatang',
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.40,
                      ),
                    ),
                    child: const Text('설정'),
                  ),
                ),
                //==============수정끝
              ],
            ),
          ),
        ],
      ),
    );
  }

  //새로운 방을 생성하는 팝업을 띄워주는 기능
  void _createNewRoom() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        DateTime? startDate;
        DateTime? endDate;

        return AlertDialog(
          title: const Text('새로운 방 만들기'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '방 이름'),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          startDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().toUtc(),
                            firstDate: DateTime.utc(2001, 1, 1),
                            lastDate: DateTime.utc(2100, 12, 31),
                          );
                          setState(() {});
                        },
                        child: const Text('시작 날짜 선택'),
                      ),
                      const SizedBox(width: 10),
                      Text(startDate != null ? startDate!.toLocal().toString().split(' ')[0] : '선택되지 않음'),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          endDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().toUtc(),
                            firstDate: DateTime.utc(2001, 1, 1),
                            lastDate: DateTime.utc(2100, 12, 31),
                          );
                          setState(() {});
                        },
                        child: const Text('종료 날짜 선택'),
                      ),
                      const SizedBox(width: 10),
                      Text(endDate != null ? endDate!.toLocal().toString().split(' ')[0] : '선택되지 않음'),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('만들기'),
              onPressed: () async{
                //방 만들기 버튼을 눌렀을 때 시작 날짜, 종료 날짜, 방 이름을 서버로 전송해서 방을 만든다.
                if (startDate!.isAfter(endDate!) == false)
                {
                  startDate = DateTime.utc(startDate!.year, startDate!.month, startDate!.day);
                  endDate = DateTime.utc(endDate!.year, endDate!.month, endDate!.day);
                  await server.createRoom(titleController.text, startDate!, endDate!);
                  _refresh();   //리프레쉬하면서 서버로부터 방 번호를 부여받는다.
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _joinNewRoom() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController roomNumString = TextEditingController();
        int roomNum = 0;

        return AlertDialog(
          title: const Text('방 참여하기'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: roomNumString,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: const InputDecoration(labelText: '방 번호 6자리를 입력해주세요.'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('참가'),
              onPressed: () async{
                roomNum = int.parse(roomNumString.text);
                if (await server.inviteRoom(roomNum));
                {
                  _refresh();   //리프레쉬하면서 방 정보를 불러온다.
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(fixedSize: MaterialStateProperty.all(const Size(150, 40))),
                onPressed: () {
                  _changeNickNameDialog(context);
                },
                child: const Text('닉네임 변경'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ButtonStyle(fixedSize: MaterialStateProperty.all(const Size(150, 40))),
                onPressed: () async {
                  bool? shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('로그아웃'),
                        content: const Text('정말 로그아웃 하시겠습니까?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('취소'),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                          TextButton(
                            child: const Text('확인'),
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                          ),
                        ],
                      );
                    },
                  );

                  if (shouldLogout == true) {
                    // 로그아웃 로직을 처리하는 코드 (예시에서는 server.logout()을 호출하고 LoginPage로 이동)
                    await server.logout();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                        builder: (BuildContext context) => const LoginPage()), (route) => false);
                  }
                },
                child: const Text('로그아웃'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ButtonStyle(fixedSize: MaterialStateProperty.all(const Size(150, 40))),
                onPressed: () {
                  // 비밀번호 변경 팝업을 띄우는 로직
                  _showChangePasswordDialog(context);
                },
                child: const Text('비밀번호 변경'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ButtonStyle(fixedSize: MaterialStateProperty.all(const Size(150, 40))),
                onPressed: () {
                  // 회원 탈퇴 팝업을 띄우는 로직
                  _showDeleteAccountDialog(context);
                },
                child: const Text('회원 탈퇴'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _changeNickNameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final newNickName = TextEditingController();
        return AlertDialog(
          title: const Text('닉네임 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("현재 닉네임: ${server.getUserName() ?? 'Null'}"),
              // 비밀번호 변경 관련 UI 추가
              TextFormField(
                // 현재 비밀번호 입력 필드
                controller: newNickName,
                decoration: const InputDecoration(labelText: '새 닉네임'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () async {
                if(await server.changeNickName(newNickName.text))
                {
                  Navigator.of(context).pop(); // 팝업 닫기
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currentPassword = TextEditingController();
        final newPassword = TextEditingController();
        return AlertDialog(
          title: const Text('비밀번호 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 비밀번호 변경 관련 UI 추가
              TextFormField(
                // 현재 비밀번호 입력 필드
                obscureText: true,
                controller: currentPassword,
                decoration: const InputDecoration(labelText: '현재 비밀번호'),
              ),
              TextFormField(
                // 새 비밀번호 입력 필드
                obscureText: true,
                controller: newPassword,
                decoration: const InputDecoration(labelText: '새 비밀번호'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () async{
                if(await server.changePassword(currentPassword.text, newPassword.text))
                {
                  Navigator.of(context).pop(); // 팝업 닫기
                }
              },
              child: const Text('변경'),
            ),

          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currentPassword = TextEditingController();
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("모든 방에서 나간 후 회원 탈퇴가 가능합니다."),
              const SizedBox(height: 15,),
              // 비밀번호 변경 관련 UI 추가
              TextFormField(
                // 현재 비밀번호 입력 필드
                obscureText: true,
                controller: currentPassword,
                decoration: const InputDecoration(labelText: '현재 비밀번호'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () async {
                bool? shouldDeleteAccount = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: const Text('정말 회원탈퇴 하시겠습니까?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('취소'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: const Text('확인'),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );
                if (shouldDeleteAccount == true)
                {
                  if(await server.deleteAccount(currentPassword.text))
                  {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                        builder: (BuildContext context) => const LoginPage()), (route) => false);
                  }
                }
              },
              child: const Text('탈퇴'),
            ),
          ],
        );
      },
    );
  }
}
