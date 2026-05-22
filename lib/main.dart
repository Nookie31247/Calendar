import 'package:flutter/material.dart';
import 'package:login/serverFunc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login/login.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  Server server = Server();
  await server.init();    //서버에 접속하기 위해 사용한다.
  runApp(const LoginPage());    //맨 처음 실행하면 로그인 페이지를 띄워 준다.
}
