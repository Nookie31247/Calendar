import 'package:flutter/material.dart';
import 'package:login/serverFunc.dart';
import 'package:login/roomList.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //상단 바 설정
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 400, // 최대 너비를 제한하여 중간 크기 화면에서 너무 넓어지지 않도록 합니다.
            ),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // 그림자의 위치를 설정
                ),
              ],
            ),
            child: const SignUpForm(),
          ),
        ),
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm>{
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _email = '';
  String _password = '';
  String _checkpassword = '';
  Server server = Server();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          //회원가입 문구
          const Text(
            '회원가입',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32.0),

          //이메일 입력 필드
          TextFormField(
            decoration: const InputDecoration(
              labelText: '이메일',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _email = value;
              });
            },
          ),
          const SizedBox(height: 16.0),

          //비밀번호 입력 필드
          TextFormField(
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
            obscureText: true,    //비밀번호 입력시 * 문자를 띄워 가려 준다.
            onChanged: (value) {
              setState(() {
                _password = value;
              });
            },
          ),
          const SizedBox(height: 16.0),

          //비밀번호 확인 입력 필드
          TextFormField(
            decoration: const InputDecoration(
              labelText: '비밀번호 확인',
              border: OutlineInputBorder(),
            ),
            obscureText: true,    //비밀번호 입력시 * 문자를 띄워 가려 준다.
            onChanged: (value) {
              setState(() {
                _checkpassword = value;
              });
            },
          ),
          const SizedBox(height: 16.0),

          //닉네임 입력 필드
          TextFormField(
            decoration: const InputDecoration(
              labelText: '닉네임',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _username = value;
              });
            },
          ),
          const SizedBox(height: 24.0),

          //가입하기 버튼
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF46B1C6), // 배경색 설정
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // 원하는 값으로 조절
              ),
              fixedSize: const Size(350, 55),
            ),
            onPressed: () async {
              //가입하기 버튼을 눌렀을 때의 처리
              if (await server.createAccount(_email, _password, _checkpassword, _username)) {
                //정보가 맞게 입력되었다면 로그인 후 방 리스트 화면으로 이동
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                    builder: (BuildContext context) => const roomList()), (route) => false);
              }
            },

            //가입하기 버튼을 구현
            child: const Text('가입하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'GowunBatang',
                fontWeight: FontWeight.w700,
                height: 0,
                letterSpacing: -0.40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}