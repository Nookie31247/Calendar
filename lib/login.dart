import 'package:flutter/material.dart';
import 'package:login/signup.dart';
import 'package:login/serverFunc.dart';
import 'package:login/roomList.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreen createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();       //이메일을 입력받기 위해 사용
  final TextEditingController _passwordController = TextEditingController();    //비밀번호를 입력받기 위해 사용
  Server server = Server();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  //로그인 글씨
                  const Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  //이메일을 입력하는 필드
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16.0),

                  //비밀번호를 입력하는 필드
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,    //비밀번호 입력시 * 문자를 띄워 가려 준다.
                  ),
                  const SizedBox(height: 24.0),

                  //로그인 버튼
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF46B1C6), // 배경색 설정
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0), // 원하는 값으로 조절
                      ),
                      fixedSize: const Size(350, 55),
                    ),
                    onPressed: () async {
                      // 로그인 버튼이 눌렸을 때의 처리
                      // 아이디와 비밀번호를 사용하여 로그인을 시도하고 결과에 따라 처리
                      String email = _emailController.text.toString();
                      String password = _passwordController.text.toString();
                      if(await server.login(email, password))
                      {
                        //로그인 성공 시 방 리스트 화면으로 이동
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
                            builder: (BuildContext context) => const roomList()), (route) => false);
                      }
                    },

                    //로그인 버튼의 텍스트를 구성
                    child: Container(
                      alignment: Alignment.center,
                      child: const Text(
                        '로그인',
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
                  ),
                  const SizedBox(height: 8),

                  //회원가입 버튼을 구현
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          //회원가입 버튼을 클릭 시 회원가입 페이지로 이동
                          Navigator.push(context, MaterialPageRoute(builder: (
                              context) => SignUpPage()));
                        },
                        child: const Text(
                          "회원가입",
                          style: TextStyle(
                            fontSize: 15.0,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                    ],
                  ),
                ],
              )
          ),
        ),
      ),
    );
  }
}