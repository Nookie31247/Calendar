import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:login/serverFunc.dart';
import 'package:login/roomList.dart';

class CalendarPage extends StatelessWidget {
  int roomNum = 0;
  CalendarPage(this.roomNum, {super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalendarPageHome(roomNum),
    );
  }
}

//유저의 이벤트 정보를 정의한다.
class Event
{
  String desc;      //이벤트의 내용
  String code = "";   //서버에서 부여하는 이벤트 고유 식별 코드
  int owner = 0;      //이벤트의 주인(0 ~ 5 사이)
  DateTime startDate, endDate;  //이벤트의 시작 날짜와 종료 날짜
  Event(this.desc, this.startDate, this.endDate, this.owner);   //이벤트 객체를 생성할 때 입력해야 하는 내용들
  Event.forServer(this.desc, this.startDate, this.endDate, this.owner, this.code);    //serverFunc에서 이벤트 객체를 생성할 때 입력해야 하는 내용들
}

class CalendarPageHome extends StatefulWidget {
  int roomNum = 0;
  CalendarPageHome(this.roomNum, {super.key});
  @override
  _CalendarPageState createState() => _CalendarPageState(roomNum);
}

class _CalendarPageState extends State<CalendarPageHome> {
  CalendarFormat _calendarFormat = CalendarFormat.month;    //캘린더의 포멧을 저장한다(월, 2주, 1주일)
  DateTime _firstDay = DateTime.utc(1970, 1, 1);            //캘린더의 시작 날짜를 저장한다.
  DateTime _lastDay = DateTime.utc(2100, 12, 31);           //캘린더의 종료 날짜를 저장한다.
  DateTime _focusedDay = DateTime.now().toUtc();            //캘린더 화면이 집중되는 날짜를 저장한다.
  DateTime? _selectedDay;                                   //선택된 날짜를 저장한다. 선택된 날짜는 동그랗게 하이라이트된다.
  int roomNum = 0;                                          //서버에서 부여받은 6자리의 방 번호를 저장한다.
  String roomName = '';                                     //방 생성할 때 설정한 방 이름을 저장한다.
  int owner = 0;                                            //현재 접속한 유저가 이 방에서 무슨 색인지 저장한다. (0 ~ 5 사이)
  List<String> userList = List<String>.filled(6, "");       //최대 6명의 유저의 이름을 저장한다.
  bool _initBuild = true;                                   //맨 처음 캘린더에 들어올 때, 미리 서버로부터 정보를 받아온 후 생성하기 위해 사용한다.
  bool _emptyDayAccent = false;                             //유저들이 선택하지 않은 날짜를 강조해서 보여줄지 여부를 저장한다..
  Server server = Server();

  final List<Color> colorList = [
    Colors.yellow,
    Colors.green,
    Colors.blueAccent,
    Colors.red,
    Colors.purple,
    Colors.orange,

  ];                      //6명의 유저 고유 색상을 설정한다.
  List<Event> _eventList = [];                              //모든 유저의 이벤트 정보를 저장한다.
  final Map<DateTime, List<Event>> _eventMap = {};          //이벤트 마커를 표시하기 위해 이벤트들을 Map 타입으로 저장한다.

  _CalendarPageState(int inputRoomNum)
  {
    //이 클래스의 생성자이다.
    roomNum = inputRoomNum;   //roomNum에 6자리의 방 번호를 저장한다.
  }

  void _setEvent()
  {
    //_eventList에 저장된 이벤트들은 Map 타입인 _eventMap에 변환하여 저장하기 위해 사용한다.
    _eventMap.clear();
    for(Event event in _eventList)
    {
      for(int i = 0; i <= event.endDate.difference(event.startDate).inDays; i++)
      {
        DateTime currentDate = event.startDate.add(Duration(days: i));
        if (_eventMap[currentDate] == null)
        {
          _eventMap[currentDate] = [event];
        }
        else
        {
          _eventMap[currentDate]?.add(event);
        }
      }
    }
  }

  List<Event> _getEventsForDay (DateTime day)
  {
    //각 요일마다 마커를 찍기 위해 사용.
    //eventMap[day]에 값이 있으면 그 값을 반환하고, 없으면 빈 리스트[] 를 반환합니다.
    return _eventMap[day] ?? [];
  }

  Future<bool> _refresh() async
  {
    //서버로부터 방 정보와 이벤트들을 불러오기 위해 사용한다.

    //서버로부터 방 정보를 불러온다.
    //불러오는 방 정보는 방 이름, 시작 날짜, 마지막 날짜, 현재 방에 참여한 유저의 정보이다.
    var serverData = await server.loadRoom(roomNum);
    roomName = serverData['name'];    //서버로부터 불러온 정보 중 방 이름을 저장한다.
    if (_firstDay != serverData['startDate'] || _lastDay != serverData['endDate'])
    {
      //서버로부터 불러온 시작 날짜와 마지막 날짜를 적용시킨다.
      _firstDay = serverData['startDate'];
      _lastDay = serverData['endDate'];
      _selectedDay = _focusedDay;
    }

    //서버로부터 불러온 현재 방에 참여한 유저 정보를 적용한다.
    owner = serverData['owner'];
    for(int i = 0; i < 6; i++)
    {
      userList[i] = serverData['user${(i + 1).toString()}Name'];
    }

    _eventList = await server.loadEvent(roomNum); //서버로부터 이벤트 정보들을 불러 온다.
    _setEvent();  //서버로부터 불러온 이벤트 정보들을 Map 타입으로 변환한다.
    setState(() {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Scaffold calendarBuild = Scaffold(
      //상단바를 설정한다.
      appBar: AppBar(
          title: Text(roomName),
          centerTitle: true,
          backgroundColor: Colors.blue.shade100,//Color(0xFFFEBE98),

          //뒤로가기 버튼
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context); // 뒤로가기 버튼 클릭 시 이전 화면으로 이동
            },
          ),
          actions:[
            //새로고침 버튼
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _refresh();
              },
            ),

            //우측 Drawer를 여는 버튼
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ]
      ),

      //우측 Drawer를 설정한다.
      //Drawer에는 내 정보, 현재 방에 참여한 인원, 방 번호, 방 나가기 버튼이 있다.
      endDrawer: Drawer(
          child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView( // Drawer 내용을 위한 ListView
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      UserAccountsDrawerHeader( // 사용자 정보 표시 부분
                        accountName: Text(server.getUserName().toString(), style: const TextStyle(color: Colors.black)),    //사용자의 이름을 표시
                        accountEmail: Text(server.getUserEmail().toString(),style: const TextStyle(color: Colors.black)),   //사용자의 이메일을 표시
                        decoration: BoxDecoration(color: Colors.blue.shade100,),
                        //동그란 유저 프로필 이미지 생성
                        currentAccountPicture: CircleAvatar(
                          backgroundColor: colorList[owner],
                          child: Text(server.getUserName()!.substring(0, 1),    //유저 이름의 맨 앞글자를 따온다.
                            style: const TextStyle(fontSize: 50.0),
                          ),
                        ),
                      ),

                      //방에 참여한 유저들의 이름과 색상 정보를 표시한다.
                      ...userList.asMap().entries.map((user)
                      {
                        if(user.value == "")
                        {
                          return Container();
                        }
                        else
                        {
                          return ListTile(
                            title: Text(user.value),
                            leading: Icon(
                              Icons.circle,
                              color: colorList[user.key],
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),
                ListTile(
                  title: Row(
                    children: <Widget>[
                      Text('방 번호: ${roomNum.toString()}'),    //방 번호 6자리를 출력한다.
                      Expanded(child: Container()),
                      //============수정
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          bool? shouldExit = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('방 나가기'),
                                content: const Text('정말 방을 나가시겠습니까?'),
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

                          if (shouldExit == true) {
                            await server.exitRoom(roomNum);
                            Navigator.pop(context);
                            Navigator.pop(context, 'deleteRoom');
                          }
                        },
                      )
                      //=================수정끝
                    ],
                  ),
                  tileColor: Colors.blue.shade100,
                )
              ]
          )
      ),

      //캘린더 본체를 구성한다.
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            daysOfWeekHeight: 30,//==========추가
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,

            onDaySelected: (selectedDay, focusedDay) {
              //날짜를 클릭할 시 selectedDay와 focusedDay의 값을 바꿔 준다.
              //그리고 이벤트 생성 팝업을 띄운다.
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showEventDialog(selectedDay);
            },

            onFormatChanged: (format) {
              //캘린더의 포멧을 변경한다.
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },

            onPageChanged: (focusedDay) {
              //캘린더 페이지를 변경할 때 강조 날짜를 변경해 준다.
              _focusedDay = focusedDay;
            },

            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },

            calendarStyle: const CalendarStyle(
              //최대 마커 개수를 6개로 제한한다.
              markersMaxCount: 6,
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                if (day.weekday == DateTime.sunday) {
                  return const Center(
                    child: Text(
                      '일',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                } else if (day.weekday == DateTime.saturday) {
                  return const Center(
                    child: Text(
                      '토',
                      style: TextStyle(color: Colors.blue),
                    ),
                  );
                }
                return null;
              },
              markerBuilder: (context, date, events) {
                //이벤트가 존재하는 날에 마커를 찍어 준다.
                if (events.isNotEmpty)
                {
                  return _buildMarker(date, events);
                }
                return null;
              },

              defaultBuilder: (context, day, focusedDay) {
                //이벤트가 없는 날짜를 강조하기 위해 사용한다.
                if(_eventMap[day] == null && _emptyDayAccent)
                {
                  //day에 이벤트가 없고, 유저가 빈 날짜 강조 기능을 활성화했을 때 빈 날짜를 강조해 준다.
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Colors.green[200],
                    ),
                    child: Text('${day.day}일'),
                  );
                }
                else
                {
                  // 이벤트가 있는 날짜에는 강조 표시를 하지 않는다.
                  return Container(
                    alignment: Alignment.center,
                    child: Text('${day.day}일'),
                  );
                }
              },

              selectedBuilder: (context, day, focusedDay) {
                //이벤트가 없는 날짜를 강조하기 위해 사용한다.
                //현재 선택된 날짜 또한 적용하기 위해 사용한다.
                if(_eventMap[day] == null && _emptyDayAccent)
                {
                  //day에 이벤트가 없고, 유저가 빈 날짜 강조 기능을 활성화했을 때 빈 날짜를 강조해 준다.
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Colors.green[200],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.circle, color: Colors.blue[200], size: 50,),
                        Text('${day.day}일'),
                      ],
                    )
                  );
                }
                else
                {
                  // 이벤트가 있는 날짜에는 강조 표시를 하지 않는다.
                  return Container(
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.circle, color: Colors.blue[200], size: 50,),
                        Text('${day.day}일'),
                      ],
                    )
                  );
                }
              },

              todayBuilder: (context, day, focusedDay) {
                //이벤트가 없는 날짜를 강조하기 위해 사용한다.
                //오늘 날짜 또한 적용하기 위해 사용한다.
                if(_eventMap[day] == null && _emptyDayAccent)
                {
                  //day에 이벤트가 없고, 유저가 빈 날짜 강조 기능을 활성화했을 때 빈 날짜를 강조해 준다.
                  return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Colors.green[200],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.circle, color: Colors.blue[100], size: 50,),
                          Text('${day.day}일'),
                        ],
                      )
                  );
                }
                else
                {
                  // 이벤트가 있는 날짜에는 강조 표시를 하지 않는다.
                  return Container(
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.circle, color: Colors.blue[100], size: 50,),
                          Text('${day.day}일'),
                        ],
                      )
                  );
                }
              },
            ),
          ),
          //==========================추가
          // FloatingActionButton(
          //   onPressed: () {
          //     setState(() {
          //       _emptyDayAccent = !_emptyDayAccent;
          //     });
          //   },
          //   child: Icon(
          //     _emptyDayAccent ? Icons.visibility_off : Icons.visibility,
          //   ),
          //   tooltip: 'Toggle empty day accent',
          // ),
          //==============================추가끝

          const Divider(height: 1, color: Colors.black87),  //캘린더와 이벤트 리스트 사이의 경계를 표시해 준다.

          //현재 접속한 유저의 이벤트 정보들을 보여준다.
          Expanded(
            child: ListView.builder(
                itemCount: _eventList.length,
                itemBuilder: (context, index) {
                  final event = _eventList[index];
                  if(event.owner == owner)
                  {
                    return ListTile(
                      title: Text(event.desc),
                      subtitle: Text(
                        '${event.startDate.year}년 ${event.startDate.month}월 ${event.startDate.day}일 - ${event.endDate.year}년 ${event.endDate.month}월 ${event.endDate.day}일',
                      ),
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorList[event.owner]
                        ),
                      ),
                      onTap: () {
                        //이벤트를 클릭할 시 해당 이벤트를 수정하거나 삭제할 수 있는 팝업을 띄워 준다.
                        _showEventEditDialog(event);
                      },
                    );
                  }
                  else {
                    return Container();
                  }
                }
            ),
          ),
        //=================추가
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _emptyDayAccent = !_emptyDayAccent;
                });
              },
              child: Icon(
                _emptyDayAccent ? Icons.visibility_off : Icons.visibility,
              ),
            ),
          ),
        ),
          //============추가 끝
      ],
    ),
    );

    //맨 처음 방에 들어올 때 서버에서 정보를 받아온 후에 위젯을 리프레쉬한다.
    //맨 처음 방에 들어오는 것이 아니라면 서버로부터 정보를 받아오지 않고 위젯을 리프레쉬한다.
    //이를 통해 서버의 부하를 최소화한다.
    if (_initBuild == true)
    {
      return FutureBuilder(
        future: _refresh(),
        builder: (context, snapshot) {
          _initBuild = false;
          if (snapshot.hasData == false) {
            return Container();
          }
          else {
            return calendarBuild;
          }
        },
      );
    }
    else
    {
      return calendarBuild;
    }
  }

  void _showEventDialog(DateTime selectedDay) {
    //새로운 이벤트를 생성하는 팝업이다.
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();    //새 일정의 내용을 입력받기 위한 텍스트 컨트롤러
        DateTime? startDate = selectedDay;                  //새 일정의 시작 날짜
        DateTime? endDate = selectedDay;                    //새 일정의 종료 날짜

        return AlertDialog(
          title: const Text('새 일정 추가'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '내용'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          startDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDay,
                            firstDate: _firstDay,
                            lastDate: _lastDay,
                          );
                          setState(() {});
                        },
                        child: const Text('시작 날짜 선택'),
                      ),
                      const SizedBox(width: 10),
                      Text(startDate != null ? startDate!.toLocal().toString().split(' ')[0] : '선택되지 않음'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          endDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDay,
                            firstDate: _firstDay,
                            lastDate: _lastDay,
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
              child: const Text('저장'),
              onPressed: () async{
                if (startDate!.isAfter(endDate!) == false)
                {
                  startDate = DateTime.utc(startDate!.year, startDate!.month, startDate!.day);
                  endDate = DateTime.utc(endDate!.year, endDate!.month, endDate!.day);
                  Event newEvent = Event(
                      titleController.text,
                      startDate!,
                      endDate!,
                      owner
                  );
                  String eventKey = await server.createEvent(roomNum, newEvent);
                  newEvent.code = eventKey;
                  _eventList.add(newEvent);
                  _setEvent();
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEventEditDialog(Event event) {
    //기존 일정을 수정하거나 삭제하는 팝업이다.
    final titleController = TextEditingController(text: event.desc);    //기존 일정의 내용을 수정하기 위한 텍스트 컨트롤러
    DateTime? startDate = event.startDate;                              //기존 일정의 시작 날짜 수정
    DateTime? endDate = event.endDate;                                  //기존 일저의 종료 날짜 수정

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('일정 수정'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '제목'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          startDate = await showDatePicker(
                            context: context,
                            initialDate: event.startDate,
                            firstDate: _firstDay,
                            lastDate: _lastDay,
                          );
                          setState(() {});
                        },
                        child: const Text('시작 날짜 선택'),
                      ),
                      const SizedBox(width: 10),
                      Text(startDate != null ? startDate!.toLocal().toString().split(' ')[0] : '선택되지 않음'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          endDate = await showDatePicker(
                            context: context,
                            initialDate: event.endDate,
                            firstDate: _firstDay,
                            lastDate: _lastDay,
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
              child: const Text('삭제'),
              onPressed: () async {
                await server.deleteEvent(roomNum, event.code);
                setState(() {
                  _eventList.remove(event);
                  _setEvent();
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('저장'),
              onPressed: () async{
                if (startDate!.isAfter(endDate!) == false)
                {
                  startDate = DateTime.utc(startDate!.year, startDate!.month, startDate!.day);
                  endDate = DateTime.utc(endDate!.year, endDate!.month, endDate!.day);
                  Event editedEvent = Event.forServer(titleController.text, startDate!, endDate!, owner, event.code);
                  await server.editEvent(roomNum, event.code, editedEvent);
                  setState(() {
                    event.desc = titleController.text;
                    event.startDate = startDate!;
                    event.endDate = endDate!;
                    _setEvent();
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMarker(DateTime date, List events)
  {
    //캘린더의 마커 디자인을 구성한다.

    //한 유저가 같은 날짜에 여러 이벤트를 등록한 경우, 마커는 하나만 찍어 준다.
    var uniqueOwners = events.map((event) => event.owner).toSet();

    return Positioned(
      top: 35,
      child: Column(
        children: [
          //마커의 개수가 4개 이상일 경우 2줄로 표시해 준다.
          Row(
            children: uniqueOwners.take(3).map((owner) {
              return Icon(
                size: 8,
                Icons.circle,
                color: colorList[owner],
              );
            }).toList(),
          ),
          Row(
            children: uniqueOwners.skip(3).map((owner) {
              return Icon(
                size: 9,
                Icons.circle,
                color: colorList[owner],
              );
            }).toList(),
          ),
        ],
      )
    );
  }
}